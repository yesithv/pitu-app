import '../entities/care_execution.dart';
import '../entities/care_frequency.dart';
import '../entities/care_schedule.dart';

abstract interface class CareRepository {
  List<CareSchedule> schedulesForPet(String petId);

  /// Crea un cuidado personalizado (RF-11) con su tipo y programación.
  void createCustomCare({
    required String petId,
    required String name,
    required CareFrequency frequency,
  });

  /// Todas las programaciones activas de mascotas activas (para el dashboard).
  List<CareSchedule> allActiveSchedules();

  List<CareExecution> executionsForPet(String petId);

  void addSchedule(CareSchedule schedule);
  void updateSchedule(CareSchedule schedule);

  /// Marca un cuidado como realizado (RF-14): registra la ejecución, recalcula
  /// la próxima fecha y devuelve la ejecución creada (para deshacer, RF-16).
  CareExecution markDone(String scheduleId, {DateTime? date, String? notes});

  /// Deshace una ejecución recién creada (RF-16).
  void undo(String executionId);
}
