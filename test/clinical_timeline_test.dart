import 'package:flutter_test/flutter_test.dart';
import 'package:pitu_app/core/data/in_memory_database.dart';
import 'package:pitu_app/core/domain/sync_metadata.dart';
import 'package:pitu_app/core/utils/clock.dart';
import 'package:pitu_app/core/utils/id_generator.dart';
import 'package:pitu_app/features/care/domain/entities/care_execution.dart';
import 'package:pitu_app/features/clinical/data/clinical_repository_impl.dart';
import 'package:pitu_app/features/clinical/domain/entities/diagnosis.dart';
import 'package:pitu_app/features/clinical/domain/entities/medical_visit.dart';
import 'package:pitu_app/features/clinical/domain/entities/timeline_entry.dart';
import 'package:pitu_app/features/clinical/domain/entities/vaccine.dart';
import 'package:pitu_app/features/clinical/domain/entities/weight_record.dart';
import 'package:pitu_app/features/pets/domain/entities/pet.dart';

TimelineLabels _labels() => TimelineLabels(
      visit: 'Visita médica',
      visitWithReason: (r) => 'Visita médica — $r',
      weightLogged: (v, u) => 'Peso registrado: $v $u',
      statusChange: (c) => 'Cambio de estado: $c',
      statusTransition: (f, t) => '$f → $t',
      diagnosisStatusLabel: (s) => s.name,
    );

/// La línea de tiempo integra visitas, vacunas, diagnósticos, ejecuciones de
/// cuidados y pesos, en orden cronológico inverso (RF-24). También verifica el
/// orden ascendente de los pesos (RF-22) y el aislamiento por mascota.
void main() {
  late InMemoryDatabase db;
  late InMemoryClinicalRepository repo;
  final clock = FixedClock(DateTime(2026, 7, 22));

  setUp(() {
    db = InMemoryDatabase();
    repo = InMemoryClinicalRepository(db, clock, const UuidGenerator());
  });

  SyncMetadata meta(String id) => SyncMetadata.create(id: id, now: clock.now());

  test('integra las cinco fuentes de historial', () {
    repo.addVisit(MedicalVisit(
        meta: meta('v1'), petId: 'p1', date: DateTime(2026, 1, 10), reason: 'Chequeo'));
    repo.addVaccine(Vaccine(
        meta: meta('vac1'), petId: 'p1', type: 'Rabia', appliedDate: DateTime(2026, 2, 5)));
    repo.addDiagnosis(Diagnosis(
        meta: meta('d1'),
        petId: 'p1',
        condition: 'Dermatitis',
        date: DateTime(2026, 3, 1)));
    repo.addWeight(WeightRecord(
        meta: meta('w1'),
        petId: 'p1',
        value: 12,
        unit: WeightUnit.kg,
        date: DateTime(2026, 4, 1)));
    db.executions.add(CareExecution(
        meta: meta('e1'),
        scheduleId: 's1',
        petId: 'p1',
        name: 'Baño',
        date: DateTime(2026, 5, 1)));

    final timeline = repo.timelineForPet('p1', _labels());
    final kinds = timeline.map((e) => e.kind).toSet();
    expect(kinds, containsAll(<TimelineKind>{
      TimelineKind.visit,
      TimelineKind.vaccine,
      TimelineKind.diagnosis,
      TimelineKind.weight,
      TimelineKind.care,
    }));
    expect(timeline, hasLength(5));
  });

  test('ordena en cronología inversa (más reciente primero)', () {
    repo.addVisit(MedicalVisit(
        meta: meta('v1'), petId: 'p1', date: DateTime(2026, 1, 10)));
    repo.addWeight(WeightRecord(
        meta: meta('w1'),
        petId: 'p1',
        value: 12,
        unit: WeightUnit.kg,
        date: DateTime(2026, 6, 1)));

    final dates = repo.timelineForPet('p1', _labels()).map((e) => e.date).toList();
    expect(dates.first, DateTime(2026, 6, 1));
    expect(dates.last, DateTime(2026, 1, 10));
  });

  test('solo incluye entradas de la mascota consultada', () {
    repo.addVisit(MedicalVisit(
        meta: meta('v1'), petId: 'p1', date: DateTime(2026, 1, 10)));
    repo.addVisit(MedicalVisit(
        meta: meta('v2'), petId: 'p2', date: DateTime(2026, 1, 11)));
    expect(repo.timelineForPet('p1', _labels()), hasLength(1));
  });

  test('weightsForPet devuelve orden ascendente por fecha (RF-22)', () {
    repo.addWeight(WeightRecord(
        meta: meta('w2'),
        petId: 'p1',
        value: 13,
        unit: WeightUnit.kg,
        date: DateTime(2026, 6, 1)));
    repo.addWeight(WeightRecord(
        meta: meta('w1'),
        petId: 'p1',
        value: 12,
        unit: WeightUnit.kg,
        date: DateTime(2026, 3, 1)));
    final dates = repo.weightsForPet('p1').map((w) => w.date).toList();
    expect(dates, [DateTime(2026, 3, 1), DateTime(2026, 6, 1)]);
  });

  test('las entradas con borrado lógico se excluyen', () {
    repo.addVisit(MedicalVisit(
        meta: meta('v1').deleted(clock.now()),
        petId: 'p1',
        date: DateTime(2026, 1, 10)));
    expect(repo.timelineForPet('p1', _labels()), isEmpty);
  });
}
