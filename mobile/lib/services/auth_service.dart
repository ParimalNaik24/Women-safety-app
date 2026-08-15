import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Wraps Firebase PHONE authentication (OTP via SMS) -- no email/password
/// anywhere in this app. The login screen only asks for the user's NAME
/// and PHONE NUMBER.
///
/// HOW IT WORKS:
///   1. User types name + phone -> verifyPhoneNumber() sends a real SMS
///   2. Either:
///      a) Android auto-detects the incoming SMS and verifies instantly
///         (verificationCompleted callback), OR
///      b) codeSent fires and we show the OTP entry screen for the user
///         to type the 6-digit code themselves
///   3. Once verified, signInWithCredential() logs the user in -- Firebase
///      creates the account automatically the first time a number
///      verifies, or logs in if it already exists.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Kicks off phone verification. [phoneNumber] must be in full
  /// international format, e.g. "+919876543210".
  Future<void> startPhoneVerification({
    required String phoneNumber,
    required void Function(PhoneAuthCredential credential) onAutoVerified,
    required void Function(String message) onFailed,
    required void Function(String verificationId, int? resendToken) onCodeSent,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) {
        onAutoVerified(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        onFailed(e.message ?? 'Verification failed');
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId, resendToken);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // Called when auto-retrieval times out -- the user just types the
        // code manually at this point, nothing extra to do here.
      },
    );
  }

  /// Builds a credential from the verification ID + the 6-digit code typed by the user.
  PhoneAuthCredential buildCredential(String verificationId, String smsCode) {
    return PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
  }

  /// Signs in with the credential and saves/updates the user's profile
  /// (name + phone) in Firestore at users/{uid}.
  Future<void> signInWithCredential(
    PhoneAuthCredential credential,
    String fullName,
  ) async {
    final userCredential = await _auth.signInWithCredential(credential);
    final uid = userCredential.user?.uid;
    final phone = userCredential.user?.phoneNumber;
    if (uid == null) {
      throw Exception('Sign-in failed: no user id returned');
    }
    await _db.collection('users').doc(uid).set({
      'fullName': fullName,
      'phoneNumber': phone ?? '',
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
