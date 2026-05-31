import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/task_model.dart';
import '../../services/auth_service.dart';
import '../../services/task_service.dart';
import '../../services/notification_service.dart';
import '../../utils/theme.dart';

class TaskFormScreen extends StatefulWidget {
  final TaskModel? task;
  const TaskFormScreen({super.key, this.task});
  @override State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _titleCtrl   = TextEditingController();
  final _descCtrl    = TextEditingController();
  final _subCtrl     = TextEditingController();

  TaskPriority _priority = TaskPriority.medium;
  TaskCategory _category = TaskCategory.assignment;
  DateTime     _deadline = DateTime.now().add(const Duration(days: 1));
  int          _weight   = 0;
  List<SubTask> _subtasks = [];
  bool _loading = false;
  bool get _isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final t = widget.task!;
      _titleCtrl.text = t.title;
      _descCtrl.text  = t.description;
      _priority = t.priority;
      _category = t.category;
      _deadline = t.deadline;
      _weight   = t.gradeWeight;
      _subtasks = List.from(t.subtasks);
    }
  }

  @override
  void dispose() { _titleCtrl.dispose(); _descCtrl.dispose(); _subCtrl.dispose(); super.dispose(); }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(context: context, initialDate: _deadline,
        firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 730)),
        builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: AppColors.primary)),
            child: child!));
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_deadline));
    if (time == null || !mounted) return;
    setState(() => _deadline = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  void _addSub() {
    final t = _subCtrl.text.trim();
    if (t.isEmpty) return;
    setState(() { _subtasks.add(SubTask(id: const Uuid().v4(), title: t)); _subCtrl.clear(); });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final uid  = context.read<AuthService>().currentUserId!;
      final svc  = context.read<TaskService>();
      final nsvc = context.read<NotificationService>();
      TaskModel saved;
      if (_isEdit) {
        saved = widget.task!.copyWith(title: _titleCtrl.text.trim(), description: _descCtrl.text.trim(),
            deadline: _deadline, priority: _priority, category: _category,
            gradeWeight: _weight, subtasks: _subtasks, updatedAt: DateTime.now());
        await svc.editTask(saved);
      } else {
        saved = await svc.addTask(userId: uid, title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(), deadline: _deadline,
            priority: _priority, category: _category, subtasks: _subtasks, gradeWeight: _weight);
      }
      await nsvc.scheduleTaskReminders(saved);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'),
          backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Task' : 'New Task'),
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
        actions: [TextButton(onPressed: _loading ? null : _save,
          child: _loading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 16)))],
      ),
      body: Form(key: _formKey, child: ListView(padding: const EdgeInsets.all(20), children: [

        _Label('Task Title'),
        TextFormField(controller: _titleCtrl, textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'e.g. Complete Assignment 1'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null),
        const SizedBox(height: 20),

        _Label('Description (optional)'),
        TextFormField(controller: _descCtrl, maxLines: 3,
            decoration: const InputDecoration(hintText: 'Add details about this task...')),
        const SizedBox(height: 20),

        _Label('Deadline'),
        GestureDetector(onTap: _pickDeadline, child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.surface,
              border: Border.all(color: AppColors.divider), borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20), const SizedBox(width: 12),
            Text(DateFormat('EEE, MMM d yyyy  •  h:mm a').format(_deadline),
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
          ]),
        )),
        const SizedBox(height: 20),

        _Label('Priority'),
        Row(children: TaskPriority.values.map((p) {
          final sel = _priority == p;
          return Expanded(child: GestureDetector(onTap: () => setState(() => _priority = p),
            child: AnimatedContainer(duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: p != TaskPriority.low ? 10 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: sel ? p.color : AppColors.surface, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sel ? p.color : AppColors.divider, width: 1.5)),
              child: Column(children: [
                Icon(p.icon, color: sel ? Colors.white : p.color, size: 20), const SizedBox(height: 4),
                Text(p.label, style: TextStyle(color: sel ? Colors.white : AppColors.textSecondary,
                    fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            )));
        }).toList()),
        const SizedBox(height: 20),

        _Label('Category'),
        Wrap(spacing: 8, runSpacing: 8, children: TaskCategory.values.map((c) {
          final sel = _category == c;
          return GestureDetector(onTap: () => setState(() => _category = c),
            child: AnimatedContainer(duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: sel ? c.color : AppColors.surface,
                  borderRadius: BorderRadius.circular(20), border: Border.all(color: sel ? c.color : AppColors.divider)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(c.icon, size: 14, color: sel ? Colors.white : c.color), const SizedBox(width: 6),
                Text(c.label, style: TextStyle(fontSize: 13, color: sel ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w600)),
              ]),
            ));
        }).toList()),
        const SizedBox(height: 20),

        _Label('Grade Weight (% of total mark)'),
        Row(children: [
          Expanded(child: Slider(value: _weight.toDouble(), min: 0, max: 100, divisions: 20,
              activeColor: AppColors.primary, onChanged: (v) => setState(() => _weight = v.toInt()))),
          Container(width: 52, height: 40, alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
              child: Text('$_weight%', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14))),
        ]),
        const SizedBox(height: 20),

        _Label('Subtasks (Task Breakdown)'),
        ..._subtasks.asMap().entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            const Icon(Icons.radio_button_unchecked_rounded, color: AppColors.primary, size: 18), const SizedBox(width: 10),
            Expanded(child: Text(e.value.title, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary))),
            GestureDetector(onTap: () => setState(() => _subtasks.removeAt(e.key)),
                child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textHint)),
          ]))),
        Row(children: [
          Expanded(child: TextFormField(controller: _subCtrl,
              decoration: const InputDecoration(hintText: 'Add a subtask step...'),
              onFieldSubmitted: (_) => _addSub())),
          const SizedBox(width: 10),
          GestureDetector(onTap: _addSub, child: Container(width: 46, height: 46,
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.add_rounded, color: Colors.white))),
        ]),
        const SizedBox(height: 40),
      ])),
    );
  }
}

class _Label extends StatelessWidget {
  final String text; const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 14)));
}
