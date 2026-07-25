import '../domain/reminder_scheduler.dart';
// Selección por plataforma en tiempo de compilación: en web se usa el stub
// (no-op) y en móvil/escritorio (dart:io disponible) la implementación real.
import 'reminder_scheduler_stub.dart'
    if (dart.library.io) 'reminder_scheduler_io.dart';

ReminderScheduler createReminderScheduler() => makeReminderScheduler();
