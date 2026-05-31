import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../models/task_model.dart';
import '../../services/auth_service.dart';
import '../../services/task_service.dart';
import '../../utils/theme.dart';
import '../tasks/task_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focused  = DateTime.now();
  DateTime _selected = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthService>().currentUserId ?? '';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Calendar')),
      body: StreamBuilder<List<TaskModel>>(
        stream: context.read<TaskService>().getTasks(uid),
        builder: (context, snap) {
          final tasks = snap.data ?? [];
          final Map<DateTime, List<TaskModel>> events = {};
          for (final t in tasks) {
            final day = DateTime(t.deadline.year, t.deadline.month, t.deadline.day);
            events[day] = [...(events[day] ?? []), t];
          }
          List<TaskModel> forDay(DateTime d) =>
              events[DateTime(d.year, d.month, d.day)] ?? [];
          final selected = forDay(_selected);

          return Column(children: [
            Container(margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
              child: TableCalendar<TaskModel>(
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay:  DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focused,
                selectedDayPredicate: (d) => isSameDay(d, _selected),
                eventLoader: forDay,
                onDaySelected: (sel, foc) => setState(() { _selected = sel; _focused = foc; }),
                onPageChanged: (f) => setState(() => _focused = f),
                calendarStyle: CalendarStyle(
                  selectedDecoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  todayDecoration: BoxDecoration(color: AppColors.primary.withOpacity(0.2), shape: BoxShape.circle),
                  todayTextStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  markerDecoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                  outsideDaysVisible: false,
                ),
                headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true,
                    leftChevronIcon:  Icon(Icons.chevron_left_rounded,  color: AppColors.primary),
                    rightChevronIcon: Icon(Icons.chevron_right_rounded, color: AppColors.primary)),
              )),

            Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(children: [
                Text(DateFormat('MMMM d').format(_selected), style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(width: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)),
                  child: Text('${selected.length} tasks',
                      style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600))),
              ])),

            Expanded(child: selected.isEmpty
                ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.event_available_rounded, size: 48, color: AppColors.primaryLight),
                    SizedBox(height: 12),
                    Text('No tasks on this day', style: TextStyle(color: AppColors.textSecondary)),
                  ]))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    itemCount: selected.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final t = selected[i];
                      return ListTile(
                        tileColor: AppColors.surface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        leading: Container(width: 4, height: 40,
                            decoration: BoxDecoration(color: t.priority.color, borderRadius: BorderRadius.circular(4))),
                        title: Text(t.title, style: TextStyle(fontWeight: FontWeight.w600,
                            decoration: t.isCompleted ? TextDecoration.lineThrough : null)),
                        subtitle: Text(DateFormat('h:mm a').format(t.deadline)),
                        trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: t.category.color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                          child: Text(t.category.label,
                              style: TextStyle(fontSize: 11, color: t.category.color, fontWeight: FontWeight.w600))),
                        onTap: () => Navigator.push(ctx,
                            MaterialPageRoute(builder: (_) => TaskDetailScreen(task: t))),
                      );
                    })),
          ]);
        }),
    );
  }
}
