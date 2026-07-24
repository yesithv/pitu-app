import '../entities/pet.dart';

/// Contrato de acceso a mascotas. La implementación de Fase 1 es local
/// (in-memory / SQLite); en Fase 2 se reemplaza por una sobre la API REST
/// sin que cambie la lógica de dominio (§8.3).
abstract interface class PetRepository {
  List<Pet> activePets();
  List<Pet> archivedPets();
  Pet? findById(String id);

  void create(Pet pet);
  void update(Pet pet);

  /// Archiva la mascota (RF-03): detiene recordatorios, la saca del conteo del
  /// plan y del dashboard, pero conserva su historial.
  void archive(String id, {ArchiveReason? reason});
  void unarchive(String id);

  /// Borrado lógico definitivo (RF-06 / RN-13).
  void softDelete(String id);
}
