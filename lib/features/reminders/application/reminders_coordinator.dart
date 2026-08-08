import 'package:collection/collection.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/data/in_memory_database.dart';
import '../../../core/i18n/l10n_labels.dart';
import '../../../core/i18n/locale_controller.dart';
import '../../../core/utils/clock.dart';
import '../../care/domain/entities/care_kind.dart';
import '../domain/reminder_scheduler.dart';

/// Traduce el estado de la base en recordatorios y los reprograma por ventanas
/// (RF-33/RF-34). En web no hace nada (el scheduler no es soportado).
class RemindersCoordinator {
  RemindersCoordinator(this._db, this._scheduler, this._clock, this._prefs);

  final InMemoryDatabase _db;
  final ReminderScheduler _scheduler;
  final Clock _clock;
  final SharedPreferences _prefs;

  /// Tope de notificaciones pendientes (por debajo del límite de 64 de iOS).
  static const int _window = 60;

  /// Hora del día por defecto para el aviso.
  static const int _hour = 9;

  Future<void> resync() async {
    if (!_scheduler.isSupported) return;
    // Notificaciones en el idioma efectivo (preferencia guardada o dispositivo,
    // con fallback a inglés). Se carga fuera del árbol de widgets.
    final l10n = await AppLocalizations.delegate.load(effectiveLocale(_prefs));
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

      final careName = careDisplayName(l10n, s.kind, s.name);
      final DateTime when;
      final String title;
      final String body;
      if (dueDate.isBefore(today)) {
        // Tarea vencida (RF-31): se recuerda de nuevo a la próxima mañana.
        if (isBirthday) continue; // un cumpleaños no se "vence"
        when = nextMorning;
        title = l10n.notifOverdueTitle(pet.name, careName);
        body = l10n.notifOverdueBody(careName, pet.name);
      } else {
        // Anticipación configurable (Pro): avisar N días antes, a la hora fija.
        final target = dueDate.subtract(Duration(days: leadDays));
        var w = DateTime(target.year, target.month, target.day, _hour);
        if (!w.isAfter(now)) {
          w = DateTime(dueDate.year, dueDate.month, dueDate.day, _hour);
        }
        if (!w.isAfter(now)) continue;
        when = w;
        title = isBirthday
            ? l10n.notifBirthdayTitle(pet.name)
            : l10n.notifDueTitle(pet.name, careName);
        body = isBirthday
            ? l10n.notifBirthdayBody(pet.name)
            : (leadDays == 0
                ? l10n.notifDueTodayBody(pet.name, careName)
                : l10n.notifDueSoonBody(pet.name, careName));
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
    await _scheduler.rescheduleAll(
      requests.take(_window).toList(),
      channelName: l10n.notifChannelName,
      channelDescription: l10n.notifChannelDescription,
    );
  }
}
