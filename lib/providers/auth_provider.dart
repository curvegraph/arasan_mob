import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/services/api_service.dart';

/// AuthProvider — single source of truth for "who is signed in".
///
/// Login itself still happens via Supabase Auth (Google OAuth, email/password,
/// phone OTP via Firebase) so the user gets a Supabase JWT. Beyond that point,
/// **all profile state is hydrated from `GET /api/auth/me`** rather than from
/// `Supabase.instance.client.auth.currentUser`'s metadata. That avoids stale
/// or partial OAuth metadata leaking into the UI as a "logged-in user" — if
/// the backend doesn't recognise the token, we're logged out.
class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ApiService _api = ApiService();

  bool _isLoggedIn = false;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  // Authoritative user fields — populated by `/api/auth/me` only.
  String? _userId;
  String? _userName;
  String? _userPhone;
  String? _userEmail;
  String? _avatarUrl;
  bool _isDemoMode = false;

  AuthProvider() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    // React to every Supabase auth state change — fetch the canonical profile
    // from our backend each time a session arrives, and clear it on signout.
    _supabase.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null) {
        await _hydrateFromBackend();
      } else if (data.event == AuthChangeEvent.signedOut) {
        _clearLocalState();
      }
      if (!_isInitialized) _isInitialized = true;
      notifyListeners();
    });

    // Give Supabase a moment to recover its session from secure storage.
    await Future.delayed(const Duration(milliseconds: 500));

    final session = _supabase.auth.currentSession;
    if (session != null) {
      await _hydrateFromBackend();
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// Calls `/api/auth/me` and replaces local user state with the response.
  /// If the backend rejects the token (401/etc.), we sign out — that's the
  /// "no fake logins" guarantee: if the backend doesn't know us, we're out.
  Future<void> _hydrateFromBackend() async {
    try {
      final data = await _api.get('/auth/me', requireAuth: true);
      final user = (data is Map && data['user'] is Map)
          ? Map<String, dynamic>.from(data['user'] as Map)
          : (data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{});

      if (user['id'] == null) {
        await _signOutLocalAndRemote();
        return;
      }

      _isLoggedIn = true;
      _userId = user['id'] as String?;
      _userEmail = user['email'] as String?;
      _userPhone = user['phone'] as String?;
      _userName = user['name'] as String?;
      _avatarUrl = user['avatar_url'] as String?;
      _error = null;
    } catch (e) {
      debugPrint('AuthProvider._hydrateFromBackend failed: $e');
      // Backend rejected our token (or unreachable). Drop the local session
      // so we don't show a half-populated logged-in UI to the user.
      await _signOutLocalAndRemote();
    }
  }

  Future<void> _signOutLocalAndRemote() async {
    try {
      await _supabase.auth.signOut();
    } catch (_) {}
    _clearLocalState();
  }

  void _clearLocalState() {
    _isLoggedIn = false;
    _isDemoMode = false;
    _userId = null;
    _userName = null;
    _userPhone = null;
    _userEmail = null;
    _avatarUrl = null;
  }

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  String? get userName => _userName;
  String? get userPhone => _userPhone;
  String? get userEmail => _userEmail;
  String? get avatarUrl => _avatarUrl;
  String? get userId => _userId;
  String? get authToken => _userId; // legacy alias — callers want a stable id
  bool get isCustomer => _isLoggedIn;
  bool get isDemoMode => _isDemoMode;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Demo mode — preview the UI without a real backend session.
  void loginAsDemo() {
    _isLoggedIn = true;
    _isDemoMode = true;
    _userId = '00000000-0000-0000-0000-000000000000';
    _userName = 'Demo User';
    _userPhone = '9000000000';
    _userEmail = 'demo@arasanmobiles.com';
    _avatarUrl = null;
    _error = null;
    notifyListeners();
  }

  Future<bool> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: name != null ? {'name': name, 'full_name': name} : null,
      );

      if (response.user == null) {
        _error = 'Failed to create account. Please try again.';
        return false;
      }

      if (response.session != null) {
        try {
          await _api.post('/auth/upsert-customer',
              body: {'name': name, 'email': email}, requireAuth: true);
        } catch (_) {}
        await _hydrateFromBackend();
        return _isLoggedIn;
      }

      // Email confirmation enabled — auto-confirm + sign in.
      final confirmed = await _autoConfirmAndSignIn(
        email: email,
        password: password,
        name: name,
      );
      if (confirmed) return true;

      _error = 'Account created! Please check your email and click the verification link to activate your account, then sign in.';
      return false;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Failed to create account. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session == null) {
        _error = 'Invalid email or password.';
        return false;
      }

      await _hydrateFromBackend();
      return _isLoggedIn;
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('email not confirmed')) {
        final confirmed = await _autoConfirmAndSignIn(
          email: email,
          password: password,
        );
        if (confirmed) return true;
        _error = 'Email not verified. Please check your email inbox and click the verification link, then try again.';
      } else {
        _error = e.message;
      }
      return false;
    } catch (_) {
      _error = 'Failed to sign in. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> _autoConfirmAndSignIn({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      await _api.post('/rpc/auth/confirm-email',
          body: {'email': email}, requireAuth: false);
      await Future.delayed(const Duration(milliseconds: 500));

      final retry = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (retry.session == null) return false;

      try {
        await _api.post('/auth/upsert-customer',
            body: {'name': name, 'email': email}, requireAuth: true);
      } catch (_) {}
      await _hydrateFromBackend();
      return _isLoggedIn;
    } catch (e) {
      debugPrint('Auto-confirm failed: $e');
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.arasanmobiles.user://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      // The deep-link handler in the router calls getSessionFromUrl, which
      // fires onAuthStateChange → _hydrateFromBackend. So we don't update
      // local state here — we just kicked off the browser flow.
      return success;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Failed to sign in with Google. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendOtp(String phone) async {
    final cleaned = phone.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length != 10) {
      _error = 'Please enter a valid 10-digit mobile number';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabase.auth.signInWithOtp(phone: '+91$cleaned');
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Failed to send OTP. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOtp(String phone, String otp) async {
    final cleaned = phone.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (otp.trim().length != 6) {
      _error = 'Please enter a valid 6-digit OTP';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase.auth.verifyOTP(
        phone: '+91$cleaned',
        token: otp.trim(),
        type: OtpType.sms,
      );

      if (response.session == null) {
        _error = 'Verification failed. Please try again.';
        return false;
      }

      await _hydrateFromBackend();
      return _isLoggedIn;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Verification failed. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Backward-compat alias.
  Future<bool> loginAsCustomer(String phone, String otp) =>
      verifyOtp(phone, otp);

  /// Login after Firebase Phone Auth verifies on-device. Calls the backend's
  /// `/auth/phone-sync` to mint a Supabase session, then hydrates from
  /// `/auth/me` for canonical profile state.
  Future<void> loginWithFirebasePhone({
    required String uid,
    required String phone,
    String? name,
  }) async {
    try {
      await _api.post('/auth/phone-sync',
          body: {'uid': uid, 'phone': phone, if (name != null) 'name': name});
    } catch (e) {
      debugPrint('phone-sync failed: $e');
    }
    // Whether or not phone-sync set up a Supabase session, ask the backend
    // who we are. If we don't have a token, _hydrateFromBackend signs us out.
    await _hydrateFromBackend();
    notifyListeners();
  }

  Future<void> logout() async {
    await _signOutLocalAndRemote();
    notifyListeners();
  }
}
