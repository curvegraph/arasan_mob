import 'package:flutter/material.dart';
import '../data/models/notification_item.dart';

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  final bool _isLoading = false;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get hasUnread => unreadCount > 0;

  List<AppNotification> getByType(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index >= 0) {
      _notifications = List.from(_notifications);
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  void markAllAsRead() {
    _notifications = _notifications
        .map((n) => n.isRead ? n : n.copyWith(isRead: true))
        .toList();
    notifyListeners();
  }

  void removeNotification(String id) {
    _notifications = List.from(_notifications)
      ..removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void clearAll() {
    _notifications = [];
    notifyListeners();
  }
}
