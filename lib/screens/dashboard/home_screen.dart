import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/task_service.dart';
import '../../services/notification_service.dart';
import '../../utils/theme.dart';
import '../auth/login_screen.dart';
import '../tasks/task_form_screen.dart';
import '../tasks/task_detail_screen.dart';
import '../calendar/calendar_screen.dart';
import '../focus/focus_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _idx = 0;
  UserModel? _user;

  @override
  void initState() { super.initState(); _loadUser(); }

  Future<void> _loadUser() async {
    final uid = context.read<AuthService>().currentUserId;
    if (uid == null) return;
    final u = await context.read<AuthService>().getUserProfile(uid);
    if (mounted) setState(() => _user = u);
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthService>().currentUserId ?? '';
    final pages = [
      _DashboardTab(user: _user, uid: uid),
      const CalendarScreen(),
      const FocusScreen(),
      ProfileScreen(user: _user, onUpdated: (u) => setState(() => _user = u)),
    ];

    return Scaffold(
      body: IndexedStack(index: _idx, children: pages),
      floatingActionButton: _idx == 0
          ? FloatingActionButton(
              onPressed: () async {
                final ok = await Navigator.push<bool>(context,
                    MaterialPageRoute(builder: (_) => const TaskFormScreen()));
                if (ok == true && mounted) setState(() {});
              },
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomBar(idx: _idx, onTap: (i) => setState(() => _idx = i)),
    );
  }
}

// ─── Dashboard Tab ─────────────────────────────────────────────────────────────

class _DashboardTab extends StatefulWidget {
  final UserModel? user; final String uid;
  const _DashboardTab({required this.user, required this.uid});
  @override State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  String _filter = 'All';
  String _sort   = 'Smart';

  @override
  Widget build(BuildContext context) {
    final svc  = context.read<TaskService>();
    final name = widget.user?.name.split(' ').first ?? 'Student';
    final h    = DateTime.now().hour;
    final greeting = h < 12 ? 'Good morning' : h < 17 ? 'Good afternoon' : 'Good evening';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: StreamBuilder<List<TaskModel>>(
        stream: svc.getTasks(widget.uid),
        builder: (context, snap) {
          final all     = snap.data ?? [];
          final active  = all.where((t) => !t.isCompleted).toList();
          final done    = all.where((t) =>  t.isCompleted).toList();
          final overdue = active.where((t) => t.isOverdue).toList();
          final today   = active.where((t) => t.isDueToday).toList();

          List<TaskModel> filtered = switch (_filter) {
            'Today'   => today,
            'Overdue' => overdue,
            'All'     => active,
            _         => active.where((t) => t.category.label == _filter).toList(),
          };
          if (_sort == 'Smart')    filtered = svc.sortBySmart(filtered);
          if (_sort == 'Deadline') filtered.sort((a, b) => a.deadline.compareTo(b.deadline));
          if (_sort == 'Priority') filtered.sort((a, b) => a.priority.index.compareTo(b.priority.index));

          return CustomScrollView(slivers: [
            // Header
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(greeting, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    Text(name, style: Theme.of(context).textTheme.headlineMedium),
                  ])),
                  CircleAvatar(radius: 20, backgroundColor: AppColors.primaryLight,
                    child: Text(name[0].toUpperCase(),
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16))),
                ]),
                const SizedBox(height: 16),

                // Stats row
                Row(children: [
                  _StatPill('Active', '${active.length}', AppColors.primary),
                  const SizedBox(width: 10),
                  _StatPill('Today',  '${today.length}',  AppColors.warning),
                  const SizedBox(width: 10),
                  _StatPill('Done',   '${done.length}',   AppColors.success),
                ]),
                const SizedBox(height: 12),

