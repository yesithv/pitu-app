import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../data/file_transfer.dart';
import '../data/file_transfer_factory.dart';
import 'backup_service.dart';

/// Puente de plataforma para archivos (se resuelve en compilación).
final fileTransferProvider =
    Provider<FileTransfer>((ref) => createFileTransfer());

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(
    ref.read(databaseProvider),
    ref.read(fileTransferProvider),
  ),
);
