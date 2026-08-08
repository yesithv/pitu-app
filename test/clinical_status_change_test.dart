import 'package:flutter_test/flutter_test.dart';
import 'package:pitu_app/core/data/in_memory_database.dart';
import 'package:pitu_app/core/domain/sync_metadata.dart';
import 'package:pitu_app/core/utils/clock.dart';
import 'package:pitu_app/core/utils/id_generator.dart';
import 'package:pitu_app/features/clinical/data/clinical_repository_impl.dart';
import 'package:pitu_app/features/clinical/domain/entities/diagnosis.dart';
import 'package:pitu_app/features/clinical/domain/entities/timeline_entry.dart';

/// Etiquetas de prueba para la línea de tiempo (equivalentes a las de es).
TimelineLabels _labels() => TimelineLabels(
      visit: 'Visita médica',
      visitWithReason: (r) => 'Visita médica — $r',
      weightLogged: (v, u) => 'Peso registrado: $v $u',
      statusChange: (c) => 'Cambio de estado: $c',
      statusTransition: (f, t) => '$f → $t',
      diagnosisStatusLabel: (s) => s.name,
    );

void main() {
  late InMemoryDatabase db;
  late InMemoryClinicalRepository repo;
  final clock = FixedClock(DateTime(2026, 7, 22));

  setUp(() {
    db = InMemoryDatabase();
    repo = InMemoryClinicalRepository(db, clock, const UuidGenerator());
  });

  Diagnosis addDiagnosis() {
    final dx = Diagnosis(
      meta: SyncMetadata.create(id: 'dx1', now: clock.now()),
      petId: 'p1',
      condition: 'Dermatitis',
      date: DateTime(2026, 6, 1),
      status: DiagnosisStatus.active,
    );
    repo.addDiagnosis(dx);
    return dx;
  }

  test('cambiar el estado registra una entrada de cambio', () {
    final dx = addDiagnosis();

    repo.updateDiagnosis(Diagnosis(
      meta: dx.meta,
      petId: dx.petId,
      condition: dx.condition,
      date: dx.date,
      status: DiagnosisStatus.resolved,
    ));

    expect(db.diagnosisStatusChanges, hasLength(1));
    final change = db.diagnosisStatusChanges.single;
    expect(change.fromStatus, DiagnosisStatus.active);
    expect(change.toStatus, DiagnosisStatus.resolved);
    expect(change.diagnosisId, 'dx1');
  });

  test('el cambio aparece en la línea de tiempo', () {
    final dx = addDiagnosis();
    repo.updateDiagnosis(dx.copyWith(status: DiagnosisStatus.chronic));

    final timeline = repo.timelineForPet('p1', _labels());
    final changeEntry = timeline.where(
        (e) => e.kind == TimelineKind.diagnosis && e.title.startsWith('Cambio de estado'));
    expect(changeEntry, hasLength(1));
    expect(changeEntry.first.diagnosisStatus, DiagnosisStatus.chronic);
  });

  test('guardar sin cambiar el estado no registra nada', () {
    final dx = addDiagnosis();

    repo.updateDiagnosis(dx.copyWith(status: DiagnosisStatus.active));

    expect(db.diagnosisStatusChanges, isEmpty);
  });
}
