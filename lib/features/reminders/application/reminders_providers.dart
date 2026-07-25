import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/reminder_scheduler.dart';

/// Scheduler de recordatorios. Se sobrescribe en `main` con la instancia real
/// (ya inicializada) según la plataforma; por defecto es no-op.
final reminderSchedulerProvider =
    Provider<ReminderScheduler>((ref) => const NoopReminderScheduler());
