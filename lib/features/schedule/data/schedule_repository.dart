import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:la_facu/data/local_db/isar_service.dart';
import 'package:la_facu/data/local_db/models/class_event_model.dart';

import 'package:la_facu/core/services/google_calendar_service.dart';

import 'package:la_facu/core/services/google_calendar_service.dart';
import 'package:la_facu/core/services/notification_service.dart';

part 'schedule_repository.g.dart';

@riverpod
class ScheduleRepository extends _$ScheduleRepository {
  @override
  Future<List<ClassEventModel>> build() async {
    final isar = await ref.watch(isarServiceProvider.future);
    return isar.classEventModels.where().findAll();
  }

  Future<void> addEvent(ClassEventModel event) async {
    final isar = await ref.read(isarServiceProvider.future);
    await isar.writeTxn(() async {
      await isar.classEventModels.put(event);
    });

    // Sincronizar con Google Calendar si está disponible
    try {
      await ref.read(googleCalendarServiceProvider).syncEventToGoogle(event);
    } catch (e) {
      print('Sincronización de horario fallida: $e');
    }

    // Programar recordatorio semanal
    try {
      final timeParts = event.startTime.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      await ref.read(notificationServiceProvider).scheduleWeeklyReminder(
        id: event.id + 10000, // Offset para evitar colisión con tareas
        title: event.subjectName,
        body: 'Tu clase de ${event.subjectName} arranca en 15 minutos.',
        dayIndex: event.dayIndex,
        hour: hour,
        minute: minute,
      );
    } catch (e) {
      print('Error al programar recordatorio semanal: $e');
    }

    ref.invalidateSelf();
  }

  Future<void> deleteEvent(Id id) async {
    // Cancelar notificación
    await ref.read(notificationServiceProvider).cancelNotification(id + 10000);

    final isar = await ref.read(isarServiceProvider.future);
    await isar.writeTxn(() async {
      await isar.classEventModels.delete(id);
    });
    ref.invalidateSelf();
  }
}
