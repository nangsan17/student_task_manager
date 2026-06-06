// Unit tests for the core business logic of the Student Productivity & Task
// Management app. These tests cover the smart-prioritisation algorithm,
// deadline state derivation, sub-task progress, copyWith immutability and
// Firestore (de)serialisation round-trips for TaskModel and SubTask.
//
// Run with:  flutter test test/task_model_test.dart
//
// None of these tests require Firebase to be initialised: TaskModel/SubTask
// are plain Dart classes, and cloud_firestore's Timestamp can be constructed
// directly in the Dart VM used by flutter_test.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sptm/models/task_model.dart';
import 'package:sptm/utils/theme.dart';

TaskModel buildTask({
  String id = 't1',
  String userId = 'u1',
  String title = 'Sample Task',
  DateTime? deadline,
  TaskPriority priority = TaskPriority.medium,
  TaskCategory category = TaskCategory.assignment,
  bool isCompleted = false,
  double progress = 0.0,
  List<SubTask> subtasks = const [],
  int gradeWeight = 0,
}) {
  final now = DateTime.now();
  return TaskModel(
    id: id,
    userId: userId,
    title: title,
    deadline: deadline ?? now.add(const Duration(days: 1)),
    priority: priority,
    category: category,
    isCompleted: isCompleted,
    progress: progress,
    subtasks: subtasks,
    gradeWeight: gradeWeight,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('SubTask', () {
    test('copyWith toggles isDone without mutating the original', () {
      const original = SubTask(id: 's1', title: 'Read chapter', isDone: false);
      final toggled = original.copyWith(isDone: true);

      expect(original.isDone, isFalse, reason: 'original must be unchanged');
      expect(toggled.isDone, isTrue);
      expect(toggled.id, 's1');
      expect(toggled.title, 'Read chapter');
    });

    test('toMap / fromMap round-trip preserves all fields', () {
      const sub = SubTask(id: 's2', title: 'Write intro', isDone: true);
      final restored = SubTask.fromMap(sub.toMap());

      expect(restored.id, sub.id);
      expect(restored.title, sub.title);
      expect(restored.isDone, sub.isDone);
    });

    test('fromMap supplies safe defaults for missing keys', () {
      final restored = SubTask.fromMap(<String, dynamic>{});
      expect(restored.id, '');
      expect(restored.title, '');
      expect(restored.isDone, isFalse);
    });
  });

  group('TaskModel deadline states', () {
    test('isOverdue is true when an incomplete task is past its deadline', () {
      final task = buildTask(
        deadline: DateTime.now().subtract(const Duration(hours: 3)),
      );
      expect(task.isOverdue, isTrue);
    });

    test('a completed task is never overdue', () {
      final task = buildTask(
        deadline: DateTime.now().subtract(const Duration(hours: 3)),
        isCompleted: true,
      );
      expect(task.isOverdue, isFalse);
    });

    test('isDueToday is true for an incomplete task due later today', () {
      final now = DateTime.now();
      // 23:59 today (guaranteed same calendar day, avoids midnight flakiness).
      final endOfToday = DateTime(now.year, now.month, now.day, 23, 59);
      final task = buildTask(deadline: endOfToday);
      expect(task.isDueToday, isTrue);
    });

    test('isDueSoon is true within the next 24 hours but not beyond', () {
      final soon = buildTask(
        deadline: DateTime.now().add(const Duration(hours: 5)),
      );
      final later = buildTask(
        deadline: DateTime.now().add(const Duration(days: 3)),
      );
      expect(soon.isDueSoon, isTrue);
      expect(later.isDueSoon, isFalse);
    });
  });

  group('TaskModel.smartScore (smart prioritisation)', () {
    test('an overdue task scores the maximum urgency component', () {
      final overdue = buildTask(
        deadline: DateTime.now().subtract(const Duration(hours: 1)),
        priority: TaskPriority.high,
        gradeWeight: 100,
      );
      // urgency 100*0.5 + priority (high=2 -> 60)*0.3 + weight 100*0.2 = 88.
      expect(overdue.smartScore, closeTo(88.0, 0.5));
    });

    test('a sooner deadline outranks a later one, all else equal', () {
      final sooner = buildTask(
        deadline: DateTime.now().add(const Duration(hours: 2)),
        priority: TaskPriority.medium,
        gradeWeight: 0,
      );
      final later = buildTask(
        deadline: DateTime.now().add(const Duration(days: 7)),
        priority: TaskPriority.medium,
        gradeWeight: 0,
      );
      expect(sooner.smartScore, greaterThan(later.smartScore));
    });

    test('higher priority outranks lower priority for the same deadline', () {
      final deadline = DateTime.now().add(const Duration(days: 2));
      final high = buildTask(deadline: deadline, priority: TaskPriority.high);
      final low = buildTask(deadline: deadline, priority: TaskPriority.low);
      expect(high.smartScore, greaterThan(low.smartScore));
    });

    test('higher grade weight raises the score for the same deadline', () {
      final deadline = DateTime.now().add(const Duration(days: 2));
      final heavy = buildTask(deadline: deadline, gradeWeight: 80);
      final light = buildTask(deadline: deadline, gradeWeight: 0);
      expect(heavy.smartScore, greaterThan(light.smartScore));
    });
  });

  group('TaskModel.subtaskProgress', () {
    test('returns the stored progress when there are no sub-tasks', () {
      final task = buildTask(progress: 0.42);
      expect(task.subtaskProgress, 0.42);
    });

    test('computes the fraction of completed sub-tasks', () {
      final task = buildTask(subtasks: const [
        SubTask(id: 'a', title: 'A', isDone: true),
        SubTask(id: 'b', title: 'B', isDone: true),
        SubTask(id: 'c', title: 'C', isDone: false),
        SubTask(id: 'd', title: 'D', isDone: false),
      ]);
      expect(task.subtaskProgress, 0.5);
    });

    test('is 1.0 when every sub-task is done', () {
      final task = buildTask(subtasks: const [
        SubTask(id: 'a', title: 'A', isDone: true),
        SubTask(id: 'b', title: 'B', isDone: true),
      ]);
      expect(task.subtaskProgress, 1.0);
    });
  });

  group('TaskModel.copyWith', () {
    test('overrides only the provided fields', () {
      final task = buildTask(title: 'Old', priority: TaskPriority.low);
      final updated = task.copyWith(
        title: 'New',
        priority: TaskPriority.high,
        isCompleted: true,
      );

      expect(updated.title, 'New');
      expect(updated.priority, TaskPriority.high);
      expect(updated.isCompleted, isTrue);
      // Untouched fields are carried over.
      expect(updated.id, task.id);
      expect(updated.userId, task.userId);
      expect(updated.category, task.category);
      // Original is untouched (immutability).
      expect(task.title, 'Old');
      expect(task.priority, TaskPriority.low);
    });
  });

  group('TaskModel Firestore (de)serialisation', () {
    test('toMap stores enums as their index and dates as Timestamps', () {
      final task = buildTask(
        priority: TaskPriority.high,
        category: TaskCategory.exam,
      );
      final map = task.toMap();

      expect(map['priority'], TaskPriority.high.index);
      expect(map['category'], TaskCategory.exam.index);
      expect(map['deadline'], isA<Timestamp>());
      expect(map['createdAt'], isA<Timestamp>());
    });

    test('fromMap reconstructs an equivalent task (round-trip)', () {
      final task = buildTask(
        title: 'Final Year Project',
        priority: TaskPriority.high,
        category: TaskCategory.project,
        gradeWeight: 40,
        subtasks: const [
          SubTask(id: 's1', title: 'Literature review', isDone: true),
          SubTask(id: 's2', title: 'Implementation', isDone: false),
        ],
      );

      final restored = TaskModel.fromMap(task.toMap());

      expect(restored.id, task.id);
      expect(restored.title, task.title);
      expect(restored.priority, task.priority);
      expect(restored.category, task.category);
      expect(restored.gradeWeight, task.gradeWeight);
      expect(restored.subtasks.length, 2);
      expect(restored.subtasks.first.title, 'Literature review');
      expect(restored.subtasks.first.isDone, isTrue);
      expect(
        restored.deadline.millisecondsSinceEpoch,
        task.deadline.millisecondsSinceEpoch,
      );
    });

    test('fromMap falls back to defaults for missing enum keys', () {
      final base = buildTask().toMap()
        ..remove('priority')
        ..remove('category');
      final restored = TaskModel.fromMap(base);
      expect(restored.priority, TaskPriority.medium); // default index 1
      expect(restored.category, TaskCategory.assignment); // default index 0
    });
  });

  group('Enum display extensions', () {
    test('TaskPriority labels map correctly', () {
      expect(TaskPriority.high.label, 'High');
      expect(TaskPriority.medium.label, 'Medium');
      expect(TaskPriority.low.label, 'Low');
    });

    test('TaskCategory labels map correctly', () {
      expect(TaskCategory.assignment.label, 'Assignment');
      expect(TaskCategory.exam.label, 'Exam');
      expect(TaskCategory.project.label, 'Project');
      expect(TaskCategory.reading.label, 'Reading');
      expect(TaskCategory.meeting.label, 'Meeting');
      expect(TaskCategory.other.label, 'Other');
    });
  });
}
