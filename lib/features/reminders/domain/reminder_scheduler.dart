/// Un recordatorio a programar en el sistema operativo.
class ReminderRequest {
  const ReminderRequest({
    required this.id,
    required this.title,
    required this.body,
    required this.when,
    this.payload,
  });

  /// Id numérico estable de la notificación (derivado del id de la programación).
  final int id;
  final String title;
  final String body;
  final DateTime when;

  /// Dato para el deep-link al tocar la notificación (RF-32): el id de la
  /// mascota a abrir.
  final String? payload;
}

/// Contrato para programar recordatorios locales (RF-30..RF-35). La app depende
/// solo de esta interfaz; en web es un no-op y en móvil usa
/// flutter_local_notifications, elegido en tiempo de compilación por plataforma.
abstract interface class ReminderScheduler {
  /// Indica si la plataforma soporta notificaciones locales (false en web).
  bool get isSupported;

  Future<void> init();

  /// Registra el manejador que se invoca al tocar una notificación (RF-32),
  /// con el `payload` (id de la mascota) como argumento.
  void setOnSelect(void Function(String payload)? handler);

  /// Solicita el permiso de notificaciones al usuario (iOS / Android 13+).
  Future<bool> requestPermission();

  /// Reprograma la ventana de próximos recordatorios (RF-34): cancela los
  /// anteriores y agenda los recibidos.
  Future<void> rescheduleAll(List<ReminderRequest> requests);

  Future<void> cancelAll();
}

/// Implementación vacía usada en web y como valor por defecto seguro.
class NoopReminderScheduler implements ReminderScheduler {
  const NoopReminderScheduler();

  @override
  bool get isSupported => false;

  @override
  Future<void> init() async {}

  @override
  void setOnSelect(void Function(String payload)? handler) {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> rescheduleAll(List<ReminderRequest> requests) async {}

  @override
  Future<void> cancelAll() async {}
}
