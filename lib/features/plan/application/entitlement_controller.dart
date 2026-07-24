import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/plan.dart';

/// Estado del plan del usuario (RD-12). En Fase 1 se persiste localmente y se
/// recupera con "Restaurar compra"; en Fase 2 se valida en servidor.
class EntitlementController extends StateNotifier<Entitlement> {
  EntitlementController() : super(_initial);

  // El prototipo se muestra con Pro activo para exhibir todas las funciones
  // (panel de cumplimiento, 2 mascotas). El paywall sigue accesible desde
  // Ajustes → Suscripción.
  static const Entitlement _initial =
      Entitlement(plan: PlanType.pro, purchaseSource: 'demo');

  void unlockPro() =>
      state = state.copyWith(plan: PlanType.pro, purchaseSource: 'store');

  void restore() => state = state; // stub: revalida el entitlement local

  /// Solo para demostración: alterna a Free para ver los límites y el paywall.
  void useFreeForDemo() => state = const Entitlement(plan: PlanType.free);
}

final entitlementProvider =
    StateNotifierProvider<EntitlementController, Entitlement>(
  (ref) => EntitlementController(),
);
