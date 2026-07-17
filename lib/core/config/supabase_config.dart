import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

  static const String _prefsUrlKey = 'supabase_config_url';
  static const String _prefsAnonKey = 'supabase_config_anon';

  /// Loads the Supabase URL + anon key. Idempotent — later calls no-op.
  ///
  /// Cache-first: once a launch has fetched the config we persist it, so every
  /// subsequent launch starts INSTANTLY from the stored values (no blocking
  /// network round trip on the startup path) and only refreshes the cache in
  /// the background. Only the very first launch — or one after the cache is
  /// cleared — has to wait for the backend.
  static Future<void> loadFromBackend() async {
    if (_loaded) return;

    final prefs = await SharedPreferences.getInstance();
    final cachedUrl = (prefs.getString(_prefsUrlKey) ?? '').trim();
    final cachedAnon = (prefs.getString(_prefsAnonKey) ?? '').trim();

    if (cachedUrl.isNotEmpty && cachedAnon.isNotEmpty) {
      _url = cachedUrl;
      _anonKey = cachedAnon;
      _loaded = true;
      // Refresh the stored config for the next launch without blocking this
      // one; swallow errors so an offline refresh never surfaces.
      unawaited(_refreshCache(prefs));
      if (kDebugMode) {
        debugPrint('SupabaseConfig: loaded from cache ($_url)');
      }
      return;
    }

    // No cache yet — must fetch before Supabase can be initialised.
    final config = await _fetchConfig();
    _url = config.url;
    _anonKey = config.anonKey;
    _loaded = true;
    await _store(prefs, config);
    if (kDebugMode) {
      debugPrint('SupabaseConfig: loaded from backend ($_url)');
    }
  }

  /// Background-only: re-fetch and overwrite the stored config so a rotated
  /// url/key is picked up on the next launch. Does not touch the live in-memory
  /// values (Supabase is already initialised with them this session).
  static Future<void> _refreshCache(SharedPreferences prefs) async {
    try {
      final config = await _fetchConfig();
      await _store(prefs, config);
    } catch (_) {
      // Offline / transient — keep the existing cache.
    }
  }

  static Future<void> _store(
      SharedPreferences prefs, _SupabaseCreds config) async {
    await prefs.setString(_prefsUrlKey, config.url);
    await prefs.setString(_prefsAnonKey, config.anonKey);
  }

  static Future<_SupabaseCreds> _fetchConfig() async {
    final uri = Uri.parse('$_apiBase/auth/supabase-config');
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
    final url = (data['url'] as String? ?? '').trim();
    final anonKey = (data['anonKey'] as String? ?? '').trim();
    if (url.isEmpty || anonKey.isEmpty) {
      throw Exception('Backend returned empty Supabase config');
    }
    return _SupabaseCreds(url, anonKey);
  }
}

class _SupabaseCreds {
  final String url;
  final String anonKey;
  const _SupabaseCreds(this.url, this.anonKey);
}
