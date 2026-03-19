import 'package:isar/isar.dart';

part 'class_event_model.g.dart';

@collection
class ClassEventModel {
  Id id = Isar.autoIncrement;

  late String subjectName;
  late String startTime; // "08:00"
  late String endTime;   // "10:00"
  late String room;
  late int dayIndex;     // 0-6 (Lunes-Domingo)
  late int colorValue;
}
