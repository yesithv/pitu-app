import 'package:shared_preferences/shared_preferences.dart';

import 'attachment_file_store.dart';
import 'drift/app_database_open.dart';
import 'drift_persistence.dart';
import 'local_persistence.dart';
import 'secure_key_store.dart';

/// Implementación para **móvil/escritorio** (`dart:io`): base SQLite cifrada con
/// SQLCipher y clave en el llavero del SO (RNF-10), con los adjuntos en el
/// filesystem (RF-29). Migra un snapshot previo si existe. Es asíncrona porque
/// leer la clave, abrir la base y la carpeta de adjuntos lo son.
Future<LocalPersistence> makePersistence(
  SharedPreferences prefs, {
  void Function(Object error, StackTrace stack)? onError,
}) async {
  final hexKey = await SecureKeyStore().obtainHexKey();
  final db = openEncryptedDatabase(hexKey);
  final files = await AttachmentFileStore.open();
  return DriftPersistence.open(db, files, prefs: prefs, onError: onError);
}
