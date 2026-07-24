import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../care/domain/entities/compliance.dart';
import '../domain/entities/pet.dart';
import 'pet_view.dart';

/// Filtro de mascota activo en Inicio/Calendario (null = "Todas").
final petFilterProvider = StateProvider<String?>((ref) => null);

final ownerNameProvider = Provider<String>((ref) {
  final db = ref.watch(databaseProvider);
  return db.ownerName;
});

/// Mascotas activas con su cumplimiento calculado.
final petViewsProvider = Provider<List<PetView>>((ref) {
  ref.watch(databaseProvider);
  final petRepo = ref.read(petRepositoryProvider);
  final careRepo = ref.read(careRepositoryProvider);
  final scheduling = ref.read(schedulingServiceProvider);
  final now = ref.read(clockProvider).now();

  return [
    for (final pet in petRepo.activePets())
      () {
        final schedules = careRepo.schedulesForPet(pet.id);
        final compliance = scheduling.complianceOf(schedules, now);
        final worst = compliance.overdue > 0
            ? ComplianceStatus.overdue
            : compliance.due > 0
                ? ComplianceStatus.due
                : ComplianceStatus.ok;
        return PetView(
          pet: pet,
          compliance: compliance,
          worstStatus: worst,
          pendingCount: compliance.overdue + compliance.due,
        );
      }(),
  ];
});

final archivedPetsProvider = Provider<List<Pet>>((ref) {
  ref.watch(databaseProvider);
  return ref.read(petRepositoryProvider).archivedPets();
});

final petByIdProvider = Provider.family<Pet?, String>((ref, id) {
  ref.watch(databaseProvider);
  return ref.read(petRepositoryProvider).findById(id);
});
