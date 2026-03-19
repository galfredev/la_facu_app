import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'models/subject_model.dart';
import 'models/task_model.dart';
import 'models/class_event_model.dart';
import 'models/user_model.dart';

part 'isar_service.g.dart';

@Riverpod(keepAlive: true)
class IsarService extends _$IsarService {
  late Isar _isar;

  @override
  Future<Isar> build() async {
    final String? path;
    if (kIsWeb) {
      path = null; // En Web, Isar maneja el almacenamiento automáticamente
    } else {
      final dir = await getApplicationDocumentsDirectory();
      path = dir.path;
    }

    _isar = await Isar.open(
      [SubjectModelSchema, TaskModelSchema, ClassEventModelSchema, UserModelSchema],
      directory: path ?? '',
    );

    // Seed data if empty
    final count = await _isar.subjectModels.count();
    if (count == 0) {
      await _seedInitialData();
    }

    return _isar;
  }

  Isar get isar => _isar;

  Future<void> clearAllData() async {
    await _isar.writeTxn(() async {
      await _isar.subjectModels.clear();
      await _isar.taskModels.clear();
      await _isar.classEventModels.clear();
    });
  }

  Future<void> _seedInitialData() async {
    await _isar.writeTxn(() async {
      // Materias
      final subjects = [
        SubjectModel()..name = 'Algoritmos'..code = 'AED'..professor = 'García'..credits = 6..colorValue = 0xFF4DAAFF..progress = 0.72,
        SubjectModel()..name = 'Cálculo II'..code = 'CALC2'..professor = 'Martínez'..credits = 5..colorValue = 0xFF9B6DFF..progress = 0.45,
        SubjectModel()..name = 'Redes'..code = 'REDES'..professor = 'López'..credits = 4..colorValue = 0xFF00E5FF..progress = 0.88,
        SubjectModel()..name = 'Bases de Datos'..code = 'BD1'..professor = 'Sánchez'..credits = 5..colorValue = 0xFFFF6B9D..progress = 0.30,
        SubjectModel()..name = 'Sistemas Operativos'..code = 'SO'..professor = 'Fernández'..credits = 6..colorValue = 0xFFFFB347..progress = 0.60,
      ];
      await _isar.subjectModels.putAll(subjects);

      // Tareas
      final now = DateTime.now();
      final tasks = [
        TaskModel()..title = 'TP1 - Árboles AVL'..subjectName = 'Algoritmos'..dueDate = now.add(const Duration(days: 3))..type = TaskTypeModel.assignment..isDone = false..colorValue = 0xFF4DAAFF,
        TaskModel()..title = 'Parcial integrador'..subjectName = 'Cálculo II'..dueDate = now.add(const Duration(days: 4))..type = TaskTypeModel.exam..isDone = false..colorValue = 0xFF9B6DFF,
        TaskModel()..title = 'Informe Lab. Redes'..subjectName = 'Redes'..dueDate = now.add(const Duration(days: 5))..type = TaskTypeModel.assignment..isDone = false..colorValue = 0xFF00E5FF,
      ];
      await _isar.taskModels.putAll(tasks);

      // Horarios (hoy para que se vea algo)
      final events = [
        ClassEventModel()..subjectName = 'Algoritmos'..startTime = '08:00'..endTime = '10:00'..room = '204'..dayIndex = now.weekday - 1..colorValue = 0xFF4DAAFF,
        ClassEventModel()..subjectName = 'Cálculo II'..startTime = '10:30'..endTime = '12:30'..room = 'Lab Mate'..dayIndex = now.weekday - 1..colorValue = 0xFF9B6DFF,
      ];
      await _isar.classEventModels.putAll(events);
    });
  }
}
