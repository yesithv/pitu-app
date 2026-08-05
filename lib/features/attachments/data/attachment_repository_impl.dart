import '../../../core/data/in_memory_database.dart';
import '../../../core/data/local_persistence.dart';
import '../domain/entities/attachment.dart';
import '../domain/repositories/attachment_repository.dart';

class InMemoryAttachmentRepository implements AttachmentRepository {
  InMemoryAttachmentRepository(this._db, this._persistence);

  final InMemoryDatabase _db;
  final LocalPersistence? _persistence;

  @override
  List<Attachment> attachmentsForPet(String petId) {
    final list = _db.attachments
        .where((a) => a.petId == petId && !a.meta.isDeleted)
        .toList();
    list.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return list;
  }

  @override
  int countForPet(String petId) => attachmentsForPet(petId).length;

  @override
  bool add(Attachment attachment) {
    _db.attachments.add(attachment);
    // Persistimos de inmediato para poder revertir si el navegador rechaza el
    // guardado (cuota de `localStorage` excedida por el blob en base64).
    final persistence = _persistence;
    if (persistence != null && !persistence.trySave(_db)) {
      _db.attachments.removeWhere((a) => a.id == attachment.id);
      return false;
    }
    _db.bump();
    return true;
  }

  @override
  void remove(String id) {
    // Se elimina físicamente para liberar la cuota que ocupa el blob. El
    // borrado lógico transversal (RN-13) se reintroducirá en la Fase 2, cuando
    // el archivo viva fuera del snapshot.
    _db.attachments.removeWhere((a) => a.id == id);
    _persistence?.trySave(_db);
    _db.bump();
  }
}
