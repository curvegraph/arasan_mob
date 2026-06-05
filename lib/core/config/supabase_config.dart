import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Supabase config for the user app.
///
/// The URL + anon key are NOT stored in this repo (no .env entry, no Dart
/// constant). They live only in `backend/.env` and are fetched at app
/// startup from `GET /api/auth/supabase-config`. Once loaded, the values
/// are cached in static fields and reused by the rest of the app via
/// `supabaseUrl` / `supabaseAnonKey`.
///
/// Trade-off: app cold-start now requires backend reachability. In dev
/// the backend runs alongside the app; in prod the storefront depends on
/// the API being up anyway, so this is no extra single-point-of-failure.
class SupabaseConfig {
  static String _url = '';
  static String _anonKey = '';
  static bool _loaded = false;

  static String get supabaseUrl => _url;
  static String get supabaseAnonKey => _anonKey;
  static bool get isConfigured => _url.isNotEmpty && _anonKey.isNotEmpty;

  /// Backend base URL. Pulled from .env (key `API_URL`) or
  /// --dart-define=API_URL=... so a single source of truth covers both
  /// dev and prod builds. Defaults to localhost for local dev.
  static String get _apiBase {
    // dart-define wins so CI builds can override without touching the file.
    const fromDefine = String.fromEnvironment('API_URL');
    if (fromDefine.isNotEmpty) return fromDefine;
    final fromEnv = (dotenv.env['API_URL'] ?? '').trim();
    if (fromEnv.isNotEmpty) return fromEnv;
    return 'http://localhost:3001/api';
  }

  /// Fetches the Supabase URL + anon key from the backend. Idempotent —
  /// the first successful call populates the cache; later calls no-op.
  static Future<void> loadFromBackend() async {
    if (_loaded) return;
    final uri = Uri.parse('${_apiBase}/auth/supabase-config');
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw Exception(
        'Backend /auth/supabase-config returned ${res.statusCode}: ${res.body}',
      );
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['success'] != true || body['data'] == null) {
      throw Exception('Bad config payload: ${res.body}');
    }
    final data = body['data'] as Map<String, dynamic>;
    _url = (data['url'] as String? ?? '').trim();
    _anonKey = (data['anonKey'] as String? ?? '').trim();
    if (_url.isEmpty || _anonKey.isEmpty) {
      throw Exception('Backend returned empty Supabase config');
    }
    _loaded = true;
    if (kDebugMode) {
      debugPrint('SupabaseConfig: loaded from backend (${_url})');
    }
  }
}
