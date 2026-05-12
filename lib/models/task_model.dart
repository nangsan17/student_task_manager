class TaskModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String priority;
  final String deadline;
  final bool isCompleted;

  TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.priority,
    required this.deadline,
    required this.isCompleted,
  });

  factory TaskModel.fromMap(Map<String, dynamic> data, String documentId) {
    return TaskModel(
      id: documentId,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      priority: data['priority'] ?? 'Low',
      deadline: data['deadline'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'priority': priority,
      'deadline': deadline,
      'isCompleted': isCompleted,
    };
  }
}
