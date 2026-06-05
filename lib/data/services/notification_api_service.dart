import 'api_service.dart';

class NotificationApiService {
  final ApiService _api = ApiService();

  /// Register device for push notifications
  Future<void> registerDevice({
    required String fcmToken,
    String? deviceType,
    String? deviceName,
    bool marketingEnabled = true,
  }) async {
    await _api.post(
      '/notifications/register-device',
      body: {
        'fcmToken': fcmToken,
        if (deviceType != null) 'deviceType': deviceType,
        if (deviceName != null) 'deviceName': deviceName,
        'marketingEnabled': marketingEnabled,
      },
      requireAuth: true,
    );
  }

  /// Unregister device
  Future<void> unregisterDevice(String fcmToken) async {
    await _api.post(
      '/notifications/unregister-device',
      body: {'fcmToken': fcmToken},
      requireAuth: true,
    );
  }

  /// Get user's notifications
  Future<NotificationsResponse> getNotifications({int page = 1, int limit = 20}) async {
    final response = await _api.get(
      '/notifications',
      queryParams: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
      requireAuth: true,
    );

    return NotificationsResponse.fromJson(response);
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    final response = await _api.get(
      '/notifications/unread-count',
      requireAuth: true,
    );

    return response['unreadCount'] as int;
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _api.patch(
      '/notifications/$notificationId/read',
      requireAuth: true,
    );
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    await _api.patch(
      '/notifications/mark-all-read',
      requireAuth: true,
    );
  }
}

class NotificationsResponse {
  final List<NotificationItem> notifications;
  final NotificationPagination pagination;

  NotificationsResponse({
    required this.notifications,
    required this.pagination,
  });

  factory NotificationsResponse.fromJson(Map<String, dynamic> json) {
    return NotificationsResponse(
      notifications: (json['notifications'] as List)
          .map((n) => NotificationItem.fromJson(n))
          .toList(),
      pagination: NotificationPagination.fromJson(json['pagination']),
    );
  }
}

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      type: json['type'],
      data: json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class NotificationPagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  NotificationPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory NotificationPagination.fromJson(Map<String, dynamic> json) {
    return NotificationPagination(
      page: json['page'],
      limit: json['limit'],
      total: json['total'],
      totalPages: json['totalPages'],
    );
  }
}
