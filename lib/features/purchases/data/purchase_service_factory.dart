import '../domain/purchase_service.dart';
// En web (sin `dart:io`) usa el stub no-op; en móvil (con `dart:io`) la
// implementación real con in_app_purchase.
import 'purchase_service_stub.dart'
    if (dart.library.io) 'purchase_service_io.dart';

PurchaseService createPurchaseService() => makePurchaseService();
