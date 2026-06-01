import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
    final u = await context.read<TaskService>().getTask(_task.userId, _task.id);
    if (u != null && mounted) setState(() => _task = u);
  }

  @override
  Widget build(BuildContext context) {
    final prog  = _task.subtaskProgress;
    final tLeft = _task.deadline.difference(DateTime.now());
    final tStr  = _task.isOverdue
        ? 'Overdue by ${(-tLeft.inHours).abs()}h'
        : tLeft.inDays > 0 ? '${tLeft.inDays}d ${tLeft.inHours % 24}h left'
        : '${tLeft.inHours}h ${tLeft.inMinutes % 60}m left';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: CupertinoButton(padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context, true),
          child: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary, size: 20)),
        title: const Text('Task Detail'),
        actions: [
          CupertinoButton(padding: const EdgeInsets.only(right: 8),
            onPressed: () async {
              final ok = await Navigator.push<bool>(context,
                  MaterialPageRoute(builder: (_) => TaskFormScreen(task: _task)));
              if (ok == true && mounted) {
                final u = await context.read<TaskService>().getTask(_task.userId, _task.id);
                if (u != null && mounted) setState(() => _task = u);
              }
            },
            child: const Icon(Icons.edit_rounded, color: AppColors.primary)),
        ],
      ),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 8, runSpacing: 8, children: [
              _Chip(_task.category.icon, _task.category.label,
                  _task.category.color.withOpacity(0.12), _task.category.color),
              _Chip(_task.priority.icon, '${_task.priority.label} Priority',
                  _task.priority.lightColor, _task.priority.color),
              if (_task.isOverdue) _Chip(Icons.warning_rounded, 'Overdue', AppColors.dangerLight, AppColors.danger),
              if (_task.isDueToday && !_task.isOverdue) _Chip(Icons.today_rounded, 'Due Today', AppColors.warningLight, AppColors.warning),
            ]),
            const SizedBox(height: 14),
            Text(_task.title, style: Theme.of(context).textTheme.titleLarge),
            if (_task.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_task.description, style: Theme.of(context).textTheme.bodyMedium)],
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _Chip(Icons.schedule_rounded, DateFormat('MMM d, h:mm a').format(_task.deadline),
                  (_task.isOverdue ? AppColors.danger : AppColors.primary).withOpacity(0.1),
                  _task.isOverdue ? AppColors.danger : AppColors.primary),
              _Chip(Icons.hourglass_bottom_rounded, tStr,
                  (_task.isOverdue ? AppColors.danger : AppColors.success).withOpacity(0.1),
                  _task.isOverdue ? AppColors.danger : AppColors.success),
              if (_task.gradeWeight > 0)
                _Chip(Icons.grade_rounded, '${_task.gradeWeight}% of grade',
                    AppColors.warning.withOpacity(0.1), AppColors.warning),
            ]),
          ])),
          const SizedBox(height: 16),

          // Progress
          if (_task.subtasks.isNotEmpty) ...[
            _Card(child: Row(children: [
              CircularPercentIndicator(radius: 38, lineWidth: 6, percent: prog.clamp(0.0, 1.0),
                center: Text('${(prog * 100).toInt()}%',
                    style: TextStyle(color: _task.priority.color, fontWeight: FontWeight.bold, fontSize: 13)),
                progressColor: _task.priority.color, backgroundColor: AppColors.divider,
                circularStrokeCap: CircularStrokeCap.round),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Progress', style: Theme.of(context).textTheme.titleMedium),
                Text('${_task.subtasks.where((s) => s.isDone).length} of ${_task.subtasks.length} done',
                    style: Theme.of(context).textTheme.bodyMedium),
              ]),
            ])),
            const SizedBox(height: 16),
            Text('Subtasks', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _Card(child: Column(children: _task.subtasks.asMap().entries.map((e) {
              final s = e.value; final i = e.key;
              return Column(children: [
                ListTile(contentPadding: EdgeInsets.zero, dense: true,
                  leading: GestureDetector(onTap: () => _toggleSub(s.id),
                    child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                          color: s.isDone ? AppColors.success : Colors.transparent,
                          border: Border.all(color: s.isDone ? AppColors.success : AppColors.textHint, width: 2),
                          borderRadius: BorderRadius.circular(6)),
                      child: s.isDone ? const Icon(Icons.check_rounded, color: Colors.white, size: 14) : null)),
                  title: Text(s.title, style: TextStyle(fontSize: 14,
                      decoration: s.isDone ? TextDecoration.lineThrough : null,
                      color: s.isDone ? AppColors.textHint : AppColors.textPrimary))),
                if (i < _task.subtasks.length - 1) const Divider(height: 1, indent: 38),
              ]);
            }).toList())),
            const SizedBox(height: 16),
          ],

          // Map
          if (_task.location != null) ...[
            Text('Location', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ClipRRect(borderRadius: BorderRadius.circular(12),
                child: SizedBox(height: 180,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                        target: LatLng(_task.location!.lat, _task.location!.lng), zoom: 15),
                    markers: {Marker(
                        markerId: const MarkerId('task'),
                        position: LatLng(_task.location!.lat, _task.location!.lng))},
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    scrollGesturesEnabled: false,
                    zoomGesturesEnabled: false,
                    rotateGesturesEnabled: false,
                    tiltGesturesEnabled: false,
                  ))),
              if (_task.location!.address.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(children: [
                  const Icon(Icons.location_on_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(child: Text(_task.location!.address,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
                ]),
              ],
            ])),
            const SizedBox(height: 16),
          ],

          // Complete button
          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              onPressed: () async {
                await context.read<TaskService>().updateTaskStatus(_task);
                if (!mounted) return;
                Navigator.pop(context, true);
              },
              icon: Icon(_task.isCompleted ? Icons.refresh_rounded : Icons.check_circle_rounded),
              label: Text(_task.isCompleted ? 'Mark as Incomplete' : 'Mark as Complete'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _task.isCompleted ? AppColors.textSecondary : AppColors.success,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            )),
          const SizedBox(height: 24),
        ],
      )),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))]),
    child: child);
}

class _Chip extends StatelessWidget {
  final IconData icon; final String label; final Color bg, fg;
  const _Chip(this.icon, this.label, this.bg, this.fg);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: fg), const SizedBox(width: 5),
      Text(label, style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w600)),
    ]));
}
