import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:shared_preferences/shared_preferences.dart';

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
/// duplicar el mapeo de dominio; los adjuntos guardan su binario en una columna
/// BLOB, fuera del JSON.
///
/// La API es síncrona (contrato de [LocalPersistence]); las escrituras a Drift
/// se difieren y se serializan en una cadena para no solapar transacciones.
class DriftPersistence implements LocalPersistence {
  DriftPersistence._(this._db, this._cached, {this.onError});

  final AppDatabase _db;

  /// Snapshot (formato [DbCodec]) leído al abrir, usado por [loadInto].
  Map<String, dynamic> _cached;

  /// Se invoca si falla una escritura diferida (p. ej. para el crash reporter).
  final void Function(Object error, StackTrace stack)? onError;

  /// Cadena que serializa las escrituras diferidas.
  Future<void> _writeChain = Future<void>.value();

  static const String _appStateKind = '__app_state__';

  /// Abre la persistencia: lee el estado actual y, si la base está vacía y hay
  /// un snapshot previo en [prefs] (instalación que se actualiza), lo **migra**
  /// a la base cifrada sin pérdida de datos.
  static Future<DriftPersistence> open(
    AppDatabase db, {
    SharedPreferences? prefs,
    void Function(Object error, StackTrace stack)? onError,
  }) async {
    final rows = await db.readAll();
    var cached = _fromRows(rows);

    if (rows.isEmpty) {
      final raw = prefs?.getString(kSnapshotKey);
      if (raw != null && raw.isNotEmpty) {
        try {
          final snap = (jsonDecode(raw) as Map).cast<String, dynamic>();
          final temp = InMemoryDatabase();
          DbCodec.decodeInto(temp, snap);
          final encoded = DbCodec.encode(temp);
          await db.replaceAll(_toRows(encoded));
          cached = encoded;
          // El snapshot antiguo se conserva como respaldo de seguridad; una
          // versión futura puede limpiarlo tras confirmar la migración.
        } catch (_) {
          // Snapshot corrupto o incompatible: se ignora y se arranca vacío.
        }
      }
    }

    return DriftPersistence._(db, cached, onError: onError);
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
    final rows = _toRows(encoded);
    _writeChain = _writeChain.then((_) => _db.replaceAll(rows)).catchError(
      (Object e, StackTrace s) {
        onError?.call(e, s);
      },
    );
  }

  /// En SQLite no existe el rechazo por cuota de `localStorage`: se acepta de
  /// forma optimista y la escritura se difiere.
  @override
  bool trySave(InMemoryDatabase db) {
    save(db);
    return true;
  }

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

  /// Convierte el map de [DbCodec] en filas ([kind], [id], data, bytes).
  static List<EntitiesCompanion> _toRows(Map<String, dynamic> encoded) {
    final rows = <EntitiesCompanion>[];
    final scalars = <String, dynamic>{};

    encoded.forEach((key, value) {
      if (value is! List) {
        scalars[key] = value;
        return;
      }
      for (final entity in value.cast<Map<String, dynamic>>()) {
        final id = ((entity['meta'] as Map)['id']) as String;
        if (key == 'attachments') {
          final copy = Map<String, dynamic>.from(entity);
          final b64 = copy.remove('dataBase64') as String?;
          rows.add(EntitiesCompanion.insert(
            kind: key,
            id: id,
            data: jsonEncode(copy),
            bytes: Value(
              (b64 == null || b64.isEmpty) ? null : base64Decode(b64),
            ),
          ));
        } else {
          rows.add(EntitiesCompanion.insert(
            kind: key,
            id: id,
            data: jsonEncode(entity),
          ));
        }
      }
    });

    rows.add(EntitiesCompanion.insert(
      kind: _appStateKind,
      id: '0',
      data: jsonEncode(scalars),
    ));
    return rows;
  }

  /// Reconstruye el map de [DbCodec] a partir de las filas leídas.
  static Map<String, dynamic> _fromRows(List<EntityRow> rows) {
    final map = <String, dynamic>{};
    for (final row in rows) {
      if (row.kind == _appStateKind) {
        map.addAll((jsonDecode(row.data) as Map).cast<String, dynamic>());
        continue;
      }
      final entity = (jsonDecode(row.data) as Map).cast<String, dynamic>();
      if (row.kind == 'attachments') {
        final Uint8List? bytes = row.bytes;
        entity['dataBase64'] = bytes == null ? '' : base64Encode(bytes);
      }
      (map.putIfAbsent(row.kind, () => <Map<String, dynamic>>[])
              as List<Map<String, dynamic>>)
          .add(entity);
    }
    return map;
  }
}
