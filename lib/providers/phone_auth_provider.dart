import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../data/services/firebase_phone_auth_service.dart';

/// Provider for Firebase Phone OTP authentication. Owns only the Firebase
/// side of phone login — once OTP succeeds, callers fetch the Firebase ID
/// token via [getIdToken] and hand it to AuthProvider, which exchanges it
/// for a Supabase session via `/auth/firebase-phone-exchange`.
class PhoneAuthProvider extends ChangeNotifier {
  final FirebasePhoneAuthService _service = FirebasePhoneAuthService();

  bool _isLoading = false;
  bool _codeSent = false;
  String? _verificationId;
  int? _resendToken;
  String? _error;
  String _phoneNumber = '';

  bool get isLoading => _isLoading;
  bool get codeSent => _codeSent;
  String? get error => _error;
  String get phoneNumber => _phoneNumber;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _isLoading = false;
    _codeSent = false;
    _verificationId = null;
    _resendToken = null;
    _error = null;
    _phoneNumber = '';
    notifyListeners();
  }

  /// Send OTP to phone number (10-digit Indian number)
  Future<void> sendOTP(String phone) async {
    final cleaned = phone.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length != 10) {
      _error = 'Please enter a valid 10-digit mobile number';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    _phoneNumber = cleaned;
    notifyListeners();

    await _service.sendOTP(
      phoneNumber: '+91$cleaned',
      onCodeSent: (verificationId, resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        _codeSent = true;
        _isLoading = false;
        notifyListeners();
      },
      onError: (msg) {
        // Surface full message so the user sees the real problem (quota,
        // billing, reCAPTCHA on web, invalid number, etc.) instead of
        // a blank "Error" line.
        _error = msg.isEmpty ? 'Unknown error sending OTP' : msg;
        debugPrint('PhoneAuthProvider.sendOTP error: $_error');
        _isLoading = false;
        notifyListeners();
      },
      onAutoVerified: (credential) async {
        // Android auto-verification
        _isLoading = true;
        notifyListeners();
        try {
          await _service.signInWithCredential(credential);
          // Keep `_codeSent` true and `_isLoading` true so the OTP step stays
          // on-screen (with the spinner) while the caller finishes the
          // exchange + navigation. `reset()` is the explicit cleanup.
          notifyListeners();
        } catch (e) {
          _error = 'Auto-verification failed: ${e.toString()}';
          _isLoading = false;
          notifyListeners();
        }
      },
      onAutoRetrievalTimeout: (verificationId) {
        _verificationId = verificationId;
      },
      forceResendingToken: _resendToken,
    );
  }

  /// Resend OTP
  Future<void> resendOTP() async {
    if (_phoneNumber.isEmpty) return;
    await sendOTP(_phoneNumber);
  }

  /// Verify OTP code
  Future<bool> verifyOTP(String otp) async {
    if (_verificationId == null) {
      _error = 'Please request OTP first';
      notifyListeners();
      return false;
    }

    final trimmed = otp.trim();
    if (trimmed.length != 6) {
      _error = 'Please enter a valid 6-digit OTP';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.verifyOTP(
        verificationId: _verificationId!,
        smsCode: trimmed,
      );
      // Don't clear `_codeSent` / `_isLoading` here — the caller still has
      // work to do (exchange the ID token for a Supabase session, hydrate
      // profile, navigate). Keeping the OTP step + spinner visible prevents
      // the login UI from flashing back to the phone-entry state while
      // that async work runs. `reset()` is the explicit cleanup.
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-verification-code':
          _error = 'Invalid OTP. Please check and try again';
          break;
        case 'session-expired':
          _error = 'OTP expired. Please request a new one';
          break;
        default:
          _error = e.message ?? 'Verification failed';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Verification failed. Please try again';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Fetch the current Firebase user's ID token, to be exchanged by the
  /// backend for a Supabase session. Returns null if no Firebase user is
  /// signed in.
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    return _service.currentUser?.getIdToken(forceRefresh);
  }
}
