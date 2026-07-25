import '../../../../core/domain/sync_metadata.dart';

/// Tipo de adjunto, para elegir la representación (miniatura vs. icono).
enum AttachmentKind { image, pdf, other }

/// Documento adjunto de una mascota (RD-10, RF-30..RF-33).
///
/// En la Fase 1 (local-first) el contenido se guarda embebido en base64 dentro
/// del snapshot, de modo que viaja también en el respaldo. En la Fase 2 el
/// blob se moverá a almacenamiento de archivos y aquí quedará solo la
/// referencia, sin tocar el dominio que lo consume.
class Attachment {
  const Attachment({
    required this.meta,
    required this.petId,
    required this.filename,
    required this.mimeType,
    required this.sizeBytes,
    required this.dataBase64,
    required this.addedAt,
    this.source,
  });

  final SyncMetadata meta;
  final String petId;
  final String filename;
  final String mimeType;
  final int sizeBytes;

  /// Contenido del archivo en base64 (sin el prefijo `data:`).
  final String dataBase64;
  final DateTime addedAt;

  /// Etiqueta de origen opcional (por ejemplo, "Documento" o "Visita 12 jul").
  final String? source;

  String get id => meta.id;

  AttachmentKind get kind {
    if (mimeType.startsWith('image/')) return AttachmentKind.image;
    if (mimeType == 'application/pdf' ||
        filename.toLowerCase().endsWith('.pdf')) {
      return AttachmentKind.pdf;
    }
    return AttachmentKind.other;
  }

  /// URI de datos lista para render/descarga (`data:<mime>;base64,<...>`).
  String get dataUri => 'data:$mimeType;base64,$dataBase64';
}
