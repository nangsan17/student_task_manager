import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db   = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User?   get currentUser   => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;

  Future<UserModel> registerUser({
    required String name, required String email,
    required String password, required String course,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
    await cred.user!.updateDisplayName(name.trim());
    final user = UserModel(uid: cred.user!.uid, name: name.trim(), email: email.trim(),
        course: course.trim(), createdAt: DateTime.now());
    await _db.collection('users').doc(user.uid).set(user.toMap());
    return user;
  }

  Future<UserModel?> loginUser({required String email, required String password}) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
    return getUserProfile(cred.user!.uid);
  }

  Future<void> logout() => _auth.signOut();

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) return UserModel.fromMap(doc.data()!);
    return null;
  }

  Future<void> updateProfile(UserModel user) async {
    await _db.collection('users').doc(user.uid).update(user.toMap());
    await _auth.currentUser?.updateDisplayName(user.name);
  }
}
