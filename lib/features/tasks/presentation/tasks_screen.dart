import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:la_facu/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:la_facu/features/tasks/data/task_repository.dart';
import 'package:la_facu/data/local_db/models/task_model.dart';
import 'package:intl/intl.dart';
import 'package:la_facu/features/tasks/presentation/widgets/add_task_dialog.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;



  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(taskRepositoryProvider);
    
    return tasksAsync.when(
      data: (tasks) {
        final pending = tasks.where((t) => !t.isDone).toList();
        final done = tasks.where((t) => t.isDone).toList();
        return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tareas', style: Theme.of(context).textTheme.displayMedium).animate().fadeIn().slideX(begin: -0.05),
                      Text('${pending.length} pendientes', style: Theme.of(context).textTheme.bodyMedium).animate().fadeIn(delay: 100.ms),
                    ],
                  ),
                  FloatingActionButton.small(
                    onPressed: () => showDialog(context: context, builder: (_) => const AddTaskDialog()), // Changed to AddTaskDialog as per original context
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
                  ).animate().fadeIn(delay: 200.ms),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? AppColors.neonBlueGlow 
                        : AppColors.pastelBlueGlow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Pendientes'),
                    Tab(text: 'Completadas'),
                  ],
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Theme.of(context).brightness == Brightness.dark ? AppColors.textMuted : AppColors.lightTextMuted,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ).animate().fadeIn(delay: 150.ms),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _TaskList(tasks: pending),
                  _TaskList(tasks: done),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}

class _TaskList extends StatelessWidget {
  final List<TaskModel> tasks;
  const _TaskList({required this.tasks});

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text('¡Todo al día!', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ).animate().fadeIn(),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (ctx, i) {
        final task = tasks[i];
        return _TaskCard(task: task)
            .animate().fadeIn(delay: (i * 70).ms).slideY(begin: 0.04);
      },
    );
  }
}

class _TaskCard extends ConsumerWidget {
  final TaskModel task;
  const _TaskCard({required this.task});

  IconData get _typeIcon {
    switch (task.type) {
      case TaskTypeModel.exam: return Icons.quiz_rounded;
      case TaskTypeModel.assignment: return Icons.assignment_rounded;
      case TaskTypeModel.quiz: return Icons.edit_note_rounded;
      case TaskTypeModel.reading: return Icons.menu_book_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(task.colorValue);

    return Dismissible(
      key: Key(task.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.2), // Changed .withValues to .withOpacity
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
      ),
      onDismissed: (_) {
        ref.read(taskRepositoryProvider.notifier).deleteTask(task.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: task.isDone ? AppColors.glassBorder : color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                ref.read(taskRepositoryProvider.notifier).toggleTaskDone(task.id);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: task.isDone ? color : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: task.isDone ? color : color.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: task.isDone 
                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                  : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () => showDialog(context: context, builder: (_) => AddTaskDialog(task: task)),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        decoration: task.isDone ? TextDecoration.lineThrough : null,
                        color: task.isDone 
                            ? (Theme.of(context).brightness == Brightness.dark ? AppColors.textMuted : AppColors.lightTextMuted)
                            : Theme.of(context).textTheme.titleMedium?.color,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(task.subjectName, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
                        Text(' • ', style: TextStyle(fontSize: 11, color: Theme.of(context).brightness == Brightness.dark ? AppColors.textMuted : AppColors.lightTextMuted)),
                        Text(DateFormat("d MMM", 'es_ES').format(task.dueDate), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Icon(_typeIcon, color: color, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}


