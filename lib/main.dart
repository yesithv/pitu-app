import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/data/in_memory_database.dart';
import 'core/data/persistence.dart';
import 'core/data/seed.dart';
import 'core/di/providers.dart';
import 'core/utils/clock.dart';
import 'core/utils/id_generator.dart';
import 'features/reminders/application/reminders_coordinator.dart';
import 'features/reminders/application/reminders_providers.dart';
import 'features/reminders/data/reminder_scheduler_factory.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carga el estado persistido (o siembra datos de ejemplo la primera vez) y
  // activa el autoguardado antes de arrancar la app.
  final prefs = await SharedPreferences.getInstance();
  final persistence = Persistence(prefs);

  final db = InMemoryDatabase();
  final loaded = persistence.loadInto(db);
  if (!loaded) {
    DatabaseSeeder(db, const UuidGenerator(), const SystemClock()).seed();
    persistence.save(db);
  }
  persistence.attachAutosave(db);

  // Recordatorios locales (no-op en web, reales en móvil). Se reprograman ante
  // cada cambio de la base.
  final scheduler = createReminderScheduler();
  await scheduler.init();
  final reminders = RemindersCoordinator(db, scheduler, const SystemClock());
  _attachReminderResync(db, reminders);
  await reminders.resync();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWith((ref) => db),
        reminderSchedulerProvider.overrideWithValue(scheduler),
      ],
      child: const PituApp(),
    ),
  );
}

/// Reprograma recordatorios ante cambios, agrupando ráfagas por microtask.
void _attachReminderResync(InMemoryDatabase db, RemindersCoordinator reminders) {
  var scheduled = false;
  db.addListener(() {
    if (scheduled) return;
    scheduled = true;
    Future.microtask(() {
      scheduled = false;
      reminders.resync();
    });
  });
}
