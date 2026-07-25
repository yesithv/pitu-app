import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../domain/purchase_service.dart' as ps;

/// Fábrica para móvil: compras reales con `in_app_purchase`.
ps.PurchaseService makePurchaseService() => LocalPurchaseService();

/// Implementación real de compras. El producto Pro es **no consumible** (pago
/// único, de por vida). Escucha el flujo de compras del sistema y resuelve la
/// operación en curso cuando la tienda confirma, cancela o falla.
class LocalPurchaseService implements ps.PurchaseService {
  final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _sub;
  Completer<ps.PurchaseResult>? _pending;
  bool _available = false;

  @override
  bool get isSupported => true;

  @override
  Future<void> init() async {
    _available = await _iap.isAvailable();
    _sub = _iap.purchaseStream.listen(
      _onUpdates,
      onError: (_) => _resolve(
          const ps.PurchaseResult(ps.PurchaseStatus.error, 'Error en la tienda.')),
    );
  }

  void _onUpdates(List<PurchaseDetails> purchases) {
    for (final p in purchases) {
      switch (p.status) {
        case PurchaseStatus.pending:
          // Compra en curso: se espera una actualización posterior.
          break;
        case PurchaseStatus.error:
          if (p.pendingCompletePurchase) _iap.completePurchase(p);
          _resolve(ps.PurchaseResult(ps.PurchaseStatus.error,
              p.error?.message ?? 'No se pudo completar la compra.'));
          break;
        case PurchaseStatus.canceled:
          if (p.pendingCompletePurchase) _iap.completePurchase(p);
          _resolve(const ps.PurchaseResult(ps.PurchaseStatus.cancelled));
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (p.productID == ps.kProProductId) {
            if (p.pendingCompletePurchase) _iap.completePurchase(p);
            _resolve(ps.PurchaseResult(p.status == PurchaseStatus.restored
                ? ps.PurchaseStatus.restored
                : ps.PurchaseStatus.purchased));
          }
          break;
      }
    }
  }

  @override
  Future<ps.StoreProduct?> loadProProduct() async {
    if (!_available) return null;
    final resp = await _iap.queryProductDetails({ps.kProProductId});
    if (resp.productDetails.isEmpty) return null;
    final p = resp.productDetails.first;
    return ps.StoreProduct(id: p.id, title: p.title, price: p.price);
  }

  @override
  Future<ps.PurchaseResult> buyPro() async {
    if (!_available) {
      return const ps.PurchaseResult(
          ps.PurchaseStatus.error, 'La tienda no está disponible.');
    }
    final resp = await _iap.queryProductDetails({ps.kProProductId});
    if (resp.productDetails.isEmpty) {
      return const ps.PurchaseResult(
          ps.PurchaseStatus.error, 'El producto no está disponible en la tienda.');
    }
    _pending = Completer<ps.PurchaseResult>();
    final param = PurchaseParam(productDetails: resp.productDetails.first);
    await _iap.buyNonConsumable(purchaseParam: param);
    return _pending!.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () => const ps.PurchaseResult(ps.PurchaseStatus.pending),
    );
  }

  @override
  Future<ps.PurchaseResult> restore() async {
    if (!_available) {
      return const ps.PurchaseResult(
          ps.PurchaseStatus.error, 'La tienda no está disponible.');
    }
    _pending = Completer<ps.PurchaseResult>();
    await _iap.restorePurchases();
    return _pending!.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () => const ps.PurchaseResult(
          ps.PurchaseStatus.error, 'No encontramos compras para restaurar.'),
    );
  }

  void _resolve(ps.PurchaseResult result) {
    final completer = _pending;
    if (completer != null && !completer.isCompleted) completer.complete(result);
    _pending = null;
  }

  @override
  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}
