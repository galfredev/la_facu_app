import 'package:isar/isar.dart';

part 'subject_model.g.dart';

@collection
class SubjectModel {
  Id id = Isar.autoIncrement;

  late String name;
  late String code;
  late String professor;
  late int credits;
  late int colorValue; // Guardamos el ARGB como int
  late double progress;

  // Relaciones o campos extra si fueran necesarios
}
