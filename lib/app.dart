import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/data/in_memory_database.dart';
import 'core/i18n/locale_controller.dart';
import 'core/data/seed.dart';
import 'core/di/providers.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_text.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/clock.dart';
import 'core/utils/id_generator.dart';
import 'features/auth/application/auth_providers.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/plan/presentation/entitlement_sync.dart';
import 'features/security/presentation/app_lock_gate.dart';
import 'features/shell/home_shell.dart';

/// Navegador raíz, usado para abrir una mascota al tocar una notificación (RF-32).
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Raíz de la aplicación PituApp (PetBienestar). Tema claro/oscuro con la
/// identidad "cálido sereno"; sigue el tema del sistema. Según el estado de
/// sesión muestra el login, la app real o la demostración aislada.
class PituApp extends ConsumerWidget {
  const PituApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    // `null` = automático: MaterialApp resuelve el idioma del dispositivo con
    // `localeResolutionCallback` (fallback a inglés).
    final locale = ref.watch(localeControllerProvider);
    return MaterialApp(
      title: 'PituApp',
      navigatorKey: rootNavigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (deviceLocale, supported) {
        // Autodetección: usa el idioma del dispositivo si está soportado; si no,
        // inglés por defecto.
        if (deviceLocale != null) {
          for (final l in supported) {
            if (l.languageCode == deviceLocale.languageCode) return l;
          }
        }
        return kDefaultLocale;
      },
      home: _home(session),
    );
  }

  Widget _home(AuthSession session) {
    switch (session.status) {
      case SessionStatus.loading:
        return const _Splash();
      case SessionStatus.loggedOut:
        return const LoginScreen();
      case SessionStatus.authenticated:
        return const EntitlementSync(child: AppLockGate(child: HomeShell()));
      case SessionStatus.demo:
        return const _DemoSession();
    }
  }
}

/// Pantalla mínima mientras se resuelve la sesión inicial.
class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.bg,
      body: Center(
        child: Container(
          width: 84,
          height: 84,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: c.brandSoft, shape: BoxShape.circle),
          child: Icon(Icons.pets, size: 40, color: c.brand),
        ),
      ),
    );
  }
}

/// Sesión de **demostración**: un `ProviderScope` anidado con una base de datos
/// propia (sembrada con datos de ejemplo, en Pro) y **sin persistencia**. Como el
/// autoguardado real está atado a la base real en `main`, nada de lo que se haga
/// aquí toca la base local del usuario; al salir de la demo el scope se descarta
/// y los cambios desaparecen.
class _DemoSession extends StatelessWidget {
  const _DemoSession();

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWith((ref) {
          final db = InMemoryDatabase();
          DatabaseSeeder(db, const UuidGenerator(), const SystemClock(),
                  demo: true)
              .seed();
          return db;
        }),
        // Sin persistencia local: la demo es efímera.
        persistenceProvider.overrideWithValue(null),
      ],
      child: const _DemoScaffold(),
    );
  }
}

class _DemoScaffold extends ConsumerWidget {
  const _DemoScaffold();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Material(
              color: c.accent.withValues(alpha: 0.22),
              child: InkWell(
                onTap: () =>
                    ref.read(sessionControllerProvider.notifier).exitDemo(),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.play_circle_outline, size: 18, color: c.accentInk),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.demoBanner,
                          style: AppText.metaStrong(c.accentInk),
                        ),
                      ),
                      Text(l10n.demoExit, style: AppText.button(c.accentInk).copyWith(fontSize: 14)),
                      Icon(Icons.chevron_right, size: 18, color: c.accentInk),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Expanded(child: HomeShell()),
        ],
      ),
    );
  }
}
