import 'package:flutter_test/flutter_test.dart';
import 'package:pitu_app/core/data/in_memory_database.dart';
import 'package:pitu_app/core/utils/clock.dart';
import 'package:pitu_app/core/utils/id_generator.dart';
import 'package:pitu_app/features/care/data/care_catalog.dart';
import 'package:pitu_app/features/pets/application/pet_onboarding_service.dart';
import 'package:pitu_app/features/pets/domain/entities/species.dart';

/// Ids deterministas para el onboarding.
class _SeqIds implements IdGenerator {
  int _n = 0;
  @override
  String newId() => 'id-${++_n}';
}

/// Verifica que al crear una mascota se precargue su plan de cuidados según la
/// especie (RF-08), con los tipos versionados (RF-13) y la próxima fecha
/// calculada desde hoy.
void main() {
  late InMemoryDatabase db;
  late FixedClock clock;
  late PetOnboardingService service;

  setUp(() {
    db = InMemoryDatabase();
    clock = FixedClock(DateTime(2026, 7, 22));
    service = PetOnboardingService(db, _SeqIds(), clock);
  });

  test('precarga el catálogo de perro', () {
    service.createPet(name: 'Pitufo', species: Species.dog);
    final expected = CareCatalog.forSpecies(Species.dog).length;
    expect(db.schedules, hasLength(expected));
    expect(db.careTypes, hasLength(expected));
    expect(expected, greaterThan(0));
  });

  test('el catálogo difiere por especie', () {
    service.createPet(name: 'Gato', species: Species.cat);
    final catCount = CareCatalog.forSpecies(Species.cat).length;
    expect(db.schedules, hasLength(catCount));
  });

  test('los tipos precargados llevan versión y especie del catálogo (RF-13)', () {
    service.createPet(name: 'Pitufo', species: Species.dog);
    for (final t in db.careTypes) {
      expect(t.catalogVersion, CareCatalog.version);
      expect(t.speciesApplicable, Species.dog);
      expect(t.isCustom, isFalse);
    }
  });

  test('la próxima fecha se calcula a partir de hoy con la frecuencia sugerida', () {
    service.createPet(name: 'Pitufo', species: Species.dog);
    for (final s in db.schedules) {
      expect(s.nextDate, s.frequency.addTo(clock.now()));
      expect(s.petId, db.pets.single.id);
    }
  });

  test('recorta el nombre y normaliza raza/edad vacías a null', () {
    final pet = service.createPet(
      name: '  Pitufo  ',
      species: Species.other,
      breed: '   ',
      ageText: '',
    );
    expect(pet.name, 'Pitufo');
    expect(pet.breed, isNull);
    expect(pet.ageText, isNull);
  });
}
