import 'dart:convert';

import '../../../core/data/db_codec.dart';
import '../../../core/data/in_memory_database.dart';
import '../../../core/data/local_persistence.dart';
import '../data/file_transfer.dart';
import '../domain/backup_result.dart';

/// Modo de importación (RF-43): reemplazar todo o combinar por UUID.
enum BackupMode { replace, combine }

/// Resumen del contenido de un respaldo, mostrado antes de importar (RF-42).
class BackupPreview {
  BackupPreview({
    required this.data,
    required this.pets,
    required this.records,
    required this.attachments,
    required this.exportedAt,
  });

  final Map<String, dynamic> data;
  final int pets;
  final int records;
  final int attachments;
  final DateTime? exportedAt;
}

/// Resultado de seleccionar un archivo para previsualizar.
class BackupPickResult {
  const BackupPickResult._(this.preview, this.error, this.cancelled);
  factory BackupPickResult.preview(BackupPreview p) =>
      BackupPickResult._(p, null, false);
  factory BackupPickResult.invalid(String message) =>
      BackupPickResult._(null, message, false);
  const BackupPickResult.cancelled() : this._(null, null, true);

  final BackupPreview? preview;
  final String? error;
  final bool cancelled;
}

/// Exporta e importa el respaldo local (RF-41..RF-46).
class BackupService {
  BackupService(this._db, this._files, this._persistence);

  final InMemoryDatabase _db;
  final FileTransfer _files;
  final LocalPersistence? _persistence;

  bool get canImport => _files.canPickFile;

  /// Crea y descarga/comparte el respaldo; registra la fecha (RF-46).
  /// Devuelve la ruta (móvil) o `null` en web, o lanza si algo falla.
  Future<String?> export() async {
    final payload = <String, dynamic>{
      ...DbCodec.encode(_db),
      'exportedAt': DateTime.now().toIso8601String(),
    };
    final json = const JsonEncoder.withIndent('  ').convert(payload);
    final path = await _files.saveText(_fileName(), json);
    _db.lastBackupAt = DateTime.now();
    _persistence?.trySave(_db);
    _db.bump();
    return path;
  }

  /// Selecciona un archivo y devuelve su resumen sin aplicar nada aún (RF-42).
  Future<BackupPickResult> pickForImport() async {
    final picked = await _files.pickTextFile();
    if (picked == null) return const BackupPickResult.cancelled();

    final Object? decoded;
    try {
      decoded = jsonDecode(picked.content);
    } catch (_) {
      return BackupPickResult.invalid(
          'No pudimos leer el archivo: no es un JSON válido.');
    }
    if (decoded is! Map) {
      return BackupPickResult.invalid(
          'El archivo no tiene el formato de un respaldo de PituApp.');
    }
    final map = decoded.cast<String, dynamic>();
    final version = map['schemaVersion'];
    if (version is! int) {
      return BackupPickResult.invalid(
          'El archivo no parece un respaldo de PituApp.');
    }
    if (version > DbCodec.schemaVersion) {
      return BackupPickResult.invalid(
          'Este respaldo se creó con una versión más nueva de PituApp. '
          'Actualiza la app para restaurarlo.');
    }

    // Se decodifica en una base intermedia para contar y validar la integridad.
    final staging = InMemoryDatabase();
    try {
      DbCodec.decodeInto(staging, map);
    } catch (_) {
      return BackupPickResult.invalid(
          'El respaldo está incompleto o dañado; no se aplicaron cambios.');
    }

    return BackupPickResult.preview(BackupPreview(
      data: map,
      pets: staging.pets.where((p) => !p.meta.isDeleted).length,
      records: staging.visits.length +
          staging.vaccines.length +
          staging.weights.length +
          staging.diagnoses.length,
      attachments: staging.attachments.length,
      exportedAt: map['exportedAt'] == null
          ? null
          : DateTime.tryParse(map['exportedAt'] as String),
    ));
  }

  /// Aplica el respaldo previsualizado con el modo elegido (RF-43/44/45).
  BackupImportResult apply(BackupPreview preview, BackupMode mode) {
    final staging = InMemoryDatabase();
    try {
      DbCodec.decodeInto(staging, preview.data);
    } catch (_) {
      return const BackupImportResult.invalid(
          'El respaldo está dañado; no se aplicaron cambios.');
    }

    if (mode == BackupMode.replace) {
      _replaceFrom(staging);
    } else {
      _combineFrom(staging);
    }

    // Persiste explícitamente para detectar falta de espacio (RF-45).
    if (_persistence != null && !_persistence.trySave(_db)) {
      return const BackupImportResult.invalid(
          'No hay espacio suficiente en este dispositivo para restaurar el respaldo.');
    }
    _db.bump();

    return BackupImportResult.success(
      pets: _db.pets.where((p) => !p.meta.isDeleted).length,
      records: _db.visits.length +
          _db.vaccines.length +
          _db.weights.length +
          _db.diagnoses.length,
    );
  }

  void _replaceFrom(InMemoryDatabase src) {
    _db.pets..clear()..addAll(src.pets);
    _db.careTypes..clear()..addAll(src.careTypes);
    _db.schedules..clear()..addAll(src.schedules);
    _db.executions..clear()..addAll(src.executions);
    _db.diagnoses..clear()..addAll(src.diagnoses);
    _db.diagnosisStatusChanges..clear()..addAll(src.diagnosisStatusChanges);
    _db.weights..clear()..addAll(src.weights);
    _db.visits..clear()..addAll(src.visits);
    _db.vaccines..clear()..addAll(src.vaccines);
    _db.attachments..clear()..addAll(src.attachments);
    _db.ownerName = src.ownerName;
    _db.biometricLockEnabled = src.biometricLockEnabled;
    _db.planType = src.planType;
    _db.purchaseSource = src.purchaseSource;
    _db.purchasedAt = src.purchasedAt;
    _db.reminderLeadDays = src.reminderLeadDays;
  }

  /// Combina por UUID: agrega los registros del respaldo que no existan ya,
  /// sin duplicar (RF-43). Los datos actuales se conservan.
  void _combineFrom(InMemoryDatabase src) {
    _merge(_db.pets, src.pets, (p) => p.id);
    _merge(_db.careTypes, src.careTypes, (t) => t.id);
    _merge(_db.schedules, src.schedules, (s) => s.id);
    _merge(_db.executions, src.executions, (e) => e.id);
    _merge(_db.diagnoses, src.diagnoses, (d) => d.id);
    _merge(_db.diagnosisStatusChanges, src.diagnosisStatusChanges, (c) => c.id);
    _merge(_db.weights, src.weights, (w) => w.id);
    _merge(_db.visits, src.visits, (v) => v.id);
    _merge(_db.vaccines, src.vaccines, (v) => v.id);
    _merge(_db.attachments, src.attachments, (a) => a.id);
  }

  static void _merge<T>(List<T> target, List<T> incoming, String Function(T) id) {
    final existing = target.map(id).toSet();
    for (final item in incoming) {
      if (!existing.contains(id(item))) target.add(item);
    }
  }

  String _fileName() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return 'pitu-respaldo-${now.year}${two(now.month)}${two(now.day)}.json';
  }
}
