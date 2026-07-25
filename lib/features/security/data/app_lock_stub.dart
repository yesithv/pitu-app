import '../domain/app_lock.dart';

/// Fábrica para plataformas sin biometría (web).
AppLock makeAppLock() => const NoopAppLock();
