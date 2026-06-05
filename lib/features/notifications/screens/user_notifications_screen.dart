import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_animations.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/notification_item.dart';
import '../../../providers/notification_provider.dart';

class UserNotificationsScreen extends StatelessWidget {
  const UserNotificationsScreen({super.key});

  IconData _iconForType(NotificationType type) {
    switch (type) {
      case NotificationType.order:
        return Icons.receipt_long_outlined;
      case NotificationType.offer:
        return Icons.local_offer_outlined;
      case NotificationType.delivery:
        return Icons.local_shipping_outlined;
      case NotificationType.general:
        return Icons.info_outline;
      case NotificationType.priceAlert:
        return Icons.trending_down;
    }
  }

  Color _colorForType(NotificationType type) {
    switch (type) {
      case NotificationType.order:
        return AppColors.info;
      case NotificationType.offer:
        return AppColors.userPrimary;
      case NotificationType.delivery:
        return AppColors.success;
      case NotificationType.general:
        return AppColors.textSecondary;
      case NotificationType.priceAlert:
        return AppColors.addToCartGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<NotificationProvider>();
    final notifications = notifProvider.notifications;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.5,
            height: 1.0,
          ),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
        actions: [
          if (notifProvider.hasUnread)
            TextButton(
              onPressed: () => notifProvider.markAllAsRead(),
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: AppColors.userPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: notifications.isEmpty
          ? _buildEmptyState()
          : _buildNotificationList(context, notifications, notifProvider),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sectionSpacing),
        child: FadeSlideIn(
          index: 0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.userPrimary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.userPrimary.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.notifications_off_outlined,
                  size: 40,
                  color: AppColors.userPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'No Notifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'You\'re all caught up! We\'ll notify\nyou when something new arrives.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationList(
    BuildContext context,
    List<AppNotification> notifications,
    NotificationProvider provider,
  ) {
    // Group by today and earlier
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final todayNotifs = notifications.where((n) {
      final nDate =
          DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      return nDate.isAtSameMomentAs(today);
    }).toList();

    final earlierNotifs = notifications.where((n) {
      final nDate =
          DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      return nDate.isBefore(today);
    }).toList();

    int staggerIndex = 0;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      children: [
        if (todayNotifs.isNotEmpty) ...[
          _buildSectionHeader('Today'),
          ...todayNotifs.map((n) {
            final widget =
                _buildNotifItem(context, n, provider, staggerIndex);
            staggerIndex++;
            return widget;
          }),
        ],
        if (earlierNotifs.isNotEmpty) ...[
          _buildSectionHeader('Earlier'),
          ...earlierNotifs.map((n) {
            final widget =
                _buildNotifItem(context, n, provider, staggerIndex);
            staggerIndex++;
            return widget;
          }),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.userPagePadding,
        AppSpacing.md,
        AppSpacing.userPagePadding,
        AppSpacing.sm,
      ),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: Color(0xFF64748B),
          letterSpacing: 1.4,
        ),
      ),
    );
  }

  Widget _buildNotifItem(
    BuildContext context,
    AppNotification notification,
    NotificationProvider provider,
    int staggerIndex,
  ) {
    final iconData = _iconForType(notification.type);
    final iconColor = _colorForType(notification.type);

    return FadeSlideIn(
      index: staggerIndex,
      child: Dismissible(
        key: Key(notification.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: AppSpacing.lg),
          color: AppColors.error.withValues(alpha: 0.15),
          child: const Icon(Icons.delete_outline, color: AppColors.error),
        ),
        onDismissed: (_) =>
            provider.removeNotification(notification.id),
        child: ScaleOnTap(
          onTap: () {
            if (!notification.isRead) {
              provider.markAsRead(notification.id);
            }
            if (notification.actionUrl != null &&
                notification.actionUrl!.isNotEmpty) {
              context.push(notification.actionUrl!);
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.userPagePadding,
              vertical: 4,
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: notification.isRead
                  ? AppColors.surface
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: notification.isRead
                    ? AppColors.glassWhite
                    : AppColors.userPrimary.withValues(alpha: 0.2),
              ),
              boxShadow: notification.isRead
                  ? null
                  : [
                      BoxShadow(
                        color:
                            AppColors.userPrimary.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: iconColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Icon(iconData, color: iconColor, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            PulseBadge(
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppColors.userPrimary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.userPrimary
                                          .withValues(alpha: 0.5),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: notification.isRead
                              ? AppColors.textHint
                              : AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        DateFormatter.timeAgo(notification.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
