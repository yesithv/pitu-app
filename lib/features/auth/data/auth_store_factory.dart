import 'package:shared_preferences/shared_preferences.dart';

import 'auth_store.dart';
// En web usa `shared_preferences`; en móvil/escritorio (dart:io) el llavero del
// SO vía `flutter_secure_storage`.
import 'auth_store_web.dart' if (dart.library.io) 'auth_store_io.dart';

/// Crea el [AuthStore] adecuado a la plataforma.
AuthStore createAuthStore(SharedPreferences prefs) => makeAuthStore(prefs);
