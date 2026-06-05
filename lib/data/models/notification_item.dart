enum NotificationType { order, offer, delivery, general, priceAlert }

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final String? actionUrl;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.actionUrl,
    this.isRead = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  AppNotification copyWith({
    bool? isRead,
  }) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      actionUrl: actionUrl,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  String get typeLabel {
    switch (type) {
      case NotificationType.order:
        return 'Order';
      case NotificationType.offer:
        return 'Offer';
      case NotificationType.delivery:
        return 'Delivery';
      case NotificationType.general:
        return 'General';
      case NotificationType.priceAlert:
        return 'Price Alert';
    }
  }
}
