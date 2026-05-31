import 'package:flutter_test/flutter_test.dart';
import 'package:student_task_manager/utils/theme.dart';
import 'package:student_task_manager/models/task_model.dart';

void main() {
  group('TaskModel', () {
    late TaskModel task;

    setUp(() {
      task = TaskModel(
        id: 'test-id',
        userId: 'user-1',
        title: 'Test Task',
        description: 'A test task',
        deadline: DateTime.now().add(const Duration(hours: 10)),
        priority: TaskPriority.high,
        category: TaskCategory.assignment,
        gradeWeight: 30,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    test('smartScore is calculated correctly', () {
      expect(task.smartScore, greaterThan(0));
      expect(task.smartScore, lessThanOrEqualTo(100));
    });

    test('isOverdue is false for future deadline', () {
      expect(task.isOverdue, isFalse);
    });

    test('isOverdue is true for past deadline', () {
      final overdue = task.copyWith(
        deadline: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(overdue.isOverdue, isTrue);
    });

    test('isDueToday returns true for today deadline', () {
      final today = task.copyWith(deadline: DateTime.now().add(const Duration(hours: 2)));
      expect(today.isDueToday, isTrue);
    });

    test('subtaskProgress returns 0 when no subtasks', () {
      expect(task.subtaskProgress, equals(0.0));
    });

    test('subtaskProgress calculates correctly', () {
      final withSubs = task.copyWith(subtasks: [
        const SubTask(id: '1', title: 'Step 1', isDone: true),
        const SubTask(id: '2', title: 'Step 2', isDone: false),
        const SubTask(id: '3', title: 'Step 3', isDone: true),
      ]);
      expect(withSubs.subtaskProgress, closeTo(0.666, 0.01));
    });

    test('copyWith preserves unchanged fields', () {
      final copy = task.copyWith(title: 'New Title');
      expect(copy.title, equals('New Title'));
      expect(copy.userId, equals(task.userId));
      expect(copy.priority, equals(task.priority));
    });

    test('toMap and fromMap roundtrip', () {
      final map = task.toMap();
      expect(map['title'], equals('Test Task'));
      expect(map['priority'], equals(TaskPriority.high.index));
      expect(map['gradeWeight'], equals(30));
    });

    test('high priority task has higher smartScore than low priority', () {
      final lowPriorityTask = task.copyWith(priority: TaskPriority.low, gradeWeight: 0);
      final highPriorityTask = task.copyWith(priority: TaskPriority.high, gradeWeight: 50);
      expect(highPriorityTask.smartScore, greaterThan(lowPriorityTask.smartScore));
    });
  });

  group('TaskPriority', () {
    test('label returns correct strings', () {
      expect(TaskPriority.high.label,   equals('High'));
      expect(TaskPriority.medium.label, equals('Medium'));
      expect(TaskPriority.low.label,    equals('Low'));
    });

    test('color is not null', () {
      for (final p in TaskPriority.values) {
        expect(p.color, isNotNull);
        expect(p.lightColor, isNotNull);
      }
    });
  });

  group('TaskCategory', () {
    test('label returns correct strings', () {
      expect(TaskCategory.assignment.label, equals('Assignment'));
      expect(TaskCategory.exam.label,       equals('Exam'));
      expect(TaskCategory.project.label,    equals('Project'));
    });

    test('color and icon are defined for all categories', () {
      for (final c in TaskCategory.values) {
        expect(c.color, isNotNull);
        expect(c.icon,  isNotNull);
      }
    });
  });

  group('SubTask', () {
    test('copyWith toggles isDone', () {
      const s = SubTask(id: '1', title: 'Do this');
      final done = s.copyWith(isDone: true);
      expect(done.isDone, isTrue);
      expect(done.title, equals('Do this'));
    });

    test('toMap and fromMap roundtrip', () {
      const s = SubTask(id: 'abc', title: 'Step', isDone: true);
      final map = s.toMap();
      final back = SubTask.fromMap(map);
      expect(back.id, equals('abc'));
      expect(back.isDone, isTrue);
    });
  });
}
