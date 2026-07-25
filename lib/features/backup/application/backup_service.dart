import 'dart:convert';

import '../../../core/data/db_codec.dart';
import '../../../core/data/in_memory_database.dart';
import '../data/file_transfer.dart';
import '../domain/backup_result.dart';

/// Exporta e importa el respaldo local (RF-41..RF-46).
///
/// El respaldo es el mismo snapshot JSON versionado de [DbCodec], de modo que
/// el formato sirve también para la migración a la API de la Fase 2. La
/// restauración se aplica sobre una base intermedia (staging): si el archivo
/// está dañado, los datos actuales no se tocan.
class BackupService {
  BackupService(this._db, this._files);

  final InMemoryDatabase _db;
  final FileTransfer _files;

  /// Si esta plataforma puede seleccionar un archivo para restaurar.
  bool get canImport => _files.canPickFile;

  /// Crea y descarga/guarda el respaldo. Devuelve la ruta de destino (móvil) o
  /// `null` cuando el navegador lo descarga sin ruta accesible.
  Future<String?> export() {
    final json = const JsonEncoder.withIndent('  ').convert(DbCodec.encode(_db));
    return _files.saveText(_fileName(), json);
  }

  Future<BackupImportResult> import() async {
    final picked = await _files.pickTextFile();
    if (picked == null) return const BackupImportResult.cancelled();

    final Object? decoded;
    try {
      decoded = jsonDecode(picked.content);
    } catch (_) {
      return const BackupImportResult.invalid(
          'No pudimos leer el archivo: no es un JSON válido.');
    }
    if (decoded is! Map) {
      return const BackupImportResult.invalid(
          'El archivo no tiene el formato de un respaldo de PituApp.');
    }

    final map = decoded.cast<String, dynamic>();
    final version = map['schemaVersion'];
    if (version is! int) {
      return const BackupImportResult.invalid(
          'El archivo no parece un respaldo de PituApp.');
    }
    if (version > DbCodec.schemaVersion) {
      return const BackupImportResult.invalid(
          'Este respaldo se creó con una versión más nueva de PituApp. '
          'Actualiza la app para restaurarlo.');
    }

    // Se decodifica primero en una base intermedia para no dejar la BD real a
    // medias si el archivo está incompleto.
    final staging = InMemoryDatabase();
    try {
      DbCodec.decodeInto(staging, map);
    } catch (_) {
      return const BackupImportResult.invalid(
          'El respaldo está incompleto o dañado; no se aplicaron cambios.');
    }

    _applyFrom(staging);
    _db.bump();

    return BackupImportResult.success(
      pets: _db.pets.where((p) => !p.meta.isDeleted).length,
      records: _db.visits.length +
          _db.vaccines.length +
          _db.weights.length +
          _db.diagnoses.length,
    );
  }

  void _applyFrom(InMemoryDatabase src) {
    _db.pets
      ..clear()
      ..addAll(src.pets);
    _db.careTypes
      ..clear()
      ..addAll(src.careTypes);
    _db.schedules
      ..clear()
      ..addAll(src.schedules);
    _db.executions
      ..clear()
      ..addAll(src.executions);
    _db.diagnoses
      ..clear()
      ..addAll(src.diagnoses);
    _db.weights
      ..clear()
      ..addAll(src.weights);
    _db.visits
      ..clear()
      ..addAll(src.visits);
    _db.vaccines
      ..clear()
      ..addAll(src.vaccines);
    _db.attachments
      ..clear()
      ..addAll(src.attachments);
    _db.ownerName = src.ownerName;
    _db.biometricLockEnabled = src.biometricLockEnabled;
  }

  String _fileName() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return 'pitu-respaldo-${now.year}${two(now.month)}${two(now.day)}.json';
  }
}
