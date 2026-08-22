import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitu_app/core/data/in_memory_database.dart';
import 'package:pitu_app/core/di/providers.dart';
import 'package:pitu_app/core/widgets/app_buttons.dart';
import 'package:pitu_app/core/widgets/common.dart';
import 'package:pitu_app/features/demo/presentation/demo_plan_pill.dart';
import 'package:pitu_app/features/demo/presentation/demo_welcome_sheet.dart';
import 'package:pitu_app/features/plan/domain/plan.dart';

import 'support/pump_app.dart';

/// Pruebas del "Recorrido Pro" del demo (`docs/DEMO_ENFOQUE.md` §3.1 y §3.3):
/// la hoja de bienvenida resalta las funciones estrella marcando las de Pro, y el
/// conmutador Free↔Pro visible alterna el plan en vivo.
void main() {
  List<Override> withPlan(PlanType plan) => [
        databaseProvider.overrideWith((ref) {
          final db = InMemoryDatabase();
          db.planType = plan;
          return db;
        }),
      ];

  testWidgets('La hoja de bienvenida lista las funciones y marca las de Pro',
      (tester) async {
    await pumpApp(tester, const DemoWelcomeSheet(),
        surfaceSize: const Size(1080, 2400));

    // Botón para empezar a explorar.
    expect(find.text('Explorar'), findsOneWidget);
    expect(find.byType(PrimaryButton), findsOneWidget);

    // Se listan las funciones estrella (historial + PDF).
    expect(find.textContaining('Historial clínico completo'), findsOneWidget);
    expect(find.textContaining('Reporte PDF'), findsOneWidget);

    // Dos funciones exclusivas de Pro llevan el distintivo (PDF y recordatorios).
    expect(find.byType(ProBadge), findsNWidgets(2));
  });

  testWidgets('El conmutador del demo alterna Pro↔Free en vivo', (tester) async {
    await pumpApp(tester, const DemoPlanPill(), overrides: withPlan(PlanType.pro));

    // En Pro: muestra la etiqueta del plan y la acción para ver como Free.
    expect(find.text('Pro'), findsOneWidget);
    expect(find.text('Ver como Free'), findsOneWidget);
    expect(find.text('Volver a Pro'), findsNothing);

    // Al tocar, baja a Free y la acción se invierte.
    await tester.tap(find.byType(DemoPlanPill));
    await tester.pumpAndSettle();

    expect(find.text('Free'), findsOneWidget);
    expect(find.text('Volver a Pro'), findsOneWidget);
    expect(find.text('Ver como Free'), findsNothing);
  });
}
