import '../../features/care/data/care_catalog.dart';
import '../../features/care/domain/entities/care_execution.dart';
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

/// Precarga datos de demostración que reproducen el prototipo (Pitufo y Luna),
/// más una mascota archivada (Firulais) para exhibir la función de archivado.
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
  DateTime _daysAgo(int d) => _daysFromNow(-d);

  void seed() {
    if (_db.pets.isNotEmpty) return;
    // Los datos de ejemplo (Pitufo y Luna) se siembran en todos los builds
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
    final pitufo = _pet(
      name: 'Pitufo',
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
      ageText: '3 años',
      weight: 4,
      birthDate: DateTime(_now.year - 3, 11, 2),
    );
    _db.pets.addAll([pitufo, luna]);

    // Mascota archivada (RF-04/RF-07): Firulais falleció. Sirve para exhibir la
    // pantalla de archivadas del demo. No se le siembran programaciones porque
    // una mascota archivada no genera recordatorios (RF-03).
    final firulais = _pet(
      name: 'Firulais',
      species: Species.dog,
      breed: 'Criollo',
      ageText: '13 años',
      weight: 22,
      birthDate: DateTime(_now.year - 13, 3, 12),
    ).copyWith(
      status: PetStatus.archived,
      archiveReason: ArchiveReason.deceased,
    );
    _db.pets.add(firulais);

    // Programaciones de Pitufo con estados variados (para el semáforo).
    _seedSchedulesFor(pitufo, overrides: {
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
      CareKind.vetVisit: _daysFromNow(40),
      CareKind.dental: _daysFromNow(90),
      CareKind.grooming: _daysFromNow(5),
      CareKind.nails: _daysFromNow(15),
      CareKind.weight: _daysFromNow(10),
    });

    // Cumpleaños de Pitufo como actividad pendiente (en ~6 días).
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
      petId: pitufo.id,
      careTypeId: bdayType.id,
      name: CareKind.birthday.defaultName,
      kind: CareKind.birthday,
      frequency: yearly,
      nextDate: DateTime(birthday.year, birthday.month, birthday.day),
    ));

    _seedPitufoHistory(pitufo);
    _seedLunaHistory(luna);
    _seedFirulaisHistory(firulais);
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

  /// Historial clínico y de cuidados extenso de Pitufo, repartido a lo largo de
  /// sus ~4 años de vida (desde cachorro hasta hoy): vacunas, consultas,
  /// diagnósticos, baños, limpiezas dentales, desparasitaciones, cortes de uñas
  /// y una curva de peso de cachorro a adulto.
  void _seedPitufoHistory(Pet pet) {
    const north = 'Clínica Veterinaria del Norte';
    const south = 'Veterinaria Patitas del Sur';

    // Vacunas: serie de cachorro + refuerzos anuales.
    _addVaccine(pet, 'Polivalente (DHPPi) — 1.ª dosis', daysAgo: 1400, clinic: north);
    _addVaccine(pet, 'Polivalente (DHPPi) — 2.ª dosis', daysAgo: 1375, clinic: north);
    _addVaccine(pet, 'Vacuna antirrábica', daysAgo: 1360, clinic: north);
    _addVaccine(pet, 'Tos de las perreras (Bordetella)', daysAgo: 1345, clinic: north);
    _addVaccine(pet, 'Polivalente (DHPPi) — refuerzo anual', daysAgo: 1095, clinic: north);
    _addVaccine(pet, 'Vacuna antirrábica', daysAgo: 1080, clinic: north);
    _addVaccine(pet, 'Polivalente (DHPPi) — refuerzo anual', daysAgo: 730, clinic: south);
    _addVaccine(pet, 'Tos de las perreras (Bordetella)', daysAgo: 715, clinic: south);
    _addVaccine(pet, 'Polivalente (DHPPi) — refuerzo anual', daysAgo: 365, clinic: north);
    // Antirrábica reciente, con próxima dosis a un año.
    _addVaccine(pet, 'Vacuna antirrábica',
        daysAgo: 10, nextInDays: 355, clinic: north);

    // Consultas médicas a lo largo de su vida.
    _addVisit(pet,
        daysAgo: 1410,
        reason: 'Revisión inicial de cachorro',
        clinic: north,
        treatment: 'Desparasitación y plan de vacunación inicial.');
    _addVisit(pet,
        daysAgo: 1100,
        reason: 'Chequeo anual',
        clinic: north,
        treatment: 'Examen general sin hallazgos relevantes.');
    _addVisit(pet,
        daysAgo: 900,
        reason: 'Gastroenteritis',
        clinic: south,
        diagnosis: 'Gastroenteritis aguda',
        treatment: 'Dieta blanda 5 días y protector gástrico.');
    _addVisit(pet,
        daysAgo: 735,
        reason: 'Chequeo anual',
        clinic: south,
        treatment: 'Examen general y limpieza dental bajo sedación.');
    _addVisit(pet,
        daysAgo: 370,
        reason: 'Chequeo anual',
        clinic: north,
        treatment: 'Examen general sin hallazgos relevantes.');
    _addVisit(pet,
        daysAgo: 24,
        reason: 'Control dermatológico',
        clinic: north,
        diagnosis: 'Dermatitis leve',
        treatment: 'Champú medicado 2 veces por semana durante 3 semanas.');

    // Diagnósticos: uno resuelto en el pasado y la dermatitis activa actual.
    _addDiagnosis(pet, 'Otitis externa',
        daysAgo: 905, status: DiagnosisStatus.resolved);
    _addDiagnosis(pet, 'Dermatitis leve',
        daysAgo: 54, status: DiagnosisStatus.active);

    // Ejecuciones de cuidado (quedan en el historial, RF-17).
    for (var d = 60; d <= 1400; d += 70) {
      _addExecution(pet, CareKind.bath, daysAgo: d);
    }
    for (var d = 90; d <= 1400; d += 100) {
      _addExecution(pet, CareKind.deworming, daysAgo: d);
    }
    for (var d = 50; d <= 1400; d += 80) {
      _addExecution(pet, CareKind.nails, daysAgo: d);
    }
    for (final d in const [1100, 735, 365]) {
      _addExecution(pet, CareKind.dental, daysAgo: d,
          notes: 'Limpieza dental profesional bajo sedación.');
    }

    // Curva de peso: cachorro (6 kg) a adulto (28 kg).
    const weightCurve = <int, double>{
      1400: 6.0,
      1300: 11.0,
      1200: 16.0,
      1100: 21.0,
      1000: 24.0,
      850: 26.0,
      700: 26.8,
      500: 27.2,
      300: 27.5,
      150: 27.8,
      60: 28.0,
      0: 28.0,
    };
    weightCurve.forEach((daysAgo, value) {
      _addWeight(pet, value, daysAgo: daysAgo);
    });
  }

  /// Historial clínico y de cuidados de Luna, congruente con una gata adulta de
  /// ~3 años (desde gatita hasta hoy): serie de vacunas felinas (FVRCP,
  /// antirrábica, leucemia FeLV) y refuerzos anuales, controles de bienestar,
  /// desparasitaciones, limpiezas dentales, cepillados, cortes de uñas y una
  /// curva de peso de gatita a adulta.
  void _seedLunaHistory(Pet pet) {
    const clinic = 'Clínica Veterinaria del Norte';
    const feline = 'Centro Felino Bigotes';

    // Vacunas: serie de gatita (FVRCP + antirrábica + FeLV) y refuerzos anuales.
    _addVaccine(pet, 'Triple felina (FVRCP) — 1.ª dosis', daysAgo: 1000, clinic: feline);
    _addVaccine(pet, 'Triple felina (FVRCP) — 2.ª dosis', daysAgo: 975, clinic: feline);
    _addVaccine(pet, 'Leucemia felina (FeLV) — 1.ª dosis', daysAgo: 970, clinic: feline);
    _addVaccine(pet, 'Triple felina (FVRCP) — 3.ª dosis', daysAgo: 945, clinic: feline);
    _addVaccine(pet, 'Leucemia felina (FeLV) — 2.ª dosis', daysAgo: 940, clinic: feline);
    _addVaccine(pet, 'Vacuna antirrábica', daysAgo: 935, clinic: feline);
    _addVaccine(pet, 'Triple felina (FVRCP) — refuerzo anual', daysAgo: 730, clinic: clinic);
    _addVaccine(pet, 'Vacuna antirrábica', daysAgo: 725, clinic: clinic);
    // Refuerzo más reciente: la próxima dosis cae en ~3 días (casa con el
    // semáforo de "vacuna en 3 días").
    _addVaccine(pet, 'Triple felina (FVRCP) — refuerzo anual',
        daysAgo: 362, nextInDays: 3, clinic: clinic);

    // Controles de bienestar y una consulta puntual resuelta.
    _addVisit(pet,
        daysAgo: 1005,
        reason: 'Revisión inicial de gatita',
        clinic: feline,
        treatment: 'Desparasitación y plan de vacunación felino.');
    _addVisit(pet,
        daysAgo: 730,
        reason: 'Control de bienestar anual',
        clinic: clinic,
        treatment: 'Examen general y limpieza dental.');
    _addVisit(pet,
        daysAgo: 500,
        reason: 'Cistitis idiopática felina',
        clinic: clinic,
        diagnosis: 'Cistitis idiopática',
        treatment: 'Dieta húmeda, aumento de ingesta de agua y manejo del estrés.');
    _addVisit(pet,
        daysAgo: 365,
        reason: 'Control de bienestar anual',
        clinic: clinic,
        treatment: 'Examen general sin hallazgos relevantes.');

    // Diagnóstico dental típico felino, ya resuelto.
    _addDiagnosis(pet, 'Gingivitis leve',
        daysAgo: 520, status: DiagnosisStatus.resolved);

    // Ejecuciones de cuidado del último año (quedan en el historial, RF-17).
    for (var d = 14; d <= 420; d += 21) {
      _addExecution(pet, CareKind.grooming, daysAgo: d);
    }
    for (var d = 20; d <= 420; d += 35) {
      _addExecution(pet, CareKind.nails, daysAgo: d);
    }
    for (var d = 150; d <= 1000; d += 190) {
      _addExecution(pet, CareKind.deworming, daysAgo: d);
    }
    for (final d in const [730, 365]) {
      _addExecution(pet, CareKind.dental, daysAgo: d,
          notes: 'Limpieza dental profesional bajo sedación.');
    }

    // Curva de peso: gatita (1.5 kg) a adulta (~4 kg).
    const weightCurve = <int, double>{
      1000: 1.5,
      900: 2.4,
      800: 3.0,
      600: 3.6,
      400: 3.9,
      200: 4.0,
      60: 4.1,
      0: 4.0,
    };
    weightCurve.forEach((daysAgo, value) {
      _addWeight(pet, value, daysAgo: daysAgo);
    });
  }

  /// Historial ligero de Firulais (archivado) para que su detalle no quede
  /// vacío: unas vacunas anuales, una consulta y algunos pesos.
  void _seedFirulaisHistory(Pet pet) {
    const clinic = 'Clínica Veterinaria del Norte';
    _addVaccine(pet, 'Polivalente (DHPPi) — refuerzo anual', daysAgo: 1100, clinic: clinic);
    _addVaccine(pet, 'Vacuna antirrábica', daysAgo: 1090, clinic: clinic);
    _addVaccine(pet, 'Polivalente (DHPPi) — refuerzo anual', daysAgo: 730, clinic: clinic);
    _addVaccine(pet, 'Vacuna antirrábica', daysAgo: 400, clinic: clinic);
    _addVisit(pet,
        daysAgo: 420,
        reason: 'Control geriátrico',
        clinic: clinic,
        treatment: 'Analítica de rutina y control de peso.');
    _addDiagnosis(pet, 'Artrosis',
        daysAgo: 500, status: DiagnosisStatus.chronic);
    _addWeight(pet, 24.0, daysAgo: 900);
    _addWeight(pet, 23.0, daysAgo: 500);
    _addWeight(pet, 22.0, daysAgo: 200);
  }

  void _addVaccine(Pet pet, String type,
      {required int daysAgo, int? nextInDays, String? clinic}) {
    _db.vaccines.add(Vaccine(
      meta: SyncMetadata.create(id: _ids.newId(), now: _now),
      petId: pet.id,
      type: type,
      appliedDate: _daysAgo(daysAgo),
      nextDoseDate: nextInDays == null ? null : _daysFromNow(nextInDays),
      clinic: clinic,
    ));
  }

  void _addVisit(Pet pet,
      {required int daysAgo,
      String? reason,
      String? clinic,
      String? diagnosis,
      String? treatment}) {
    _db.visits.add(MedicalVisit(
      meta: SyncMetadata.create(id: _ids.newId(), now: _now),
      petId: pet.id,
      date: _daysAgo(daysAgo),
      clinic: clinic,
      reason: reason,
      diagnosis: diagnosis,
      treatment: treatment,
    ));
  }

  void _addDiagnosis(Pet pet, String condition,
      {required int daysAgo, required DiagnosisStatus status}) {
    _db.diagnoses.add(Diagnosis(
      meta: SyncMetadata.create(id: _ids.newId(), now: _now),
      petId: pet.id,
      condition: condition,
      date: _daysAgo(daysAgo),
      status: status,
    ));
  }

  void _addExecution(Pet pet, CareKind kind,
      {required int daysAgo, String? notes}) {
    final scheduleId = _scheduleIdFor(pet, kind);
    if (scheduleId == null) return;
    _db.executions.add(CareExecution(
      meta: SyncMetadata.create(id: _ids.newId(), now: _now),
      scheduleId: scheduleId,
      petId: pet.id,
      name: kind.defaultName,
      date: _daysAgo(daysAgo),
      notes: notes,
    ));
  }

  void _addWeight(Pet pet, double value, {required int daysAgo}) {
    _db.weights.add(WeightRecord(
      meta: SyncMetadata.create(id: _ids.newId(), now: _now),
      petId: pet.id,
      value: value,
      unit: WeightUnit.kg,
      date: _daysAgo(daysAgo),
    ));
  }

  /// Busca el `scheduleId` de un cuidado de la mascota por su tipo (para
  /// vincular las ejecuciones del historial). `null` si la mascota no tiene esa
  /// programación (p. ej. las archivadas, sin programaciones sembradas).
  String? _scheduleIdFor(Pet pet, CareKind kind) {
    for (final s in _db.schedules) {
      if (s.petId == pet.id && s.kind == kind) return s.id;
    }
    return null;
  }
}
