import 'package:isar/isar.dart';

part 'task_model.g.dart';

@collection
class TaskModel {
  Id id = Isar.autoIncrement;

  late String title;
  late String subjectName;
  late DateTime dueDate;
  
  @enumerated
  late TaskTypeModel type;
  
  late bool isDone;
  late int colorValue;
  String? googleEventId; // ID del evento en Google Calendar
}

enum TaskTypeModel { exam, assignment, quiz, reading }
