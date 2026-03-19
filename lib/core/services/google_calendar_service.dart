import 'package:la_facu/core/services/google_calendar_api.dart';
import 'package:la_facu/features/subjects/data/subject_repository.dart';
import 'package:la_facu/features/tasks/data/task_repository.dart';
import 'package:la_facu/features/schedule/data/schedule_repository.dart';
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
      final events = await _api!.events.list(
        'primary',
        timeMin: minDate?.toUtc(),
        timeMax: maxDate?.toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
      );
      return events.items ?? [];
    } catch (e) {
      print('Error al obtener eventos de Google: $e');
      return [];
    }
  }

  /// Crear un evento en Google Calendar basado en un objeto local
  Future<void> syncEventToGoogle(ClassEventModel localEvent) async {
    if (_api == null) return;

    // TODO: Implementar lógica para mapear ClassEventModel a calendar.Event
    // Esto requiere manejar fechas reales basándose en el dayIndex y la semana actual
  }

  /// Crear una tarea en Google Calendar (como evento)
  Future<void> syncTaskToGoogle(TaskModel localTask) async {
    if (_api == null) return;

    final event = calendar.Event()
      ..summary = 'EstudioForge: ${localTask.title}'
      ..description = 'Materia: ${localTask.subjectName}'
      ..start = calendar.EventDateTime(
        dateTime: localTask.dueDate.toUtc(),
        timeZone: 'UTC',
      )
      ..end = calendar.EventDateTime(
        dateTime: localTask.dueDate.add(const Duration(hours: 1)).toUtc(),
        timeZone: 'UTC',
      );

    try {
      await _api!.events.insert(event, 'primary');
    } catch (e) {
      print('Error al insertar tarea en Google: $e');
    }
  }
}

final googleCalendarServiceProvider = Provider<GoogleCalendarService>((ref) {
  final api = ref.watch(calendarApiProvider).value;
  return GoogleCalendarService(api);
});
