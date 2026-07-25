import '../domain/purchase_service.dart';

/// Fábrica para plataformas sin tienda (web): no-op.
PurchaseService makePurchaseService() => const NoopPurchaseService();
