import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _subCtrl = TextEditingController();

  TaskPriority _priority = TaskPriority.medium;
  TaskCategory _category = TaskCategory.assignment;
  DateTime _deadline = DateTime.now().add(const Duration(days: 1));
  int _weight = 0;
  List<SubTask> _subtasks = [];
  bool _saving = false;
  bool get _isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final t = widget.task!;
      _titleCtrl.text = t.title;
      _descCtrl.text = t.description;
      _priority = t.priority;
      _category = t.category;
      _deadline = t.deadline;
      _weight = t.gradeWeight;
      _subtasks = List.from(t.subtasks);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _subCtrl.dispose();
    super.dispose();
  }

  // FIX: iOS-style Cupertino spinner time picker (replaces broken Material clock)
  Future<void> _pickDeadline() async {
    DateTime temp = _deadline;
    // Step 1: pick date
    final date = await showDatePicker(
        context: context,
        initialDate: _deadline,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 730)),
        builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
                colorScheme: Theme.of(ctx)
                    .colorScheme
                    .copyWith(primary: AppColors.primary)),
            child: child!));
    if (date == null || !mounted) return;

    // Step 2: Cupertino spinner time picker
    await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => SizedBox(
            height: 300,
            child: Column(children: [
              Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                  child: Row(children: [
                    const Text('Select Time',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    const Spacer(),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Done',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700))),
                  ])),
              Expanded(
                  child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: DateTime(date.year, date.month, date.day,
                    _deadline.hour, _deadline.minute),
                onDateTimeChanged: (t) => temp =
                    DateTime(date.year, date.month, date.day, t.hour, t.minute),
              )),
            ])));

    if (!mounted) return;
    setState(() => _deadline = temp);
  }

  void _addSub() {
    final t = _subCtrl.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _subtasks.add(SubTask(id: const Uuid().v4(), title: t));
      _subCtrl.clear();
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // THE DEFINITIVE SAVE FIX
  // Rule: capture Navigator + ScaffoldMessenger + all providers BEFORE any await.
  // Then pop with the pre-captured navigator — works even if widget unmounts.
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_saving) return;

    // ▼ Capture everything NOW — before any await
    final nav = Navigator.of(context);
    final snack = ScaffoldMessenger.of(context);
    final uid = context.read<AuthService>().currentUserId!;
    final svc = context.read<TaskService>();
    final nsvc = context.read<NotificationService>();

    setState(() => _saving = true);

    try {
      TaskModel saved;
      if (_isEdit) {
        saved = widget.task!.copyWith(
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            deadline: _deadline,
            priority: _priority,
            category: _category,
            gradeWeight: _weight,
            subtasks: _subtasks,
            updatedAt: DateTime.now());
        await svc.editTask(saved);
      } else {
        saved = await svc.addTask(
            userId: uid,
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            deadline: _deadline,
            priority: _priority,
            category: _category,
            subtasks: _subtasks,
            gradeWeight: _weight);
      }
      nsvc.scheduleTaskReminders(saved).ignore(); // fire-and-forget
      nav.pop(true); // always succeeds
    } catch (e) {
      setState(() => _saving = false);
      snack.showSnackBar(SnackBar(
          content: const Text('Could not save task. Try again.'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.pop(context),
            child:
                const Icon(Icons.close_rounded, color: AppColors.textPrimary)),
        title: Text(_isEdit ? 'Edit Task' : 'New Task'),
        actions: [
          Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: AppColors.primary))
                      : const Text('Save',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)))),
        ],
      ),
      body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              _L('Task Title'),
              TextFormField(
                  controller: _titleCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                      hintText: 'e.g. Complete Assignment 1'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Title is required'
                      : null),
              const SizedBox(height: 18),
              _L('Description (optional)'),
              TextFormField(
                  controller: _descCtrl,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  decoration:
                      const InputDecoration(hintText: 'Add details...')),
              const SizedBox(height: 18),
              _L('Deadline'),
              _Tap(
                  icon: Icons.calendar_today_rounded,
                  label: DateFormat('EEE, MMM d yyyy  •  h:mm a')
                      .format(_deadline),
                  onTap: _pickDeadline),
              const SizedBox(height: 18),
              _L('Priority'),
              Row(
                  children: TaskPriority.values.map((p) {
                final sel = _priority == p;
                return Expanded(
                    child: GestureDetector(
                        onTap: () => setState(() => _priority = p),
                        child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: EdgeInsets.only(
                                right: p != TaskPriority.low ? 10 : 0),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                                color: sel ? p.color : AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: sel ? p.color : AppColors.divider,
                                    width: 1.5)),
                            child: Column(children: [
                              Icon(p.icon,
                                  color: sel ? Colors.white : p.color,
                                  size: 18),
                              const SizedBox(height: 3),
                              Text(p.label,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: sel
                                          ? Colors.white
                                          : AppColors.textSecondary)),
                            ]))));
              }).toList()),
              const SizedBox(height: 18),
              _L('Category'),
              Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: TaskCategory.values.map((c) {
                    final sel = _category == c;
                    return GestureDetector(
                        onTap: () => setState(() => _category = c),
                        child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                                color: sel ? c.color : AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: sel ? c.color : AppColors.divider)),
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(c.icon,
                                  size: 13,
                                  color: sel ? Colors.white : c.color),
                              const SizedBox(width: 5),
                              Text(c.label,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: sel
                                          ? Colors.white
                                          : AppColors.textSecondary)),
                            ])));
                  }).toList()),
              const SizedBox(height: 18),
              _L('Grade Weight — $_weight%'),
              Row(children: [
                Expanded(
                    child: Slider(
                        value: _weight.toDouble(),
                        min: 0,
                        max: 100,
                        divisions: 20,
                        activeColor: AppColors.primary,
                        onChanged: (v) => setState(() => _weight = v.toInt()))),
                Container(
                    width: 46,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10)),
                    child: Text('$_weight%',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13))),
              ]),
              const SizedBox(height: 18),
              _L('Subtasks (Task Breakdown)'),
              ..._subtasks
                  .asMap()
                  .entries
                  .map((e) => Dismissible(
                      key: Key(e.value.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                              color: AppColors.dangerLight,
                              borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.delete_outline_rounded,
                              color: AppColors.danger)),
                      onDismissed: (_) =>
                          setState(() => _subtasks.removeAt(e.key)),
                      child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.divider)),
                          child: Row(children: [
                            const Icon(Icons.drag_indicator_rounded,
                                color: AppColors.textHint, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(e.value.title,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textPrimary))),
                            GestureDetector(
                                onTap: () =>
                                    setState(() => _subtasks.removeAt(e.key)),
                                child: const Icon(Icons.close_rounded,
                                    size: 16, color: AppColors.textHint)),
                          ]))))
                  .toList(),
              Row(children: [
                Expanded(
                    child: TextFormField(
                        controller: _subCtrl,
                        decoration: const InputDecoration(
                            hintText: 'Add a step... (swipe to delete)'),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _addSub())),
                const SizedBox(width: 10),
                GestureDetector(
                    onTap: _addSub,
                    child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.add_rounded,
                            color: Colors.white))),
              ]),
            ],
          )),
    );
  }
}

class _L extends StatelessWidget {
  final String t;
  const _L(this.t);
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(t,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary)));
}

class _Tap extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _Tap(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.color});
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Icon(icon, color: color ?? AppColors.primary, size: 18),
            const SizedBox(width: 12),
            Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 14,
                        color: color ?? AppColors.textPrimary,
                        fontWeight: FontWeight.w500))),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textHint, size: 18),
          ])));
}
