import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// SessionManager - Handles persistent session storage for user app
///
/// This manager explicitly stores and restores sessions using SharedPreferences
/// with refresh tokens for proper session restoration on app restart.
class SessionManager {
  static const String _refreshTokenKey = 'arasan_user_refresh_token';
  static const String _accessTokenKey = 'arasan_user_access_token';
  static const String _userEmailKey = 'arasan_user_email';
  static const String _userIdKey = 'arasan_user_id';
  static const String _userNameKey = 'arasan_user_name';
  static const String _sessionExpiryKey = 'arasan_user_session_expiry';

  static SupabaseClient get _client => Supabase.instance.client;

  /// Save current session to persistent storage
  static Future<void> saveSession() async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) {
        debugPrint('SessionManager: No session to save');
        return;
      }

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_refreshTokenKey, session.refreshToken ?? '');
      await prefs.setString(_accessTokenKey, session.accessToken);
      await prefs.setString(_userEmailKey, session.user.email ?? '');
      await prefs.setString(_userIdKey, session.user.id);
      await prefs.setString(_userNameKey,
          session.user.userMetadata?['name'] as String? ??
          session.user.userMetadata?['full_name'] as String? ?? '');
      await prefs.setInt(_sessionExpiryKey, session.expiresAt ?? 0);

      debugPrint('SessionManager: Session saved for ${session.user.email}');
    } catch (e) {
      debugPrint('SessionManager: Error saving session: $e');
    }
  }

  /// Restore session from persistent storage using refresh token
  /// Returns true if session was successfully restored
  static Future<bool> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(_refreshTokenKey);

      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint('SessionManager: No refresh token stored');
        return false;
      }

      debugPrint('SessionManager: Attempting to restore session...');

      // Use refresh token to restore session
      final response = await _client.auth.setSession(refreshToken);

      if (response.user != null) {
        debugPrint('SessionManager: Session restored for ${response.user?.email}');

        // Update stored tokens with new ones
        if (response.session != null) {
          await prefs.setString(_refreshTokenKey, response.session!.refreshToken ?? refreshToken);
          await prefs.setString(_accessTokenKey, response.session!.accessToken);
          await prefs.setInt(_sessionExpiryKey, response.session!.expiresAt ?? 0);
        }

        return true;
      } else {
        debugPrint('SessionManager: Session restoration returned no user');
        return false;
      }
    } on AuthException catch (e) {
      debugPrint('SessionManager: Auth error restoring session: ${e.message}');
      // Token might be expired or invalid, clear stored session
      await clearSession();
      return false;
    } catch (e) {
      debugPrint('SessionManager: Error restoring session: $e');
      return false;
    }
  }

  /// Check if there's a stored session
  static Future<bool> hasStoredSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(_refreshTokenKey);
      return refreshToken != null && refreshToken.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get stored user info (for display while restoring)
  static Future<Map<String, String?>> getStoredUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'email': prefs.getString(_userEmailKey),
        'userId': prefs.getString(_userIdKey),
        'name': prefs.getString(_userNameKey),
      };
    } catch (e) {
      return {};
    }
  }

  /// Clear stored session
  static Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_userEmailKey);
      await prefs.remove(_userIdKey);
      await prefs.remove(_userNameKey);
      await prefs.remove(_sessionExpiryKey);
      debugPrint('SessionManager: Session cleared');
    } catch (e) {
      debugPrint('SessionManager: Error clearing session: $e');
    }
  }

  /// Update session tokens (called after token refresh)
  static Future<void> updateTokens(String accessToken, String refreshToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_refreshTokenKey, refreshToken);
      await prefs.setString(_accessTokenKey, accessToken);
      debugPrint('SessionManager: Tokens updated');
    } catch (e) {
      debugPrint('SessionManager: Error updating tokens: $e');
    }
  }
}
