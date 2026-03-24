import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:la_facu/features/subjects/data/subject_repository.dart';
import 'package:la_facu/data/local_db/models/subject_model.dart';
import 'package:la_facu/features/subjects/presentation/widgets/add_subject_dialog.dart';

class SubjectsScreen extends ConsumerWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectRepositoryProvider);
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
                      Text('Materias', style: Theme.of(context).textTheme.displayMedium).animate().fadeIn().slideX(begin: -0.05),
                      Text('${subjectsAsync.value?.length ?? 0} materias este cuatrimestre', style: Theme.of(context).textTheme.bodyMedium).animate().fadeIn(delay: 100.ms),
                    ],
                  ),
                  FloatingActionButton.small(
                    onPressed: () => showDialog(context: context, builder: (_) => const SubjectDialog()),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
                  ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.8, 0.8)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: subjectsAsync.when(
                data: (subjects) => ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: subjects.length,
                  itemBuilder: (ctx, i) => GestureDetector(
                    onTap: () => showDialog(context: context, builder: (_) => SubjectDialog(subject: subjects[i])),
                    child: _SubjectCard(
                      subject: subjects[i],
                    ),
                  ).animate().fadeIn(delay: (150 + i * 70).ms, duration: 400.ms).slideY(begin: 0.05),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class _SubjectCard extends StatelessWidget {
  final SubjectModel subject;
  const _SubjectCard({required this.subject});

  @override
  Widget build(BuildContext context) {
    final color = Color(subject.colorValue);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Color(subject.colorValue).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    subject.name.substring(0, 1),
                    style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subject.name, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(subject.professor, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
                  ],
                ),
              ),
              Chip(
                label: Text('${subject.credits} UC', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                backgroundColor: color.withValues(alpha: 0.1),
                side: BorderSide(color: color.withValues(alpha: 0.25)),
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Progress
          // Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progreso', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11)),
              Text('${(subject.progress * 100).round()}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: subject.progress,
              minHeight: 5,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}