                // Overdue
                if (overdue.isNotEmpty) ...[
                  Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: AppColors.dangerLight, borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.danger.withOpacity(0.25))),
                    child: Row(children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 18), const SizedBox(width: 8),
                      Text('${overdue.length} task(s) overdue!',
                          style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600, fontSize: 13)),
                    ])).animate().shakeX(hz: 2),
                  const SizedBox(height: 10),
                ],

                // Filter chips
                SizedBox(height: 34, child: ListView(scrollDirection: Axis.horizontal, children: [
                  'All', 'Today', 'Overdue', ...TaskCategory.values.map((c) => c.label)
                ].map((f) => Padding(padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(label: Text(f, style: TextStyle(
                      fontSize: 12,
                      color: _filter == f ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: _filter == f ? FontWeight.w600 : FontWeight.normal)),
                    selected: _filter == f,
                    selectedColor: AppColors.primaryLight,
                    backgroundColor: AppColors.surface,
                    side: BorderSide(color: _filter == f ? AppColors.primary.withOpacity(0.3) : AppColors.divider),
                    onSelected: (_) => setState(() => _filter = f),
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ))).toList())),
                const SizedBox(height: 10),

                // Sort
                Row(children: [
                  Text('${filtered.length} tasks',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimary)),
                  const Spacer(),
                  CupertinoButton(padding: EdgeInsets.zero, onPressed: () => _showSortSheet(context),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.sort_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(_sort, style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                    ])),
                ]),
              ]),
            )),

            // Task list
            snap.connectionState == ConnectionState.waiting
                ? const SliverToBoxAdapter(child: Center(child: Padding(
                    padding: EdgeInsets.all(40), child: CupertinoActivityIndicator())))
                : filtered.isEmpty
                    ? SliverToBoxAdapter(child: _Empty(_filter))
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                        sliver: SliverList(delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            final t = filtered[i];
                            return Padding(padding: const EdgeInsets.only(bottom: 10),
                              child: _TaskCard(task: t,
                                onTap: () async {
                                  await Navigator.push(context,
                                      CupertinoPageRoute(builder: (_) => TaskDetailScreen(task: t)));
                                  if (mounted) setState(() {});
                                },
                                onToggle: () async {
                                  await context.read<TaskService>().updateTaskStatus(t);
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(!t.isCompleted ? '✅ Task completed!' : 'Task reopened'),
                                    backgroundColor: AppColors.success,
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 2),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
                                },
                                onDelete: () => _confirmDelete(context, t),
                              ).animate().fadeIn(delay: Duration(milliseconds: i * 50)),
                            );
                          }, childCount: filtered.length))),
          ]);
        },
      )),
    );
  }

  void _showSortSheet(BuildContext context) {
    showCupertinoModalPopup(context: context, builder: (ctx) => CupertinoActionSheet(
      title: const Text('Sort Tasks'),
      actions: ['Smart', 'Deadline', 'Priority'].map((s) => CupertinoActionSheetAction(
        onPressed: () { setState(() => _sort = s); Navigator.pop(ctx); },
        isDefaultAction: _sort == s,
        child: Text(s))).toList(),
      cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
    ));
  }

  Future<void> _confirmDelete(BuildContext context, TaskModel t) async {
    final ok = await showCupertinoDialog<bool>(context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Delete Task'),
        content: Text('Delete "${t.title}"? This cannot be undone.'),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          CupertinoDialogAction(isDestructiveAction: true, onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ]));
    if (ok != true || !mounted) return;
    await context.read<TaskService>().deleteTask(t);
    await context.read<NotificationService>().cancelTaskReminders(t.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Task deleted'), behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2)));
  }
}

