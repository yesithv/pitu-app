import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

/// Estados posibles de la sesión de la app.
enum SessionStatus {
  /// Resolviendo la sesión inicial (arranque).
  loading,

  /// Sin sesión: se muestra la pantalla de login.
  loggedOut,

  /// Sesión iniciada con la cuenta local.
  authenticated,

  /// Sesión de **demostración**: datos de ejemplo aislados y efímeros.
  demo,
}

/// Estado de sesión + usuario actual (si lo hay).
class AuthSession {
  const AuthSession(this.status, {this.user});

  final SessionStatus status;
  final AuthUser? user;

  static const AuthSession loading = AuthSession(SessionStatus.loading);
  static const AuthSession loggedOut = AuthSession(SessionStatus.loggedOut);
  static const AuthSession demo = AuthSession(SessionStatus.demo);
}

/// Repositorio de autenticación. Se **sobreescribe en `main`** con la
/// implementación local real (`LocalAuthRepository`). El valor por defecto falla
/// a propósito para detectar un arranque mal compuesto.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  throw UnimplementedError(
      'authRepositoryProvider debe sobreescribirse en main con la instancia real.');
});

/// Sesión inicial resuelta en `main` (autenticada si hay sesión guardada, o
/// `loggedOut`). Se sobreescribe en el arranque; por defecto, cargando.
final initialSessionProvider =
    Provider<AuthSession>((ref) => AuthSession.loading);

/// Controlador de la sesión: expone el estado y las transiciones (login,
/// registro, entrar/salir de la demo, cerrar sesión).
final sessionControllerProvider =
    StateNotifierProvider<SessionController, AuthSession>((ref) {
  return SessionController(
    ref.watch(authRepositoryProvider),
    ref.watch(initialSessionProvider),
  );
});

class SessionController extends StateNotifier<AuthSession> {
  SessionController(this._repo, AuthSession initial) : super(initial);

  final AuthRepository _repo;

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final result = await _repo.login(email: email, password: password);
    if (result.ok) {
      state = AuthSession(SessionStatus.authenticated, user: result.user);
    }
    return result;
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final result =
        await _repo.register(name: name, email: email, password: password);
    if (result.ok) {
      state = AuthSession(SessionStatus.authenticated, user: result.user);
    }
    return result;
  }

  /// Entra a la sesión de demostración (datos de ejemplo aislados y efímeros).
  void enterDemo() => state = AuthSession.demo;

  /// Sale de la demo y vuelve a la pantalla de login.
  void exitDemo() => state = AuthSession.loggedOut;

  /// Cierra la sesión (conserva la cuenta registrada) y vuelve al login.
  Future<void> logout() async {
    await _repo.logout();
    state = AuthSession.loggedOut;
  }
}
