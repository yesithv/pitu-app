import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../domain/app_lock.dart';

/// Mecanismo de bloqueo. Se sobrescribe en `main` con la instancia real por
/// plataforma; por defecto no-op.
final appLockProvider = Provider<AppLock>((ref) => const NoopAppLock());

/// Preferencia de bloqueo biométrico (persistida en la base local).
final biometricEnabledProvider = Provider<bool>((ref) {
  final db = ref.watch(databaseProvider);
  return db.biometricLockEnabled;
});
