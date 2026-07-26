import 'package:collection/collection.dart';

import '../../../core/data/in_memory_database.dart';
import '../../../core/utils/clock.dart';
import '../../care/domain/entities/care_kind.dart';
import '../domain/reminder_scheduler.dart';

/// Traduce el estado de la base en recordatorios y los reprograma por ventanas
/// (RF-33/RF-34). En web no hace nada (el scheduler no es soportado).
class RemindersCoordinator {
  RemindersCoordinator(this._db, this._scheduler, this._clock);

  final InMemoryDatabase _db;
  final ReminderScheduler _scheduler;
  final Clock _clock;

  /// Tope de notificaciones pendientes (por debajo del límite de 64 de iOS).
  static const int _window = 60;

  /// Hora del día por defecto para el aviso.
  static const int _hour = 9;

  Future<void> resync() async {
    if (!_scheduler.isSupported) return;
    final now = _clock.now();
    final leadDays = _db.reminderLeadDays.clamp(0, 30);
    final today = DateTime(now.year, now.month, now.day);
    final todayAt9 = DateTime(now.year, now.month, now.day, _hour);
    final nextMorning =
        todayAt9.isAfter(now) ? todayAt9 : todayAt9.add(const Duration(days: 1));
    final requests = <ReminderRequest>[];

    for (final s in _db.schedules) {
      if (!s.isActive || !s.reminderEnabled || s.meta.isDeleted) continue;
      final pet = _db.pets.firstWhereOrNull((p) => p.id == s.petId);
      if (pet == null || !pet.isActive) continue;

      final isBirthday = s.kind == CareKind.birthday;
      final dueDate =
          DateTime(s.nextDate.year, s.nextDate.month, s.nextDate.day);

      final DateTime when;
      final String title;
      final String body;
      if (dueDate.isBefore(today)) {
        // Tarea vencida (RF-31): se recuerda de nuevo a la próxima mañana.
        if (isBirthday) continue; // un cumpleaños no se "vence"
        when = nextMorning;
        title = '${pet.name}: ${s.name} vencido';
        body = '${s.name} de ${pet.name} sigue pendiente. 🐾';
      } else {
        // Anticipación configurable (Pro): avisar N días antes, a la hora fija.
        final target = dueDate.subtract(Duration(days: leadDays));
        var w = DateTime(target.year, target.month, target.day, _hour);
        if (!w.isAfter(now)) {
          w = DateTime(dueDate.year, dueDate.month, dueDate.day, _hour);
        }
        if (!w.isAfter(now)) continue;
        when = w;
        title =
            isBirthday ? '🎂 ${pet.name} cumple años' : '${pet.name}: ${s.name}';
        body = isBirthday
            ? '¡Hoy ${pet.name} está de cumpleaños! 🎂'
            : (leadDays == 0
                ? 'Hoy le toca ${s.name.toLowerCase()} a ${pet.name}. 🐾'
                : 'Pronto le toca ${s.name.toLowerCase()} a ${pet.name}. 🐾');
      }

      requests.add(ReminderRequest(
        id: s.id.hashCode & 0x7fffffff,
        title: title,
        body: body,
        when: when,
        payload: pet.id,
      ));
    }

    requests.sort((a, b) => a.when.compareTo(b.when));
    await _scheduler.rescheduleAll(requests.take(_window).toList());
  }
}
