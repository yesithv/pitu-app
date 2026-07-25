/// Contrato para el bloqueo biométrico opcional de la app (RNF-11). La app
/// depende solo de esta interfaz; en web es un no-op y en móvil usa local_auth,
/// elegido en tiempo de compilación por plataforma.
abstract interface class AppLock {
  /// Falso en web (no hay biometría).
  bool get isSupported;

  /// El dispositivo tiene biometría o credencial configurada y disponible.
  Future<bool> canAuthenticate();

  /// Solicita autenticación; devuelve true si el usuario se autenticó (o si no
  /// aplica bloqueo, como en web).
  Future<bool> authenticate(String reason);
}

/// Implementación vacía para web y valor por defecto seguro: nunca bloquea.
class NoopAppLock implements AppLock {
  const NoopAppLock();

  @override
  bool get isSupported => false;

  @override
  Future<bool> canAuthenticate() async => false;

  @override
  Future<bool> authenticate(String reason) async => true;
}
