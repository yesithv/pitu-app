import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/data/in_memory_database.dart';
import 'core/data/persistence_factory.dart';
import 'core/data/seed.dart';
import 'core/di/providers.dart';
import 'core/observability/crash_reporter.dart';
import 'core/observability/crash_reporter_providers.dart';
import 'core/utils/clock.dart';
import 'core/utils/id_generator.dart';
import 'features/auth/application/auth_providers.dart';
import 'features/auth/data/auth_store_factory.dart';
import 'features/auth/data/local_auth_repository.dart';
import 'features/care/application/catalog_updater.dart';
import 'features/reminders/application/reminders_coordinator.dart';
import 'features/reminders/application/reminders_providers.dart';
import 'features/reminders/data/reminder_scheduler_factory.dart';
import 'features/reminders/domain/reminder_scheduler.dart';
import 'features/pets/presentation/pet_detail_screen.dart';
import 'features/purchases/application/purchases_providers.dart';
import 'features/purchases/data/purchase_service_factory.dart';
import 'features/security/application/security_providers.dart';
import 'features/security/data/app_lock_factory.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Reporte de errores (no-op por ahora; se enchufa un backend real después).
  // Se conecta a los handlers globales de Flutter antes de arrancar la app.
  final crashReporter = createCrashReporter();
  await crashReporter.init();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    crashReporter.recordError(details.exception, details.stack, fatal: true);
  };
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    crashReporter.recordError(error, stack, fatal: true);
    return true;
  };

  // Carga el estado persistido (o siembra datos de ejemplo la primera vez) y
  // activa el autoguardado antes de arrancar la app.
  final prefs = await SharedPreferences.getInstance();
  // En móvil abre la base SQLite cifrada (Drift + SQLCipher, RNF-10) y migra un
  // snapshot previo si existe; en web usa el snapshot en localStorage.
  final persistence = await createPersistence(
    prefs,
    onError: (error, stack) =>
        crashReporter.recordError(error, stack, fatal: false),
  );

  final db = InMemoryDatabase();
  final loaded = persistence.loadInto(db);
  if (!loaded) {
    DatabaseSeeder(db, const UuidGenerator(), const SystemClock(), demo: kDemoMode)
        .seed();
    persistence.save(db);
  }
  // Aplica actualizaciones aditivas del catálogo a las mascotas existentes
  // (RF-13). No-op mientras la versión del catálogo no cambie.
  CatalogUpdater(db, const UuidGenerator(), const SystemClock()).reconcile();
  persistence.attachAutosave(db);

  // Recordatorios locales (no-op en web, reales en móvil). Se reprograman ante
  // cada cambio de la base.
  final scheduler = createReminderScheduler();
  await scheduler.init();
  // Al tocar una notificación, abre la mascota asociada (RF-32).
  scheduler.setOnSelect((petId) {
    rootNavigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => PetDetailScreen(petId: petId)),
    );
  });
  final reminders = RemindersCoordinator(db, scheduler, const SystemClock());
  _attachReminderResync(db, reminders);
  await reminders.resync();
  // Al volver a primer plano, si cambió la zona horaria del dispositivo (RF-33),
  // se refija la zona local y se reprograman todos los recordatorios.
  WidgetsBinding.instance
      .addObserver(_TimeZoneReminderObserver(scheduler, reminders));

  // Bloqueo biométrico (no-op en web, real en móvil).
  final appLock = createAppLock();

  // Compras dentro de la app (no-op en web, reales en móvil).
  final purchases = createPurchaseService();
  await purchases.init();

  // Cuenta local (Fase 1): sin backend. Determina la sesión inicial; si hay una
  // sesión guardada se entra directo, si no se muestra el login.
  final authRepository = LocalAuthRepository(createAuthStore(prefs));
  final initialUser = await authRepository.currentSession();
  final initialSession = initialUser != null
      ? AuthSession(SessionStatus.authenticated, user: initialUser)
      : AuthSession.loggedOut;

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWith((ref) => db),
        persistenceProvider.overrideWithValue(persistence),
        reminderSchedulerProvider.overrideWithValue(scheduler),
        appLockProvider.overrideWithValue(appLock),
        purchaseServiceProvider.overrideWithValue(purchases),
        crashReporterProvider.overrideWithValue(crashReporter),
        authRepositoryProvider.overrideWithValue(authRepository),
        initialSessionProvider.overrideWithValue(initialSession),
      ],
      child: const PituApp(),
    ),
  );
}

/// Observa el ciclo de vida para reprogramar los recordatorios cuando cambia la
/// zona horaria del dispositivo (RF-33). Al reanudar la app se re-lee la zona
/// local; si cambió, se reprograma toda la ventana con la hora local correcta.
class _TimeZoneReminderObserver extends WidgetsBindingObserver {
  _TimeZoneReminderObserver(this._scheduler, this._reminders);

  final ReminderScheduler _scheduler;
  final RemindersCoordinator _reminders;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    Future(() async {
      if (await _scheduler.refreshTimeZone()) {
        await _reminders.resync();
      }
    });
  }
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
