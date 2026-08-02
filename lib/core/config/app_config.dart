import 'package:flutter/foundation.dart' show kDebugMode;

/// Modo demostración. Cuando es `true`, el primer arranque siembra los datos de
/// ejemplo **en plan Pro** y Ajustes muestra el conmutador para alternar
/// Free/Pro; sirve para exhibir todas las funciones (demo web) y para el
/// desarrollo local.
///
/// - En **debug** (dev local con `flutter run`) es `true` por defecto.
/// - En **release de producción** (build de tienda) es `false`: el usuario
///   arranca en Free y desbloquea Pro comprando o restaurando.
/// - La **demo web** (GitHub Pages) es un build release, así que la CI lo fuerza
///   con `--dart-define=PITU_DEMO=true` para conservar el Pro de exhibición.
const bool kDemoMode = bool.fromEnvironment('PITU_DEMO', defaultValue: kDebugMode);
