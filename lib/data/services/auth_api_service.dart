import 'api_service.dart';

class AuthApiService {
  final ApiService _api = ApiService();

  /// Register new user
  Future<AuthResponse> register({
    required String email,
    required String password,
    String? name,
    String? phone,
  }) async {
    final response = await _api.post('/auth/register', body: {
      'email': email,
      'password': password,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
    });
    return AuthResponse.fromJson(response);
  }

  /// Login with email/password
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post('/auth/login', body: {
      'email': email,
      'password': password,
    });
    return LoginResponse.fromJson(response);
  }

  /// Request OTP login
  Future<OtpResponse> requestOtp({String? email, String? phone}) async {
    final response = await _api.post('/auth/login/otp', body: {
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
    });
    return OtpResponse.fromJson(response);
  }

  /// Verify OTP
  Future<LoginResponse> verifyOtp({
    String? email,
    String? phone,
    required String token,
  }) async {
    final response = await _api.post('/auth/verify-otp', body: {
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      'token': token,
    });
    return LoginResponse.fromJson(response);
  }

  /// Refresh access token
  Future<SessionResponse> refreshToken(String refreshToken) async {
    final response = await _api.post('/auth/refresh', body: {
      'refreshToken': refreshToken,
    });
    return SessionResponse.fromJson(response);
  }

  /// Logout
  Future<void> logout() async {
    await _api.post('/auth/logout', requireAuth: true);
  }

  /// Request password reset
  Future<MessageResponse> forgotPassword(String email) async {
    final response = await _api.post('/auth/forgot-password', body: {
      'email': email,
    });
    return MessageResponse.fromJson(response);
  }

  /// Reset password with token
  Future<MessageResponse> resetPassword(String password) async {
    final response = await _api.post('/auth/reset-password', body: {
      'password': password,
    });
    return MessageResponse.fromJson(response);
  }

  /// Get current user profile
  Future<UserResponse> getMe() async {
    final response = await _api.get('/auth/me', requireAuth: true);
    return UserResponse.fromJson(response);
  }

  /// Update profile
  Future<UserResponse> updateProfile({
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    final response = await _api.patch('/auth/profile',
      body: {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      },
      requireAuth: true,
    );
    return UserResponse.fromJson(response);
  }

  /// Change password
  Future<MessageResponse> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _api.post('/auth/change-password',
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
      requireAuth: true,
    );
    return MessageResponse.fromJson(response);
  }

  /// Delete account
  Future<MessageResponse> deleteAccount() async {
    final response = await _api.delete('/auth/account', requireAuth: true);
    return MessageResponse.fromJson(response);
  }
}

/// User model
class User {
  final String id;
  final String email;
  final String? name;
  final String? phone;
  final String? avatarUrl;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.email,
    this.name,
    this.phone,
    this.avatarUrl,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      phone: json['phone'],
      avatarUrl: json['avatar_url'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'phone': phone,
    'avatar_url': avatarUrl,
  };
}

/// Session model
class Session {
  final String accessToken;
  final String refreshToken;
  final int expiresAt;

  Session({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      expiresAt: json['expiresAt'],
    );
  }

  bool get isExpired => DateTime.now().millisecondsSinceEpoch > expiresAt * 1000;

  DateTime get expiresAtDateTime =>
      DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
}

/// Auth response (for registration)
class AuthResponse {
  final User user;
  final String message;

  AuthResponse({required this.user, required this.message});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: User.fromJson(json['user']),
      message: json['message'] ?? '',
    );
  }
}

/// Login response
class LoginResponse {
  final User user;
  final Session session;

  LoginResponse({required this.user, required this.session});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      user: User.fromJson(json['user']),
      session: Session.fromJson(json['session']),
    );
  }
}

/// Session response (for token refresh)
class SessionResponse {
  final Session session;

  SessionResponse({required this.session});

  factory SessionResponse.fromJson(Map<String, dynamic> json) {
    return SessionResponse(
      session: Session.fromJson(json['session']),
    );
  }
}

/// OTP response
class OtpResponse {
  final String message;
  final String sentTo;

  OtpResponse({required this.message, required this.sentTo});

  factory OtpResponse.fromJson(Map<String, dynamic> json) {
    return OtpResponse(
      message: json['message'],
      sentTo: json['sentTo'],
    );
  }
}

/// User response
class UserResponse {
  final User user;
  final String? message;

  UserResponse({required this.user, this.message});

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      user: User.fromJson(json['user']),
      message: json['message'],
    );
  }
}

/// Generic message response
class MessageResponse {
  final String message;

  MessageResponse({required this.message});

  factory MessageResponse.fromJson(Map<String, dynamic> json) {
    return MessageResponse(message: json['message'] ?? '');
  }
}
