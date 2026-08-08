import 'package:drift/drift.dart';

part 'app_database.g.dart';

/// Fila genérica clave-valor de la base local cifrada. Hay **una entrada por
/// entidad**, identificada por ([kind], [id]):
///
/// - [kind]  colección (`pets`, `careTypes`, `attachments`, …, y `__app_state__`
///   para los escalares).
/// - [id]    UUID de cliente de la entidad (`meta.id`); `0` para el estado global.
/// - [data]  JSON de la entidad, **mismo formato que el respaldo** (`DbCodec`),
///   de modo que no se reimplementa el mapeo de dominio.
/// - [bytes] binario de los adjuntos, guardado como BLOB **fuera** del JSON
///   (RF-29 avanza: el `dataBase64` no viaja en texto).
///
/// Un esquema por (kind, id) es deliberadamente simple para la Fase 1: mantiene
/// una sola tabla, reutiliza el códec ya probado y habilita como evolución
/// futura las **escrituras incrementales** por entidad (upsert/borrado por
/// clave) sin rehacer el dominio.
@DataClassName('EntityRow')
class Entities extends Table {
  TextColumn get kind => text()();
  TextColumn get id => text()();
  TextColumn get data => text()();
  BlobColumn get bytes => blob().nullable()();

  @override
  Set<Column> get primaryKey => {kind, id};
}

/// Base local sobre Drift/SQLite. El cifrado en reposo (SQLCipher, RNF-10) se
/// aplica al **abrir** el ejecutor (ver `app_database_open.dart`), no en el
/// esquema: aquí solo vive la estructura y las operaciones.
@DriftDatabase(tables: [Entities])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  /// Lee todas las filas (se hace una sola vez al arrancar para hidratar el
  /// modelo en memoria).
  Future<List<EntityRow>> readAll() => select(entities).get();

  /// Reemplazo transaccional completo (replace-all): borra todo e inserta el
  /// nuevo conjunto en una única transacción, de forma atómica.
  Future<void> replaceAll(List<EntitiesCompanion> rows) async {
    await transaction(() async {
      await delete(entities).go();
      await batch((b) => b.insertAll(entities, rows));
    });
  }
}
