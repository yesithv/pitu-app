import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../core/domain/sync_metadata.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/id_generator.dart';
import '../../../core/utils/image_compressor.dart';
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

  /// Tope por archivo. En **móvil** los adjuntos viven en el filesystem (RF-29),
  /// así que se permite hasta 15 MB; en **web** siguen embebidos en el snapshot
  /// del navegador, por lo que se acota a 2 MB para no agotar su cuota.
  static final int maxBytes = kIsWeb ? 2 * 1024 * 1024 : 15 * 1024 * 1024;
  static final String maxLabel = kIsWeb ? '2 MB' : '15 MB';

  bool get canAdd => _files.canPickFile;

  Future<AddAttachmentResult> pickAndAdd(String petId, {String? source}) async {
    final picked = await _files.pickBinaryFile();
    if (picked == null) {
      return const AddAttachmentResult(AddAttachmentStatus.cancelled);
    }
    // Comprime las imágenes antes de almacenarlas (RF-28).
    final compressed =
        compressImage(picked.bytes, mimeType: picked.mimeType);
    if (compressed.bytes.length > maxBytes) {
      return AddAttachmentResult(AddAttachmentStatus.tooLarge,
          'El archivo supera el límite de $maxLabel por documento.');
    }
    final now = _clock.now();
    final attachment = Attachment(
      meta: SyncMetadata.create(id: _ids.newId(), now: now),
      petId: petId,
      filename: picked.name.trim().isEmpty ? 'documento' : picked.name,
      mimeType: compressed.mimeType,
      sizeBytes: compressed.bytes.length,
      dataBase64: base64Encode(compressed.bytes),
      addedAt: now,
      source: source ?? 'Documento',
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
