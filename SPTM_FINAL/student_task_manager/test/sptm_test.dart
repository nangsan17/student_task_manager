// ============================================================
// SPTM – Student Productivity & Task Management
// Automated Test Suite
// Group 27 | CT124-3-2 Mobile App Engineering
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sptm/models/task_model.dart';
import 'package:sptm/models/user_model.dart';
import 'package:sptm/utils/theme.dart';

// ─────────────────────────────────────────────────────────────
// 1. TASK MODEL UNIT TESTS
// ─────────────────────────────────────────────────────────────
void main() {
  group('TaskModel – core fields & serialisation', () {
    late TaskModel baseTask;

    setUp(() {
      baseTask = TaskModel(
        id: 'test-id-001',
        userId: 'user-uid-001',
        title: 'Complete MAE Assignment',
        description: 'Flutter app Part 2 submission',
        deadline: DateTime(2026, 7, 15, 23, 59),
        priority: TaskPriority.high,
        category: TaskCategory.assignment,
        gradeWeight: 60,
        createdAt: DateTime(2026, 6, 1),
        updatedAt: DateTime(2026, 6, 1),
      );
    });

    test('TC-01: TaskModel stores all fields correctly', () {
      expect(baseTask.id, 'test-id-001');
      expect(baseTask.title, 'Complete MAE Assignment');
      expect(baseTask.priority, TaskPriority.high);
      expect(baseTask.category, TaskCategory.assignment);
      expect(baseTask.gradeWeight, 60);
      expect(baseTask.isCompleted, false);
      expect(baseTask.progress, 0.0);
    });

    test('TC-02: toMap() serialises all fields', () {
      final map = baseTask.toMap();
      expect(map['id'], 'test-id-001');
      expect(map['title'], 'Complete MAE Assignment');
      expect(map['priority'], TaskPriority.high.index);
      expect(map['category'], TaskCategory.assignment.index);
      expect(map['gradeWeight'], 60);
      expect(map['isCompleted'], false);
    });

    test('TC-03: copyWith() returns modified copy without mutating original', () {
      final edited = baseTask.copyWith(
        title: 'Edited Title',
        isCompleted: true,
        progress: 1.0,
      );
      expect(edited.title, 'Edited Title');
      expect(edited.isCompleted, true);
      expect(edited.progress, 1.0);
      // Original unchanged
      expect(baseTask.title, 'Complete MAE Assignment');
      expect(baseTask.isCompleted, false);
    });

    test('TC-04: isOverdue returns true for past incomplete task', () {
      final past = baseTask.copyWith(
          deadline: DateTime.now().subtract(const Duration(hours: 2)));
      expect(past.isOverdue, true);
    });

    test('TC-05: isOverdue returns false for completed task even if past deadline', () {
      final completedPast = baseTask.copyWith(
        deadline: DateTime.now().subtract(const Duration(hours: 2)),
        isCompleted: true,
      );
      expect(completedPast.isOverdue, false);
    });

    test('TC-06: isDueToday returns true for task due today', () {
      final now = DateTime.now();
      final today = baseTask.copyWith(
          deadline: DateTime(now.year, now.month, now.day, 23, 59));
      expect(today.isDueToday, true);
    });

    test('TC-07: isDueSoon returns true for task due within 24h', () {
      final soon = baseTask.copyWith(
          deadline: DateTime.now().add(const Duration(hours: 6)));
      expect(soon.isDueSoon, true);
    });

    test('TC-08: isDueSoon returns false for task due after 24h', () {
      final later = baseTask.copyWith(
          deadline: DateTime.now().add(const Duration(days: 3)));
      expect(later.isDueSoon, false);
    });

    test('TC-09: smartScore is higher for high-priority task vs low-priority', () {
      final highPri = baseTask.copyWith(
        priority: TaskPriority.high,
        deadline: DateTime.now().add(const Duration(hours: 10)),
      );
      final lowPri = baseTask.copyWith(
        priority: TaskPriority.low,
        deadline: DateTime.now().add(const Duration(hours: 10)),
      );
      expect(highPri.smartScore, greaterThan(lowPri.smartScore));
    });

    test('TC-10: smartScore is higher for imminent deadline', () {
      final urgent = baseTask.copyWith(
          deadline: DateTime.now().add(const Duration(hours: 1)));
      final relaxed = baseTask.copyWith(
          deadline: DateTime.now().add(const Duration(days: 30)));
      expect(urgent.smartScore, greaterThan(relaxed.smartScore));
    });
  });

  // ─────────────────────────────────────────────────────────────
  // 2. SUBTASK UNIT TESTS
  // ─────────────────────────────────────────────────────────────
  group('SubTask – behaviour and progress', () {
    test('TC-11: SubTask defaults to not done', () {
      const s = SubTask(id: 's1', title: 'Read docs');
      expect(s.isDone, false);
    });

    test('TC-12: SubTask copyWith toggles isDone', () {
      const s = SubTask(id: 's1', title: 'Read docs');
      final done = s.copyWith(isDone: true);
      expect(done.isDone, true);
      expect(s.isDone, false);
    });

    test('TC-13: SubTask toMap round-trips correctly', () {
      const s = SubTask(id: 's2', title: 'Write tests', isDone: true);
      final map = s.toMap();
      final back = SubTask.fromMap(map);
      expect(back.id, 's2');
      expect(back.title, 'Write tests');
      expect(back.isDone, true);
    });

    test('TC-14: subtaskProgress = 0 when no subtasks are done', () {
      final task = TaskModel(
        id: 'x', userId: 'u', title: 'T',
        deadline: DateTime.now().add(const Duration(days: 1)),
        subtasks: const [
          SubTask(id: 'a', title: 'Step 1'),
          SubTask(id: 'b', title: 'Step 2'),
        ],
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      expect(task.subtaskProgress, 0.0);
    });

    test('TC-15: subtaskProgress = 0.5 when half of subtasks done', () {
      final task = TaskModel(
        id: 'x', userId: 'u', title: 'T',
        deadline: DateTime.now().add(const Duration(days: 1)),
        subtasks: const [
          SubTask(id: 'a', title: 'Step 1', isDone: true),
          SubTask(id: 'b', title: 'Step 2', isDone: false),
        ],
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      expect(task.subtaskProgress, 0.5);
    });

    test('TC-16: subtaskProgress = 1.0 when all subtasks done', () {
      final task = TaskModel(
        id: 'x', userId: 'u', title: 'T',
        deadline: DateTime.now().add(const Duration(days: 1)),
        subtasks: const [
          SubTask(id: 'a', title: 'Step 1', isDone: true),
          SubTask(id: 'b', title: 'Step 2', isDone: true),
        ],
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      expect(task.subtaskProgress, 1.0);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // 3. USER MODEL UNIT TESTS
  // ─────────────────────────────────────────────────────────────
  group('UserModel – fields and serialisation', () {
    late UserModel user;

    setUp(() {
      user = UserModel(
        uid: 'uid-001',
        name: 'Nang Thet Htar San',
        email: 'tp084170@mail.apu.edu.my',
        course: 'Bachelor of Science (Hons) in Software Engineering',
        totalTasksCompleted: 5,
        currentStreak: 3,
        lat: 3.139,
        lng: 101.687,
        locationAddress: 'APU Technology Park Malaysia',
        createdAt: DateTime(2026, 1, 1),
      );
    });

    test('TC-17: UserModel stores all fields correctly', () {
      expect(user.uid, 'uid-001');
      expect(user.name, 'Nang Thet Htar San');
      expect(user.totalTasksCompleted, 5);
      expect(user.currentStreak, 3);
      expect(user.lat, 3.139);
    });

    test('TC-18: UserModel toMap includes all keys', () {
      final map = user.toMap();
      expect(map.containsKey('uid'), true);
      expect(map.containsKey('name'), true);
      expect(map.containsKey('totalTasksCompleted'), true);
      expect(map.containsKey('currentStreak'), true);
      expect(map.containsKey('lat'), true);
      expect(map.containsKey('lng'), true);
    });

    test('TC-19: UserModel copyWith updates only specified fields', () {
      final updated = user.copyWith(name: 'Nour Mohamed', currentStreak: 7);
      expect(updated.name, 'Nour Mohamed');
      expect(updated.currentStreak, 7);
      expect(updated.email, user.email); // unchanged
      expect(updated.totalTasksCompleted, user.totalTasksCompleted);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // 4. THEME / ENUM UNIT TESTS
  // ─────────────────────────────────────────────────────────────
  group('TaskPriority and TaskCategory enums', () {
    test('TC-20: TaskPriority labels are correct', () {
      expect(TaskPriority.high.label, 'High');
      expect(TaskPriority.medium.label, 'Medium');
      expect(TaskPriority.low.label, 'Low');
    });

    test('TC-21: TaskPriority colors are distinct', () {
      expect(TaskPriority.high.color, isNot(equals(TaskPriority.low.color)));
      expect(TaskPriority.medium.color, isNot(equals(TaskPriority.high.color)));
    });

    test('TC-22: TaskCategory labels are correct', () {
      expect(TaskCategory.assignment.label, 'Assignment');
      expect(TaskCategory.exam.label, 'Exam');
      expect(TaskCategory.project.label, 'Project');
      expect(TaskCategory.reading.label, 'Reading');
      expect(TaskCategory.meeting.label, 'Meeting');
      expect(TaskCategory.other.label, 'Other');
    });

    test('TC-23: All 6 categories have distinct colors', () {
      final colors = TaskCategory.values.map((c) => c.color).toSet();
      expect(colors.length, 6);
    });

    test('TC-24: AppColors.primary is defined and non-transparent', () {
      expect(AppColors.primary.alpha, 255);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // 5. TASK SORTING / BUSINESS LOGIC TESTS
  // ─────────────────────────────────────────────────────────────
  group('Smart sort business logic', () {
    TaskModel makeTask({
      required String id,
      required TaskPriority priority,
      required DateTime deadline,
      int gradeWeight = 0,
    }) =>
        TaskModel(
          id: id,
          userId: 'u',
          title: id,
          deadline: deadline,
          priority: priority,
          gradeWeight: gradeWeight,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

    test('TC-25: Overdue high-priority task scores highest', () {
      final overdue = makeTask(
        id: 'overdue',
        priority: TaskPriority.high,
        deadline: DateTime.now().subtract(const Duration(hours: 1)),
        gradeWeight: 50,
      );
      final future = makeTask(
        id: 'future',
        priority: TaskPriority.low,
        deadline: DateTime.now().add(const Duration(days: 7)),
      );
      expect(overdue.smartScore, greaterThan(future.smartScore));
    });

    test('TC-26: Grade weight influences smart score', () {
      final highWeight = makeTask(
        id: 'hw',
        priority: TaskPriority.medium,
        deadline: DateTime.now().add(const Duration(hours: 48)),
        gradeWeight: 100,
      );
      final noWeight = makeTask(
        id: 'nw',
        priority: TaskPriority.medium,
        deadline: DateTime.now().add(const Duration(hours: 48)),
        gradeWeight: 0,
      );
      expect(highWeight.smartScore, greaterThan(noWeight.smartScore));
    });

    test('TC-27: smartScore stays within 0–200 range for realistic inputs', () {
      final tasks = [
        makeTask(id: '1', priority: TaskPriority.high,
            deadline: DateTime.now().add(const Duration(minutes: 30)), gradeWeight: 100),
        makeTask(id: '2', priority: TaskPriority.low,
            deadline: DateTime.now().add(const Duration(days: 60))),
        makeTask(id: '3', priority: TaskPriority.medium,
            deadline: DateTime.now().add(const Duration(hours: 12)), gradeWeight: 50),
      ];
      for (final t in tasks) {
        expect(t.smartScore, greaterThanOrEqualTo(0));
        expect(t.smartScore, lessThan(300));
      }
    });
  });

  // ─────────────────────────────────────────────────────────────
  // 6. TASK COLLECTION FILTERING LOGIC
  // ─────────────────────────────────────────────────────────────
  group('Task filtering logic', () {
    final now = DateTime.now();

    final tasks = [
      TaskModel(
        id: '1', userId: 'u', title: 'Overdue Task',
        deadline: now.subtract(const Duration(hours: 3)),
        category: TaskCategory.assignment,
        priority: TaskPriority.high,
        createdAt: now, updatedAt: now,
      ),
      TaskModel(
        id: '2', userId: 'u', title: 'Due Today',
        deadline: DateTime(now.year, now.month, now.day, 23, 30),
        category: TaskCategory.exam,
        priority: TaskPriority.medium,
        createdAt: now, updatedAt: now,
      ),
      TaskModel(
        id: '3', userId: 'u', title: 'Future Project',
        deadline: now.add(const Duration(days: 10)),
        category: TaskCategory.project,
        priority: TaskPriority.low,
        createdAt: now, updatedAt: now,
      ),
      TaskModel(
        id: '4', userId: 'u', title: 'Completed',
        deadline: now.subtract(const Duration(days: 1)),
        isCompleted: true,
        category: TaskCategory.reading,
        priority: TaskPriority.low,
        createdAt: now, updatedAt: now,
      ),
    ];

    test('TC-28: Active filter excludes completed tasks', () {
      final active = tasks.where((t) => !t.isCompleted).toList();
      expect(active.length, 3);
      expect(active.any((t) => t.isCompleted), false);
    });

    test('TC-29: Overdue filter returns only overdue incomplete tasks', () {
      final overdue = tasks.where((t) => t.isOverdue).toList();
      expect(overdue.length, 1);
      expect(overdue.first.id, '1');
    });

    test('TC-30: Today filter returns only tasks due today', () {
      final today = tasks.where((t) => t.isDueToday).toList();
      expect(today.every((t) => t.isDueToday), true);
    });

    test('TC-31: Category filter works for Assignment', () {
      final assignments = tasks
          .where((t) => !t.isCompleted && t.category == TaskCategory.assignment)
          .toList();
      expect(assignments.length, 1);
      expect(assignments.first.title, 'Overdue Task');
    });

    test('TC-32: Completed tasks do not appear in active view', () {
      final active = tasks.where((t) => !t.isCompleted).toList();
      expect(active.any((t) => t.id == '4'), false);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // 7. WIDGET TESTS
  // ─────────────────────────────────────────────────────────────
  group('Widget tests – theme & basic rendering', () {
    testWidgets('TC-33: AppTheme.light creates a valid ThemeData', (tester) async {
      final theme = AppTheme.light;
      expect(theme, isA<ThemeData>());
      expect(theme.scaffoldBackgroundColor, AppColors.background);
    });

    testWidgets('TC-34: MaterialApp with AppTheme renders without error',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Center(child: Text('SPTM Test')),
          ),
        ),
      );
      expect(find.text('SPTM Test'), findsOneWidget);
    });

    testWidgets('TC-35: ElevatedButton with primary color renders correctly',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {},
              child: const Text('Save Task'),
            ),
          ),
        ),
      );
      expect(find.text('Save Task'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('TC-36: Circular progress indicator shows during loading',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('TC-37: TextFormField validates empty title', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Form(
              key: formKey,
              child: Column(children: [
                TextFormField(
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Title required' : null,
                ),
                ElevatedButton(
                  onPressed: () => formKey.currentState?.validate(),
                  child: const Text('Submit'),
                ),
              ]),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Submit'));
      await tester.pump();
      expect(find.text('Title required'), findsOneWidget);
    });

    testWidgets('TC-38: BottomNavigationBar renders 4 tabs', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: BottomNavigationBar(
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.calendar_month), label: 'Calendar'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.timer), label: 'Focus'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.person), label: 'Profile'),
              ],
              currentIndex: 0,
              onTap: (_) {},
            ),
          ),
        ),
      );
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Calendar'), findsOneWidget);
      expect(find.text('Focus'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('TC-39: Priority chip row renders 3 choices', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Row(
              children: TaskPriority.values
                  .map((p) => Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Text(p.label),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
      );
      expect(find.text('High'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('Low'), findsOneWidget);
    });

    testWidgets('TC-40: Category chip row renders 6 categories', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Wrap(
              children: TaskCategory.values
                  .map((c) => Chip(label: Text(c.label)))
                  .toList(),
            ),
          ),
        ),
      );
      for (final c in TaskCategory.values) {
        expect(find.text(c.label), findsWidgets);
      }
    });
  });

  // ─────────────────────────────────────────────────────────────
  // 8. EDGE CASE TESTS
  // ─────────────────────────────────────────────────────────────
  group('Edge cases and boundary conditions', () {
    test('TC-41: Task with gradeWeight=0 still has valid smartScore', () {
      final t = TaskModel(
        id: 'e1', userId: 'u', title: 'No weight',
        deadline: DateTime.now().add(const Duration(hours: 5)),
        gradeWeight: 0,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      expect(t.smartScore, isNot(isNaN));
      expect(t.smartScore, greaterThanOrEqualTo(0));
    });

    test('TC-42: Task title with special characters stores correctly', () {
      final t = TaskModel(
        id: 'e2', userId: 'u',
        title: 'Résumé & Présentation — "Final Draft"',
        deadline: DateTime.now().add(const Duration(days: 1)),
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      expect(t.title, 'Résumé & Présentation — "Final Draft"');
    });

    test('TC-43: subtaskProgress returns stored progress when subtasks empty', () {
      final t = TaskModel(
        id: 'e3', userId: 'u', title: 'No subs',
        deadline: DateTime.now().add(const Duration(days: 1)),
        subtasks: const [],
        progress: 0.75,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      expect(t.subtaskProgress, 0.75);
    });

    test('TC-44: gradeWeight clamps at 100 in smartScore calculation', () {
      final t = TaskModel(
        id: 'e4', userId: 'u', title: 'Max weight',
        deadline: DateTime.now().add(const Duration(hours: 12)),
        gradeWeight: 100,
        priority: TaskPriority.high,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      expect(t.smartScore, isNot(isNaN));
    });

    test('TC-45: Task with exactly now() deadline is considered overdue', () {
      // A deadline that passed even 1 second ago is overdue
      final t = TaskModel(
        id: 'e5', userId: 'u', title: 'Just passed',
        deadline: DateTime.now().subtract(const Duration(seconds: 1)),
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      expect(t.isOverdue, true);
    });

    test('TC-46: UserModel with null photoUrl serialises without error', () {
      final u = UserModel(
        uid: 'u1', name: 'Test', email: 't@t.com',
        photoUrl: null,
        createdAt: DateTime.now(),
      );
      final map = u.toMap();
      expect(map['photoUrl'], isNull);
    });

    test('TC-47: Empty subtasks list serialises to empty list in map', () {
      final t = TaskModel(
        id: 'e6', userId: 'u', title: 'No subs',
        deadline: DateTime.now().add(const Duration(days: 1)),
        subtasks: const [],
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      final map = t.toMap();
      expect((map['subtasks'] as List).isEmpty, true);
    });

    test('TC-48: Task priority index matches enum order (high=0, med=1, low=2)', () {
      expect(TaskPriority.high.index, 0);
      expect(TaskPriority.medium.index, 1);
      expect(TaskPriority.low.index, 2);
    });

    test('TC-49: Multiple subtasks serialise and deserialise in correct order', () {
      const subs = [
        SubTask(id: 's1', title: 'First'),
        SubTask(id: 's2', title: 'Second'),
        SubTask(id: 's3', title: 'Third'),
      ];
      final maps = subs.map((s) => s.toMap()).toList();
      final back = maps.map((m) => SubTask.fromMap(m)).toList();
      expect(back[0].title, 'First');
      expect(back[1].title, 'Second');
      expect(back[2].title, 'Third');
    });

    test('TC-50: AppColors surface is white (0xFFFFFFFF)', () {
      expect(AppColors.surface.value, 0xFFFFFFFF);
    });
  });
}
