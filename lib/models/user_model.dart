import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String course;
  final int totalTasksCompleted;
  final int currentStreak;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.course = '',
    this.totalTasksCompleted = 0,
    this.currentStreak = 0,
    required this.createdAt,
  });

  UserModel copyWith({
    String? uid, String? name, String? email, String? photoUrl,
    String? course, int? totalTasksCompleted, int? currentStreak, DateTime? createdAt,
  }) => UserModel(
    uid: uid ?? this.uid, name: name ?? this.name, email: email ?? this.email,
    photoUrl: photoUrl ?? this.photoUrl, course: course ?? this.course,
    totalTasksCompleted: totalTasksCompleted ?? this.totalTasksCompleted,
    currentStreak: currentStreak ?? this.currentStreak, createdAt: createdAt ?? this.createdAt,
  );

  Map<String, dynamic> toMap() => {
    'uid': uid, 'name': name, 'email': email, 'photoUrl': photoUrl, 'course': course,
    'totalTasksCompleted': totalTasksCompleted, 'currentStreak': currentStreak,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory UserModel.fromMap(Map<String, dynamic> m) => UserModel(
    uid: m['uid'] ?? '', name: m['name'] ?? '', email: m['email'] ?? '',
    photoUrl: m['photoUrl'], course: m['course'] ?? '',
    totalTasksCompleted: m['totalTasksCompleted'] ?? 0,
    currentStreak: m['currentStreak'] ?? 0,
    createdAt: m['createdAt'] != null ? (m['createdAt'] as Timestamp).toDate() : DateTime.now(),
  );
}
