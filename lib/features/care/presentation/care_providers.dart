import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../domain/entities/care_schedule.dart';
import '../domain/entities/compliance.dart';
import '../../pets/domain/entities/pet.dart';
import 'schedule_view.dart';

ScheduleView _toView(
  CareSchedule s,
  Pet pet,
  ComplianceStatus status,
  String relative,
  int daysUntil,
) =>
    ScheduleView(
      schedule: s,
      pet: pet,
      status: status,
      relativeLabel: relative,
      daysUntil: daysUntil,
    );

/// Programaciones de todas las mascotas activas, ya con estado calculado y
/// ordenadas por próxima fecha (para Inicio y Calendario).
final scheduleViewsForActiveProvider = Provider<List<ScheduleView>>((ref) {
  ref.watch(databaseProvider); // reactividad ante mutaciones
  final careRepo = ref.read(careRepositoryProvider);
  final petRepo = ref.read(petRepositoryProvider);
  final scheduling = ref.read(schedulingServiceProvider);
  final now = ref.read(clockProvider).now();

  final pets = {for (final p in petRepo.activePets()) p.id: p};
  final views = <ScheduleView>[];
  for (final s in careRepo.allActiveSchedules()) {
    final pet = pets[s.petId];
    if (pet == null) continue;
    views.add(_toView(
      s,
      pet,
      scheduling.statusOf(s.nextDate, now),
      scheduling.relativeLabel(s.nextDate, now),
      scheduling.daysUntil(s.nextDate, now),
    ));
  }
  views.sort((a, b) => a.schedule.nextDate.compareTo(b.schedule.nextDate));
  return views;
});

/// Programaciones de una mascota concreta.
final scheduleViewsForPetProvider =
    Provider.family<List<ScheduleView>, String>((ref, petId) {
  ref.watch(databaseProvider);
  final careRepo = ref.read(careRepositoryProvider);
  final petRepo = ref.read(petRepositoryProvider);
  final scheduling = ref.read(schedulingServiceProvider);
  final now = ref.read(clockProvider).now();

  final pet = petRepo.findById(petId);
  if (pet == null) return const [];
  final views = <ScheduleView>[];
  for (final s in careRepo.schedulesForPet(petId)) {
    views.add(_toView(
      s,
      pet,
      scheduling.statusOf(s.nextDate, now),
      scheduling.relativeLabel(s.nextDate, now),
      scheduling.daysUntil(s.nextDate, now),
    ));
  }
  views.sort((a, b) => a.schedule.nextDate.compareTo(b.schedule.nextDate));
  return views;
});
