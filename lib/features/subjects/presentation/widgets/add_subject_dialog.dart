import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:la_facu/core/theme/app_theme.dart';
import 'package:la_facu/data/local_db/models/subject_model.dart';
import 'package:la_facu/features/subjects/data/subject_repository.dart';

class SubjectDialog extends ConsumerStatefulWidget {
  final SubjectModel? subject;
  const SubjectDialog({super.key, this.subject});

  @override
  ConsumerState<SubjectDialog> createState() => _SubjectDialogState();
}

class _SubjectDialogState extends ConsumerState<SubjectDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _professorController;
  late final TextEditingController _creditsController;
  late Color _selectedColor;

  bool get isEdit => widget.subject != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.subject?.name);
    _codeController = TextEditingController(text: widget.subject?.code);
    _professorController = TextEditingController(text: widget.subject?.professor);
    _creditsController = TextEditingController(text: widget.subject?.credits.toString());
    _selectedColor = widget.subject != null ? Color(widget.subject!.colorValue) : AppColors.subjectColors[0];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _professorController.dispose();
    _creditsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.subjectColors : AppColors.lightSubjectColors;

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
                          isEdit ? 'EDIT_SUBJECT' : 'NEW_SUBJECT',
                          style: AppTheme.monoTextStyle.copyWith(
                            fontSize: 10,
                            letterSpacing: 2,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isEdit ? widget.subject!.name : 'Añadir Materia',
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
                _buildField('SUBJECT_NAME', _nameController, Icons.book_rounded, hint: 'Ej: Análisis Matemático II'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildField('ID_CODE', _codeController, Icons.terminal_rounded, hint: 'AM2-2024')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildField('CREDITS', _creditsController, Icons.data_array_rounded, keyboardType: TextInputType.number, hint: '6')),
                  ],
                ),
                const SizedBox(height: 16),
                _buildField('PROFESSOR', _professorController, Icons.account_circle_outlined, hint: 'Nombre del docente'),
                const SizedBox(height: 24),
                
                Text('COLOR_TAG', style: AppTheme.monoTextStyle.copyWith(fontSize: 10, color: AppColors.textMuted)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: colors.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final color = colors[index];
                      final isSelected = _selectedColor.toARGB32() == color.toARGB32();
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = color),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected ? Border.all(color: Colors.white, width: 2.5) : null,
                            boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 10, spreadRadius: 1)] : null,
                          ),
                          child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                        ),
                      );
                    },
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
                        child: Text(isEdit ? 'GUARDAR' : 'CREAR MATERIA', style: const TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildField(String tag, TextEditingController controller, IconData icon, {TextInputType? keyboardType, String? hint}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(tag, style: AppTheme.monoTextStyle.copyWith(fontSize: 10, color: AppColors.textMuted)),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
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
              borderSide: BorderSide(color: _selectedColor.withOpacity(0.5), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (v) => v == null || v.isEmpty ? 'M_REQUIRED' : null,
        ),
      ],
    );
  }

  void _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar materia?'),
        content: const Text('Esta acción también eliminará las tareas y horarios asociados.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ref.read(subjectRepositoryProvider.notifier).deleteSubject(widget.subject!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final subject = (widget.subject ?? SubjectModel())
        ..name = _nameController.text
        ..code = _codeController.text
        ..professor = _professorController.text
        ..credits = int.tryParse(_creditsController.text) ?? 0
        ..colorValue = _selectedColor.toARGB32();
        
      if (!isEdit) {
        subject.progress = 0.0;
      }

      await ref.read(subjectRepositoryProvider.notifier).addSubject(subject);
      if (mounted) Navigator.pop(context);
    }
  }
}

