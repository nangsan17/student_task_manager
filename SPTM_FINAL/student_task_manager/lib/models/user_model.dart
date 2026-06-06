import 'package:cloud_firestore/cloud_firestore.dart';
 
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String course;
  final int totalTasksCompleted;
  // Profile location (university/home)
  final double? lat;
  final double? lng;
  final String locationAddress;
  final DateTime? lastTaskCompletedAt;
  final DateTime createdAt;
 
  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.course = '',
    this.totalTasksCompleted = 0,
    this.lat,
    this.lng,
    this.locationAddress = '',
    this.lastTaskCompletedAt,
    required this.createdAt,
  });
 
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? photoUrl,
    String? course,
    int? totalTasksCompleted,
    double? lat,
    double? lng,
    String? locationAddress,
    DateTime? lastTaskCompletedAt,
    DateTime? createdAt,
  }) =>
      UserModel(
        uid: uid ?? this.uid,
        name: name ?? this.name,
        email: email ?? this.email,
        photoUrl: photoUrl ?? this.photoUrl,
        course: course ?? this.course,
        totalTasksCompleted: totalTasksCompleted ?? this.totalTasksCompleted,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        locationAddress: locationAddress ?? this.locationAddress,
        lastTaskCompletedAt: lastTaskCompletedAt ?? this.lastTaskCompletedAt,
        createdAt: createdAt ?? this.createdAt,
      );
 
  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'course': course,
        'totalTasksCompleted': totalTasksCompleted,
        'lat': lat,
        'lng': lng,
        'locationAddress': locationAddress,
        'lastTaskCompletedAt': lastTaskCompletedAt != null
            ? Timestamp.fromDate(lastTaskCompletedAt!)
            : null,
        'createdAt': Timestamp.fromDate(createdAt),
      };
 
  factory UserModel.fromMap(Map<String, dynamic> m) => UserModel(
        uid: m['uid'] ?? '',
        name: m['name'] ?? '',
        email: m['email'] ?? '',
        photoUrl: m['photoUrl'],
        course: m['course'] ?? '',
        totalTasksCompleted: m['totalTasksCompleted'] ?? 0,
        lat: (m['lat'] as num?)?.toDouble(),
        lng: (m['lng'] as num?)?.toDouble(),
        locationAddress: m['locationAddress'] ?? '',
        lastTaskCompletedAt: m['lastTaskCompletedAt'] != null
            ? (m['lastTaskCompletedAt'] as Timestamp).toDate()
            : null,
        createdAt: m['createdAt'] != null
            ? (m['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
      );
}
