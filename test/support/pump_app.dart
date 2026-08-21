import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitu_app/l10n/app_localizations.dart';

/// Arnés mínimo para pruebas de widget: envuelve [child] en un [ProviderScope]
/// (con los [overrides] que se pasen) y un [MaterialApp] con las localizaciones
/// reales, forzando el español para poder aseverar los textos de la interfaz.
///
/// El tema es un [ThemeData] claro mínimo: basta con el brillo, porque
/// `context.colors` resuelve los tokens de color por `Theme.of(context).brightness`
/// (ver `app_colors.dart`), sin depender de `AppTheme`/google_fonts. Así las
/// pruebas son herméticas (no tocan la red ni canales de plataforma).
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        locale: const Locale('es'),
        theme: ThemeData(brightness: Brightness.light, useMaterial3: true),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
