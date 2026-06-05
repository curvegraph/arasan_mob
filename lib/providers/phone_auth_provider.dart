import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../data/services/api_service.dart';
import '../data/services/firebase_phone_auth_service.dart';

/// Provider for Firebase Phone OTP authentication.
/// After Firebase phone auth succeeds, it also creates/links the user
/// row in the backend so the rest of the app (orders, cart, etc.) works.
class PhoneAuthProvider extends ChangeNotifier {
  final FirebasePhoneAuthService _service = FirebasePhoneAuthService();
  final ApiService _api = ApiService();

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
          final userCred = await _service.signInWithCredential(credential);
          await _syncWithSupabase(userCred);
          _isLoading = false;
          _codeSent = false;
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
      final userCred = await _service.verifyOTP(
        verificationId: _verificationId!,
        smsCode: trimmed,
      );
      await _syncWithSupabase(userCred);
      _isLoading = false;
      _codeSent = false;
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

  /// After Firebase phone auth, sync user via the backend so cart/orders work.
  Future<void> _syncWithSupabase(UserCredential userCred) async {
    final user = userCred.user;
    if (user == null) return;

    final resolvedPhone = user.phoneNumber ?? '+91$_phoneNumber';

    try {
      await _api.post('/auth/phone-sync', body: {
        'uid': user.uid,
        // Send null when no display name; backend derives a real name
        // instead of using the literal "Customer" placeholder.
        'name': user.displayName,
        'phone': resolvedPhone,
        'email': user.email,
      });
    } catch (e) {
      debugPrint('Phone-auth backend sync: $e');
    }
  }

  /// Get the Firebase user info for the main AuthProvider
  Map<String, String?> get firebaseUserInfo {
    final user = _service.currentUser;
    return {
      'uid': user?.uid,
      'phone': user?.phoneNumber,
      'name': user?.displayName,
      'email': user?.email,
    };
  }
}
