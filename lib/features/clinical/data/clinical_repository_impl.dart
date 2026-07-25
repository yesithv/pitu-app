import '../../../core/data/in_memory_database.dart';
import '../../../core/utils/clock.dart';
import '../domain/entities/diagnosis.dart';
import '../domain/entities/medical_visit.dart';
import '../domain/entities/timeline_entry.dart';
import '../domain/entities/vaccine.dart';
import '../domain/entities/weight_record.dart';
import '../domain/repositories/clinical_repository.dart';

class InMemoryClinicalRepository implements ClinicalRepository {
  InMemoryClinicalRepository(this._db, this._clock);

  final InMemoryDatabase _db;
  final Clock _clock;

  @override
  List<Diagnosis> diagnosesForPet(String petId) =>
      _db.diagnoses.where((d) => d.petId == petId && !d.meta.isDeleted).toList();

  @override
  List<Diagnosis> activeDiagnosesForPet(String petId) =>
      diagnosesForPet(petId).where((d) => d.isCurrent).toList();

  @override
  List<WeightRecord> weightsForPet(String petId) {
    final list =
        _db.weights.where((w) => w.petId == petId && !w.meta.isDeleted).toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  @override
  List<MedicalVisit> visitsForPet(String petId) =>
      _db.visits.where((v) => v.petId == petId && !v.meta.isDeleted).toList();

  @override
  List<Vaccine> vaccinesForPet(String petId) =>
      _db.vaccines.where((v) => v.petId == petId && !v.meta.isDeleted).toList();

  @override
  List<TimelineEntry> timelineForPet(String petId) {
    final entries = <TimelineEntry>[];

    for (final v in visitsForPet(petId)) {
      entries.add(TimelineEntry(
        date: v.date,
        kind: TimelineKind.visit,
        title: v.reason == null
            ? 'Visita médica'
            : 'Visita médica — ${v.reason}',
        subtitle: v.clinic,
        diagnosisLabel: v.diagnosis,
        diagnosisStatus: v.diagnosis == null ? null : DiagnosisStatus.active,
      ));
    }
    for (final vac in vaccinesForPet(petId)) {
      entries.add(TimelineEntry(
        date: vac.appliedDate,
        kind: TimelineKind.vaccine,
        title: vac.type,
        subtitle: vac.clinic,
      ));
    }
    for (final e in _db.executions
        .where((e) => e.petId == petId && !e.meta.isDeleted)) {
      entries.add(TimelineEntry(
        date: e.date,
        kind: TimelineKind.care,
        title: e.name,
        subtitle: e.notes,
      ));
    }
    for (final w in weightsForPet(petId)) {
      entries.add(TimelineEntry(
        date: w.date,
        kind: TimelineKind.weight,
        title: 'Peso registrado: ${_fmtWeight(w)} ${w.unit.label}',
        subtitle: w.note,
      ));
    }

    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  @override
  void addWeight(WeightRecord record) {
    _db.weights.add(record);
    _db.bump();
  }

  @override
  void addVisit(MedicalVisit visit) {
    _db.visits.add(visit);
    _db.bump();
  }

  @override
  void addVaccine(Vaccine vaccine) {
    _db.vaccines.add(vaccine);
    _db.bump();
  }

  @override
  void addDiagnosis(Diagnosis diagnosis) {
    _db.diagnoses.add(diagnosis);
    _db.bump();
  }

  @override
  void updateDiagnosisStatus(String diagnosisId, DiagnosisStatus status) {
    final i = _db.diagnoses.indexWhere((d) => d.id == diagnosisId);
    if (i >= 0) {
      _db.diagnoses[i] = _db.diagnoses[i]
          .copyWith(status: status, meta: _db.diagnoses[i].meta.touched(_clock.now()));
      _db.bump();
    }
  }

  static String _fmtWeight(WeightRecord w) =>
      w.value == w.value.roundToDouble() ? w.value.toInt().toString() : w.value.toString();
}