// ─── Task Card ─────────────────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  final TaskModel task; final VoidCallback onTap, onToggle, onDelete;
  const _TaskCard({required this.task, required this.onTap, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final prog = task.subtaskProgress;
    return GestureDetector(onTap: onTap, child: Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: task.isOverdue ? AppColors.danger.withOpacity(0.25) : AppColors.divider),
        boxShadow: [BoxShadow(color: task.priority.color.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 3, height: 56,
              decoration: BoxDecoration(color: task.priority.color, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: task.category.color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(task.category.icon, size: 10, color: task.category.color), const SizedBox(width: 3),
                  Text(task.category.label, style: TextStyle(fontSize: 10, color: task.category.color, fontWeight: FontWeight.w600)),
                ])),
              const Spacer(),
              if (task.isOverdue)
                _Badge('OVERDUE', AppColors.danger, AppColors.dangerLight)
              else if (task.isDueToday)
                _Badge('TODAY', AppColors.warning, AppColors.warningLight),
              if (task.location != null) ...[
                const SizedBox(width: 4),
                const Icon(Icons.location_on_rounded, size: 13, color: AppColors.primary),
              ],
            ]),
            const SizedBox(height: 5),
            Text(task.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    color: task.isCompleted ? AppColors.textHint : AppColors.textPrimary)),
            const SizedBox(height: 3),
            Row(children: [
              const Icon(Icons.schedule_rounded, size: 11, color: AppColors.textHint), const SizedBox(width: 3),
              Text(DateFormat('MMM d, h:mm a').format(task.deadline),
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              if (task.gradeWeight > 0) ...[
                const SizedBox(width: 8),
                const Icon(Icons.grade_rounded, size: 11, color: AppColors.textHint), const SizedBox(width: 3),
                Text('${task.gradeWeight}%', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ]),
          ])),
          const SizedBox(width: 10),
          Column(children: [
            GestureDetector(onTap: onToggle,
              child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                width: 24, height: 24,
                decoration: BoxDecoration(
                    color: task.isCompleted ? AppColors.success : Colors.transparent,
                    border: Border.all(color: task.isCompleted ? AppColors.success : AppColors.divider, width: 2),
                    borderRadius: BorderRadius.circular(7)),
                child: task.isCompleted
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 14) : null)),
            const SizedBox(height: 8),
            GestureDetector(onTap: onDelete,
                child: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.textHint)),
          ]),
        ])),
        if (task.subtasks.isNotEmpty)
          Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 10), child: Column(children: [
            Row(children: [
              Text('${task.subtasks.where((s) => s.isDone).length}/${task.subtasks.length} steps',
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              const Spacer(),
              Text('${(prog * 100).toInt()}%',
                  style: TextStyle(fontSize: 10, color: task.priority.color, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 4),
            LinearPercentIndicator(lineHeight: 4, percent: prog.clamp(0.0, 1.0),
                progressColor: task.priority.color, backgroundColor: AppColors.divider,
                padding: EdgeInsets.zero, barRadius: const Radius.circular(4)),
          ])),
      ])));
  }
}

class _Badge extends StatelessWidget {
  final String t; final Color fg, bg;
  const _Badge(this.t, this.fg, this.bg);
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(t, style: TextStyle(fontSize: 9, color: fg, fontWeight: FontWeight.bold, letterSpacing: 0.3)));
}

class _StatPill extends StatelessWidget {
  final String label, value; final Color color;
  const _StatPill(this.label, this.value, this.color);
  @override Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ])));
}

class _Empty extends StatelessWidget {
  final String filter; const _Empty(this.filter);
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(40),
    child: Column(children: [
      const Icon(Icons.check_circle_outline_rounded, size: 56, color: AppColors.primaryLight),
      const SizedBox(height: 12),
      Text(filter == 'All' ? 'No tasks yet!' : 'No $filter tasks',
          style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 6),
      Text(filter == 'All' ? 'Tap + to create your first task' : 'Tasks will appear here',
          style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
    ]));
}

// ─── Bottom Bar ─────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final int idx; final ValueChanged<int> onTap;
  const _BottomBar({required this.idx, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.5))),
    child: SafeArea(top: false, child: SizedBox(height: 56,
      child: Row(children: [
        _tab(0, Icons.home_rounded, 'Home'),
        _tab(1, Icons.calendar_month_rounded, 'Calendar'),
        // FAB gap
        const Expanded(child: SizedBox()),
        _tab(2, Icons.timer_rounded, 'Focus'),
        _tab(3, Icons.person_rounded, 'Profile'),
      ]))),
  );

  Widget _tab(int i, IconData icon, String label) => Expanded(child: CupertinoButton(
    padding: EdgeInsets.zero,
    onPressed: () => onTap(i),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 22, color: idx == i ? AppColors.primary : AppColors.textHint),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 10,
          color: idx == i ? AppColors.primary : AppColors.textHint,
          fontWeight: idx == i ? FontWeight.w600 : FontWeight.normal)),
    ])));
}
