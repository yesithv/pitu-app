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
    final requests = <ReminderRequest>[];

    for (final s in _db.schedules) {
      if (!s.isActive || !s.reminderEnabled || s.meta.isDeleted) continue;
      final pet = _db.pets.firstWhereOrNull((p) => p.id == s.petId);
      if (pet == null || !pet.isActive) continue;
      if (!s.nextDate.isAfter(now)) continue;

      // Anticipación configurable (Pro): avisar N días antes, a la hora fija.
      final target = DateTime(s.nextDate.year, s.nextDate.month, s.nextDate.day)
          .subtract(Duration(days: leadDays));
      var when = DateTime(target.year, target.month, target.day, _hour);
      // Si la anticipación deja el aviso en el pasado, se avisa el mismo día.
      if (!when.isAfter(now)) {
        when = DateTime(s.nextDate.year, s.nextDate.month, s.nextDate.day, _hour);
      }
      if (!when.isAfter(now)) continue;

      final isBirthday = s.kind == CareKind.birthday;
      requests.add(ReminderRequest(
        id: s.id.hashCode & 0x7fffffff,
        title: isBirthday ? '🎂 ${pet.name} cumple años' : '${pet.name}: ${s.name}',
        body: isBirthday
            ? '¡Hoy ${pet.name} está de cumpleaños! 🎂'
            : (leadDays == 0
                ? 'Hoy le toca ${s.name.toLowerCase()} a ${pet.name}. 🐾'
                : 'Pronto le toca ${s.name.toLowerCase()} a ${pet.name}. 🐾'),
        when: when,
      ));
    }

    requests.sort((a, b) => a.when.compareTo(b.when));
    await _scheduler.rescheduleAll(requests.take(_window).toList());
  }
}
