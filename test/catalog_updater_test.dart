import 'package:flutter_test/flutter_test.dart';
import 'package:pitu_app/core/data/in_memory_database.dart';
import 'package:pitu_app/core/domain/sync_metadata.dart';
import 'package:pitu_app/core/utils/clock.dart';
import 'package:pitu_app/core/utils/id_generator.dart';
import 'package:pitu_app/features/care/application/catalog_updater.dart';
import 'package:pitu_app/features/care/data/care_catalog.dart';
import 'package:pitu_app/features/care/domain/entities/care_frequency.dart';
import 'package:pitu_app/features/care/domain/entities/care_kind.dart';
import 'package:pitu_app/features/care/domain/entities/care_schedule.dart';
import 'package:pitu_app/features/pets/domain/entities/pet.dart';
import 'package:pitu_app/features/pets/domain/entities/species.dart';

void main() {
  final clock = FixedClock(DateTime(2026, 7, 22));

  InMemoryDatabase dbWithDog(List<CareKind> kinds) {
    final db = InMemoryDatabase();
    final pet = Pet(
      meta: SyncMetadata.create(id: 'p1', now: clock.now()),
      name: 'Firulais',
      species: Species.dog,
    );
    db.pets.add(pet);
    for (final k in kinds) {
      db.schedules.add(CareSchedule(
        meta: SyncMetadata.create(id: 'sch-${k.name}', now: clock.now()),
        petId: pet.id,
        careTypeId: 'ct-${k.name}',
        name: k.name,
        kind: k,
        frequency: const CareFrequency(1, FrequencyUnit.months),
        nextDate: clock.now(),
      ));
    }
    return db;
  }

  Set<CareKind> catalogKindsForDog() =>
      CareCatalog.forSpecies(Species.dog).map((t) => t.kind).toSet();

  test('reconcile agrega los cuidados faltantes del catálogo', () {
    final db = dbWithDog([CareKind.vaccine, CareKind.bath]);
    CatalogUpdater(db, const UuidGenerator(), clock).reconcile();

    final petKinds =
        db.schedules.where((s) => s.petId == 'p1').map((s) => s.kind).toSet();
    expect(petKinds, containsAll(catalogKindsForDog()));
    expect(db.catalogAppliedVersion, CareCatalog.version);
  });

  test('no re-agrega ni duplica si ya están todos (idempotente)', () {
    final db = dbWithDog(catalogKindsForDog().toList());
    final updater = CatalogUpdater(db, const UuidGenerator(), clock);

    updater.reconcile();
    final countAfterFirst =
        db.schedules.where((s) => s.petId == 'p1').length;

    // Fuerza otra pasada de la lógica de reconciliación.
    db.catalogAppliedVersion = 0;
    updater.reconcile();
    final countAfterSecond =
        db.schedules.where((s) => s.petId == 'p1').length;

    expect(countAfterSecond, countAfterFirst);
    expect(countAfterSecond, catalogKindsForDog().length);
  });

  test('no re-agrega un cuidado que el usuario borró (borrado lógico)', () {
    final db = dbWithDog([CareKind.vaccine]);
    // Marca "baño" como borrado lógicamente.
    db.schedules.add(CareSchedule(
      meta: SyncMetadata.create(id: 'sch-bath', now: clock.now())
          .deleted(clock.now()),
      petId: 'p1',
      careTypeId: 'ct-bath',
      name: 'Baño',
      kind: CareKind.bath,
      frequency: const CareFrequency(2, FrequencyUnit.months),
      nextDate: clock.now(),
    ));

    CatalogUpdater(db, const UuidGenerator(), clock).reconcile();

    final bathSchedules =
        db.schedules.where((s) => s.petId == 'p1' && s.kind == CareKind.bath);
    expect(bathSchedules, hasLength(1)); // el borrado sigue siendo el único
  });
}
