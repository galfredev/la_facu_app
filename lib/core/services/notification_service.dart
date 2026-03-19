import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Inicializar zona horaria
    tz.initializeTimeZones();
    final dynamic tzRes = await FlutterTimezone.getLocalTimezone();
    String timeZoneName = tzRes is String ? tzRes : tzRes.toString();
    if (timeZoneName.contains('(')) {
      // Maneja formatos como "TimezoneInfo(America/Buenos_Aires, null)"
      timeZoneName = timeZoneName.split('(').last.split(',').first.replaceAll(')', '').trim();
    }
    
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    // Configuración para iOS
    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Configuración general
    const InitializationSettings initializationSettings = InitializationSettings(
      iOS: initializationSettingsDarwin,
      android: AndroidInitializationSettings('@mipmap/ic_launcher'), // Placeholder para Android
    );

    await _notificationsPlugin.initialize(initializationSettings);
  }

  /// Programar una notificación para una tarea
  Future<void> scheduleTaskReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    // Si la fecha ya pasó, no programar
    if (scheduledDate.isBefore(DateTime.now())) return;

    await _notificationsPlugin.zonedSchedule(
      id,
      'Próxima Tarea: $title',
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Opcional
    );
  }

  /// Programar una notificación semanal para una clase
  Future<void> scheduleWeeklyReminder({
    required int id,
    required String title,
    required String body,
    required int dayIndex, // 0 (Lun) - 6 (Dom)
    required int hour,
    required int minute,
  }) async {
    // Calcular el próximo día de la semana que corresponde
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    ).subtract(const Duration(minutes: 15)); // Avisar 15 mins antes

    // Ajustar al día correcto de la semana (dayIndex indexado en 0 para Lunes)
    // weekday en ISO es 1 (Lun) - 7 (Dom)
    final targetWeekday = dayIndex + 1;
    while (scheduledDate.weekday != targetWeekday || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      id,
      'Próxima Clase: $title',
      body,
      scheduledDate,
      const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  /// Cancelar una notificación
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}

final notificationServiceProvider = Provider((ref) => NotificationService());
