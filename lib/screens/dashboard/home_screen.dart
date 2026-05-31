import 'package:flutter/material.dart';
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
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const TaskFormScreen()));
                if (mounted) setState(() {});
              },
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('New Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomNav(idx: _idx, onTap: (i) => setState(() => _idx = i)),
    );
  }
}

// ─── Dashboard Tab ────────────────────────────────────────────────────────────

class _DashboardTab extends StatefulWidget {
  final UserModel? user;
  final String uid;
  const _DashboardTab({required this.user, required this.uid});
  @override State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  String _filter = 'All';
  String _sort   = 'Smart';

  @override
  Widget build(BuildContext context) {
    final svc = context.read<TaskService>();
    final name = widget.user?.name.split(' ').first ?? 'Student';
    final h    = DateTime.now().hour;
    final greeting = h < 12 ? 'Good morning' : h < 17 ? 'Good afternoon' : 'Good evening';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: StreamBuilder<List<TaskModel>>(
        stream: svc.getTasks(widget.uid),
        builder: (context, snap) {
          final all       = snap.data ?? [];
          final active    = all.where((t) => !t.isCompleted).toList();
          final done      = all.where((t) =>  t.isCompleted).toList();
          final overdue   = active.where((t) => t.isOverdue).toList();
          final today     = active.where((t) => t.isDueToday).toList();

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
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Greeting
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('$greeting,', style: Theme.of(context).textTheme.bodyMedium),
                    Text(name, style: Theme.of(context).textTheme.headlineMedium),
                  ])),
                  CircleAvatar(radius: 22, backgroundColor: AppColors.primaryLight,
                    child: Text(name[0].toUpperCase(),
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18))),
                ]),
                const SizedBox(height: 20),

                // Stat cards
                Row(children: [
                  _StatCard('Active', '${active.length}', AppColors.primary,   Icons.pending_actions_rounded),
                  const SizedBox(width: 12),
                  _StatCard('Today',  '${today.length}',  AppColors.warning,   Icons.today_rounded),
                  const SizedBox(width: 12),
                  _StatCard('Done',   '${done.length}',   AppColors.success,   Icons.check_circle_rounded),
                ]),
                const SizedBox(height: 16),

                // Overdue warning
                if (overdue.isNotEmpty)
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.dangerLight, borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.danger.withOpacity(0.3))),
                    child: Row(children: [
                      const Icon(Icons.warning_rounded, color: AppColors.danger, size: 20), const SizedBox(width: 8),
                      Text('${overdue.length} task(s) overdue!',
                          style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600, fontSize: 13)),
                    ]),
                  ).animate().shakeX(hz: 2),

                if (overdue.isNotEmpty) const SizedBox(height: 12),

                // Filter chips
                SizedBox(height: 38, child: ListView(scrollDirection: Axis.horizontal,
                  children: ['All', 'Today', 'Overdue', ...TaskCategory.values.map((c) => c.label)]
                      .map((f) => Padding(padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(label: Text(f), selected: _filter == f,
                          onSelected: (_) => setState(() => _filter = f),
                          selectedColor: AppColors.primaryLight, checkmarkColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: _filter == f ? AppColors.primary : AppColors.textSecondary,
                            fontWeight: _filter == f ? FontWeight.w600 : FontWeight.normal, fontSize: 12),
                        ))).toList(),
                )),
                const SizedBox(height: 12),

                // Sort row
                Row(children: [
                  Text('${filtered.length} tasks', style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  const Text('Sort: ', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  DropdownButton<String>(value: _sort, underline: const SizedBox(),
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                    items: ['Smart', 'Deadline', 'Priority']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => _sort = v!)),
                ]),
                const SizedBox(height: 4),
              ]),
            )),

            // Task list
            if (snap.connectionState == ConnectionState.waiting)
              const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())))
            else if (filtered.isEmpty)
              SliverToBoxAdapter(child: _EmptyState(_filter))
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList(delegate: SliverChildBuilderDelegate(
                  (ctx, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TaskCard(
                      task: filtered[i],
                      onTap: () async {
                        await Navigator.push(context,
                            MaterialPageRoute(builder: (_) => TaskDetailScreen(task: filtered[i])));
                        if (mounted) setState(() {});
                      },
                      onToggle: () async {
                        await context.read<TaskService>().updateTaskStatus(filtered[i]);
                        if (!mounted) return;
                        final label = !filtered[i].isCompleted ? 'completed' : 'reopened';
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Task $label!'), backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating));
                      },
                      onDelete: () async {
                        final ok = await showDialog<bool>(context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: const Text('Delete Task'),
                            content: Text('Delete "${filtered[i].title}"?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              ElevatedButton(onPressed: () => Navigator.pop(ctx, true),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                                  child: const Text('Delete')),
                            ],
                          ));
                        if (ok != true || !mounted) return;
                        await context.read<TaskService>().deleteTask(filtered[i]);
                        await context.read<NotificationService>().cancelTaskReminders(filtered[i].id);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Task deleted'), behavior: SnackBarBehavior.floating));
                      },
                    ).animate().fadeIn(delay: Duration(milliseconds: i * 60)),
                  ),
                  childCount: filtered.length,
                )),
              ),
          ]);
        },
      )),
    );
  }
}

