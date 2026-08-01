import '../../features/care/data/care_catalog.dart';
import '../../features/care/domain/entities/care_frequency.dart';
import '../../features/care/domain/entities/care_kind.dart';
import '../../features/care/domain/entities/care_schedule.dart';
import '../../features/care/domain/entities/care_type.dart';
import '../../features/clinical/domain/entities/diagnosis.dart';
import '../../features/clinical/domain/entities/medical_visit.dart';
import '../../features/clinical/domain/entities/vaccine.dart';
import '../../features/clinical/domain/entities/weight_record.dart';
import '../../features/pets/domain/entities/pet.dart';
import '../../features/pets/domain/entities/species.dart';
import '../../features/plan/domain/plan.dart';
import '../domain/sync_metadata.dart';
import '../utils/clock.dart';
import '../utils/id_generator.dart';
import 'in_memory_database.dart';

/// Precarga datos de demostración que reproducen el prototipo (Firulais y Luna).
/// En producción, el primer arranque sería el onboarding con la base vacía.
class DatabaseSeeder {
  DatabaseSeeder(this._db, this._ids, this._clock, {this.demo = false});

  final InMemoryDatabase _db;
  final IdGenerator _ids;
  final Clock _clock;

  /// En modo demo el sembrado arranca en Pro (para exhibir todas las funciones);
  /// en producción los mismos datos de ejemplo arrancan en Free.
  final bool demo;

  DateTime get _now => _clock.now();
  DateTime _daysFromNow(int d) => _now.add(Duration(days: d));

  void seed() {
    if (_db.pets.isNotEmpty) return;
    // Los datos de ejemplo (Firulais y Luna) se siembran en todos los builds
    // para que la app se vea "viva" en el primer arranque. Solo el plan y el
    // nombre del dueño dependen del modo demo.
    if (demo) {
      _db.ownerName = 'Yesith';
      // La demo arranca en Pro para exhibir todas las funciones.
      _db.planType = PlanType.pro;
      _db.purchaseSource = 'demo';
    } else {
      // Producción: sin nombre de dueño precargado (el perfil lo pedirá) y en
      // Free (el default de la BD).
      _db.ownerName = '';
    }

    final birthday = _daysFromNow(6);
    final firulais = _pet(
      name: 'Firulais',
      species: Species.dog,
      breed: 'Labrador',
      ageText: '4 años',
      weight: 28,
      birthDate: DateTime(_now.year - 4, birthday.month, birthday.day),
    );
    final luna = _pet(
      name: 'Luna',
      species: Species.cat,
      breed: 'Criollo',
      ageText: '2 años',
      weight: 4,
    );
    _db.pets.addAll([firulais, luna]);

    // Programaciones de Firulais con estados variados (para el semáforo).
    _seedSchedulesFor(firulais, overrides: {
      CareKind.deworming: _daysFromNow(-5), // atrasado: "Venció hace 5 días"
      CareKind.bath: _daysFromNow(4), // próximo: sábado
      CareKind.vaccine: _daysFromNow(70),
      CareKind.dental: _daysFromNow(85),
      CareKind.nails: _daysFromNow(20),
      CareKind.weight: _daysFromNow(12),
    });

    // Programaciones de Luna: una vacuna próxima.
    _seedSchedulesFor(luna, overrides: {
      CareKind.vaccine: _daysFromNow(3), // "En 3 días"
      CareKind.deworming: _daysFromNow(30),
      CareKind.dental: _daysFromNow(90),
      CareKind.bath: _daysFromNow(45),
      CareKind.nails: _daysFromNow(15),
      CareKind.weight: _daysFromNow(10),
    });

    // Cumpleaños de Firulais como actividad pendiente (en ~6 días).
    const yearly = CareFrequency(1, FrequencyUnit.years);
    final bdayType = CareType(
      meta: SyncMetadata.create(id: _ids.newId(), now: _now),
      name: CareKind.birthday.defaultName,
      kind: CareKind.birthday,
      suggestedFrequency: yearly,
    );
    _db.careTypes.add(bdayType);
    _db.schedules.add(CareSchedule(
      meta: SyncMetadata.create(id: _ids.newId(), now: _now),
      petId: firulais.id,
      careTypeId: bdayType.id,
      name: CareKind.birthday.defaultName,
      kind: CareKind.birthday,
      frequency: yearly,
      nextDate: DateTime(birthday.year, birthday.month, birthday.day),
    ));

    _seedClinicalFor(firulais);
  }

  Pet _pet({
    required String name,
    required Species species,
    String? breed,
    String? ageText,
    double? weight,
    DateTime? birthDate,
  }) {
    return Pet(
      meta: SyncMetadata.create(id: _ids.newId(), now: _now),
      name: name,
      species: species,
      breed: breed,
      ageText: ageText,
      weight: weight,
      birthDate: birthDate,
    );
  }

  void _seedSchedulesFor(Pet pet, {required Map<CareKind, DateTime> overrides}) {
    for (final template in CareCatalog.forSpecies(pet.species)) {
      final careType = CareType(
        meta: SyncMetadata.create(id: _ids.newId(), now: _now),
        name: template.name,
        kind: template.kind,
        suggestedFrequency: template.frequency,
        speciesApplicable: pet.species,
        catalogVersion: CareCatalog.version,
      );
      _db.careTypes.add(careType);
      _db.schedules.add(CareSchedule(
        meta: SyncMetadata.create(id: _ids.newId(), now: _now),
        petId: pet.id,
        careTypeId: careType.id,
        name: template.name,
        kind: template.kind,
        frequency: template.frequency,
        nextDate: overrides[template.kind] ?? _daysFromNow(30),
      ));
    }
  }

  void _seedClinicalFor(Pet pet) {
    // Diagnóstico activo: Dermatitis leve.
    _db.diagnoses.add(Diagnosis(
      meta: SyncMetadata.create(id: _ids.newId(), now: _now),
      petId: pet.id,
      condition: 'Dermatitis leve',
      date: _daysFromNow(-54),
      status: DiagnosisStatus.active,
    ));

    // Visita médica dermatológica.
    _db.visits.add(MedicalVisit(
      meta: SyncMetadata.create(id: _ids.newId(), now: _now),
      petId: pet.id,
      date: _daysFromNow(-24),
      clinic: 'Clínica Veterinaria del Norte',
      reason: 'Control dermatológico',
      diagnosis: 'Dermatitis leve',
      treatment: 'Champú medicado 2 veces por semana durante 3 semanas.',
    ));

    // Vacuna antirrábica reciente.
    _db.vaccines.add(Vaccine(
      meta: SyncMetadata.create(id: _ids.newId(), now: _now),
      petId: pet.id,
      type: 'Vacuna antirrábica',
      appliedDate: _daysFromNow(-10),
      nextDoseDate: _daysFromNow(355),
      clinic: 'Clínica Veterinaria del Norte',
    ));

    // Curva de peso.
    const points = <int, double>{-150: 26.0, -100: 26.5, -60: 27.2, -30: 27.6, 0: 28.0};
    points.forEach((offset, value) {
      _db.weights.add(WeightRecord(
        meta: SyncMetadata.create(id: _ids.newId(), now: _now),
        petId: pet.id,
        value: value,
        unit: WeightUnit.kg,
        date: _daysFromNow(offset),
      ));
    });
  }
}
