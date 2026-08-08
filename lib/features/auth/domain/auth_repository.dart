import 'auth_user.dart';

/// Resultado de una operación de autenticación. Un `AuthResult` es éxito (con el
/// usuario) o error (con un mensaje en español listo para mostrar).
class AuthResult {
  const AuthResult._({this.user, this.error});

  factory AuthResult.success(AuthUser user) => AuthResult._(user: user);
  factory AuthResult.failure(String message) => AuthResult._(error: message);

  final AuthUser? user;
  final String? error;

  bool get ok => user != null;
}

/// Contrato de autenticación de la cuenta **local** (Fase 1).
///
/// Sigue el patrón repositorio del proyecto: el dominio y la presentación no
/// dependen de la fuente. Hoy la implementación es local
/// ([LocalAuthRepository]); en Fase 2 basta sustituirla por una que hable con el
/// backend, sin tocar la UI (ERS §8.3, RF-53).
abstract class AuthRepository {
  /// Si ya existe una cuenta registrada en el dispositivo.
  Future<bool> hasAccount();

  /// Crea la cuenta local. Falla si el correo ya está registrado o si los datos
  /// no son válidos. En caso de éxito deja la sesión iniciada.
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  });

  /// Inicia sesión con correo y contraseña. Falla si no coinciden o no hay
  /// cuenta. En caso de éxito deja la sesión iniciada.
  Future<AuthResult> login({
    required String email,
    required String password,
  });

  /// Cierra la sesión activa (conserva la cuenta registrada).
  Future<void> logout();

  /// El usuario de la sesión activa, o `null` si no hay sesión iniciada.
  Future<AuthUser?> currentSession();
}
