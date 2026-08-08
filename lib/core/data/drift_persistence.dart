import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import 'attachment_file_store.dart';
import 'db_codec.dart';
import 'drift/app_database.dart';
import 'in_memory_database.dart';
import 'local_persistence.dart';
import 'persistence.dart' show kSnapshotKey;

/// Persistencia local sobre **SQLite cifrado (Drift + SQLCipher)** para móvil y
/// escritorio (RNF-10). Es la implementación de [LocalPersistence] que sustituye
/// al snapshot en `shared_preferences` en las plataformas con llavero del SO.
///
/// Estrategia: el modelo reactivo [InMemoryDatabase] sigue siendo la fuente de
/// verdad en memoria; esta clase lo **hidrata al arrancar** (lectura única) y
/// **persiste en segundo plano** ante cada cambio con un reemplazo transaccional
/// completo (replace-all). Reutiliza [DbCodec] como formato de fila para no
/// duplicar el mapeo de dominio.
///
/// Los **adjuntos** guardan su binario en el **filesystem** ([AttachmentFileStore],
/// RF-29 / RNF-04): la fila solo lleva la **ruta** (`filePath` en el JSON); al
/// cargar se rehidrata `dataBase64` en memoria para no tocar el render ni el
/// respaldo.
///
/// La API es síncrona (contrato de [LocalPersistence]); las escrituras a Drift y
/// a los archivos se difieren y se serializan en una cadena para no solaparse.
class DriftPersistence implements LocalPersistence {
  DriftPersistence._(this._db, this._files, this._cached, {this.onError});

  final AppDatabase _db;
  final AttachmentFileStore _files;

  /// Snapshot (formato [DbCodec], con `dataBase64` ya hidratado) leído al abrir,
  /// usado por [loadInto].
  Map<String, dynamic> _cached;

  /// Se invoca si falla una escritura diferida (p. ej. para el crash reporter).
  final void Function(Object error, StackTrace stack)? onError;

  /// Cadena que serializa las escrituras diferidas.
  Future<void> _writeChain = Future<void>.value();

  static const String _appStateKind = '__app_state__';
  static const String _attachmentsKind = 'attachments';

  /// Abre la persistencia: lee el estado actual (rehidratando los adjuntos desde
  /// disco) y, si la base está vacía y hay un snapshot previo en [prefs]
  /// (instalación que se actualiza), lo **migra** a la base cifrada + filesystem
  /// sin pérdida de datos.
  static Future<DriftPersistence> open(
    AppDatabase db,
    AttachmentFileStore files, {
    SharedPreferences? prefs,
    void Function(Object error, StackTrace stack)? onError,
  }) async {
    final rows = await db.readAll();
    var cached = await _fromRows(rows, files);

    if (rows.isEmpty) {
      final raw = prefs?.getString(kSnapshotKey);
      if (raw != null && raw.isNotEmpty) {
        try {
          final snap = (jsonDecode(raw) as Map).cast<String, dynamic>();
          final temp = InMemoryDatabase();
          DbCodec.decodeInto(temp, snap);
          final encoded = DbCodec.encode(temp);
          await db.replaceAll(await _toRows(encoded, files));
          cached = encoded;
          // El snapshot antiguo se conserva como respaldo de seguridad; una
          // versión futura puede limpiarlo tras confirmar la migración.
        } catch (_) {
          // Snapshot corrupto o incompatible: se ignora y se arranca vacío.
        }
      }
    }

    return DriftPersistence._(db, files, cached, onError: onError);
  }

  @override
  bool loadInto(InMemoryDatabase db) {
    DbCodec.decodeInto(db, _cached);
    return db.pets.isNotEmpty;
  }

  @override
  void save(InMemoryDatabase db) {
    final encoded = DbCodec.encode(db);
    _cached = encoded;
    _writeChain = _writeChain.then((_) async {
      final rows = await _toRows(encoded, _files);
      await _db.replaceAll(rows);
    }).catchError((Object e, StackTrace s) {
      onError?.call(e, s);
    });
  }

