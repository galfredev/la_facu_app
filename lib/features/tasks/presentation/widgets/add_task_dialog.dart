import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:la_facu/core/theme/app_theme.dart';
import 'package:la_facu/data/local_db/models/task_model.dart';
import 'package:la_facu/features/tasks/data/task_repository.dart';
import 'package:la_facu/features/subjects/data/subject_repository.dart';
import 'package:intl/intl.dart';

class AddTaskDialog extends ConsumerStatefulWidget {
  final TaskModel? task;
  const AddTaskDialog({super.key, this.task});

  @override
  ConsumerState<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends ConsumerState<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late DateTime _selectedDate;
  late TaskTypeModel _selectedType;
  String? _selectedSubjectName;
  late Color _selectedColor;

  bool get isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title);
    _selectedDate = widget.task?.dueDate ?? DateTime.now().add(const Duration(days: 1));
    _selectedType = widget.task?.type ?? TaskTypeModel.assignment;
    _selectedSubjectName = widget.task?.subjectName;
    _selectedColor = widget.task != null ? Color(widget.task!.colorValue) : AppColors.neonBlue;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(subjectRepositoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.98),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.glassBorderBright),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'EDIT_TASK' : 'NEW_TASK',
                          style: AppTheme.monoTextStyle.copyWith(
                            fontSize: 10,
                            letterSpacing: 2,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isEdit ? widget.task!.title : 'Nueva Tarea',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    if (isEdit)
                      IconButton(
                        onPressed: _delete,
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                      ),
                  ],
                ),
                const SizedBox(height: 32),
                
                _buildFieldTag('TASK_TITLE'),
                TextFormField(
                  controller: _titleController,
                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w500),
                  decoration: _inputDecoration(Icons.assignment_outlined, hint: 'Ej: Informe Final'),
                  validator: (v) => v == null || v.isEmpty ? 'T_REQUIRED' : null,
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldTag('SUBJECT'),
                          subjectsAsync.when(
                            data: (subjects) => DropdownButtonFormField<String>(
                              value: _selectedSubjectName,
                              isExpanded: true,
                              style: GoogleFonts.outfit(fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                              decoration: _inputDecoration(Icons.book_outlined),
                              items: subjects.map((s) => DropdownMenuItem(
                                value: s.name,
                                child: Text(s.name, overflow: TextOverflow.ellipsis),
                                onTap: () => _selectedColor = Color(s.colorValue),
                              )).toList(),
                              onChanged: (v) => setState(() => _selectedSubjectName = v),
                              validator: (v) => v == null ? 'REQ' : null,
                            ),
                            loading: () => const LinearProgressIndicator(),
                            error: (_, __) => const Icon(Icons.error_outline),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldTag('TYPE'),
                          DropdownButtonFormField<TaskTypeModel>(
                            value: _selectedType,
                            style: GoogleFonts.outfit(fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                            decoration: _inputDecoration(Icons.category_outlined),
                            items: TaskTypeModel.values.map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(_taskLabel(t)),
                            )).toList(),
                            onChanged: (v) => setState(() => _selectedType = v!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildFieldTag('DUE_DATE'),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceVariant.withOpacity(0.2) : Colors.black.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? AppColors.glassBorder : AppColors.lightGlassBorder.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primaryBlue),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat("d MMM, yyyy", 'es_ES').format(_selectedDate),
                          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        const Icon(Icons.edit_calendar_rounded, size: 18, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: isDark ? AppColors.glassBorder : AppColors.lightGlassBorder),
                        ),
                        child: const Text('CANCELAR'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(isEdit ? 'GUARDAR' : 'CREAR TAREA', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldTag(String tag) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(tag, style: AppTheme.monoTextStyle.copyWith(fontSize: 10, color: AppColors.textMuted)),
    );
  }

  InputDecoration _inputDecoration(IconData icon, {String? hint}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 18),
      filled: true,
      fillColor: isDark ? AppColors.surfaceVariant.withOpacity(0.2) : Colors.black.withOpacity(0.03),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? AppColors.glassBorder : AppColors.lightGlassBorder.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  String _taskLabel(TaskTypeModel t) {
    switch (t) {
      case TaskTypeModel.exam: return 'Parcial';
      case TaskTypeModel.assignment: return 'TP';
      case TaskTypeModel.quiz: return 'Quiz';
      case TaskTypeModel.reading: return 'Lectura';
    }
  }

  void _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  void _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar tarea?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await ref.read(taskRepositoryProvider.notifier).deleteTask(widget.task!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedSubjectName == null) return;
      
      final task = (widget.task ?? TaskModel())
        ..title = _titleController.text
        ..subjectName = _selectedSubjectName!
        ..dueDate = _selectedDate
        ..type = _selectedType
        ..colorValue = _selectedColor.toARGB32();
      
      if (!isEdit) {
        task.isDone = false;
      }

      await ref.read(taskRepositoryProvider.notifier).addTask(task);
      if (mounted) Navigator.pop(context);
    }
  }
}
