import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../utils/theme.dart';

class TaskService {
  final _db   = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> _ref(String uid) =>
      _db.collection('users').doc(uid).collection('tasks');

  // ── CREATE ────────────────────────────────────────────────────────────────
  Future<TaskModel> addTask({
    required String userId,
    required String title,
    String description = '',
    required DateTime deadline,
    TaskPriority priority = TaskPriority.medium,
    TaskCategory category = TaskCategory.assignment,
    List<SubTask> subtasks = const [],
    int gradeWeight = 0,
  }) async {
    final id  = _uuid.v4();
    final now = DateTime.now();
    final task = TaskModel(
      id: id, userId: userId, title: title, description: description,
      deadline: deadline, priority: priority, category: category,
      subtasks: subtasks, gradeWeight: gradeWeight,
      createdAt: now, updatedAt: now,
    );
    await _ref(userId).doc(id).set(task.toMap());
    return task;
  }

  // ── READ: stream all ──────────────────────────────────────────────────────
  Stream<List<TaskModel>> getTasks(String userId) =>
      _ref(userId).orderBy('deadline').snapshots()
          .map((s) => s.docs.map((d) => TaskModel.fromMap(d.data())).toList());

  // ── READ: single ──────────────────────────────────────────────────────────
  Future<TaskModel?> getTask(String userId, String taskId) async {
    final doc = await _ref(userId).doc(taskId).get();
    if (doc.exists && doc.data() != null) return TaskModel.fromMap(doc.data()!);
    return null;
  }

  // ── UPDATE: full edit ─────────────────────────────────────────────────────
  Future<void> editTask(TaskModel task) async =>
      _ref(task.userId).doc(task.id).update(
          task.copyWith(updatedAt: DateTime.now()).toMap());

  // ── UPDATE: toggle complete ───────────────────────────────────────────────
  Future<void> updateTaskStatus(TaskModel task) async {
    final done = !task.isCompleted;
    final updated = task.copyWith(
      isCompleted: done,
      progress: done ? 1.0 : task.subtaskProgress,
      updatedAt: DateTime.now(),
    );
    await _ref(task.userId).doc(task.id).update(updated.toMap());
    if (done) {
      await _db.collection('users').doc(task.userId).update({
        'totalTasksCompleted': FieldValue.increment(1),
      });
    }
  }

  // ── UPDATE: subtask toggle ────────────────────────────────────────────────
  Future<void> toggleSubtask(TaskModel task, String subtaskId) async {
    final updated = task.subtasks.map((s) =>
        s.id == subtaskId ? s.copyWith(isDone: !s.isDone) : s).toList();
    final done = updated.where((s) => s.isDone).length;
    final prog = updated.isEmpty ? task.progress : done / updated.length;
    await _ref(task.userId).doc(task.id).update({
      'subtasks': updated.map((s) => s.toMap()).toList(),
      'progress': prog,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // ── DELETE ────────────────────────────────────────────────────────────────
  Future<void> deleteTask(TaskModel task) =>
      _ref(task.userId).doc(task.id).delete();

  Future<void> deleteCompleted(String userId) async {
    final snap = await _ref(userId).where('isCompleted', isEqualTo: true).get();
    final batch = _db.batch();
    for (final doc in snap.docs) batch.delete(doc.reference);
    await batch.commit();
  }

  // ── SMART SORT ────────────────────────────────────────────────────────────
  List<TaskModel> sortBySmart(List<TaskModel> tasks) =>
      [...tasks]..sort((a, b) => b.smartScore.compareTo(a.smartScore));
}
