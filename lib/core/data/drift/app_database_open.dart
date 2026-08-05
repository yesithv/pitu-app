import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';

import 'app_database.dart';

/// Nombre del archivo de la base cifrada en el directorio de documentos de la app.
const String kDbFileName = 'pituapp.sqlite';

/// Abre una [AppDatabase] respaldada por un archivo SQLite **cifrado con
/// SQLCipher** (RNF-10). La [hexKey] es una clave de 32 bytes en hexadecimal
/// (64 caracteres) provista por el llavero del SO; se aplica como *raw key*
/// (`PRAGMA key = "x'...'"`) para evitar KDF y problemas de escapado.
///
/// La carga de la librería SQLCipher sustituye a la `sqlite3` del sistema; en
/// Android se aplica además el workaround conocido para versiones antiguas.
/// Este archivo es **solo nativo** (`dart:io`): en web se usa el snapshot.
AppDatabase openEncryptedDatabase(String hexKey) {
  return AppDatabase(_encryptedExecutor(hexKey));
}

LazyDatabase _encryptedExecutor(String hexKey) {
  return LazyDatabase(() async {
    // Usar la SQLCipher empaquetada en lugar de la sqlite del sistema.
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
      open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
    }
    if (Platform.isIOS || Platform.isMacOS) {
      // En iOS/macOS SQLCipher se enlaza estáticamente; se resuelve del proceso.
      open.overrideFor(
        Platform.isIOS ? OperatingSystem.iOS : OperatingSystem.macOS,
        DynamicLibrary.process,
      );
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, kDbFileName));

    // Se abre en el mismo isolate (no `createInBackground`) para que el override
    // de la librería SQLCipher aplique en el isolate que realmente abre el archivo.
    return NativeDatabase(
      file,
      setup: (rawDb) {
        // Clave cruda (32 bytes en hex); debe aplicarse antes de cualquier lectura.
        rawDb.execute('PRAGMA key = "x\'$hexKey\'";');
        // Verifica que efectivamente se abrió con SQLCipher (no la sqlite normal):
        // `cipher_version` está vacío si la librería no es SQLCipher.
        final version = rawDb.select('PRAGMA cipher_version;');
        if (version.isEmpty) {
          throw StateError(
            'SQLCipher no está activo: la base no quedaría cifrada en reposo.',
          );
        }
      },
    );
  });
}
