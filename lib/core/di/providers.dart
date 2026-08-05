import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/care/data/care_repository_impl.dart';
import '../../features/care/domain/repositories/care_repository.dart';
import '../../features/care/domain/services/scheduling_service.dart';
import '../../features/clinical/data/clinical_repository_impl.dart';
import '../../features/clinical/domain/repositories/clinical_repository.dart';
import '../../features/pets/data/pet_repository_impl.dart';
import '../../features/pets/domain/repositories/pet_repository.dart';
import '../config/app_config.dart';
import '../data/in_memory_database.dart';
import '../data/local_persistence.dart';
import '../data/seed.dart';
import '../utils/clock.dart';
import '../utils/id_generator.dart';

/// Composición de dependencias (raíz de la app). Cambiar la implementación de
/// datos en Fase 2 consiste en sustituir los providers de repositorio, sin
/// tocar dominio ni presentación (§8.3).

final clockProvider = Provider<Clock>((ref) => const SystemClock());

final idGeneratorProvider =
    Provider<IdGenerator>((ref) => const UuidGenerator());

final schedulingServiceProvider =
    Provider<SchedulingService>((ref) => const SchedulingService());

/// Persistencia local del snapshot. Se sobreescribe en `main` con la instancia
/// enlazada a shared_preferences; el valor por defecto no persiste (útil en
/// tests o entornos sin almacenamiento).
final persistenceProvider = Provider<LocalPersistence?>((ref) => null);

/// Base de datos local (in-memory en el MVP). Instancia estable y sembrada.
final databaseProvider = ChangeNotifierProvider<InMemoryDatabase>((ref) {
  final db = InMemoryDatabase();
  DatabaseSeeder(db, ref.read(idGeneratorProvider), ref.read(clockProvider),
          demo: kDemoMode)
      .seed();
  return db;
});

// Los repositorios usan `ref.read` de la BD (instancia estable): mantienen su
// estado interno (p. ej. snapshots de deshacer) entre notificaciones. La
// reactividad de la UI proviene de observar [databaseProvider] en las vistas.

final petRepositoryProvider = Provider<PetRepository>(
  (ref) => InMemoryPetRepository(
    ref.read(databaseProvider),
    ref.read(clockProvider),
  ),
);

final careRepositoryProvider = Provider<CareRepository>(
  (ref) => InMemoryCareRepository(
    ref.read(databaseProvider),
    ref.read(clockProvider),
    ref.read(idGeneratorProvider),
    ref.read(schedulingServiceProvider),
  ),
);

final clinicalRepositoryProvider = Provider<ClinicalRepository>(
  (ref) => InMemoryClinicalRepository(
    ref.read(databaseProvider),
    ref.read(clockProvider),
    ref.read(idGeneratorProvider),
  ),
);
