/// Contrato de reporte de errores/telemetría de fallos. La app depende solo de
/// esta interfaz; hoy la implementación por defecto es no-op y en el futuro se
/// enchufa un backend real (p. ej. Sentry/Crashlytics) reemplazando la fábrica,
/// sin tocar los call sites ni el resto del código.
abstract interface class CrashReporter {
  Future<void> init();

  /// Registra un error con su stack. [fatal] marca los que rompen la app.
  void recordError(Object error, StackTrace? stack, {bool fatal = false});

  /// Deja una migaja de contexto (breadcrumb) para el próximo error.
  void log(String message);
}

/// Implementación vacía: no envía nada. Valor por defecto seguro (y el único por
/// ahora, mientras no se integre un backend real).
class NoopCrashReporter implements CrashReporter {
  const NoopCrashReporter();

  @override
  Future<void> init() async {}

  @override
  void recordError(Object error, StackTrace? stack, {bool fatal = false}) {}

  @override
  void log(String message) {}
}

/// Fábrica del reporter. Hoy devuelve el no-op en todas las plataformas; cuando
/// se integre un backend real, aquí (o con imports condicionales por plataforma,
/// como recordatorios/compras) se devuelve la implementación concreta.
CrashReporter createCrashReporter() => const NoopCrashReporter();
