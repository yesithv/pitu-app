import 'package:local_auth/local_auth.dart';

import '../domain/app_lock.dart';

AppLock makeAppLock() => LocalAppLock();

/// Bloqueo biométrico real para móvil (RNF-11) usando local_auth.
///
/// Nota: solo se compila en móvil (dart:io); requiere validación en
/// dispositivo/emulador. El build web usa el stub no-op.
class LocalAppLock implements AppLock {
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  bool get isSupported => true;

  @override
  Future<bool> canAuthenticate() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return supported || canCheck;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(stickyAuth: true),
      );
    } catch (_) {
      return false;
    }
  }
}
