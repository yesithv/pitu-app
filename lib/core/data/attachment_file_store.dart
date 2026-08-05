import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Almacén de los binarios de los adjuntos en el **sistema de archivos** de la
/// app (RF-29 / RNF-04): la base de datos guarda solo la ruta, el contenido vive
/// en `<documentos de la app>/attachments/<id>`.
///
/// Solo móvil/escritorio (`dart:io`): en web no hay filesystem y los adjuntos
/// siguen en el snapshot. Se usa desde la persistencia Drift.
class AttachmentFileStore {
  AttachmentFileStore(this._dir);

  final Directory _dir;

  /// Abre (creando si hace falta) la carpeta de adjuntos bajo el directorio de
  /// documentos de la app.
  static Future<AttachmentFileStore> open() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'attachments'));
    final store = AttachmentFileStore(dir);
    await store._ensureDir();
    return store;
  }

  Future<void> _ensureDir() async {
    if (!await _dir.exists()) await _dir.create(recursive: true);
  }

  String pathFor(String id) => p.join(_dir.path, id);

  /// Escribe los bytes del adjunto [id] y devuelve la ruta absoluta.
  Future<String> write(String id, Uint8List bytes) async {
    await _ensureDir();
    final file = File(pathFor(id));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  /// Lee los bytes de un archivo; `null` si no existe.
  Future<Uint8List?> readBytes(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  /// Borra un archivo (no falla si ya no existe).
  Future<void> delete(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  /// Elimina todos los adjuntos (para "borrar todos mis datos", RNF-13).
  Future<void> deleteAll() async {
    if (await _dir.exists()) await _dir.delete(recursive: true);
    await _ensureDir();
  }

  /// Conserva solo los archivos cuyos [ids] siguen vigentes; borra el resto
  /// (evita adjuntos huérfanos tras eliminar registros).
  Future<void> retainOnly(Set<String> ids) async {
    if (!await _dir.exists()) return;
    await for (final entity in _dir.list()) {
      if (entity is File && !ids.contains(p.basename(entity.path))) {
        await entity.delete();
      }
    }
  }

  /// Suma el tamaño de todos los adjuntos en disco (RNF-06).
  Future<int> totalBytes() async {
    if (!await _dir.exists()) return 0;
    var total = 0;
    await for (final entity in _dir.list()) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }
}
