import '../domain/reminder_scheduler.dart';

/// Fábrica para plataformas sin soporte de notificaciones locales (web).
ReminderScheduler makeReminderScheduler() => const NoopReminderScheduler();
