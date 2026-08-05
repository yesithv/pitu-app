import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Custodia de la clave de cifrado de la base local en el **llavero del SO**
/// (Android Keystore / iOS Keychain), vía `flutter_secure_storage`.
///
/// La clave es de 32 bytes (256 bits) en hexadecimal; se genera una sola vez con
/// un generador seguro y se reutiliza en arranques posteriores. Nunca se guarda
/// en claro fuera del llavero.
class SecureKeyStore {
  SecureKeyStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  static const String _keyName = 'pituapp.db.key.v1';

  /// Devuelve la clave hexadecimal (64 caracteres). La crea y persiste la
  /// primera vez.
  Future<String> obtainHexKey() async {
    final existing = await _storage.read(key: _keyName);
    if (existing != null && existing.length == 64) return existing;
    final hex = _randomHex(32);
    await _storage.write(key: _keyName, value: hex);
    return hex;
  }

  static String _randomHex(int bytes) {
    final rnd = Random.secure();
    final buffer = StringBuffer();
    for (var i = 0; i < bytes; i++) {
      buffer.write(rnd.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}
