import '../../pets/domain/entities/pet.dart';
import '../domain/entities/care_schedule.dart';
import '../domain/entities/compliance.dart';

/// Modelo de vista de una programación lista para renderizar: combina la
/// programación con su mascota y su estado de cumplimiento ya calculado.
class ScheduleView {
  const ScheduleView({
    required this.schedule,
    required this.pet,
    required this.status,
    required this.relativeLabel,
    required this.daysUntil,
  });

  final CareSchedule schedule;
  final Pet pet;
  final ComplianceStatus status;
  final String relativeLabel;

  /// Días hasta la próxima fecha (negativo si ya venció).
  final int daysUntil;

  String get id => schedule.id;
  String get name => schedule.name;
  bool get isPending => daysUntil <= 3; // vencidos + próximos inmediatos
}
