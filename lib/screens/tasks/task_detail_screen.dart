import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../models/task_model.dart';
import '../../services/task_service.dart';
import '../../utils/theme.dart';
import 'task_form_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final TaskModel task;
  const TaskDetailScreen({super.key, required this.task});
  @override State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late TaskModel _task;

  @override
  void initState() { super.initState(); _task = widget.task; }

  Future<void> _toggleSub(String id) async {
    await context.read<TaskService>().toggleSubtask(_task, id);
    if (!mounted) return;
    final updated = await context.read<TaskService>().getTask(_task.userId, _task.id);
    if (updated != null && mounted) setState(() => _task = updated);
  }

  @override
  Widget build(BuildContext context) {
    final prog    = _task.subtaskProgress;
    final tLeft   = _task.deadline.difference(DateTime.now());
    final tStr    = _task.isOverdue
        ? 'Overdue by ${(-tLeft.inHours).abs()}h'
        : tLeft.inDays > 0 ? '${tLeft.inDays}d ${tLeft.inHours % 24}h left'
        : '${tLeft.inHours}h ${tLeft.inMinutes % 60}m left';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Task Detail'), actions: [
        IconButton(icon: const Icon(Icons.edit_rounded), onPressed: () async {
          final ok = await Navigator.push<bool>(context,
              MaterialPageRoute(builder: (_) => TaskFormScreen(task: _task)));
          if (ok == true && mounted) {
            final u = await context.read<TaskService>().getTask(_task.userId, _task.id);
            if (u != null && mounted) setState(() => _task = u);
          }
        }),
      ]),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Color(0x1A6C63FF), blurRadius: 12)]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 8, runSpacing: 8, children: [
                _Chip(icon: _task.category.icon, label: _task.category.label,
                    bg: _task.category.color.withOpacity(0.12), fg: _task.category.color),
                _Chip(icon: _task.priority.icon, label: '${_task.priority.label} Priority',
                    bg: _task.priority.lightColor, fg: _task.priority.color),
              ]),
              const SizedBox(height: 14),
              Text(_task.title, style: Theme.of(context).textTheme.titleLarge),
              if (_task.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(_task.description, style: Theme.of(context).textTheme.bodyMedium),
              ],
              const SizedBox(height: 16),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _Chip(icon: Icons.schedule_rounded, label: DateFormat('MMM d, h:mm a').format(_task.deadline),
                    bg: (_task.isOverdue ? AppColors.danger : AppColors.primary).withOpacity(0.1),
                    fg: _task.isOverdue ? AppColors.danger : AppColors.primary),
                _Chip(icon: Icons.hourglass_bottom_rounded, label: tStr,
                    bg: (_task.isOverdue ? AppColors.danger : AppColors.textSecondary).withOpacity(0.1),
                    fg: _task.isOverdue ? AppColors.danger : AppColors.textSecondary),
                if (_task.gradeWeight > 0)
                  _Chip(icon: Icons.grade_rounded, label: '${_task.gradeWeight}% of grade',
                      bg: AppColors.warning.withOpacity(0.1), fg: AppColors.warning),
              ]),
            ])),
          const SizedBox(height: 20),

          // Progress
          if (_task.subtasks.isNotEmpty) ...[
            Container(padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
              child: Row(children: [
                CircularPercentIndicator(radius: 40, lineWidth: 6, percent: prog.clamp(0.0, 1.0),
                    center: Text('${(prog * 100).toInt()}%',
                        style: TextStyle(color: _task.priority.color, fontWeight: FontWeight.bold, fontSize: 14)),
                    progressColor: _task.priority.color, backgroundColor: AppColors.divider,
                    circularStrokeCap: CircularStrokeCap.round),
                const SizedBox(width: 20),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Progress', style: Theme.of(context).textTheme.titleMedium),
                  Text('${_task.subtasks.where((s) => s.isDone).length} of ${_task.subtasks.length} done',
                      style: Theme.of(context).textTheme.bodyMedium),
                ]),
              ])),
            const SizedBox(height: 20),
            Text('Subtasks', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Container(decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
              child: Column(children: _task.subtasks.asMap().entries.map((e) {
                final s = e.value; final i = e.key;
                return Column(children: [
                  ListTile(
                    leading: GestureDetector(onTap: () => _toggleSub(s.id),
                      child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                        width: 24, height: 24,
                        decoration: BoxDecoration(
                            color: s.isDone ? AppColors.success : Colors.transparent,
                            border: Border.all(color: s.isDone ? AppColors.success : AppColors.textHint, width: 2),
                            borderRadius: BorderRadius.circular(6)),
                        child: s.isDone ? const Icon(Icons.check_rounded, color: Colors.white, size: 15) : null)),
                    title: Text(s.title, style: TextStyle(fontSize: 14,
                        decoration: s.isDone ? TextDecoration.lineThrough : null,
                        color: s.isDone ? AppColors.textHint : AppColors.textPrimary)),
                  ),
                  if (i < _task.subtasks.length - 1) const Divider(height: 1, indent: 56),
                ]);
              }).toList())),
            const SizedBox(height: 20),
          ],

          SizedBox(width: double.infinity, child: ElevatedButton.icon(
            onPressed: () async {
              await context.read<TaskService>().updateTaskStatus(_task);
              if (!mounted) return;
              Navigator.pop(context, true);
            },
            icon: Icon(_task.isCompleted ? Icons.refresh_rounded : Icons.check_circle_rounded),
            label: Text(_task.isCompleted ? 'Mark as Incomplete' : 'Mark as Complete'),
            style: ElevatedButton.styleFrom(
                backgroundColor: _task.isCompleted ? AppColors.textSecondary : AppColors.success),
          )),
          const SizedBox(height: 20),
        ],
      )),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon; final String label; final Color bg, fg;
  const _Chip({required this.icon, required this.label, required this.bg, required this.fg});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: fg), const SizedBox(width: 5),
      Text(label, style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w500)),
    ]),
  );
}
