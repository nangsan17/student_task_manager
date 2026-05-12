import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

class TaskService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _taskCollection =>
      _firestore.collection('tasks');

  // Add task
  Future<void> addTask(TaskModel task) async {
    await _taskCollection.add(task.toMap());
  }

  // Get tasks
  Stream<List<TaskModel>> getTasks() {
    return _taskCollection.snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return TaskModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();
      },
    );
  }

  // Delete task
  Future<void> deleteTask(String id) async {
    await _taskCollection.doc(id).delete();
  }

  // Toggle complete
  Future<void> updateTaskStatus(
    String id,
    bool currentStatus,
  ) async {
    await _taskCollection.doc(id).update({
      'isCompleted': !currentStatus,
    });
  }
}