import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';
import 'auth_store.dart';

/// Implementación **local** de [AuthRepository] (Fase 1): una sola cuenta por
/// dispositivo, sin backend. La contraseña nunca se guarda en claro: se guarda
/// una sal aleatoria y el hash SHA-256 de `sal + contraseña`. La cuenta y la
/// sesión activa viven en un [AuthStore] (llavero del SO en móvil,
/// `shared_preferences` en web).
///
/// En Fase 2 esta clase se sustituye por una que hable con el backend (RF-53)
/// sin tocar dominio ni presentación.
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(this._store);

  final AuthStore _store;

  static const String _accountKey = 'pituapp.auth.account.v1';
  static const String _sessionKey = 'pituapp.auth.session.v1';

  @override
  Future<bool> hasAccount() async => (await _readAccount()) != null;

  @override
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final cleanName = name.trim();
    final cleanEmail = _normalizeEmail(email);
    if (cleanName.isEmpty) {
      return AuthResult.failure('Escribe tu nombre.');
    }
    if (!_isValidEmail(cleanEmail)) {
      return AuthResult.failure('Escribe un correo válido.');
    }
    if (password.length < 6) {
      return AuthResult.failure('La contraseña debe tener al menos 6 caracteres.');
    }
    if (await hasAccount()) {
      return AuthResult.failure(
          'Ya hay una cuenta en este dispositivo. Inicia sesión o usa la demo.');
    }

    final salt = _randomHex(16);
    final account = <String, dynamic>{
      'name': cleanName,
      'email': cleanEmail,
      'salt': salt,
      'hash': _hash(salt, password),
    };
    await _store.write(_accountKey, jsonEncode(account));
    await _store.write(_sessionKey, cleanEmail);
    return AuthResult.success(AuthUser(name: cleanName, email: cleanEmail));
  }

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final cleanEmail = _normalizeEmail(email);
    final account = await _readAccount();
    if (account == null) {
      return AuthResult.failure('Aún no hay una cuenta. Crea una para empezar.');
    }
    final matches = account['email'] == cleanEmail &&
        account['hash'] == _hash(account['salt'] as String, password);
    if (!matches) {
      return AuthResult.failure('Correo o contraseña incorrectos.');
    }
    await _store.write(_sessionKey, cleanEmail);
    return AuthResult.success(
        AuthUser(name: account['name'] as String, email: cleanEmail));
  }

  @override
  Future<void> logout() => _store.delete(_sessionKey);

  @override
  Future<AuthUser?> currentSession() async {
    final sessionEmail = await _store.read(_sessionKey);
    if (sessionEmail == null || sessionEmail.isEmpty) return null;
    final account = await _readAccount();
    if (account == null || account['email'] != sessionEmail) return null;
    return AuthUser(name: account['name'] as String, email: sessionEmail);
  }

  Future<Map<String, dynamic>?> _readAccount() async {
    final raw = await _store.read(_accountKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return (jsonDecode(raw) as Map).cast<String, dynamic>();
    } catch (_) {
      return null;
    }
  }

  static String _normalizeEmail(String email) => email.trim().toLowerCase();

  static bool _isValidEmail(String email) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

  static String _hash(String salt, String password) =>
      sha256.convert(utf8.encode('$salt$password')).toString();

  static String _randomHex(int bytes) {
    final rnd = Random.secure();
    final buffer = StringBuffer();
    for (var i = 0; i < bytes; i++) {
      buffer.write(rnd.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}
