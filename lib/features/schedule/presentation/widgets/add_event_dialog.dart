import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:la_facu/core/theme/app_theme.dart';
import 'package:la_facu/data/local_db/models/class_event_model.dart';
import 'package:la_facu/data/local_db/models/subject_model.dart';
import 'package:la_facu/features/schedule/data/schedule_repository.dart';
import 'package:la_facu/features/subjects/data/subject_repository.dart';
import 'package:google_fonts/google_fonts.dart';

class AddEventDialog extends ConsumerStatefulWidget {
  final ClassEventModel? event;
  const AddEventDialog({super.key, this.event});

  @override
  ConsumerState<AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends ConsumerState<AddEventDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedSubjectName;
  late Color _selectedColor;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late final TextEditingController _roomController;
  late int _selectedDayIndex;

  final List<String> _days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

  bool get isEdit => widget.event != null;

  @override
  void initState() {
    super.initState();
    _selectedSubjectName = widget.event?.subjectName;
    _selectedColor = widget.event != null ? Color(widget.event!.colorValue) : AppColors.neonBlue;
    
    if (widget.event != null) {
      final startParts = widget.event!.startTime.split(':');
      final endParts = widget.event!.endTime.split(':');
      _startTime = TimeOfDay(hour: int.parse(startParts[0]), minute: int.parse(startParts[1]));
      _endTime = TimeOfDay(hour: int.parse(endParts[0]), minute: int.parse(endParts[1]));
      _selectedDayIndex = widget.event!.dayIndex;
      _roomController = TextEditingController(text: widget.event!.room);
    } else {
      _startTime = const TimeOfDay(hour: 8, minute: 0);
      _endTime = const TimeOfDay(hour: 10, minute: 0);
      _selectedDayIndex = 0;
      _roomController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _roomController.dispose();
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
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.glassBorderBright),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
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
                          isEdit ? 'EDIT_SCHEDULE' : 'NEW_SCHEDULE',
                          style: AppTheme.monoTextStyle.copyWith(
                            fontSize: 10,
                            letterSpacing: 2,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isEdit ? widget.event!.subjectName : 'Nuevo Horario',
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
                
                _buildFieldTag('SUBJECT_LINK'),
                subjectsAsync.when(
                  data: (subjects) => DropdownButtonFormField<String>(
                    initialValue: _selectedSubjectName,
                    isExpanded: true,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                    decoration: _inputDecoration(Icons.book_outlined),
                    items: subjects
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.name,
                            child: Text(s.name, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      SubjectModel? selectedSubject;
                      for (final subject in subjects) {
                        if (subject.name == v) {
                          selectedSubject = subject;
                          break;
                        }
                      }
                      setState(() {
                        _selectedSubjectName = v;
                        if (selectedSubject != null) {
                          _selectedColor = Color(selectedSubject.colorValue);
                        }
                      });
                    },
                    validator: (v) => v == null ? 'REQ' : null,
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => const Icon(Icons.error_outline),
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldTag('DAY_OF_WEEK'),
                          DropdownButtonFormField<int>(
                            initialValue: _selectedDayIndex,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: Theme.of(context).textTheme.titleLarge?.color,
                            ),
                            decoration: _inputDecoration(Icons.calendar_today_rounded),
                            items: List.generate(7, (i) => DropdownMenuItem(
                              value: i,
                              child: Text(_days[i]),
                            )),
                            onChanged: (v) => setState(() => _selectedDayIndex = v!),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldTag('ROOM_ID'),
                          TextFormField(
                            controller: _roomController,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).textTheme.titleLarge?.color,
                            ),
                            decoration: _inputDecoration(Icons.location_on_outlined, hint: 'Aula'),
                            validator: (v) => v == null || v.isEmpty ? 'REQ' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildFieldTag('TIME_WINDOW'),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickTime(true),
                        borderRadius: BorderRadius.circular(12),
                        child: _buildTimeBox('START', _startTime),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickTime(false),
                        borderRadius: BorderRadius.circular(12),
                        child: _buildTimeBox('END', _endTime),
                      ),
                    ),
                  ],
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
                        child: Text(isEdit ? 'GUARDAR' : 'CREAR HORARIO', style: const TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildTimeBox(String label, TimeOfDay time) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariant.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.glassBorder : AppColors.lightGlassBorder.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTheme.monoTextStyle.copyWith(fontSize: 9, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(
            time.format(context),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(IconData icon, {String? hint}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 18),
      filled: true,
      fillColor: isDark ? AppColors.surfaceVariant.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? AppColors.glassBorder : AppColors.lightGlassBorder.withValues(alpha: 0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  void _pickTime(bool isStart) async {
    final t = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (t != null) {
      setState(() {
        if (isStart) {
          _startTime = t;
        } else {
          _endTime = t;
        }
      });
    }
  }

  void _delete() async {
     final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar horario?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await ref.read(scheduleRepositoryProvider.notifier).deleteEvent(widget.event!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final startMinutes = (_startTime.hour * 60) + _startTime.minute;
      final endMinutes = (_endTime.hour * 60) + _endTime.minute;

      if (endMinutes <= startMinutes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La hora de fin debe ser posterior al inicio.'),
          ),
        );
        return;
      }

      final event = (widget.event ?? ClassEventModel())
        ..subjectName = _selectedSubjectName!
        ..dayIndex = _selectedDayIndex
        ..startTime = '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}'
        ..endTime = '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}'
        ..room = _roomController.text.trim()
        ..colorValue = _selectedColor.toARGB32();

      await ref.read(scheduleRepositoryProvider.notifier).addEvent(event);
      if (mounted) Navigator.pop(context);
    }
  }
}
