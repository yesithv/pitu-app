import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/reminder_scheduler.dart';

ReminderScheduler makeReminderScheduler() => LocalReminderScheduler();

/// Recordatorios locales reales para móvil (RF-30..RF-35). Programa por ventanas
/// respetando el límite de iOS (64) y reprograma ante cambios.
///
/// Nota: esta implementación solo se compila en móvil (dart:io) y requiere
/// validación en dispositivo/emulador; el build web usa el stub no-op.
class LocalReminderScheduler implements ReminderScheduler {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;
  void Function(String payload)? _onSelect;

  /// Nombre IANA de la zona horaria fijada como local (RF-33). Se usa para
  /// detectar cambios de zona y reprogramar.
  String? _tzName;

  /// Si el SO permite alarmas exactas (RF-35). Se resuelve al pedir permisos;
  /// mientras tanto se degrada a inexacto para no fallar.
  bool _exactAllowed = false;

  @override
  bool get isSupported => true;

  @override
  void setOnSelect(void Function(String payload)? handler) =>
      _onSelect = handler;

  @override
  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    // Fija la zona horaria del dispositivo como local (RF-33). Sin esto,
    // `tz.local` es UTC y las notificaciones se agendan a la hora equivocada.
    await _applyDeviceTimeZone();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) _onSelect?.call(payload);
      },
    );
    _ready = true;
  }

  /// Lee la zona horaria del dispositivo y la aplica como local. Devuelve `true`
  /// si cambió respecto a la anterior. Ante cualquier error deja UTC (fallback).
  Future<bool> _applyDeviceTimeZone() async {
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      if (name == _tzName) return false;
      tz.setLocalLocation(tz.getLocation(name));
      _tzName = name;
      return true;
    } catch (_) {
      // Zona desconocida o plugin no disponible: se conserva la anterior/UTC.
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    await init();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final iosGranted = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final androidGranted = await android?.requestNotificationsPermission();
    // Alarmas exactas (RF-35): pide el permiso y consulta si quedó habilitado.
    if (android != null) {
      await android.requestExactAlarmsPermission();
      _exactAllowed = await android.canScheduleExactNotifications() ?? false;
    }
    return iosGranted ?? androidGranted ?? true;
  }

  @override
  Future<bool> refreshTimeZone() async {
    await init();
    return _applyDeviceTimeZone();
  }

  @override
  Future<void> rescheduleAll(List<ReminderRequest> requests) async {
    await init();
    await _plugin.cancelAll();
    // Con permiso de alarmas exactas (RF-35), agenda exacto; si no, inexacto
    // (degradación segura para no romper en Android 12+ sin el permiso).
    final scheduleMode = _exactAllowed
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    for (final r in requests) {
      final when = tz.TZDateTime.from(r.when, tz.local);
      // No programar fechas pasadas.
      if (when.isBefore(tz.TZDateTime.now(tz.local))) continue;
      await _plugin.zonedSchedule(
        r.id,
        r.title,
        r.body,
        when,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'pitu_reminders',
            'Recordatorios de cuidados',
            channelDescription: 'Avisos de los cuidados de tus mascotas',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: r.payload,
      );
    }
  }

  @override
  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }
}
