import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic errors;

  ApiException(this.message, {this.statusCode, this.errors});

  @override
  String toString() => message;
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String _baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3001/api',
  );

  static const _requestTimeout = Duration(seconds: 15);
  static const _maxRetries = 3;

  final http.Client _client = http.Client();

  // Per-request auth diagnostic logging — keep off in normal runs (one log
  // line per API call adds up fast and stalls the main isolate). Flip to
  // true when investigating auth/session failures.
  static const _verboseAuthLog = false;

  Future<String?> _getAuthToken() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (_verboseAuthLog) {
      final user = Supabase.instance.client.auth.currentUser;
      debugPrint('[ApiService] _getAuthToken: session=${session != null}, '
          'user=${user?.email ?? user?.id ?? "null"}, '
          'expired=${session?.isExpired}, '
          'tokenLen=${session?.accessToken.length ?? 0}');
    }
    return session?.accessToken;
  }

  Future<Map<String, String>> _buildHeaders({bool requireAuth = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    final token = await _getAuthToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    } else if (requireAuth) {
      throw ApiException('Authentication required', statusCode: 401);
    }

    return headers;
  }

  dynamic _parseResponse(http.Response response) {
    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body['pagination'] != null) {
        final result = Map<String, dynamic>.from(body);
        result.remove('success');
        result.remove('message');
        return result;
      }
      return body['data'];
    }

    throw ApiException(
      body['message'] ?? 'An error occurred',
      statusCode: response.statusCode,
      errors: body['errors'],
    );
  }

  /// Whether the error is transient and worth retrying.
  bool _isRetryable(Object error) {
    if (error is SocketException || error is TimeoutException) return true;
    if (error is ApiException) {
      final code = error.statusCode;
      return code != null && (code == 408 || code == 429 || code >= 500);
    }
    return false;
  }

  /// Executes [request] with retry + exponential backoff for transient errors.
  Future<dynamic> _withRetry(Future<http.Response> Function() request) async {
    Object? lastError;
    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final response = await request().timeout(_requestTimeout);
        return _parseResponse(response);
      } on TimeoutException {
        lastError = ApiException('Request timed out', statusCode: 408);
      } on SocketException catch (e) {
        lastError = ApiException('No internet connection: ${e.message}');
      } catch (e) {
        if (!_isRetryable(e) || attempt == _maxRetries - 1) rethrow;
        lastError = e;
      }
      // Exponential backoff: 500ms, 1s, 2s
      final delay = Duration(milliseconds: 500 * (1 << attempt));
      if (kDebugMode) debugPrint('[ApiService] Retry ${attempt + 1} after $delay');
      await Future.delayed(delay);
    }
    throw lastError ?? ApiException('Request failed after $_maxRetries attempts');
  }

  // GET request
  Future<dynamic> get(String endpoint, {bool requireAuth = false, Map<String, String>? queryParams}) async {
    final uri = Uri.parse('$_baseUrl$endpoint').replace(queryParameters: queryParams);
    final headers = await _buildHeaders(requireAuth: requireAuth);
    return _withRetry(() => _client.get(uri, headers: headers));
  }

  // POST request
  Future<dynamic> post(String endpoint, {dynamic body, bool requireAuth = false}) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final headers = await _buildHeaders(requireAuth: requireAuth);
    return _withRetry(() => _client.post(uri, headers: headers, body: body != null ? jsonEncode(body) : null));
  }

  // PUT request
  Future<dynamic> put(String endpoint, {dynamic body, bool requireAuth = false}) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final headers = await _buildHeaders(requireAuth: requireAuth);
    return _withRetry(() => _client.put(uri, headers: headers, body: body != null ? jsonEncode(body) : null));
  }

  // PATCH request
  Future<dynamic> patch(String endpoint, {dynamic body, bool requireAuth = false}) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final headers = await _buildHeaders(requireAuth: requireAuth);
    return _withRetry(() => _client.patch(uri, headers: headers, body: body != null ? jsonEncode(body) : null));
  }

  // DELETE request
  Future<dynamic> delete(String endpoint, {bool requireAuth = false}) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final headers = await _buildHeaders(requireAuth: requireAuth);
    return _withRetry(() => _client.delete(uri, headers: headers));
  }
}
