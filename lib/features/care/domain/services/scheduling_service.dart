import '../entities/care_frequency.dart';
import '../entities/care_schedule.dart';
import '../entities/compliance.dart';

/// Lógica pura de programación y cumplimiento (RF-12, RF-36). Sin dependencias
/// de UI ni de la fuente de datos: totalmente testeable.
class SchedulingService {
  const SchedulingService({this.dueWindowDays = 7});

  /// Ventana en días para considerar un cuidado "próximo".
  final int dueWindowDays;

  /// Próxima fecha a partir de la última ejecución y la frecuencia (RF-12).
  DateTime nextDateFrom(DateTime lastDone, CareFrequency frequency) =>
      frequency.addTo(lastDone);

  /// Días entre [now] y [nextDate] (negativo si ya venció).
  int daysUntil(DateTime nextDate, DateTime now) {
    final a = DateTime(now.year, now.month, now.day);
    final b = DateTime(nextDate.year, nextDate.month, nextDate.day);
    return b.difference(a).inDays;
  }

  ComplianceStatus statusOf(DateTime nextDate, DateTime now) {
    final days = daysUntil(nextDate, now);
    if (days < 0) return ComplianceStatus.overdue;
    if (days <= dueWindowDays) return ComplianceStatus.due;
    return ComplianceStatus.ok;
  }

  /// Texto relativo del estado ("Venció hace 5 días", "En 3 días", "Al día").
  String relativeLabel(DateTime nextDate, DateTime now) {
    final days = daysUntil(nextDate, now);
    if (days < 0) {
      final d = -days;
      return d == 1 ? 'Venció ayer' : 'Venció hace $d días';
    }
    if (days == 0) return 'Hoy';
    if (days == 1) return 'Mañana';
    return 'En $days días';
  }

  /// Cumplimiento agregado de una mascota a partir de sus programaciones.
  PetCompliance complianceOf(Iterable<CareSchedule> schedules, DateTime now) {
    final active = schedules.where((s) => s.isActive).toList();
    if (active.isEmpty) return PetCompliance.empty;
    var overdue = 0;
    var due = 0;
    for (final s in active) {
      switch (statusOf(s.nextDate, now)) {
        case ComplianceStatus.overdue:
          overdue++;
        case ComplianceStatus.due:
          due++;
        case ComplianceStatus.ok:
          break;
      }
    }
    return PetCompliance(
      total: active.length,
      upToDate: active.length - overdue,
      overdue: overdue,
      due: due,
    );
  }
}
