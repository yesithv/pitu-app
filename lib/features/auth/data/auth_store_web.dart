import 'package:shared_preferences/shared_preferences.dart';

import 'auth_store.dart';

/// Implementación para **web** (y entornos sin `dart:io`): guarda las
/// credenciales en `shared_preferences` (que en web es `localStorage`). El
/// navegador no tiene llavero del SO; la contraseña nunca se guarda en claro
/// (solo un hash salado, ver [LocalAuthRepository]).
class PrefsAuthStore implements AuthStore {
  PrefsAuthStore(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<String?> read(String key) async => _prefs.getString(key);

  @override
  Future<void> write(String key, String value) async {
    await _prefs.setString(key, value);
  }

  @override
  Future<void> delete(String key) async {
    await _prefs.remove(key);
  }
}

AuthStore makeAuthStore(SharedPreferences prefs) => PrefsAuthStore(prefs);
