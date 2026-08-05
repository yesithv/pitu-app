import 'in_memory_database.dart';

/// Contrato de la persistencia local en reposo. Desacopla el dominio del backend
/// concreto para poder elegir por plataforma (patrón repositorio, ERS §8.3):
///
/// - **Web**: [SnapshotPersistence] (snapshot JSON en `shared_preferences` /
///   `localStorage`); el navegador no tiene llavero ni SQLCipher.
/// - **Móvil / escritorio**: `DriftPersistence` (SQLite cifrado con SQLCipher y
///   clave en el llavero del SO), que cumple **RNF-10** (cifrado en reposo).
///
/// La instancia concreta se obtiene con `createPersistence(prefs)`
/// (`persistence_factory.dart`), que resuelve la plataforma vía conditional
/// imports, igual que el resto de factories del proyecto.
///
/// La API es **síncrona a propósito** para no propagar `async` por el dominio ni
/// la UI: las implementaciones que usan un backend asíncrono (Drift) precargan
/// los datos al arrancar y difieren las escrituras en segundo plano.
abstract class LocalPersistence {
  /// Carga el estado persistido en [db]. Devuelve `true` si había datos válidos
  /// (con al menos una mascota); `false` si no hay nada guardado o está corrupto,
  /// para que el llamador siembre los datos de ejemplo.
  bool loadInto(InMemoryDatabase db);

  /// Persiste el estado actual de [db] en reposo.
  void save(InMemoryDatabase db);

  /// Intenta persistir devolviendo si el guardado se aceptó. En web sirve para
  /// revertir cambios que exceden la cuota de `localStorage`; en backends sin esa
  /// limitación (SQLite) devuelve `true` de forma optimista y difiere la escritura.
  bool trySave(InMemoryDatabase db);

  /// Persiste automáticamente ante cada mutación de [db], agrupando ráfagas.
  void attachAutosave(InMemoryDatabase db);
}
