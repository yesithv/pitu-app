import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/in_memory_database.dart';
import '../../../core/di/providers.dart';
import '../domain/plan.dart';

/// Estado del plan del usuario (RD-12). En Fase 1 se **persiste localmente**
/// (en el snapshot) y se recupera con "Restaurar compra"; en Fase 2 se valida
/// en servidor. Por defecto Free; una compra real (o el desbloqueo de
/// demostración en web) lo eleva a Pro y se conserva entre sesiones.
class EntitlementController extends StateNotifier<Entitlement> {
  EntitlementController(this._db) : super(_readFrom(_db));

  final InMemoryDatabase _db;

  static Entitlement _readFrom(InMemoryDatabase db) => Entitlement(
        plan: db.planType,
        purchaseSource: db.purchaseSource,
        purchasedAt: db.purchasedAt,
      );

  void unlockPro() => _persist(Entitlement(
        plan: PlanType.pro,
        purchaseSource: state.purchaseSource ?? 'store',
        purchasedAt: state.purchasedAt ?? DateTime.now(),
      ));

  void restore() => state = state; // la revalidación real la hace PurchaseService

  /// Solo para demostración: alterna a Free para ver los límites y el paywall.
  void useFreeForDemo() => _persist(const Entitlement(plan: PlanType.free));

  void _persist(Entitlement entitlement) {
    state = entitlement;
    _db.planType = entitlement.plan;
    _db.purchaseSource = entitlement.purchaseSource;
    _db.purchasedAt = entitlement.purchasedAt;
    _db.bump();
  }
}

final entitlementProvider =
    StateNotifierProvider<EntitlementController, Entitlement>(
  (ref) => EntitlementController(ref.read(databaseProvider)),
);
