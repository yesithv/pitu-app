import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/purchase_service.dart';

/// Servicio de compras. Se sobrescribe en `main` con la instancia real (ya
/// inicializada) según la plataforma; por defecto es no-op.
final purchaseServiceProvider =
    Provider<PurchaseService>((ref) => const NoopPurchaseService());
