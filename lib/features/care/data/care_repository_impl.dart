import 'package:collection/collection.dart';

import '../../../core/data/in_memory_database.dart';
import '../../../core/domain/sync_metadata.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/id_generator.dart';
import '../domain/entities/care_execution.dart';
import '../domain/entities/care_schedule.dart';
import '../domain/repositories/care_repository.dart';
import '../domain/services/scheduling_service.dart';

class InMemoryCareRepository implements CareRepository {
  InMemoryCareRepository(this._db, this._clock, this._ids, this._scheduling);

  final InMemoryDatabase _db;
  final Clock _clock;
  final IdGenerator _ids;
  final SchedulingService _scheduling;

  /// Snapshots para deshacer con exactitud (RF-16), por id de ejecución.
  final Map<String, CareSchedule> _undo = {};

  bool _petIsActive(String petId) {
    final pet = _db.pets.firstWhereOrNull((p) => p.id == petId);
    return pet?.isActive ?? false;
  }

  @override
  List<CareSchedule> schedulesForPet(String petId) => _db.schedules
      .where((s) => s.petId == petId && s.isActive && !s.meta.isDeleted)
      .toList();

  @override
  List<CareSchedule> allActiveSchedules() => _db.schedules
      .where((s) => s.isActive && !s.meta.isDeleted && _petIsActive(s.petId))
      .toList();

  @override
  List<CareExecution> executionsForPet(String petId) => _db.executions
      .where((e) => e.petId == petId && !e.meta.isDeleted)
      .toList();

  @override
  void addSchedule(CareSchedule schedule) {
    _db.schedules.add(schedule);
    _db.bump();
  }

  @override
  void updateSchedule(CareSchedule schedule) {
    final i = _db.schedules.indexWhere((s) => s.id == schedule.id);
    if (i >= 0) {
      _db.schedules[i] = schedule.copyWith(meta: schedule.meta.touched(_clock.now()));
      _db.bump();
    }
  }

  @override
  CareExecution markDone(String scheduleId, {DateTime? date, String? notes}) {
    final now = _clock.now();
    final i = _db.schedules.indexWhere((s) => s.id == scheduleId);
    if (i < 0) {
      throw StateError('Programación no encontrada: $scheduleId');
    }
    final schedule = _db.schedules[i];
    final doneDate = date ?? now;

    final execution = CareExecution(
      meta: SyncMetadata.create(id: _ids.newId(), now: now),
      scheduleId: scheduleId,
      petId: schedule.petId,
      name: schedule.name,
      date: doneDate,
      notes: notes,
    );

    // Snapshot para deshacer y recálculo de próxima fecha (RF-14).
    _undo[execution.id] = schedule;
    _db.schedules[i] = schedule.copyWith(
      lastDoneDate: doneDate,
      nextDate: _scheduling.nextDateFrom(doneDate, schedule.frequency),
      meta: schedule.meta.touched(now),
    );
    _db.executions.add(execution);
    _db.bump();
    return execution;
  }

  @override
  void undo(String executionId) {
    _db.executions.removeWhere((e) => e.id == executionId);
    final snapshot = _undo.remove(executionId);
    if (snapshot != null) {
      final i = _db.schedules.indexWhere((s) => s.id == snapshot.id);
      if (i >= 0) _db.schedules[i] = snapshot;
    }
    _db.bump();
  }
}
