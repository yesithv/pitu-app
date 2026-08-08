import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Idiomas soportados por la app, con el inglés como valor por defecto cuando el
/// idioma del dispositivo no coincide con ninguno (autodetección + fallback).
///
/// El orden no implica prioridad: la resolución real la hace `MaterialApp`
/// (`localeResolutionCallback` en `app.dart`) a partir del idioma del sistema.
const List<Locale> kSupportedLocales = [
  Locale('en'),
  Locale('es'),
  Locale('fr'),
  Locale('pt'),
  Locale('de'),
];

/// Locale por defecto cuando el idioma del dispositivo no está soportado.
const Locale kDefaultLocale = Locale('en');

/// Clave de `SharedPreferences` donde se guarda el idioma elegido manualmente.
const String kLocalePrefKey = 'app_locale';

/// `SharedPreferences` compartido. Se **sobreescribe en `main`** con la instancia
/// ya cargada; el valor por defecto falla a propósito para detectar un arranque
/// mal compuesto.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
      'sharedPreferencesProvider debe sobreescribirse en main con la instancia real.');
});

/// Idioma activo de la app.
///
/// - `null` = **automático**: se sigue el idioma del dispositivo (la resolución
///   final, con fallback a inglés, la hace `MaterialApp`).
/// - Un [Locale] concreto = el usuario forzó ese idioma desde Ajustes.
///
/// La preferencia se persiste en `SharedPreferences` para que sobreviva a
/// reinicios de la app.
final localeControllerProvider =
    StateNotifierProvider<LocaleController, Locale?>((ref) {
  return LocaleController(ref.watch(sharedPreferencesProvider));
});

class LocaleController extends StateNotifier<Locale?> {
  LocaleController(this._prefs) : super(_readInitial(_prefs));

  final SharedPreferences _prefs;

  static Locale? _readInitial(SharedPreferences prefs) {
    final code = prefs.getString(kLocalePrefKey);
    if (code == null || code.isEmpty) return null; // automático
    final match = _matchSupported(code);
    return match; // si el guardado ya no es soportado, cae en null (automático)
  }

  /// Devuelve el [Locale] soportado que coincide por `languageCode`, o `null`.
  static Locale? _matchSupported(String languageCode) {
    for (final l in kSupportedLocales) {
      if (l.languageCode == languageCode) return l;
    }
    return null;
  }

  /// Cambia el idioma. `null` vuelve al modo automático (sigue al dispositivo).
  Future<void> setLocale(Locale? locale) async {
    state = locale;
    if (locale == null) {
      await _prefs.remove(kLocalePrefKey);
    } else {
      await _prefs.setString(kLocalePrefKey, locale.languageCode);
    }
  }
}

/// Locale efectivo fuera del árbol de widgets (p. ej. para notificaciones): usa
/// la preferencia guardada; si es automático, sigue el idioma del dispositivo;
/// si ninguno está soportado, cae en inglés.
Locale effectiveLocale(SharedPreferences prefs) {
  final saved = prefs.getString(kLocalePrefKey);
  if (saved != null && saved.isNotEmpty) {
    final match = LocaleController._matchSupported(saved);
    if (match != null) return match;
  }
  final device = PlatformDispatcher.instance.locale;
  final match = LocaleController._matchSupported(device.languageCode);
  return match ?? kDefaultLocale;
}
