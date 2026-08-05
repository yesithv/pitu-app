import 'package:shared_preferences/shared_preferences.dart';

import 'local_persistence.dart';
// En web usa el stub (snapshot en localStorage); en móvil/escritorio (dart:io)
// la implementación real con SQLite cifrado (Drift + SQLCipher).
import 'persistence_stub.dart'
    if (dart.library.io) 'persistence_io.dart';

/// Crea la [LocalPersistence] adecuada a la plataforma. En móvil/escritorio abre
/// la base cifrada (asíncrono: obtiene la clave del llavero y lee el estado); en
/// web devuelve el snapshot. [onError] recibe fallos de escritura diferida.
Future<LocalPersistence> createPersistence(
  SharedPreferences prefs, {
  void Function(Object error, StackTrace stack)? onError,
}) =>
    makePersistence(prefs, onError: onError);
