import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationService {
  NotificationService._internal();

  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  Future<void>? _initialization;

  Future<void> init() async {
    if (_initialization != null) {
      return _initialization!;
    }

    _initialization = _initialize();
    return _initialization!;
  }

  Future<void> _initialize() async {
    // Inicializar zona horaria
    tz.initializeTimeZones();

    try {
      final dynamic tzRes = await FlutterTimezone.getLocalTimezone();
      String timeZoneName = tzRes is String ? tzRes : tzRes.toString();
      if (timeZoneName.contains('(')) {
        timeZoneName = timeZoneName.split('(').last.split(',').first.replaceAll(')', '').trim();
      }

      // Verificar que el timezone exista, si no usar UTC
      try {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      } catch (_) {
        // Si falla, intentar con Buenos Aires por defecto para Latinoamerica
        try {
          tz.setLocalLocation(tz.getLocation('America/Argentina/Buenos_Aires'));
        } catch (_) {
          try {
            tz.setLocalLocation(tz.getLocation('America/New_York'));
          } catch (_) {
            tz.setLocalLocation(tz.UTC);
          }
        }
      }
    } catch (e) {
      // Si todo falla, usar UTC
      tz.setLocalLocation(tz.UTC);
    }

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
    await init();

    // Si la fecha ya pasó, no programar
    if (scheduledDate.isBefore(DateTime.now())) return;

    await _notificationsPlugin.zonedSchedule(
      id,
      'Próxima Tarea: $title',
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'la_facu_tasks',
          'Tareas de La Facu',
          channelDescription: 'Recordatorios de entregas y exámenes',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'La Facu',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
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
    await init();

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
        android: AndroidNotificationDetails(
          'la_facu_classes',
          'Clases de La Facu',
          channelDescription: 'Recordatorios de horarios de cursada',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'La Facu',
        ),
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
    await init();
    await _notificationsPlugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await init();
    await _notificationsPlugin.cancelAll();
  }
}

final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());
