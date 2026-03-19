import 'package:isar/isar.dart';

part 'user_model.g.dart';

@collection
class UserModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String? email;

  String? name;
  String? bio;
  String? university;
  String? career;
  String? photoPath;

  bool notificationsEnabled = true;

  UserModel({
    this.email,
    this.name,
    this.bio,
    this.university,
    this.career,
    this.photoPath,
    this.notificationsEnabled = true,
  });
}
