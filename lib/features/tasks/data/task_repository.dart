import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:la_facu/data/local_db/isar_service.dart';
import 'package:la_facu/data/local_db/models/task_model.dart';

import 'package:la_facu/core/services/google_calendar_service.dart';
import 'package:la_facu/core/services/notification_service.dart';

part 'task_repository.g.dart';

@riverpod
class TaskRepository extends _$TaskRepository {
  @override
  Future<List<TaskModel>> build() async {
    final isar = await ref.watch(isarServiceProvider.future);
    return isar.taskModels.where().sortByDueDate().findAll();
  }

  Future<void> addTask(TaskModel task) async {
    final isar = await ref.read(isarServiceProvider.future);
    await isar.writeTxn(() async {
      await isar.taskModels.put(task);
    });
    
    // Sincronizar con Google Calendar si está disponible
    try {
      final googleId = await ref.read(googleCalendarServiceProvider).syncTaskToGoogle(task);
      if (googleId != null) {
        task.googleEventId = googleId;
        await isar.writeTxn(() async {
          await isar.taskModels.put(task);
        });
      }
    } catch (e) {
      debugPrint('Sincronización de tarea fallida: $e');
    }

    // Programar recordatorio local
    try {
      await ref.read(notificationServiceProvider).scheduleTaskReminder(
        id: task.id,
        title: task.title,
        body: 'Materia: ${task.subjectName}',
        scheduledDate: task.dueDate.subtract(const Duration(hours: 2)), // Avisar 2 horas antes
      );
    } catch (e) {
      debugPrint('Error al programar notificación: $e');
    }

    ref.invalidateSelf();
  }

  Future<void> toggleTaskDone(Id id) async {
    final isar = await ref.read(isarServiceProvider.future);
    await isar.writeTxn(() async {
      final task = await isar.taskModels.get(id);
      if (task != null) {
        task.isDone = !task.isDone;
        await isar.taskModels.put(task);
        
        // Si se marca como hecha, cancelar notificación
        if (task.isDone) {
          await ref.read(notificationServiceProvider).cancelNotification(id);
        }
      }
    });
    ref.invalidateSelf();
  }

  Future<void> deleteTask(Id id) async {
    final isar = await ref.read(isarServiceProvider.future);
    final task = await isar.taskModels.get(id);

    // Cancelar notificación primero
    await ref.read(notificationServiceProvider).cancelNotification(id);
    await ref.read(googleCalendarServiceProvider).deleteGoogleEvent(task?.googleEventId);

    await isar.writeTxn(() async {
      await isar.taskModels.delete(id);
    });
    ref.invalidateSelf();
  }
}
