import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:la_facu/core/auth/google_auth_service.dart';
import 'package:la_facu/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:la_facu/features/subjects/data/subject_repository.dart';
import 'package:la_facu/features/tasks/data/task_repository.dart';
import 'package:la_facu/features/schedule/data/schedule_repository.dart';
import 'package:la_facu/core/services/google_calendar_service.dart';
import 'package:la_facu/features/subjects/presentation/widgets/add_subject_dialog.dart';
import 'package:la_facu/features/tasks/presentation/widgets/add_task_dialog.dart';
import 'package:la_facu/features/schedule/presentation/widgets/add_event_dialog.dart';
import 'package:la_facu/features/settings/data/user_repository.dart';
import 'package:intl/intl.dart';
import 'package:la_facu/data/local_db/models/task_model.dart';
import 'package:la_facu/data/local_db/models/user_model.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectRepositoryProvider);
    final tasksAsync = ref.watch(taskRepositoryProvider);
    final userAsync = ref.watch(userRepositoryProvider);
    final googleUser = ref.watch(googleAuthProvider);
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Buenos d\u00edas'
        : now.hour < 19
        ? 'Buenas tardes'
        : 'Buenas noches';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorPrimary = AppColors.primaryBlue;
    final colorSecondary = AppColors.accentSage;
    final userName = userAsync.value?.name?.split(' ').first ?? 'Estudiante';
    final colorTertiary = AppColors.accentAmber;
    final glowColor = AppColors.primaryBlueGlow;
    final googleCalendarService = ref.watch(googleCalendarServiceProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Decor (Mesh Gradient Style)
          Positioned(
            top: -150,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorPrimary.withValues(alpha: isDark ? 0.15 : 0.08),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // ----- HEADER PERSONALIZADO -----
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                    greeting.toUpperCase(),
                                    style: AppTheme.monoTextStyle.copyWith(
                                      fontSize: 10,
                                      letterSpacing: 3,
                                      color: colorPrimary,
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(duration: 400.ms)
                                  .slideY(begin: 0.2),
                              const SizedBox(height: 4),
                              Text(
                                    userName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .displaySmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -1,
                                        ),
                                  )
                                  .animate()
                                  .fadeIn(delay: 200.ms)
                                  .slideX(begin: -0.1),
                              const SizedBox(height: 10),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: googleUser != null
                                    ? Container(
                                        key: const ValueKey('google-active'),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryBlue
                                              .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          border: Border.all(
                                            color: AppColors.primaryBlue
                                                .withValues(alpha: 0.15),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.cloud_done_rounded,
                                              size: 14,
                                              color: AppColors.primaryBlue,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Google activo',
                                              style: AppTheme.monoTextStyle
                                                  .copyWith(
                                                    fontSize: 9,
                                                    color:
                                                        AppColors.primaryBlue,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : const SizedBox.shrink(
                                        key: ValueKey('google-inactive'),
                                      ),
                              ),
                            ],
                          ),
                        ),
                        _ProfileAvatar(
                          userAsync: userAsync,
                          googleUser: googleUser,
                          colorPrimary: colorPrimary,
                          glowColor: glowColor,
                          isDark: isDark,
                          userName: userName,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ----- HOY EN LA FACU (MAIN FOCUS) -----
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Hoy en la Facu',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorPrimary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                DateFormat(
                                  'EEEE d',
                                  'es_ES',
                                ).format(now).toUpperCase(),
                                style: AppTheme.monoTextStyle.copyWith(
                                  fontSize: 10,
                                  color: colorPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ref
                            .watch(scheduleRepositoryProvider)
                            .when(
                              data: (events) {
                                final todayEvents = events
                                    .where((e) => e.dayIndex == now.weekday - 1)
                                    .toList();
                                if (todayEvents.isEmpty) {
                                  return _EmptyHoyCard(
                                    colorPrimary: colorPrimary,
                                  );
                                }
                                return Column(
                                  children: todayEvents
                                      .map(
                                        (e) => _EventCard(
                                          title: e.subjectName,
                                          subtitle:
                                              '${e.startTime} - ${e.endTime} \u2022 ${e.room}',
                                          color: Color(e.colorValue),
                                          icon: Icons.school_rounded,
                                          onTap: () => context.go('/schedule'),
                                        ),
                                      )
                                      .toList(),
                                );
                              },
                              loading: () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              error: (_, _) =>
                                  const Text('Error al cargar clases'),
                            ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

                  const SizedBox(height: 24),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Movimientos Google',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        if (googleUser == null)
                          const _CalendarHintCard(
                            icon: Icons.cloud_off_rounded,
                            title: 'Google desconectado',
                            subtitle:
                                'Cuando conectes la cuenta, ver\u00e1s eventos relevantes ac\u00e1.',
                          )
                        else
                          FutureBuilder(
                            future: googleCalendarService.getEvents(
                              minDate: now.subtract(const Duration(days: 1)),
                              maxDate: now.add(const Duration(days: 7)),
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              final events = snapshot.data ?? [];
                              if (events.isEmpty) {
                                return const _CalendarHintCard(
                                  icon: Icons.event_busy_rounded,
                                  title: 'Sin eventos Google cercanos',
                                  subtitle:
                                      'La app se enfoca en la cursada y avisa solo lo importante.',
                                );
                              }

                              final visibleEvents = events.take(2).toList();
                              return Column(
                                children: [
                                  ...visibleEvents.map(
                                    (event) => _GoogleEventCard(
                                      title:
                                          event.summary ??
                                          'Evento sin t\u00edtulo',
                                      subtitle: event.start?.dateTime != null
                                          ? DateFormat(
                                              'EEE d MMM, HH:mm',
                                              'es_ES',
                                            ).format(
                                              event.start!.dateTime!.toLocal(),
                                            )
                                          : 'Evento de d\u00eda completo',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const _CalendarHintCard(
                                    icon: Icons.school_rounded,
                                    title: 'Enfoque acad\u00e9mico',
                                    subtitle:
                                        'Los eventos Google aparecen como contexto, pero la prioridad sigue siendo la facu.',
                                  ),
                                ],
                              );
                            },
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ----- ACCIONES RÃPIDAS (MODERN BAR) -----
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _ModernQuickBtn(
                          icon: Icons.add_task_rounded,
                          label: 'Tarea',
                          color: colorPrimary,
                          onTap: () => showDialog(
                            context: context,
                            builder: (_) => const AddTaskDialog(),
                          ),
                        ),
                        _ModernQuickBtn(
                          icon: Icons.calendar_today_rounded,
                          label: 'Horario',
                          color: colorSecondary,
                          onTap: () => showDialog(
                            context: context,
                            builder: (_) => const AddEventDialog(),
                          ),
                        ),
                        _ModernQuickBtn(
                          icon: Icons.book_rounded,
                          label: 'Materia',
                          color: colorTertiary,
                          onTap: () => showDialog(
                            context: context,
                            builder: (_) => const SubjectDialog(),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 600.ms),

                  const SizedBox(height: 40),

                  // ----- PROGRESO ACADÃ‰MICO -----
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tus Materias',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 16),
                        subjectsAsync.when(
                          data: (subjects) => SizedBox(
                            height: 130,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              clipBehavior: Clip.none,
                              itemCount: subjects.length,
                              itemBuilder: (context, index) {
                                final s = subjects[index];
                                return _SubjectProgressCard(
                                      subject: _SubjectOrb(
                                        name: s.name,
                                        initial: s.name[0],
                                        color: Color(s.colorValue),
                                        progress: s.progress,
                                      ),
                                    )
                                    .animate()
                                    .fadeIn(delay: (700 + index * 80).ms)
                                    .slideX(begin: 0.1);
                              },
                            ),
                          ),
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (_, _) => const Text('Error al cargar'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ----- PRÃ“XIMAS TAREAS -----
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pendientes Cr\u00edticos',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        tasksAsync.when(
                          data: (tasks) {
                            final upcoming = tasks
                                .where((t) => !t.isDone)
                                .take(3)
                                .toList();
                            if (upcoming.isEmpty) {
                              return const Center(
                                child: Text(
                                  'No hay tareas pendientes',
                                  style: TextStyle(fontSize: 12),
                                ),
                              );
                            }
                            return Column(
                              children: upcoming.asMap().entries.map((e) {
                                final t = e.value;
                                return _EventCard(
                                      title: t.title,
                                      subtitle:
                                          '${t.subjectName} \u2022 ${DateFormat("d MMM").format(t.dueDate)}',
                                      color: Color(t.colorValue),
                                      icon: _taskIcon(t.type),
                                      onTap: () => context.go('/tasks'),
                                    )
                                    .animate()
                                    .fadeIn(delay: (850 + e.key * 80).ms)
                                    .slideX(begin: 0.05);
                              }).toList(),
                            );
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (_, _) => const Text('Error'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Profile Avatar Widget ----
class _ProfileAvatar extends StatelessWidget {
  final AsyncValue<UserModel?> userAsync;
  final UserInfo? googleUser;
  final Color colorPrimary;
  final Color glowColor;
  final bool isDark;
  final String userName;

  const _ProfileAvatar({
    required this.userAsync,
    required this.googleUser,
    required this.colorPrimary,
    required this.glowColor,
    required this.isDark,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        userAsync.value?.photoPath != null &&
        File(userAsync.value!.photoPath!).existsSync();
    final googlePhoto = googleUser?.photoUrl;
    final hasGooglePhoto =
        !hasPhoto && googlePhoto != null && googlePhoto.isNotEmpty;

    return GestureDetector(
      onTap: () => context.go('/settings'),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorPrimary.withValues(alpha: 0.1),
          border: Border.all(
            color: colorPrimary.withValues(alpha: 0.2),
            width: 2,
          ),
          image: hasPhoto
              ? DecorationImage(
                  image: FileImage(File(userAsync.value!.photoPath!)),
                  fit: BoxFit.cover,
                )
              : hasGooglePhoto
              ? DecorationImage(
                  image: NetworkImage(googlePhoto),
                  fit: BoxFit.cover,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: glowColor.withValues(alpha: isDark ? 0.3 : 0.1),
              blurRadius: 12,
            ),
          ],
        ),
        child: !hasPhoto && !hasGooglePhoto
            ? Center(
                child: Text(
                  userName[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

// ---- Empty Today Widget ----
class _EmptyHoyCard extends StatelessWidget {
  final Color colorPrimary;
  const _EmptyHoyCard({required this.colorPrimary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: colorPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorPrimary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorPrimary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.wb_sunny_rounded, color: colorPrimary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\u00a1D\u00eda libre!',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'No tienes clases programadas para hoy.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Modern Quick Action Button ----
class _ModernQuickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ModernQuickBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? color.withValues(alpha: 0.9)
                    : color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Subject Progress Card ----
class _SubjectProgressCard extends StatelessWidget {
  final _SubjectOrb subject;

  const _SubjectProgressCard({required this.subject});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final glassBorder = isDark
        ? AppColors.glassBorder
        : AppColors.lightGlassBorder;

    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: glassBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  value: subject.progress,
                  strokeWidth: 6,
                  backgroundColor: subject.color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(subject.color),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '${(subject.progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            subject.name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ---- Models & Helper ----
class _SubjectOrb {
  final String name;
  final String initial;
  final Color color;
  final double progress;
  const _SubjectOrb({
    required this.name,
    required this.initial,
    required this.color,
    required this.progress,
  });
}

class _EventCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _EventCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final glassBorder = isDark
        ? AppColors.glassBorder
        : AppColors.lightGlassBorder;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: glassBorder),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleEventCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _GoogleEventCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.event_rounded,
            color: AppColors.primaryBlue,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarHintCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _CalendarHintCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGlassBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

IconData _taskIcon(TaskTypeModel t) {
  switch (t) {
    case TaskTypeModel.exam:
      return Icons.quiz_rounded;
    case TaskTypeModel.assignment:
      return Icons.assignment_rounded;
    case TaskTypeModel.quiz:
      return Icons.edit_note_rounded;
    case TaskTypeModel.reading:
      return Icons.menu_book_rounded;
  }
}
