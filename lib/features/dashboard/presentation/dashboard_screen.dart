import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:la_facu/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:la_facu/features/subjects/data/subject_repository.dart';
import 'package:la_facu/features/tasks/data/task_repository.dart';
import 'package:la_facu/features/schedule/data/schedule_repository.dart';
import 'package:la_facu/features/subjects/presentation/widgets/add_subject_dialog.dart';
import 'package:la_facu/features/tasks/presentation/widgets/add_task_dialog.dart';
import 'package:la_facu/features/schedule/presentation/widgets/add_event_dialog.dart';
import 'package:la_facu/features/settings/data/user_repository.dart';
import 'package:intl/intl.dart';
import 'package:la_facu/data/local_db/models/task_model.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectRepositoryProvider);
    final tasksAsync = ref.watch(taskRepositoryProvider);
    final userAsync = ref.watch(userRepositoryProvider);
    final now = DateTime.now();
    final greeting = now.hour < 12 ? 'Buenos días' : now.hour < 19 ? 'Buenas tardes' : 'Buenas noches';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorPrimary = AppColors.primaryBlue;
    final colorSecondary = AppColors.accentSage;
    final titleColor1 = AppColors.primaryBlue;
    final titleColor2 = AppColors.accentSage;
    final userName = userAsync.value?.name?.split(' ').first ?? 'Estudiante';
    final colorTertiary = AppColors.accentAmber;
    final glowColor = AppColors.primaryBlueGlow;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$greeting, $userName',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark ? null : AppColors.lightTextPrimary.withValues(alpha: 0.8),
                            fontWeight: isDark ? null : FontWeight.w600,
                          ),
                        ).animate().fadeIn(duration: 400.ms),
                        Text(
                          'La Facu',
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            foreground: Paint()
                              ..shader = LinearGradient(
                                colors: [titleColor1, titleColor2],
                              ).createShader(const Rect.fromLTWH(0, 0, 200, 40)),
                          ),
                        ).animate().fadeIn(delay: 100.ms, duration: 500.ms).slideX(begin: -0.1),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => context.go('/settings'),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorPrimary.withValues(alpha: 0.1),
                          image: userAsync.value?.photoPath != null 
                              ? DecorationImage(image: FileImage(File(userAsync.value!.photoPath!)), fit: BoxFit.cover)
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: glowColor.withValues(alpha: isDark ? 0.3 : 0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: userAsync.value?.photoPath == null 
                            ? Center(
                                child: Text(userName[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                              )
                            : null,
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                  ],
                ),

                const SizedBox(height: 32),

                // Stats row
                Row(
                  children: [
                    _StatCard(
                      label: 'Materias', 
                      value: subjectsAsync.value?.length.toString() ?? '0', 
                      color: colorPrimary,
                      onTap: () => context.go('/subjects'),
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Tareas', 
                      value: tasksAsync.value?.where((t) => !t.isDone).length.toString() ?? '0', 
                      color: colorSecondary,
                      onTap: () => context.go('/tasks'),
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Esta semana', 
                      value: '12h', 
                      color: colorTertiary,
                      onTap: () => context.go('/schedule'),
                    ),
                  ],
                ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.1),

                const SizedBox(height: 28),

                // Progreso Académico
                Text(
                  'Progreso Académico',
                  style: Theme.of(context).textTheme.titleLarge,
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 4),
                Text(
                  'Avance de materias',
                  style: Theme.of(context).textTheme.bodyMedium,
                ).animate().fadeIn(delay: 350.ms),

                const SizedBox(height: 16),

                // Cards de Materias
                subjectsAsync.when(
                  data: (subjects) => SizedBox(
                    height: 140,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      clipBehavior: Clip.none,
                      itemCount: subjects.length,
                      itemBuilder: (context, index) {
                        final s = subjects[index];
                        return GestureDetector(
                          onTap: () => context.go('/subjects'),
                          child: _SubjectProgressCard(
                            subject: _SubjectOrb(
                              name: s.name,
                              initial: s.name[0],
                              color: Color(s.colorValue),
                              progress: s.progress,
                            ),
                          ),
                        ).animate().fadeIn(delay: (400 + index * 80).ms).slideX(begin: 0.1);
                      },
                    ),
                  ),
                  loading: () => const SizedBox(height: 140, child: Center(child: CircularProgressIndicator())),
                  error: (_, __) => const SizedBox(height: 140, child: Center(child: Text('Error al cargar materias'))),
                ),

                const SizedBox(height: 28),

                // Quick Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _QuickActionBtn(
                      icon: Icons.add_task_rounded, 
                      label: 'Nueva Tarea', 
                      color: colorPrimary,
                      onTap: () => showDialog(context: context, builder: (_) => const AddTaskDialog()),
                    ),
                    _QuickActionBtn(
                      icon: Icons.add_card_rounded, 
                      label: 'Nuevo Horario', 
                      color: colorSecondary,
                      onTap: () => showDialog(context: context, builder: (_) => const AddEventDialog()),
                    ),
                    _QuickActionBtn(
                      icon: Icons.library_add_rounded, 
                      label: 'Nueva Materia', 
                      color: colorTertiary,
                      onTap: () => showDialog(context: context, builder: (_) => const SubjectDialog()),
                    ),
                  ],
                ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1),

                const SizedBox(height: 28),

                // Hoy en la Facu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hoy en la facu',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      DateFormat('EEEE d', 'es_ES').format(now),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12, color: colorPrimary),
                    ),
                  ],
                ).animate().fadeIn(delay: 460.ms),
                const SizedBox(height: 12),
                ref.watch(scheduleRepositoryProvider).when(
                  data: (events) {
                    final todayEvents = events.where((e) => e.dayIndex == now.weekday - 1).toList();
                    if (todayEvents.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorPrimary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colorPrimary.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.wb_sunny_rounded, color: colorPrimary),
                            const SizedBox(width: 12),
                            Text('¡Día libre de cursada!', style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      );
                    }
                    return Column(
                      children: todayEvents.map((e) => _EventCard(
                        title: e.subjectName,
                        subtitle: '${e.startTime} - ${e.endTime} • ${e.room}',
                        color: Color(e.colorValue),
                        icon: Icons.school_rounded,
                        onTap: () => context.go('/schedule'),
                      )).toList(),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Text('Error al cargar clases'),
                ).animate().fadeIn(delay: 480.ms),

                const SizedBox(height: 32),

                // Próximas tareas
                const SizedBox(height: 12),
                tasksAsync.when(
                  data: (tasks) {
                    final upcoming = tasks.where((t) => !t.isDone).take(3).toList();
                    if (upcoming.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: Text('No hay tareas pendientes', style: Theme.of(context).textTheme.bodyMedium)),
                      );
                    }
                    return Column(
                      children: upcoming.asMap().entries.map((e) {
                         final t = e.value;
                         return _EventCard(
                           title: t.title,
                           subtitle: '${t.subjectName} • ${DateFormat("d MMM").format(t.dueDate)}',
                           color: Color(t.colorValue),
                           icon: _taskIcon(t.type),
                           onTap: () => context.go('/tasks'),
                         ).animate().fadeIn(delay: (550 + e.key * 80).ms, duration: 400.ms).slideX(begin: 0.05);
                      }).toList(),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Text('Error al cargar eventos'),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
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
    final glassBorder = isDark ? AppColors.glassBorder : AppColors.lightGlassBorder;

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
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            subject.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 13),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ---- Models ----
class _SubjectOrb {
  final String name;
  final String initial;
  final Color color;
  final double progress;
  const _SubjectOrb({required this.name, required this.initial, required this.color, required this.progress});
}

// ---- Widgets ----
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;
  const _StatCard({required this.label, required this.value, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final borderColor = color.withValues(alpha: isDark ? 0.25 : 0.15);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isDark ? 0.07 : 0.04), 
                blurRadius: 10
              )
            ],
          ),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11)),
          ],
        ),
      ),
    ),
  );
}
}

class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  
  const _QuickActionBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _EventCard({required this.title, required this.subtitle, required this.color, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final glassBorder = isDark ? AppColors.glassBorder : AppColors.lightGlassBorder;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: glassBorder, width: 1),
        ),
        child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14)),
              const SizedBox(height: 2),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
            ],
          ),
          const Spacer(),
          Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 18),
        ],
      ),
    ),
  );
}
}
IconData _taskIcon(TaskTypeModel t) {
  switch (t) {
    case TaskTypeModel.exam: return Icons.quiz_rounded;
    case TaskTypeModel.assignment: return Icons.assignment_rounded;
    case TaskTypeModel.quiz: return Icons.edit_note_rounded;
    case TaskTypeModel.reading: return Icons.menu_book_rounded;
  }
}
