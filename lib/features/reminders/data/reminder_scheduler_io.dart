import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

  @override
  bool get isSupported => true;

  @override
  void setOnSelect(void Function(String payload)? handler) =>
      _onSelect = handler;

  @override
  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
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
    return iosGranted ?? androidGranted ?? true;
  }

  @override
  Future<void> rescheduleAll(List<ReminderRequest> requests) async {
    await init();
    await _plugin.cancelAll();
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
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
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
