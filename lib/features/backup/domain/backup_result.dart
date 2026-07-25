/// Resultado de restaurar un respaldo (RF-42..RF-46).
enum BackupImportStatus { success, cancelled, invalid }

class BackupImportResult {
  const BackupImportResult._(
    this.status, {
    this.message,
    this.pets = 0,
    this.records = 0,
  });

  const BackupImportResult.cancelled()
      : this._(BackupImportStatus.cancelled);

  const BackupImportResult.invalid(String message)
      : this._(BackupImportStatus.invalid, message: message);

  const BackupImportResult.success({required int pets, required int records})
      : this._(BackupImportStatus.success, pets: pets, records: records);

  final BackupImportStatus status;
  final String? message;
  final int pets;
  final int records;

  bool get isSuccess => status == BackupImportStatus.success;
}
