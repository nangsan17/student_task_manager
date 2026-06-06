import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/task_service.dart';
import '../../services/notification_service.dart';
import '../../utils/theme.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel? user;
  final ValueChanged<UserModel> onUpdated;
  const ProfileScreen({super.key, required this.user, required this.onUpdated});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserModel _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user ?? UserModel(
        uid: '', name: 'Student', email: '', createdAt: DateTime.now());
  }

  Future<void> _showEditDialog() async {
    final nameCtrl = TextEditingController(text: _currentUser.name);
    final courseCtrl = TextEditingController(text: _currentUser.course);

    await showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Edit Profile'),
            content: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  CupertinoTextField(
                      controller: nameCtrl,
                      placeholder: 'Full Name',
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          border: Border.all(color: AppColors.divider),
                          borderRadius: BorderRadius.circular(8))),
                  const SizedBox(height: 12),
                  CupertinoTextField(
                      controller: courseCtrl,
                      placeholder: 'Course / Program',
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          border: Border.all(color: AppColors.divider),
                          borderRadius: BorderRadius.circular(8))),
                ])),
            actions: [
              CupertinoDialogAction(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () async {
                    final updated = _currentUser.copyWith(
                        name: nameCtrl.text.trim() != ''
                            ? nameCtrl.text.trim()
                            : _currentUser.name,
                        course: courseCtrl.text.trim());
                    Navigator.pop(ctx);
                    widget.onUpdated(updated);
                    setState(() => _currentUser = updated);
                  },
                  child: const Text('Save')),
            ]));
  }

  Future<void> _pickAndUploadPhoto() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('📸 Photo selected!'), duration: Duration(seconds: 1)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking photo: $e'), backgroundColor: AppColors.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthService>().currentUserId ?? '';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
          title: const Text('Profile'),
          actions: [
            CupertinoButton(
                padding: const EdgeInsets.only(right: 12),
                onPressed: () async {
                  final ok = await showCupertinoDialog<bool>(
                      context: context,
                      builder: (ctx) => CupertinoAlertDialog(
                              title: const Text('Sign Out'),
                              content: const Text(
                                  'Are you sure you want to sign out?'),
                              actions: [
                                CupertinoDialogAction(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel')),
                                CupertinoDialogAction(
                                    isDestructiveAction: true,
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Sign Out')),
                              ]));
                  if (ok != true || !context.mounted) return;
                  await context.read<AuthService>().logout();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                      PageRouteBuilder(
                          pageBuilder: (_, __, ___) => const LoginScreen(),
                          transitionDuration: Duration.zero),
                      (_) => false);
                },
                child: const Text('Sign Out',
                    style: TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                        fontSize: 14))),
          ]),
      body: StreamBuilder<List<TaskModel>>(
          stream: context.read<TaskService>().getTasks(uid),
          builder: (ctx, snap) {
            final tasks = snap.data ?? [];
            final completed = tasks.where((t) => t.isCompleted).length;
            final active = tasks.where((t) => !t.isCompleted).length;
            final overdue = tasks.where((t) => t.isOverdue).length;
            final rate = tasks.isEmpty ? 0.0 : completed / tasks.length;
            final Map<TaskCategory, int> cats = {};
            for (final t in tasks)
              cats[t.category] = (cats[t.category] ?? 0) + 1;

            return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(color: Color(0x0A000000), blurRadius: 8)
                          ]),
                      child: Column(children: [
                        Stack(children: [
                          CircleAvatar(
                              radius: 36,
                              backgroundColor: AppColors.primaryLight,
                              backgroundImage: _currentUser.photoUrl != null
                                  ? NetworkImage(_currentUser.photoUrl!)
                                  : null,
                              child: _currentUser.photoUrl == null
                                  ? Text(
                                      _currentUser.name.isNotEmpty
                                          ? _currentUser.name[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary))
                                  : null),
                          Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                  onTap: _pickAndUploadPhoto,
                                  child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.2),
                                                blurRadius: 4)
                                          ]),
                                      child: const Icon(Icons.camera_alt_rounded,
                                          size: 14, color: Colors.white))))
                        ]),
                        const SizedBox(height: 10),
                        Text(_currentUser.name,
                            style: Theme.of(ctx).textTheme.titleLarge),
                        const SizedBox(height: 2),
                        Text(_currentUser.email,
                            style: Theme.of(ctx).textTheme.bodyMedium),
                        if (_currentUser.course.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(20)),
                              child: Text(_currentUser.course,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600),
                                  textAlign: TextAlign.center)),
                        ],
                        const SizedBox(height: 12),
                        GestureDetector(
                            onTap: _showEditDialog,
                            child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 8),
                                decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(20)),
                                child: const Row(mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.edit_rounded,
                                          size: 14, color: Colors.white),
                                      SizedBox(width: 6),
                                      Text('Edit Profile',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12))
                                    ])))
                      ])),
                  const SizedBox(height: 16),

                  Row(children: [
                    _Stat('Total', '${tasks.length}', AppColors.primary,
                        Icons.list_alt_rounded),
                    const SizedBox(width: 10),
                    _Stat('Done', '$completed', AppColors.success,
                        Icons.check_circle_rounded),
                    const SizedBox(width: 10),
                    _Stat('Active', '$active', AppColors.warning,
                        Icons.pending_rounded),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    _Stat('Overdue', '$overdue', AppColors.danger,
                        Icons.warning_rounded),
                    const SizedBox(width: 10),
                    _Stat('Rate', '${(rate * 100).toInt()}%', AppColors.primary,
                        Icons.trending_up_rounded),
                    const SizedBox(width: 10),
                    const Expanded(child: SizedBox.shrink()),
                  ]),
                  const SizedBox(height: 16),

                  Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16)),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Text('Completion Rate',
                                  style: Theme.of(ctx).textTheme.titleMedium),
                              const Spacer(),
                              Text('${(rate * 100).toInt()}%',
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary)),
                            ]),
                            const SizedBox(height: 12),
                            ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                    value: rate.clamp(0.0, 1.0),
                                    minHeight: 10,
                                    backgroundColor: AppColors.divider,
                                    color: AppColors.primary)),
                            const SizedBox(height: 8),
                            Text(
                                '$completed of ${tasks.length} tasks completed',
                                style: Theme.of(ctx).textTheme.bodyMedium),
                          ])),
                  const SizedBox(height: 16),

                  if (cats.isNotEmpty)
                    Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16)),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tasks by Category',
                                  style: Theme.of(ctx).textTheme.titleMedium),
                              const SizedBox(height: 16),
                              SizedBox(
                                  height: 150,
                                  child: PieChart(PieChartData(
                                      sections: cats.entries
                                          .map((e) => PieChartSectionData(
                                              value: e.value.toDouble(),
                                              color: e.key.color,
                                              title: '${e.value}',
                                              radius: 48,
                                              titleStyle: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white)))
                                          .toList(),
                                      centerSpaceRadius: 36,
                                      sectionsSpace: 2))),
                              const SizedBox(height: 12),
                              Wrap(
                                  spacing: 12,
                                  runSpacing: 6,
                                  children: cats.entries
                                      .map((e) => Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: BoxDecoration(
                                                        color: e.key.color,
                                                        shape:
                                                            BoxShape.circle)),
                                                const SizedBox(width: 5),
                                                Text(
                                                    '${e.key.label} (${e.value})',
                                                    style: const TextStyle(
                                                        fontSize: 11,
                                                        color: AppColors
                                                            .textSecondary)),
                                              ]))
                                      .toList()),
                            ])),
                    const SizedBox(height: 20),
                  Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.primary.withOpacity(0.3))),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(children: [
                              Icon(Icons.notifications_rounded,
                                  color: AppColors.primary, size: 18),
                              SizedBox(width: 8),
                              Text('Test Notifications',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary)),
                            ]),
                            const SizedBox(height: 10),
                            const Text(
                                'Tap button to test notification sound and vibration.',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                            const SizedBox(height: 10),
                            CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () async {
                                  await context
                                      .read<NotificationService>()
                                      .showTestNotification();
                                  if (mounted)
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                            content: Text(
                                                '✓ Test notification sent!')));
                                },
                                child: Container(
                                    width: double.infinity,
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: const Text('Send Test Now',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13))))
                          ])),
                  const SizedBox(height: 16),
                ]));
          }),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _Stat(this.label, this.value, this.color, this.icon);
  @override
  Widget build(BuildContext context) => Expanded(
      child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider)),
          child: Column(children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500))
          ])));
}

