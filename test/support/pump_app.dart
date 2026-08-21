import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitu_app/core/theme/app_theme.dart';
import 'package:pitu_app/l10n/app_localizations.dart';

/// Arnés para pruebas de widget: envuelve [child] en un [ProviderScope] (con los
/// [overrides] que se pasen) y un [MaterialApp] con las localizaciones reales,
/// forzando el español para poder aseverar los textos de la interfaz.
///
/// Usa el tema **real** de la app ([AppTheme.light]) para ganar fidelidad
/// (`inputDecorationTheme`, `appBarTheme`, `colorScheme`, etc.), no un tema
/// mínimo. En `flutter test` la carga de google_fonts está aislada: la petición
/// de red se intercepta y el paquete cae a la fuente por defecto sin lanzar.
///
/// [surfaceSize] fija un lienzo de prueba concreto (p. ej. el alto de un teléfono)
/// cuando una pantalla no cabe en el tamaño por defecto (800x600) y su `ListView`
/// virtualiza campos fuera de vista. Se restablece automáticamente al terminar.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
  Size? surfaceSize,
}) async {
  if (surfaceSize != null) {
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        locale: const Locale('es'),
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
