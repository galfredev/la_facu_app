import 'package:flutter/foundation.dart';
import 'package:la_facu/core/services/google_calendar_api.dart';
import 'package:la_facu/data/local_db/models/task_model.dart';
import 'package:la_facu/data/local_db/models/class_event_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;

class GoogleCalendarService {
  final calendar.CalendarApi? _api;

  GoogleCalendarService(this._api);

  /// Obtener eventos de Google Calendar para un rango de fechas
  Future<List<calendar.Event>> getEvents({
    DateTime? minDate,
    DateTime? maxDate,
  }) async {
    if (_api == null) return [];

    try {
      final events = await _api.events.list(
        'primary',
        timeMin: minDate?.toUtc(),
        timeMax: maxDate?.toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
      );
      return events.items ?? [];
    } catch (e) {
      debugPrint('Error al obtener eventos de Google: $e');
      return [];
    }
  }

  /// Crear un evento en Google Calendar basado en un objeto local
  Future<String?> syncEventToGoogle(ClassEventModel localEvent) async {
    if (_api == null) return null;
    final targetWeekday = localEvent.dayIndex + 1;
    final event = _buildClassEvent(localEvent, targetWeekday);

    try {
      if (localEvent.googleEventId case final googleId?) {
        final updatedEvent = await _api.events.patch(event, 'primary', googleId);
        return updatedEvent.id ?? googleId;
      }

      final createdEvent = await _api.events.insert(event, 'primary');
      return createdEvent.id;
    } catch (e) {
      debugPrint('Error al sincronizar clase con Google: $e');
      return null;
    }
  }

  /// Crear una tarea en Google Calendar (como evento)
  Future<String?> syncTaskToGoogle(TaskModel localTask) async {
    if (_api == null) return null;
    final event = _buildTaskEvent(localTask);

    try {
      if (localTask.googleEventId case final googleId?) {
        final updatedEvent = await _api.events.patch(event, 'primary', googleId);
        return updatedEvent.id ?? googleId;
      }

      final createdEvent = await _api.events.insert(event, 'primary');
      return createdEvent.id;
    } catch (e) {
      debugPrint('Error al insertar tarea en Google: $e');
      return null;
    }
  }

  Future<void> deleteGoogleEvent(String? googleEventId) async {
    if (_api == null || googleEventId == null || googleEventId.isEmpty) return;

    try {
      await _api.events.delete('primary', googleEventId);
    } catch (e) {
      debugPrint('Error al borrar evento de Google: $e');
    }
  }

  calendar.Event _buildClassEvent(
    ClassEventModel localEvent,
    int targetWeekday,
  ) {
    // Calcular la fecha del próximo evento basado en el dayIndex.
    final now = DateTime.now();
    int daysDiff = targetWeekday - now.weekday;
    if (daysDiff < 0) {
      daysDiff += 7;
    }

    final eventDate = now.add(Duration(days: daysDiff));
    final startTimeParts = localEvent.startTime.split(':');
    final endTimeParts = localEvent.endTime.split(':');

    final startDateTime = DateTime(
      eventDate.year,
      eventDate.month,
      eventDate.day,
      int.parse(startTimeParts[0]),
      int.parse(startTimeParts[1]),
    );

    final endDateTime = DateTime(
      eventDate.year,
      eventDate.month,
      eventDate.day,
      int.parse(endTimeParts[0]),
      int.parse(endTimeParts[1]),
    );

    return calendar.Event()
      ..summary = 'La Facu: ${localEvent.subjectName}'
      ..location = 'Aula: ${localEvent.room}'
      ..description = 'Clase programada desde la app La Facu'
      ..start = calendar.EventDateTime(
        dateTime: startDateTime.toUtc(),
        timeZone: 'UTC',
      )
      ..end = calendar.EventDateTime(
        dateTime: endDateTime.toUtc(),
        timeZone: 'UTC',
      )
      ..recurrence = ['RRULE:FREQ=WEEKLY;BYDAY=${_getWeekDayCode(targetWeekday)}'];
  }

  calendar.Event _buildTaskEvent(TaskModel localTask) {
    return calendar.Event()
      ..summary = 'La Facu: ${localTask.title}'
      ..description = 'Materia: ${localTask.subjectName}'
      ..start = calendar.EventDateTime(
        dateTime: localTask.dueDate.toUtc(),
        timeZone: 'UTC',
      )
      ..end = calendar.EventDateTime(
        dateTime: localTask.dueDate.add(const Duration(hours: 1)).toUtc(),
        timeZone: 'UTC',
      );
  }

  String _getWeekDayCode(int weekday) {
    switch (weekday) {
      case DateTime.monday: return 'MO';
      case DateTime.tuesday: return 'TU';
      case DateTime.wednesday: return 'WE';
      case DateTime.thursday: return 'TH';
      case DateTime.friday: return 'FR';
      case DateTime.saturday: return 'SA';
      case DateTime.sunday: return 'SU';
      default: return 'MO';
    }
  }
}

final googleCalendarServiceProvider = Provider<GoogleCalendarService>((ref) {
  final api = ref.watch(calendarApiProvider).value;
  return GoogleCalendarService(api);
});
