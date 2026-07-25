import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'db_codec.dart';
import 'in_memory_database.dart';

/// Persistencia local del snapshot de la base. En web usa `localStorage`, en
/// móvil el almacenamiento nativo (vía shared_preferences). Es una solución de
/// transición: en la iteración móvil se reemplaza por Drift/SQLite cifrado
/// como otra implementación de repositorio, sin tocar el dominio.
class Persistence {
  Persistence(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'pituapp.snapshot.v1';

  /// Carga el snapshot en [db]. Devuelve true si había datos válidos.
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

  void save(InMemoryDatabase db) {
    _prefs.setString(_key, jsonEncode(DbCodec.encode(db)));
  }

  /// Intenta persistir devolviendo si tuvo éxito. Útil para operaciones que
  /// pueden exceder la cuota del almacenamiento (p. ej. adjuntos grandes en
  /// `localStorage`): el llamador puede revertir el cambio si falla.
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
