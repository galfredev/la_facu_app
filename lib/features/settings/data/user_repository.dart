import 'package:isar/isar.dart';
import 'package:la_facu/core/auth/google_auth_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:la_facu/data/local_db/models/user_model.dart';
import 'package:la_facu/data/local_db/isar_service.dart';

part 'user_repository.g.dart';

@riverpod
class UserRepository extends _$UserRepository {
  @override
  Future<UserModel?> build() async {
    final isar = await ref.watch(isarServiceProvider.future);
    final user = await isar.userModels.where().findFirst();
    if (user == null) {
      // Create a default user if none exists
      final newUser = UserModel(
        name: 'Nuevo Estudiante',
        email: 'estudiante@lafacu.app',
        bio: 'Hola. Estoy usando La Facu para enfocarme en mis estudios.',
        university: 'Mi Universidad',
        career: 'Mi Carrera',
        notificationsEnabled: true,
      );
      await isar.writeTxn(() => isar.userModels.put(newUser));
      return newUser;
    }
    return user;
  }

  Future<void> syncGoogleProfile(UserInfo account) async {
    final isar = await ref.read(isarServiceProvider.future);
    final user = await build();

    if (user == null) {
      return;
    }

    final currentBio = user.bio?.trim() ?? '';
    final shouldRefreshBio =
        currentBio.isEmpty ||
        currentBio ==
            'Hola. Estoy usando La Facu para enfocarme en mis estudios.';

    user
      ..name = account.displayName.isNotEmpty ? account.displayName : user.name
      ..email = account.email.isNotEmpty ? account.email : user.email
      ..bio = shouldRefreshBio
          ? 'Cuenta conectada con Google. Completa tu carrera, universidad y descripcion.'
          : user.bio;

    await isar.writeTxn(() => isar.userModels.put(user));
    ref.invalidateSelf();
  }

  Future<void> updateProfile({
    String? name,
    String? bio,
    String? university,
    String? career,
    String? photoPath,
  }) async {
    final isar = await ref.read(isarServiceProvider.future);
    final user = await build();

    if (user != null) {
      final updatedUser = user
        ..name = name ?? user.name
        ..bio = bio ?? user.bio
        ..university = university ?? user.university
        ..career = career ?? user.career
        ..photoPath = photoPath ?? user.photoPath;

      await isar.writeTxn(() => isar.userModels.put(updatedUser));
      ref.invalidateSelf();
    }
  }

  Future<void> toggleNotifications() async {
    final isar = await ref.read(isarServiceProvider.future);
    final user = await build();

    if (user != null) {
      user.notificationsEnabled = !user.notificationsEnabled;
      await isar.writeTxn(() => isar.userModels.put(user));
      ref.invalidateSelf();
    }
  }
}
