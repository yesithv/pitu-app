import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'db_codec.dart';
import 'in_memory_database.dart';
import 'local_persistence.dart';

/// Clave del snapshot JSON en `shared_preferences` / `localStorage`.
///
/// Se expone para que la implementación móvil ([drift_persistence.dart]) pueda
/// **migrar** un snapshot preexistente a la BD cifrada la primera vez.
const String kSnapshotKey = 'pituapp.snapshot.v1';

/// Persistencia local basada en un **snapshot JSON completo**. En web usa
/// `localStorage`; es también la implementación de reserva en entornos sin
/// almacenamiento nativo.
///
/// En móvil se sustituye por `DriftPersistence` (SQLite cifrado) vía
/// `createPersistence`; esta clase se conserva para la web, donde no hay llavero
/// del SO ni SQLCipher.
class SnapshotPersistence implements LocalPersistence {
  SnapshotPersistence(this._prefs);

  final SharedPreferences _prefs;
  static const _key = kSnapshotKey;

  @override
  bool loadInto(InMemoryDatabase db) {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return false;
    try {
      final map = (jsonDecode(raw) as Map).cast<String, dynamic>();
      DbCodec.decodeInto(db, map);
      return db.pets.isNotEmpty;
    } catch (_) {
      // Snapshot corrupto o de versión incompatible: se ignora y se re-siembra.
      return false;
    }
  }

  @override
  void save(InMemoryDatabase db) {
    _prefs.setString(_key, jsonEncode(DbCodec.encode(db)));
  }

  /// Intenta persistir devolviendo si tuvo éxito. Útil para operaciones que
  /// pueden exceder la cuota del almacenamiento (p. ej. adjuntos grandes en
  /// `localStorage`): el llamador puede revertir el cambio si falla.
  @override
  bool trySave(InMemoryDatabase db) {
    try {
      save(db);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Persiste automáticamente ante cada cambio, agrupando ráfagas por microtask
  /// para no serializar más de una vez por frame lógico.
  @override
  void attachAutosave(InMemoryDatabase db) {
    var scheduled = false;
    db.addListener(() {
      if (scheduled) return;
      scheduled = true;
      Future.microtask(() {
        scheduled = false;
        save(db);
      });
    });
  }
}
