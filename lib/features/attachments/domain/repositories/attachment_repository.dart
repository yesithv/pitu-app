import '../entities/attachment.dart';

abstract interface class AttachmentRepository {
  /// Adjuntos vigentes de una mascota, del más reciente al más antiguo.
  List<Attachment> attachmentsForPet(String petId);

  int countForPet(String petId);

  /// Agrega un adjunto. Devuelve `false` si no se pudo persistir (por ejemplo,
  /// al exceder la cuota del almacenamiento local); en ese caso no se conserva.
  bool add(Attachment attachment);

  void remove(String id);
}
