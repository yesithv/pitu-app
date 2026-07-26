import 'package:collection/collection.dart';

import '../../../core/data/in_memory_database.dart';
import '../../../core/utils/clock.dart';
import '../domain/entities/pet.dart';
import '../domain/repositories/pet_repository.dart';

class InMemoryPetRepository implements PetRepository {
  InMemoryPetRepository(this._db, this._clock);

  final InMemoryDatabase _db;
  final Clock _clock;

  @override
  List<Pet> activePets() =>
      _db.pets.where((p) => p.isActive).toList();

  @override
  List<Pet> archivedPets() =>
      _db.pets.where((p) => p.isArchived && !p.meta.isDeleted).toList();

  @override
  Pet? findById(String id) =>
      _db.pets.firstWhereOrNull((p) => p.id == id && !p.meta.isDeleted);

  @override
  void create(Pet pet) {
    _db.pets.add(pet);
    _db.bump();
  }

  @override
  void update(Pet pet) {
    _replace(pet.copyWith(meta: pet.meta.touched(_clock.now())));
    _db.bump();
  }

  @override
  void archive(String id, {ArchiveReason? reason}) {
    final pet = findById(id);
    if (pet == null) return;
    _replace(pet.copyWith(
      status: PetStatus.archived,
      archiveReason: reason,
      meta: pet.meta.touched(_clock.now()),
    ));
    // Detiene recordatorios de sus programaciones (RF-03).
    for (var i = 0; i < _db.schedules.length; i++) {
      if (_db.schedules[i].petId == id) {
        _db.schedules[i] = _db.schedules[i].copyWith(reminderEnabled: false);
      }
    }
    _db.bump();
  }

  @override
  void unarchive(String id) {
    final pet = findById(id);
    if (pet == null) return;
    final now = _clock.now();
    _replace(pet.copyWith(
      status: PetStatus.active,
      meta: pet.meta.touched(now),
    ));
    // Reactiva recordatorios y recalcula las próximas fechas vencidas (RF-05).
    final today = DateTime(now.year, now.month, now.day);
    for (var i = 0; i < _db.schedules.length; i++) {
      final s = _db.schedules[i];
      if (s.petId != id) continue;
      var next = s.nextDate;
      var guard = 0;
      while (next.isBefore(today) && guard < 1000) {
        next = s.frequency.addTo(next);
        guard++;
      }
      _db.schedules[i] = s.copyWith(reminderEnabled: true, nextDate: next);
    }
    _db.bump();
  }

  @override
  void softDelete(String id) {
    final pet = findById(id);
    if (pet == null) return;
    _replace(pet.copyWith(meta: pet.meta.deleted(_clock.now())));
    // Elimina definitivamente todos sus datos asociados (RF-06).
    _db.schedules.removeWhere((s) => s.petId == id);
    _db.executions.removeWhere((e) => e.petId == id);
    _db.diagnoses.removeWhere((d) => d.petId == id);
    _db.weights.removeWhere((w) => w.petId == id);
    _db.visits.removeWhere((v) => v.petId == id);
    _db.vaccines.removeWhere((v) => v.petId == id);
    _db.attachments.removeWhere((a) => a.petId == id);
    _db.bump();
  }

  void _replace(Pet pet) {
    final i = _db.pets.indexWhere((p) => p.id == pet.id);
    if (i >= 0) _db.pets[i] = pet;
  }
}
