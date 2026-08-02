import '../../../core/data/in_memory_database.dart';
import '../../../core/domain/sync_metadata.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/id_generator.dart';
import '../data/care_catalog.dart';
import '../domain/entities/care_schedule.dart';
import '../domain/entities/care_type.dart';

/// Aplica actualizaciones del catálogo de cuidados a las mascotas existentes
/// (RF-13 / RN-09). Es **aditivo e idempotente**: solo agrega cuidados de un
/// `CareKind` que la mascota aún no tiene; nunca modifica, reactiva ni
/// re-agrega los existentes (incluidos los que el usuario borró), de modo que
/// las personalizaciones se conservan.
class CatalogUpdater {
  CatalogUpdater(this._db, this._ids, this._clock);

  final InMemoryDatabase _db;
  final IdGenerator _ids;
  final Clock _clock;

  void reconcile() {
    if (_db.catalogAppliedVersion >= CareCatalog.version) return;

    final now = _clock.now();
    for (final pet in _db.pets.where((p) => !p.meta.isDeleted)) {
      // Incluye los borrados lógicos: si el usuario eliminó un cuidado, no se
      // vuelve a agregar.
      final existingKinds =
          _db.schedules.where((s) => s.petId == pet.id).map((s) => s.kind).toSet();

      for (final template in CareCatalog.forSpecies(pet.species)) {
        if (existingKinds.contains(template.kind)) continue;

        final careType = CareType(
          meta: SyncMetadata.create(id: _ids.newId(), now: now),
          name: template.name,
          kind: template.kind,
          suggestedFrequency: template.frequency,
          speciesApplicable: pet.species,
          catalogVersion: CareCatalog.version,
        );
        _db.careTypes.add(careType);
        _db.schedules.add(CareSchedule(
          meta: SyncMetadata.create(id: _ids.newId(), now: now),
          petId: pet.id,
          careTypeId: careType.id,
          name: template.name,
          kind: template.kind,
          frequency: template.frequency,
          nextDate: template.frequency.addTo(now),
        ));
        existingKinds.add(template.kind);
      }
    }

    _db.catalogAppliedVersion = CareCatalog.version;
    _db.bump();
  }
}
