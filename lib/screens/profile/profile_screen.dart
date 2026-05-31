import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/task_service.dart';
import '../../utils/theme.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  final UserModel? user;
  final ValueChanged<UserModel> onUpdated;
  const ProfileScreen({super.key, required this.user, required this.onUpdated});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthService>().currentUserId ?? '';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profile'), actions: [
        IconButton(icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
          onPressed: () async {
            final ok = await showDialog<bool>(context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: const Text('Sign Out'), content: const Text('Are you sure?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  ElevatedButton(onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                      child: const Text('Sign Out')),
                ]));
            if (ok != true || !context.mounted) return;
            await context.read<AuthService>().logout();
            if (!context.mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
          }),
      ]),
      body: StreamBuilder<List<TaskModel>>(
        stream: context.read<TaskService>().getTasks(uid),
        builder: (ctx, snap) {
          final tasks    = snap.data ?? [];
          final completed = tasks.where((t) => t.isCompleted).length;
          final active   = tasks.where((t) => !t.isCompleted).length;
          final overdue  = tasks.where((t) => t.isOverdue).length;
          final rate     = tasks.isEmpty ? 0.0 : completed / tasks.length;
          final Map<TaskCategory, int> cats = {};
          for (final t in tasks) cats[t.category] = (cats[t.category] ?? 0) + 1;

          return SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
            // Avatar
            Container(width: double.infinity, padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
              child: Column(children: [
                CircleAvatar(radius: 40, backgroundColor: AppColors.primaryLight,
                  child: Text(user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary))),
                const SizedBox(height: 12),
                Text(user?.name ?? 'Student', style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(user?.email ?? '', style: Theme.of(ctx).textTheme.bodyMedium),
                if (user?.course.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)),
                    child: Text(user!.course, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center)),
                ],
              ])),
            const SizedBox(height: 20),

            // Stats grid
            Row(children: [
              _Stat('Total',   '${tasks.length}', AppColors.primary,   Icons.list_alt_rounded),
              const SizedBox(width: 12),
              _Stat('Done',    '$completed',       AppColors.success,   Icons.check_circle_rounded),
              const SizedBox(width: 12),
              _Stat('Active',  '$active',          AppColors.warning,   Icons.pending_rounded),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _Stat('Overdue', '$overdue',         AppColors.danger,    Icons.warning_rounded),
              const SizedBox(width: 12),
              _Stat('Streak',  '${user?.currentStreak ?? 0}d', AppColors.accent, Icons.local_fire_department_rounded),
              const SizedBox(width: 12),
              _Stat('Rate',    '${(rate * 100).toInt()}%', AppColors.primary, Icons.trending_up_rounded),
            ]),
            const SizedBox(height: 20),

            // Completion bar
            Container(width: double.infinity, padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Completion Rate', style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: 16),
                Stack(children: [
                  Container(height: 12, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(6))),
                  FractionallySizedBox(widthFactor: rate.clamp(0.0, 1.0),
                    child: Container(height: 12, decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent])))),
                ]),
                const SizedBox(height: 8),
                Text('$completed of ${tasks.length} tasks completed', style: Theme.of(ctx).textTheme.bodyMedium),
              ])),
            const SizedBox(height: 20),

            // Pie chart
            if (cats.isNotEmpty)
              Container(width: double.infinity, padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Tasks by Category', style: Theme.of(ctx).textTheme.titleMedium),
                  const SizedBox(height: 20),
                  SizedBox(height: 160, child: PieChart(PieChartData(
                    sections: cats.entries.map((e) => PieChartSectionData(
                        value: e.value.toDouble(), color: e.key.color, title: '${e.value}',
                        radius: 50, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white))).toList(),
                    centerSpaceRadius: 40, sectionsSpace: 2))),
                  const SizedBox(height: 16),
                  Wrap(spacing: 12, runSpacing: 8, children: cats.entries.map((e) =>
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: e.key.color, shape: BoxShape.circle)),
                        const SizedBox(width: 5),
                        Text('${e.key.label} (${e.value})', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ])).toList()),
                ])),
          ]));
        }),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value; final Color color; final IconData icon;
  const _Stat(this.label, this.value, this.color, this.icon);
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 18), const SizedBox(height: 6),
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ])));
}
