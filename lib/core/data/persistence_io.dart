import 'package:shared_preferences/shared_preferences.dart';

import 'drift/app_database_open.dart';
import 'drift_persistence.dart';
import 'local_persistence.dart';
import 'secure_key_store.dart';

/// Implementación para **móvil/escritorio** (`dart:io`): base SQLite cifrada con
/// SQLCipher y clave en el llavero del SO (RNF-10). Migra un snapshot previo si
/// existe. Es asíncrona porque leer la clave y abrir la base lo son.
Future<LocalPersistence> makePersistence(
  SharedPreferences prefs, {
  void Function(Object error, StackTrace stack)? onError,
}) async {
  final hexKey = await SecureKeyStore().obtainHexKey();
  final db = openEncryptedDatabase(hexKey);
  return DriftPersistence.open(db, prefs: prefs, onError: onError);
}
