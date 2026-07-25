import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../backup/application/backup_providers.dart';
import '../data/attachment_repository_impl.dart';
import '../domain/entities/attachment.dart';
import '../domain/repositories/attachment_repository.dart';
import 'attachment_service.dart';

final attachmentRepositoryProvider = Provider<AttachmentRepository>(
  (ref) => InMemoryAttachmentRepository(
    ref.read(databaseProvider),
    ref.read(persistenceProvider),
  ),
);

final attachmentServiceProvider = Provider<AttachmentService>(
  (ref) => AttachmentService(
    ref.read(attachmentRepositoryProvider),
    ref.read(fileTransferProvider),
    ref.read(idGeneratorProvider),
    ref.read(clockProvider),
  ),
);

final attachmentsForPetProvider =
    Provider.family<List<Attachment>, String>((ref, petId) {
  ref.watch(databaseProvider);
  return ref.read(attachmentRepositoryProvider).attachmentsForPet(petId);
});
