import 'package:shared_preferences/shared_preferences.dart';

import 'local_persistence.dart';
import 'persistence.dart';

/// Implementación para **web** (y entornos sin `dart:io`): snapshot JSON en
/// `localStorage`. El navegador no tiene llavero del SO ni SQLCipher, así que la
/// base cifrada (RNF-10) queda reservada a móvil/escritorio.
Future<LocalPersistence> makePersistence(
  SharedPreferences prefs, {
  void Function(Object error, StackTrace stack)? onError,
}) async =>
    SnapshotPersistence(prefs);
