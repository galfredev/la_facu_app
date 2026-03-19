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
}

enum TaskTypeModel { exam, assignment, quiz, reading }
