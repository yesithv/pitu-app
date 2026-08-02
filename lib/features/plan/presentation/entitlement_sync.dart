import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../purchases/application/purchases_providers.dart';
import '../application/entitlement_controller.dart';
import '../domain/plan.dart';

/// Restaura la compra al inicio, en segundo plano y **solo si el plan local es
/// Free** (RF-49). Cubre el caso de reinstalación o equipo nuevo: si la tienda
/// confirma una compra previa, sube a Pro sin intervención del usuario.
///
/// Es *upgrade-only*: nunca degrada un Pro ya presente y, al saltar cuando ya
/// hay Pro, evita el diálogo de inicio de sesión de la tienda en cada arranque.
/// En web/escritorio `PurchaseService.isSupported` es `false`, así que es no-op.
class EntitlementSync extends ConsumerStatefulWidget {
  const EntitlementSync({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<EntitlementSync> createState() => _EntitlementSyncState();
}

class _EntitlementSyncState extends ConsumerState<EntitlementSync> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoRestore());
  }

  Future<void> _autoRestore() async {
    final purchases = ref.read(purchaseServiceProvider);
    if (!purchases.isSupported) return; // web/escritorio: sin tienda.
    if (ref.read(entitlementProvider).plan != PlanType.free) return; // ya Pro.

    final result = await purchases.restore();
    if (!mounted) return;
    if (result.grantsPro) {
      ref.read(entitlementProvider.notifier).unlockPro();
    }
    // Sin compra que restaurar: se permanece en Free, en silencio.
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
