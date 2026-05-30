import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/task_model.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _taskCollection => _firestore.collection('tasks');

  Future<void> addTask(TaskModel task) async {
    await _taskCollection.add(task.toMap());
  }

  Stream<List<TaskModel>> getTasks() {
    final currentUser = _auth.currentUser;

    return _taskCollection
        .where('userId', isEqualTo: currentUser?.uid)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return TaskModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();
        });
  }

  Future<void> deleteTask(String id) async {
    await _taskCollection.doc(id).delete();
  }

  Future<void> updateTaskStatus(String id, bool currentStatus) async {
    await _taskCollection.doc(id).update({'isCompleted': !currentStatus});
  }

  Future<void> editTask(
    String id,
    String newTitle,
    String newDescription,
    String newPriority,
    String newDeadline,
  ) async {
    await _taskCollection.doc(id).update({
      'title': newTitle,
      'description': newDescription,
      'priority': newPriority,
      'deadline': newDeadline,
    });
  }
}
