import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:la_facu/core/services/google_calendar_service.dart';
import 'package:la_facu/core/services/notification_service.dart';
import 'package:la_facu/data/local_db/isar_service.dart';
import 'package:la_facu/data/local_db/models/class_event_model.dart';
import 'package:la_facu/data/local_db/models/subject_model.dart';
import 'package:la_facu/data/local_db/models/task_model.dart';

part 'subject_repository.g.dart';

@riverpod
class SubjectRepository extends _$SubjectRepository {
  @override
  Future<List<SubjectModel>> build() async {
    final isar = await ref.watch(isarServiceProvider.future);
    return isar.subjectModels.where().findAll();
  }

  Future<void> addSubject(SubjectModel subject) async {
    final isar = await ref.read(isarServiceProvider.future);
    await isar.writeTxn(() async {
      await isar.subjectModels.put(subject);
    });
    ref.invalidateSelf();
  }

  Future<void> deleteSubject(Id id) async {
    final isar = await ref.read(isarServiceProvider.future);
    final subject = await isar.subjectModels.get(id);
    if (subject == null) {
      return;
    }

    final tasks = await isar.taskModels
        .filter()
        .subjectNameEqualTo(subject.name)
        .findAll();
    final events = await isar.classEventModels
        .filter()
        .subjectNameEqualTo(subject.name)
        .findAll();

    await isar.writeTxn(() async {
      await isar.taskModels.deleteAll(tasks.map((task) => task.id).toList());
      await isar.classEventModels.deleteAll(events.map((event) => event.id).toList());
      await isar.subjectModels.delete(id);
    });

    for (final task in tasks) {
      await ref.read(notificationServiceProvider).cancelNotification(task.id);
      await ref.read(googleCalendarServiceProvider).deleteGoogleEvent(task.googleEventId);
    }

    for (final event in events) {
      await ref.read(notificationServiceProvider).cancelNotification(event.id + 10000);
      await ref.read(googleCalendarServiceProvider).deleteGoogleEvent(event.googleEventId);
    }

    ref.invalidateSelf();
  }
}
