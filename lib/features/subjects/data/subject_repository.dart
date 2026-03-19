import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:la_facu/data/local_db/isar_service.dart';
import 'package:la_facu/data/local_db/models/subject_model.dart';

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
    await isar.writeTxn(() async {
      await isar.subjectModels.delete(id);
    });
    ref.invalidateSelf();
  }
}
