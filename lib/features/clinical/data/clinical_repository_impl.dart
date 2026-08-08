import '../../../core/data/in_memory_database.dart';
import '../../../core/domain/sync_metadata.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/id_generator.dart';
import '../domain/entities/diagnosis.dart';
import '../domain/entities/diagnosis_status_change.dart';
import '../domain/entities/medical_visit.dart';
import '../domain/entities/timeline_entry.dart';
import '../domain/entities/vaccine.dart';
import '../domain/entities/weight_record.dart';
import '../domain/repositories/clinical_repository.dart';

class InMemoryClinicalRepository implements ClinicalRepository {
  InMemoryClinicalRepository(this._db, this._clock, this._ids);

  final InMemoryDatabase _db;
  final Clock _clock;
  final IdGenerator _ids;

  /// Registra un cambio de estado de diagnóstico como entrada del historial
  /// (RF-21). Solo agrega si el estado realmente cambió.
  void _logStatusChange(Diagnosis before, DiagnosisStatus to) {
    if (before.status == to) return;
    final now = _clock.now();
    _db.diagnosisStatusChanges.add(DiagnosisStatusChange(
      meta: SyncMetadata.create(id: _ids.newId(), now: now),
      petId: before.petId,
      diagnosisId: before.id,
      condition: before.condition,
      fromStatus: before.status,
      toStatus: to,
      changedAt: now,
    ));
  }

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
  List<TimelineEntry> timelineForPet(String petId, TimelineLabels labels) {
    final entries = <TimelineEntry>[];

    for (final v in visitsForPet(petId)) {
      entries.add(TimelineEntry(
        date: v.date,
        kind: TimelineKind.visit,
        title: v.reason == null
            ? labels.visit
            : labels.visitWithReason(v.reason!),
        subtitle: v.clinic,
        sourceId: v.id,
      ));
    }
    for (final vac in vaccinesForPet(petId)) {
      entries.add(TimelineEntry(
        date: vac.appliedDate,
        kind: TimelineKind.vaccine,
        title: vac.type,
        subtitle: vac.clinic,
        sourceId: vac.id,
      ));
    }
    for (final d in diagnosesForPet(petId)) {
      entries.add(TimelineEntry(
        date: d.date,
        kind: TimelineKind.diagnosis,
        title: d.condition,
        subtitle: d.notes,
        sourceId: d.id,
        diagnosisStatus: d.status,
        diagnosisLabel: labels.diagnosisStatusLabel(d.status),
      ));
    }
    for (final e in _db.executions
        .where((e) => e.petId == petId && !e.meta.isDeleted)) {
      entries.add(TimelineEntry(
        date: e.date,
        kind: TimelineKind.care,
        title: e.name,
        subtitle: e.notes,
        sourceId: e.id,
      ));
    }
    for (final w in weightsForPet(petId)) {
      entries.add(TimelineEntry(
        date: w.date,
        kind: TimelineKind.weight,
        title: labels.weightLogged(_fmtWeight(w), w.unit.label),
        subtitle: w.note,
        sourceId: w.id,
      ));
    }
    for (final ch in _db.diagnosisStatusChanges
        .where((c) => c.petId == petId && !c.meta.isDeleted)) {
      entries.add(TimelineEntry(
        date: ch.changedAt,
        kind: TimelineKind.diagnosis,
        title: labels.statusChange(ch.condition),
        subtitle: labels.statusTransition(
            labels.diagnosisStatusLabel(ch.fromStatus),
            labels.diagnosisStatusLabel(ch.toStatus)),
        sourceId: ch.diagnosisId,
        diagnosisStatus: ch.toStatus,
        diagnosisLabel: labels.diagnosisStatusLabel(ch.toStatus),
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
      _logStatusChange(_db.diagnoses[i], status);
      _db.diagnoses[i] = _db.diagnoses[i]
          .copyWith(status: status, meta: _db.diagnoses[i].meta.touched(_clock.now()));
      _db.bump();
    }
  }

  @override
  void updateWeight(WeightRecord record) {
    final i = _db.weights.indexWhere((w) => w.id == record.id);
    if (i >= 0) {
      _db.weights[i] = record;
      _db.bump();
    }
  }

  @override
  void deleteWeight(String id) {
    _db.weights.removeWhere((w) => w.id == id);
    _db.bump();
  }

  @override
  void updateVisit(MedicalVisit visit) {
    final i = _db.visits.indexWhere((v) => v.id == visit.id);
    if (i >= 0) {
      _db.visits[i] = visit;
      _db.bump();
    }
  }

  @override
  void deleteVisit(String id) {
    _db.visits.removeWhere((v) => v.id == id);
    _db.bump();
  }

  @override
  void updateVaccine(Vaccine vaccine) {
    final i = _db.vaccines.indexWhere((v) => v.id == vaccine.id);
    if (i >= 0) {
      _db.vaccines[i] = vaccine;
      _db.bump();
    }
  }

  @override
  void deleteVaccine(String id) {
    _db.vaccines.removeWhere((v) => v.id == id);
    _db.bump();
  }

  @override
  void updateDiagnosis(Diagnosis diagnosis) {
    final i = _db.diagnoses.indexWhere((d) => d.id == diagnosis.id);
    if (i >= 0) {
      _logStatusChange(_db.diagnoses[i], diagnosis.status);
      _db.diagnoses[i] = diagnosis;
      _db.bump();
    }
  }

  @override
  void deleteDiagnosis(String id) {
    _db.diagnoses.removeWhere((d) => d.id == id);
    _db.bump();
  }

  static String _fmtWeight(WeightRecord w) =>
      w.value == w.value.roundToDouble() ? w.value.toInt().toString() : w.value.toString();
}
