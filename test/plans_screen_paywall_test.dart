import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitu_app/core/data/in_memory_database.dart';
import 'package:pitu_app/core/di/providers.dart';
import 'package:pitu_app/core/widgets/app_buttons.dart';
import 'package:pitu_app/features/plan/domain/plan.dart';
import 'package:pitu_app/features/plan/presentation/plans_screen.dart';
import 'package:pitu_app/features/purchases/application/purchases_providers.dart';
import 'package:pitu_app/features/purchases/domain/purchase_service.dart';

import 'support/pump_app.dart';

/// Pruebas de widget del paywall (RF-50): comparativa Free/Pro con candado
/// honesto. Verifica que el CTA de desbloqueo y el estado "plan actual" cambien
/// según el plan vigente. La fuente del plan es [InMemoryDatabase] (a través de
/// `entitlementProvider`), que aquí se inyecta por override.
void main() {
  /// Override de la base de datos con un plan concreto.
  List<Override> withPlan(PlanType plan) => [
        databaseProvider.overrideWith((ref) {
          final db = InMemoryDatabase();
          db.planType = plan;
          return db;
        }),
        // Aísla la pantalla del servicio real: PlansScreen.initState llama a
        // loadProProduct(); el no-op lo hace determinista y sin canales nativos.
        purchaseServiceProvider.overrideWithValue(const NoopPurchaseService()),
      ];

  testWidgets('En Free se ofrece desbloquear Pro y Free figura como plan actual',
      (tester) async {
    await pumpApp(tester, const PlansScreen(), overrides: withPlan(PlanType.free));

    // El CTA de Pro está disponible (aún no comprado).
    expect(find.text('Desbloquear Pro'), findsOneWidget);
    // Aún no se ha comprado Pro.
    expect(find.text('Pro · Comprado'), findsNothing);
    // Free es el plan vigente.
    expect(find.text('Plan actual'), findsOneWidget);
    // El botón principal (desbloquear Pro) está habilitado.
    expect(
      tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('En Pro se muestra "Comprado" y desaparece el CTA de desbloqueo',
      (tester) async {
    await pumpApp(tester, const PlansScreen(), overrides: withPlan(PlanType.pro));

    // Pro ya está comprado: sin CTA de desbloqueo.
    expect(find.text('Pro · Comprado'), findsOneWidget);
    expect(find.text('Desbloquear Pro'), findsNothing);
    // Con Pro vigente, Free deja de ser el plan actual y muestra su botón neutro.
    expect(find.text('Plan actual'), findsNothing);
    expect(find.text('Plan gratuito'), findsOneWidget);
  });

  testWidgets('Con función bloqueada, el paywall explica qué es exclusivo de Pro',
      (tester) async {
    await pumpApp(
      tester,
      const PlansScreen(blockedFeature: 'El reporte PDF'),
      overrides: withPlan(PlanType.free),
    );

    // La nota de "disponible en Pro" incluye el nombre de la función bloqueada.
    expect(find.textContaining('El reporte PDF'), findsOneWidget);
  });
}
