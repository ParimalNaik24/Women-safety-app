import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> loginWithNameAndPhone({
    required String fullName,
    required String phoneNumber,
  }) async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }

    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('Login failed: no user id returned');
    }

    await _db.collection('users').doc(uid).set({
      'fullName': fullName,
      'phoneNumber': phoneNumber,
    }, SetOptions(merge: true));
  }

  Future<String> getFullName() async {
    final uid = currentUser?.uid;
    if (uid == null) return '';
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['fullName'] ?? '';
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}