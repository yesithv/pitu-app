import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_store.dart';

/// Implementación para **móvil/escritorio** (`dart:io`): guarda las credenciales
/// en el llavero del SO (Android Keystore / iOS Keychain) vía
/// `flutter_secure_storage`, igual que la clave de cifrado de la base
/// ([SecureKeyStore]). No usa el `prefs` recibido.
class SecureAuthStore implements AuthStore {
  SecureAuthStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

AuthStore makeAuthStore(SharedPreferences prefs) => SecureAuthStore();
