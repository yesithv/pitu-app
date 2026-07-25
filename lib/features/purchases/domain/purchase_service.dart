/// Identificador del producto Pro (pago único / no consumible). Debe coincidir
/// con el configurado en App Store Connect y Google Play Console.
const String kProProductId = 'pituapp_pro_lifetime';

/// Resultado de una operación de compra o restauración.
enum PurchaseStatus { purchased, restored, cancelled, pending, error, notSupported }

class PurchaseResult {
  const PurchaseResult(this.status, [this.message = '']);
  final PurchaseStatus status;
  final String message;

  bool get grantsPro =>
      status == PurchaseStatus.purchased || status == PurchaseStatus.restored;
}

/// Producto tal como lo expone la tienda (precio localizado incluido).
class StoreProduct {
  const StoreProduct({required this.id, required this.title, required this.price});
  final String id;
  final String title;
  final String price;
}

/// Contrato de compras dentro de la app (RF-49/RF-50). La app depende solo de
/// esta interfaz; en web es un no-op y en móvil usa `in_app_purchase`, elegido
/// en tiempo de compilación por plataforma (igual que recordatorios y bloqueo).
abstract interface class PurchaseService {
  /// `false` en web/escritorio sin tienda; `true` en móvil.
  bool get isSupported;

  Future<void> init();

  /// Detalles del producto Pro (para mostrar el precio real de la tienda), o
  /// `null` si no está disponible.
  Future<StoreProduct?> loadProProduct();

  /// Lanza la compra del producto Pro.
  Future<PurchaseResult> buyPro();

  /// Restaura una compra previa (RF-49).
  Future<PurchaseResult> restore();

  Future<void> dispose();
}

/// Implementación vacía para web y como valor por defecto seguro.
class NoopPurchaseService implements PurchaseService {
  const NoopPurchaseService();

  @override
  bool get isSupported => false;

  @override
  Future<void> init() async {}

  @override
  Future<StoreProduct?> loadProProduct() async => null;

  @override
  Future<PurchaseResult> buyPro() async =>
      const PurchaseResult(PurchaseStatus.notSupported);

  @override
  Future<PurchaseResult> restore() async =>
      const PurchaseResult(PurchaseStatus.notSupported);

  @override
  Future<void> dispose() async {}
}