// ─── Task Card ────────────────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onTap, onToggle, onDelete;
  const _TaskCard({required this.task, required this.onTap, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final prog = task.subtaskProgress;
    return GestureDetector(onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: task.isOverdue ? AppColors.danger.withOpacity(0.3) : AppColors.divider),
          boxShadow: [BoxShadow(color: task.priority.color.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(children: [
          Padding(padding: const EdgeInsets.all(14), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Priority bar
            Container(width: 4, height: 60,
                decoration: BoxDecoration(color: task.priority.color, borderRadius: BorderRadius.circular(4))),
            const SizedBox(width: 12),
            // Content
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: task.category.color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(task.category.icon, size: 11, color: task.category.color), const SizedBox(width: 4),
                    Text(task.category.label, style: TextStyle(fontSize: 11, color: task.category.color, fontWeight: FontWeight.w600)),
                  ])),
                const Spacer(),
                if (task.isOverdue)
                  _Badge('OVERDUE', AppColors.danger, AppColors.dangerLight)
                else if (task.isDueToday)
                  _Badge('TODAY', AppColors.warning, AppColors.warningLight),
              ]),
              const SizedBox(height: 6),
              Text(task.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    color: task.isCompleted ? AppColors.textHint : AppColors.textPrimary)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.schedule_rounded, size: 13, color: AppColors.textHint), const SizedBox(width: 4),
                Text(DateFormat('MMM d, h:mm a').format(task.deadline),
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                if (task.gradeWeight > 0) ...[
                  const SizedBox(width: 10),
                  const Icon(Icons.grade_rounded, size: 13, color: AppColors.textHint), const SizedBox(width: 4),
                  Text('${task.gradeWeight}%', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ]),
            ])),
            // Actions
            Column(children: [
              GestureDetector(onTap: onToggle,
                child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    color: task.isCompleted ? AppColors.success : Colors.transparent,
                    border: Border.all(color: task.isCompleted ? AppColors.success : AppColors.textHint, width: 2),
                    borderRadius: BorderRadius.circular(8)),
                  child: task.isCompleted ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null)),
              const SizedBox(height: 8),
              GestureDetector(onTap: onDelete,
                  child: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.textHint)),
            ]),
          ])),
          if (task.subtasks.isNotEmpty)
            Padding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 12), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text('${task.subtasks.where((s) => s.isDone).length}/${task.subtasks.length} subtasks',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  const Spacer(),
                  Text('${(prog * 100).toInt()}%',
                      style: TextStyle(fontSize: 11, color: task.priority.color, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 6),
                LinearPercentIndicator(lineHeight: 5, percent: prog.clamp(0.0, 1.0),
                    progressColor: task.priority.color, backgroundColor: AppColors.divider,
                    padding: EdgeInsets.zero, barRadius: const Radius.circular(4)),
              ],
            )),
        ]),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text; final Color textColor, bgColor;
  const _Badge(this.text, this.textColor, this.bgColor);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: TextStyle(fontSize: 10, color: textColor, fontWeight: FontWeight.bold)),
  );
}

class _StatCard extends StatelessWidget {
  final String label, value; final Color color; final IconData icon;
  const _StatCard(this.label, this.value, this.color, this.icon);
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 20), const SizedBox(height: 6),
      Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ]),
  ));
}

class _EmptyState extends StatelessWidget {
  final String filter; const _EmptyState(this.filter);
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(40),
    child: Column(children: [
      const Icon(Icons.check_circle_outline_rounded, size: 64, color: AppColors.primaryLight),
      const SizedBox(height: 16),
      Text(filter == 'All' ? 'No tasks yet!' : 'No $filter tasks',
          style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      Text(filter == 'All' ? 'Tap + to add your first task' : 'Tasks will appear here',
          style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
    ]),
  );
}

class _BottomNav extends StatelessWidget {
  final int idx; final ValueChanged<int> onTap;
  const _BottomNav({required this.idx, required this.onTap});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: AppColors.surface,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -2))]),
    child: SafeArea(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _NavItem(Icons.home_rounded,             'Home',     idx == 0, () => onTap(0)),
        _NavItem(Icons.calendar_month_rounded,   'Calendar', idx == 1, () => onTap(1)),
        const SizedBox(width: 48),
        _NavItem(Icons.timer_rounded,            'Focus',    idx == 2, () => onTap(2)),
        _NavItem(Icons.person_rounded,           'Profile',  idx == 3, () => onTap(3)),
      ]),
    )),
  );
}

class _NavItem extends StatelessWidget {
  final IconData icon; final String label; final bool selected; final VoidCallback onTap;
  const _NavItem(this.icon, this.label, this.selected, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: AnimatedContainer(duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: selected ? AppColors.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(12)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: selected ? AppColors.primary : AppColors.textHint, size: 22),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10,
            color: selected ? AppColors.primary : AppColors.textHint,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
      ]),
    ),
  );
}
