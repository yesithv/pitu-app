import '../domain/app_lock.dart';
// En web usa el stub (no-op); en móvil/escritorio (dart:io) la implementación
// real con local_auth.
import 'app_lock_stub.dart' if (dart.library.io) 'app_lock_io.dart';

AppLock createAppLock() => makeAppLock();
