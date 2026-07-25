import 'dart:convert';

import '../../../core/domain/sync_metadata.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/id_generator.dart';
import '../../backup/data/file_transfer.dart';
import '../domain/entities/attachment.dart';
import '../domain/repositories/attachment_repository.dart';

enum AddAttachmentStatus { success, cancelled, tooLarge, quota }

class AddAttachmentResult {
  const AddAttachmentResult(this.status, [this.message = '']);
  final AddAttachmentStatus status;
  final String message;
}

/// Orquesta la selección de un archivo, su validación de tamaño y su guardado
/// como adjunto embebido (RF-30..RF-33). Mantiene la política de tamaño en un
/// solo lugar.
class AttachmentService {
  AttachmentService(this._repo, this._files, this._ids, this._clock);

  final AttachmentRepository _repo;
  final FileTransfer _files;
  final IdGenerator _ids;
  final Clock _clock;

  /// Tope por archivo. Los adjuntos viajan en base64 dentro del snapshot local,
  /// así que se acota su tamaño para no agotar el almacenamiento del navegador.
  static const int maxBytes = 2 * 1024 * 1024;
  static const String maxLabel = '2 MB';

  bool get canAdd => _files.canPickFile;

  Future<AddAttachmentResult> pickAndAdd(String petId) async {
    final picked = await _files.pickBinaryFile();
    if (picked == null) {
      return const AddAttachmentResult(AddAttachmentStatus.cancelled);
    }
    if (picked.bytes.length > maxBytes) {
      return const AddAttachmentResult(AddAttachmentStatus.tooLarge,
          'El archivo supera el límite de $maxLabel por documento.');
    }
    final now = _clock.now();
    final attachment = Attachment(
      meta: SyncMetadata.create(id: _ids.newId(), now: now),
      petId: petId,
      filename: picked.name.trim().isEmpty ? 'documento' : picked.name,
      mimeType: picked.mimeType,
      sizeBytes: picked.bytes.length,
      dataBase64: base64Encode(picked.bytes),
      addedAt: now,
      source: 'Documento',
    );
    final ok = _repo.add(attachment);
    if (!ok) {
      return const AddAttachmentResult(AddAttachmentStatus.quota,
          'No hay espacio suficiente en este dispositivo para guardar el archivo.');
    }
    return const AddAttachmentResult(AddAttachmentStatus.success);
  }

  /// Descarga/guarda un adjunto ya almacenado.
  Future<void> download(Attachment attachment) => _files.saveBytes(
        attachment.filename,
        base64Decode(attachment.dataBase64),
        mime: attachment.mimeType,
      );
}