  /// En SQLite no existe el rechazo por cuota de `localStorage`: se acepta de
  /// forma optimista y la escritura se difiere.
  @override
  bool trySave(InMemoryDatabase db) {
    save(db);
    return true;
  }

  @override
  Future<void> deleteAllAttachmentFiles() => _files.deleteAll();

  /// Espera a que terminen las escrituras diferidas pendientes. Útil en pruebas
  /// y antes de cerrar la app para garantizar la persistencia.
  Future<void> flush() => _writeChain;

  @override
  void attachAutosave(InMemoryDatabase db) {
    var scheduled = false;
    db.addListener(() {
      if (scheduled) return;
      scheduled = true;
      Future.microtask(() {
        scheduled = false;
        save(db);
      });
    });
  }

  // ---- mapeo entidad <-> fila ------------------------------------------

  /// Convierte el map de [DbCodec] en filas. Para los adjuntos, escribe los bytes
  /// al filesystem y guarda la ruta (`filePath`) en el JSON, dejando la columna
  /// BLOB nula; además borra los archivos huérfanos.
  static Future<List<EntitiesCompanion>> _toRows(
    Map<String, dynamic> encoded,
    AttachmentFileStore files,
  ) async {
    final rows = <EntitiesCompanion>[];
    final scalars = <String, dynamic>{};
    final attachmentIds = <String>{};

    for (final entry in encoded.entries) {
      final key = entry.key;
      final value = entry.value;
      if (value is! List) {
        scalars[key] = value;
        continue;
      }
      for (final entity in value.cast<Map<String, dynamic>>()) {
        final id = ((entity['meta'] as Map)['id']) as String;
        if (key == _attachmentsKind) {
          attachmentIds.add(id);
          final copy = Map<String, dynamic>.from(entity);
          final b64 = copy.remove('dataBase64') as String?;
          if (b64 != null && b64.isNotEmpty) {
            copy['filePath'] = await files.write(id, base64Decode(b64));
          }
          rows.add(EntitiesCompanion.insert(
            kind: key,
            id: id,
            data: jsonEncode(copy),
          ));
        } else {
          rows.add(EntitiesCompanion.insert(
            kind: key,
            id: id,
            data: jsonEncode(entity),
          ));
        }
      }
    }

    rows.add(EntitiesCompanion.insert(
      kind: _appStateKind,
      id: '0',
      data: jsonEncode(scalars),
    ));

    // Elimina los archivos de adjuntos que ya no existen en la base.
    await files.retainOnly(attachmentIds);
    return rows;
  }

  /// Reconstruye el map de [DbCodec] a partir de las filas, rehidratando el
  /// `dataBase64` de los adjuntos desde su archivo (o desde la columna BLOB si
  /// viniera de una versión anterior).
  static Future<Map<String, dynamic>> _fromRows(
    List<EntityRow> rows,
    AttachmentFileStore files,
  ) async {
    final map = <String, dynamic>{};
    for (final row in rows) {
      if (row.kind == _appStateKind) {
        map.addAll((jsonDecode(row.data) as Map).cast<String, dynamic>());
        continue;
      }
      final entity = (jsonDecode(row.data) as Map).cast<String, dynamic>();
      if (row.kind == _attachmentsKind) {
        entity['dataBase64'] = await _attachmentBase64(entity, row, files);
        entity.remove('filePath');
      }
      (map.putIfAbsent(row.kind, () => <Map<String, dynamic>>[])
              as List<Map<String, dynamic>>)
          .add(entity);
    }
    return map;
  }

  static Future<String> _attachmentBase64(
    Map<String, dynamic> entity,
    EntityRow row,
    AttachmentFileStore files,
  ) async {
    final path = entity['filePath'] as String?;
    if (path != null && path.isNotEmpty) {
      final bytes = await files.readBytes(path);
      if (bytes != null) return base64Encode(bytes);
    }
    // Compatibilidad con datos previos que guardaban el binario en la columna.
    final Uint8List? legacy = row.bytes;
    return legacy == null ? '' : base64Encode(legacy);
  }
}
