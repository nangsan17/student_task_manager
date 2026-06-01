import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/theme.dart';

class SubTask {
  final String id;
  final String title;
  final bool isDone;
  const SubTask({required this.id, required this.title, this.isDone = false});
  SubTask copyWith({String? id, String? title, bool? isDone}) => SubTask(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone);
  Map<String, dynamic> toMap() => {'id': id, 'title': title, 'isDone': isDone};
  factory SubTask.fromMap(Map<String, dynamic> m) => SubTask(
      id: m['id'] ?? '', title: m['title'] ?? '', isDone: m['isDone'] ?? false);
}

class TaskModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime deadline;
  final TaskPriority priority;
  final TaskCategory category;
  final bool isCompleted;
  final double progress;
  final List<SubTask> subtasks;
  final int gradeWeight;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    required this.deadline,
    this.priority = TaskPriority.medium,
    this.category = TaskCategory.assignment,
    this.isCompleted = false,
    this.progress = 0.0,
    this.subtasks = const [],
    this.gradeWeight = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  double get smartScore {
    final h = deadline.difference(DateTime.now()).inHours;
    final urgency = h <= 0 ? 100.0 : (1000 / (h + 1)).clamp(0.0, 100.0);
    final pri = (2 - priority.index) * 30.0;
    final weight = gradeWeight.toDouble().clamp(0.0, 100.0);
    return urgency * 0.5 + pri * 0.3 + weight * 0.2;
  }

  bool get isOverdue => !isCompleted && deadline.isBefore(DateTime.now());
  bool get isDueToday {
    final n = DateTime.now();
    return deadline.year == n.year &&
        deadline.month == n.month &&
        deadline.day == n.day &&
        !isCompleted;
  }

  bool get isDueSoon {
    final h = deadline.difference(DateTime.now()).inHours;
    return h > 0 && h <= 24 && !isCompleted;
  }

  double get subtaskProgress {
    if (subtasks.isEmpty) return progress;
    return subtasks.where((s) => s.isDone).length / subtasks.length;
  }

  TaskModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? deadline,
    TaskPriority? priority,
    TaskCategory? category,
    bool? isCompleted,
    double? progress,
    List<SubTask>? subtasks,
    int? gradeWeight,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      TaskModel(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        title: title ?? this.title,
        description: description ?? this.description,
        deadline: deadline ?? this.deadline,
        priority: priority ?? this.priority,
        category: category ?? this.category,
        isCompleted: isCompleted ?? this.isCompleted,
        progress: progress ?? this.progress,
        subtasks: subtasks ?? this.subtasks,
        gradeWeight: gradeWeight ?? this.gradeWeight,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'title': title,
        'description': description,
        'deadline': Timestamp.fromDate(deadline),
        'priority': priority.index,
        'category': category.index,
        'isCompleted': isCompleted,
        'progress': progress,
        'subtasks': subtasks.map((s) => s.toMap()).toList(),
        'gradeWeight': gradeWeight,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory TaskModel.fromMap(Map<String, dynamic> m) => TaskModel(
        id: m['id'] ?? '',
        userId: m['userId'] ?? '',
        title: m['title'] ?? '',
        description: m['description'] ?? '',
        deadline: (m['deadline'] as Timestamp).toDate(),
        priority: TaskPriority.values[(m['priority'] as int?) ?? 1],
        category: TaskCategory.values[(m['category'] as int?) ?? 0],
        isCompleted: m['isCompleted'] ?? false,
        progress: (m['progress'] as num?)?.toDouble() ?? 0.0,
        subtasks: (m['subtasks'] as List<dynamic>? ?? [])
            .map((s) => SubTask.fromMap(s as Map<String, dynamic>))
            .toList(),
        gradeWeight: m['gradeWeight'] ?? 0,
        createdAt: (m['createdAt'] as Timestamp).toDate(),
        updatedAt: (m['updatedAt'] as Timestamp).toDate(),
      );

  get location => null;
}
