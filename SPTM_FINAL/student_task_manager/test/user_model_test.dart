// Unit tests for UserModel: copyWith semantics and Firestore round-tripping,
// including the location fields used by the profile location picker.
//
// Run with:  flutter test test/user_model_test.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sptm/models/user_model.dart';

void main() {
  UserModel buildUser() => UserModel(
        uid: 'u1',
        name: 'Nang Thet Htar San',
        email: 'student@apu.edu.my',
        course: 'BSc (Hons) Software Engineering',
        totalTasksCompleted: 12,
        currentStreak: 4,
        lat: 3.1390,
        lng: 101.6869,
        locationAddress: 'Asia Pacific University, Kuala Lumpur',
        createdAt: DateTime(2026, 1, 15),
      );

  group('UserModel.copyWith', () {
    test('overrides only the provided fields', () {
      final user = buildUser();
      final updated = user.copyWith(name: 'Updated Name', currentStreak: 7);

      expect(updated.name, 'Updated Name');
      expect(updated.currentStreak, 7);
      expect(updated.email, user.email); // unchanged
      expect(updated.uid, user.uid); // unchanged
      expect(user.name, 'Nang Thet Htar San'); // original untouched
    });
  });

  group('UserModel Firestore (de)serialisation', () {
    test('toMap / fromMap round-trip preserves all fields', () {
      final user = buildUser();
      final restored = UserModel.fromMap(user.toMap());

      expect(restored.uid, user.uid);
      expect(restored.name, user.name);
      expect(restored.email, user.email);
      expect(restored.course, user.course);
      expect(restored.totalTasksCompleted, 12);
      expect(restored.currentStreak, 4);
      expect(restored.lat, closeTo(3.1390, 0.0001));
      expect(restored.lng, closeTo(101.6869, 0.0001));
      expect(restored.locationAddress, contains('Asia Pacific University'));
      expect(restored.createdAt, DateTime(2026, 1, 15));
    });

    test('toMap stores createdAt as a Timestamp', () {
      expect(buildUser().toMap()['createdAt'], isA<Timestamp>());
    });

    test('fromMap supplies safe defaults for an empty document', () {
      final restored = UserModel.fromMap(<String, dynamic>{});
      expect(restored.uid, '');
      expect(restored.name, '');
      expect(restored.totalTasksCompleted, 0);
      expect(restored.currentStreak, 0);
      expect(restored.lat, isNull);
      expect(restored.lng, isNull);
      expect(restored.locationAddress, '');
    });
  });
}
