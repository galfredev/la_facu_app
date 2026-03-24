import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:la_facu/features/schedule/data/schedule_repository.dart';
import 'package:la_facu/data/local_db/models/class_event_model.dart';
import 'package:la_facu/core/theme/app_theme.dart';
import 'package:la_facu/features/schedule/presentation/widgets/add_event_dialog.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;



  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }



  List<ClassEventModel> _getEventsForDay(List<ClassEventModel> allEvents, DateTime day) {
    // 1 es Lunes, 7 es Domingo en DateTime. Nosostros guardamos 0-6 (Lunes-Domingo)
    final dayIdx = day.weekday - 1;
    return allEvents.where((e) => e.dayIndex == dayIdx).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.neonBlue : AppColors.pastelBlue;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColors.lightTextMuted;
    final glassBorder = isDark ? AppColors.glassBorder : AppColors.lightGlassBorder;

    final eventsAsync = ref.watch(scheduleRepositoryProvider);

    return eventsAsync.when(
      data: (allEvents) {
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
                    Text('Horarios', style: Theme.of(context).textTheme.displayMedium)
                        .animate().fadeIn().slideX(begin: -0.05),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _calendarFormat == CalendarFormat.month ? Icons.calendar_view_week_rounded : Icons.calendar_month_rounded,
                          color: primaryColor,
                        ),
                        onPressed: () {
                          setState(() {
                            _calendarFormat = _calendarFormat == CalendarFormat.month
                                ? CalendarFormat.week
                                : CalendarFormat.month;
                          });
                        },
                      ),
                      FloatingActionButton.small(
                        onPressed: () => showDialog(context: context, builder: (_) => const AddEventDialog()),
                        backgroundColor: primaryColor,
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ],
                  ).animate().fadeIn(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Calendario
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: glassBorder),
              ),
              child: TableCalendar<ClassEventModel>(
                locale: 'es_ES',
                firstDay: DateTime.utc(2023, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                startingDayOfWeek: StartingDayOfWeek.monday,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  if (!isSameDay(_selectedDay, selectedDay)) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  }
                },
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  }
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                eventLoader: (day) => _getEventsForDay(allEvents, day),
                
                // Estilos del UI
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: Theme.of(context).textTheme.titleLarge!,
                  leftChevronIcon: Icon(Icons.chevron_left_rounded, color: primaryColor),
                  rightChevronIcon: Icon(Icons.chevron_right_rounded, color: primaryColor),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(color: textMuted, fontWeight: FontWeight.w600, fontSize: 13),
                  weekendStyle: TextStyle(color: textMuted.withValues(alpha: 0.6), fontWeight: FontWeight.w600, fontSize: 13),
                ),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  defaultTextStyle: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                  weekendTextStyle: TextStyle(color: textColor.withValues(alpha: 0.6), fontWeight: FontWeight.w500),
                  todayDecoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: TextStyle(color: primaryColor, fontWeight: FontWeight.w700),
                  selectedDecoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: primaryColor.withValues(alpha: 0.4), blurRadius: 8)],
                  ),
                  selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  markerDecoration: BoxDecoration(
                    color: isDark ? AppColors.neonPurple : AppColors.pastelPurple,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 24),
            
            // Lista de eventos
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                _selectedDay != null 
                  ? DateFormat("EEEE, d 'de' MMMM", 'es_ES').format(_selectedDay!).toUpperCase()
                  : 'Eventos del día',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.2),
              ),
            ).animate().fadeIn(delay: 150.ms),

            Expanded(
              child: _getEventsForDay(allEvents, _selectedDay ?? _focusedDay).isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_busy_rounded, size: 56, color: textMuted.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text('Día libre. ¡Aprovechá para repasar u ocio!', style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ).animate().fadeIn(),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _getEventsForDay(allEvents, _selectedDay ?? _focusedDay).length,
                      itemBuilder: (ctx, i) {
                        final ev = _getEventsForDay(allEvents, _selectedDay ?? _focusedDay)[i];
                        return _ClassCard(event: ev, color: Color(ev.colorValue))
                            .animate().fadeIn(delay: (i * 80).ms).slideX(begin: 0.04);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  },
  loading: () => const Center(child: CircularProgressIndicator()),
  error: (e, _) => Center(child: Text('Error: $e')),
);
  }
}

class _ClassCard extends ConsumerWidget {
  final ClassEventModel event;
  final Color color;
  const _ClassCard({required this.event, required this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final glassBorder = isDark ? AppColors.glassBorder : AppColors.lightGlassBorder;
    final textMuted = isDark ? AppColors.textMuted : AppColors.lightTextMuted;

    return Dismissible(
      key: Key(event.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
      ),
      onDismissed: (_) {
        ref.read(scheduleRepositoryProvider.notifier).deleteEvent(event.id);
      },
      child: GestureDetector(
        onTap: () => showDialog(context: context, builder: (_) => AddEventDialog(event: event)),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: glassBorder),
          ),
          child: Row(
            children: [
              // Línea de color
              Container(
                width: 4,
                height: 52,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.subjectName, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 14, color: textMuted),
                        const SizedBox(width: 4),
                        Text('${event.startTime} - ${event.endTime}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
                        const SizedBox(width: 12),
                        Icon(Icons.location_on_rounded, size: 14, color: textMuted),
                        const SizedBox(width: 4),
                        Expanded(child: Text(event.room, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


