import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:la_facu/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:la_facu/core/auth/google_auth_service.dart';
import 'package:la_facu/core/services/google_calendar_service.dart';
import 'package:la_facu/core/services/notification_service.dart';
import 'package:la_facu/core/theme/theme_provider.dart';
import 'package:la_facu/data/local_db/isar_service.dart';
import 'package:la_facu/data/local_db/models/user_model.dart';
import 'package:la_facu/features/subjects/data/subject_repository.dart';
import 'package:la_facu/features/tasks/data/task_repository.dart';
import 'package:la_facu/features/schedule/data/schedule_repository.dart';
import '../data/user_repository.dart';
import 'widgets/edit_profile_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final googleUser = ref.watch(googleAuthProvider);
    final userAsync = ref.watch(userRepositoryProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                'Configuraci\u00f3n',
                style: Theme.of(context).textTheme.displayMedium,
              ).animate().fadeIn().slideX(begin: -0.05),
              const SizedBox(height: 24),

              // Perfil
              userAsync.when(
                data: (user) => _ProfileCard(
                  user: user,
                  googleUser: googleUser,
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05),
                loading: () => const _ProfileCardLoading(),
                error: (_, _) => const Text('Error al cargar perfil'),
              ),

              const SizedBox(height: 20),
              _GoogleConnectionCard(
                user: googleUser,
                onConnect: () async {
                  final account = await ref
                      .read(googleAuthProvider.notifier)
                      .login();
                  if (account != null && context.mounted) {
                    await ref
                        .read(userRepositoryProvider.notifier)
                        .syncGoogleProfile(account);
                    ref.invalidate(userRepositoryProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Conectado como ${account.email}'),
                      ),
                    );
                  }
                },
                onDisconnect: () async {
                  await ref.read(googleAuthProvider.notifier).logout();
                },
              ),

              const SizedBox(height: 24),
              _SettingsSection(
                title: 'Cuenta',
                items: [
                  _SettingsTile(
                    icon: Icons.account_circle_rounded,
                    label: 'Perfil',
                    subtitle: 'Editar datos personales',
                    color: AppColors.primaryBlue,
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => const EditProfileDialog(),
                    ),
                  ),
                  _SettingsTile(
                    icon: Icons.calendar_today_rounded,
                    label: 'Google Calendar',
                    subtitle: googleUser?.email ?? 'Conectar cuenta',
                    color: const Color(0xFF4285F4),
                    onTap: () async {
                      try {
                        final notifier = ref.read(googleAuthProvider.notifier);
                        if (googleUser == null) {
                          final account = await notifier.login();
                          if (account != null && context.mounted) {
                            await ref
                                .read(userRepositoryProvider.notifier)
                                .syncGoogleProfile(account);
                            ref.invalidate(userRepositoryProvider);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Conectado como ${account.email}',
                                ),
                              ),
                            );
                          }
                        } else {
                          await notifier.logout();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Sesi\u00f3n cerrada'),
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'No se pudo completar la conexi\u00f3n con Google: ',
                              ),
                              backgroundColor: Colors.orangeAccent,
                            ),
                          );
                        }
                      }
                    },
                    trailing: googleUser != null
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.greenAccent,
                            size: 20,
                          )
                        : null,
                  ),
                  _SettingsTile(
                    icon: Icons.notifications_rounded,
                    label: 'Notificaciones',
                    subtitle: 'Recordatorios en este dispositivo',
                    color: AppColors.accentSage,
                    trailing: userAsync.when(
                      data: (user) => Switch(
                        value: user?.notificationsEnabled ?? true,
                        activeThumbColor: AppColors.primaryBlue,
                        onChanged: (val) {
                          ref
                              .read(userRepositoryProvider.notifier)
                              .toggleNotifications();
                        },
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                    onTap: () => ref
                        .read(userRepositoryProvider.notifier)
                        .toggleNotifications(),
                  ),
                ],
              ).animate().fadeIn(delay: 150.ms),
              const SizedBox(height: 16),
              _SettingsSection(
                title: 'Apariencia',
                items: [
                  _SettingsTile(
                    icon: isDark
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    label: 'Tema',
                    subtitle: isDark
                        ? 'Modo oscuro (enfocado)'
                        : 'Modo claro (limpio)',
                    color: isDark
                        ? AppColors.accentSage
                        : AppColors.primaryBlue,
                    trailing: Switch(
                      value: !isDark,
                      activeThumbColor: AppColors.primaryBlue,
                      onChanged: (val) {
                        ref.read(themeModeProvider.notifier).toggleTheme();
                      },
                    ),
                    onTap: () {
                      ref.read(themeModeProvider.notifier).toggleTheme();
                    },
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 16),
              _SettingsSection(
                title: 'Datos',
                items: [
                  _SettingsTile(
                    icon: Icons.delete_sweep_rounded,
                    label: 'Borrar datos',
                    subtitle: 'Limpiar todo Isar',
                    color: Colors.redAccent,
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('\u00bfBorrar todos los datos?'),
                          content: const Text(
                            'Esta acci\u00f3n eliminar\u00e1 todas las materias, tareas y horarios localmente. No se puede deshacer.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text(
                                'Borrar Todo',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        final tasks = await ref.read(
                          taskRepositoryProvider.future,
                        );
                        final events = await ref.read(
                          scheduleRepositoryProvider.future,
                        );

                        for (final task in tasks) {
                          await ref
                              .read(googleCalendarServiceProvider)
                              .deleteGoogleEvent(task.googleEventId);
                        }

                        for (final event in events) {
                          await ref
                              .read(googleCalendarServiceProvider)
                              .deleteGoogleEvent(event.googleEventId);
                        }

                        await ref.read(notificationServiceProvider).cancelAll();
                        await ref
                            .read(isarServiceProvider.notifier)
                            .clearAllData();
                        ref.invalidate(subjectRepositoryProvider);
                        ref.invalidate(taskRepositoryProvider);
                        ref.invalidate(scheduleRepositoryProvider);
                        ref.invalidate(userRepositoryProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Todos los datos han sido borrados',
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ).animate().fadeIn(delay: 250.ms),
              const SizedBox(height: 16),
              _SettingsSection(
                title: 'Acerca de',
                items: [
                  _SettingsTile(
                    icon: Icons.info_rounded,
                    label: 'La Facu',
                    subtitle: 'v1.0.0 • GalfreDev',
                    color: AppColors.textMuted,
                  ),
                ],
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleConnectionCard extends StatelessWidget {
  final UserInfo? user;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  const _GoogleConnectionCard({
    required this.user,
    required this.onConnect,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final connected = user != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: connected
              ? AppColors.primaryBlue.withValues(alpha: 0.28)
              : AppColors.lightGlassBorder,
        ),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: connected
                    ? [AppColors.primaryBlue, AppColors.accentSage]
                    : [
                        AppColors.textMuted.withValues(alpha: 0.25),
                        AppColors.textMuted.withValues(alpha: 0.1),
                      ],
              ),
            ),
            child: Icon(
              connected
                  ? Icons.verified_user_rounded
                  : Icons.cloud_sync_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  connected ? 'Google conectado' : 'Conectar Google',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  connected
                      ? 'Perfil activo y listo para sincronizar calendario.'
                      : 'Activa tu cuenta para ver perfil y sincronización.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
                if (connected) ...[
                  const SizedBox(height: 6),
                  Text(
                    user?.email ?? '',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          connected
              ? TextButton(onPressed: onDisconnect, child: const Text('Cerrar'))
              : FilledButton(
                  onPressed: onConnect,
                  child: const Text('Conectar'),
                ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05);
  }
}

class _ProfileCard extends StatelessWidget {
  final UserModel? user;
  final UserInfo? googleUser;

  const _ProfileCard({required this.user, required this.googleUser});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final photoPath = user?.photoPath;
    final hasPhoto = photoPath != null && File(photoPath).existsSync();
    final googlePhoto = googleUser?.photoUrl;
    final hasGooglePhoto =
        !hasPhoto && googlePhoto != null && googlePhoto.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue.withValues(alpha: isDark ? 0.15 : 0.08),
            AppColors.accentSage.withValues(alpha: isDark ? 0.08 : 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppColors.glassBorderBright
              : AppColors.lightGlassBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              image: hasPhoto
                  ? DecorationImage(
                      image: FileImage(File(photoPath)),
                      fit: BoxFit.cover,
                    )
                  : hasGooglePhoto
                  ? DecorationImage(
                      image: NetworkImage(googlePhoto),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: !hasPhoto && !hasGooglePhoto
                ? const Center(
                    child: Icon(
                      Icons.person_rounded,
                      color: AppColors.primaryBlue,
                      size: 32,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  googleUser?.displayName ?? user?.name ?? 'Usuario',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  user?.career ?? 'Configura tu carrera',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                Text(
                  user?.university ?? 'Mi Universidad',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const EditProfileDialog(),
            ),
            icon: const Icon(
              Icons.edit_rounded,
              color: AppColors.primaryBlue,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCardLoading extends StatelessWidget {
  const _ProfileCardLoading();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<_SettingsTile> items;
  const _SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final glassBorder = isDark
        ? AppColors.glassBorder
        : AppColors.lightGlassBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(letterSpacing: 1.2),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: glassBorder),
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final isLast = e.key == items.length - 1;
              return Column(
                children: [
                  e.value,
                  if (!isLast)
                    Divider(
                      height: 1,
                      color: glassBorder,
                      indent: 16,
                      endIndent: 16,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.textMuted : AppColors.lightTextMuted;

    return InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontSize: 14),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      color: mutedColor,
                    ),
                  ),
                ],
              ),
            ),
            trailing ??
                Icon(Icons.chevron_right_rounded, color: mutedColor, size: 18),
          ],
        ),
      ),
    );
  }
}
