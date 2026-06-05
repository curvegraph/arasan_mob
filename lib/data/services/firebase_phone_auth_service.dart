import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebasePhoneAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  /// Send OTP to the given phone number.
  /// [phoneNumber] must include country code, e.g. '+919876543210'
  Future<void> sendOTP({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String error) onError,
    required void Function(PhoneAuthCredential credential) onAutoVerified,
    required void Function(String verificationId) onAutoRetrievalTimeout,
    int? forceResendingToken,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        forceResendingToken: forceResendingToken,
        verificationCompleted: (PhoneAuthCredential credential) {
          debugPrint('Firebase Phone Auth: Auto-verified');
          onAutoVerified(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('Firebase Phone Auth error: ${e.message}');
          onError(_translateError(e));
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('Firebase Phone Auth: Code sent');
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          onAutoRetrievalTimeout(verificationId);
        },
      );
    } catch (e) {
      onError('Failed to send OTP: $e');
    }
  }

  Future<UserCredential> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await _auth.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithCredential(
      PhoneAuthCredential credential) async {
    return await _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  String _translateError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Invalid phone number format';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later';
      case 'missing-client-identifier':
      case 'app-not-authorized':
        return 'This Firebase project is not authorised for phone auth.';
      case 'billing-not-enabled':
        return 'Firebase billing must be enabled for phone auth on this plan.';
      default:
        final msg = e.message ?? '';
        return msg.isEmpty ? 'Auth error: ${e.code}' : msg;
    }
  }
}
