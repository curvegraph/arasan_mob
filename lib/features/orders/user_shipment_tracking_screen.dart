import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/utils/app_animations.dart';
import '../../core/utils/glass_morphism.dart';
import '../../data/services/secure_api_service.dart';
import '../../providers/user_order_provider.dart';

class UserShipmentTrackingScreen extends StatefulWidget {
  final String orderId;

  const UserShipmentTrackingScreen({super.key, required this.orderId});

  @override
  State<UserShipmentTrackingScreen> createState() =>
      _UserShipmentTrackingScreenState();
}

class _UserShipmentTrackingScreenState
    extends State<UserShipmentTrackingScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _tracking;

  @override
  void initState() {
    super.initState();
    _fetchTracking();
  }

  Future<void> _fetchTracking() async {
    final orderProvider = context.read<UserOrderProvider>();
    final order = orderProvider.getOrderById(widget.orderId);

    if (order == null || order.trackingId == null) {
      setState(() {
        _isLoading = false;
        _error = order == null
            ? 'Order not found'
            : 'No tracking information available for this order.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result =
          await SecureApiService().trackShipment(order.trackingId!);
      if (result['success'] == true && result['tracking'] != null) {
        setState(() {
          _tracking = result['tracking'] as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['error'] as String? ??
              'Unable to fetch tracking information.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load tracking data. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<UserOrderProvider>();
    final order = orderProvider.getOrderById(widget.orderId);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: const Text(
          'Shipment Tracking',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.4,
            height: 1.0,
          ),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFE2E8F0),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _fetchTracking,
            icon: const Icon(Icons.refresh, size: 22),
            tooltip: 'Refresh tracking',
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: _buildBody(order),
    );
  }

  Widget _buildBody(dynamic order) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.userPrimary),
            SizedBox(height: AppSpacing.md),
            Text(
              'Fetching tracking details...',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.userPagePadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  size: 40,
                  color: AppColors.textHint,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _error!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: _fetchTracking,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_tracking == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: _fetchTracking,
      color: AppColors.userPrimary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeSlideIn(
              index: 0,
              child: _buildHeader(order),
            ),
            const SizedBox(height: AppSpacing.md),
            FadeSlideIn(
              index: 1,
              child: _buildCurrentStatus(),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_tracking!['estimated_delivery'] != null ||
                _tracking!['delivered_date'] != null)
              FadeSlideIn(
                index: 2,
                child: _buildDeliveryDateCard(),
              ),
            const SizedBox(height: AppSpacing.md),
            FadeSlideIn(
              index: 3,
              child: _buildActivityTimeline(),
            ),
            const SizedBox(height: AppSpacing.sectionSpacing),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(dynamic order) {
    final courierName = _tracking!['courier_name'] as String? ?? 'Courier';

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.userPagePadding,
        AppSpacing.md,
        AppSpacing.userPagePadding,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: PremiumDecorations.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.userPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.userPrimary.withValues(alpha: 0.25),
                  ),
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  size: 20,
                  color: AppColors.userPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (order != null)
                      Text(
                        'Order #${order.id}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      courierName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (order?.trackingId != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.tag,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'AWB: ${order.trackingId}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentStatus() {
    final currentStatus =
        _tracking!['current_status'] as String? ?? 'Unknown';
    final statusCode = _tracking!['shipment_status'] as int? ?? 0;

    final statusColor = _getStatusColor(statusCode);
    final statusIcon = _getStatusIcon(statusCode);

    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.userPagePadding),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: PremiumDecorations.glassCard(),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Icon(statusIcon, size: 24, color: statusColor),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Status',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  currentStatus,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              _getStatusLabel(statusCode),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryDateCard() {
    final deliveredDate = _tracking!['delivered_date'] as String?;
    final estimatedDelivery = _tracking!['estimated_delivery'] as String?;

    final isDelivered = deliveredDate != null && deliveredDate.isNotEmpty;
    final dateStr = isDelivered ? deliveredDate : estimatedDelivery;

    if (dateStr == null || dateStr.isEmpty) return const SizedBox.shrink();

    DateTime? date;
    try {
      date = DateTime.parse(dateStr);
    } catch (_) {
      return const SizedBox.shrink();
    }

    final formattedDate = DateFormat('dd MMM yyyy').format(date);
    final label = isDelivered ? 'Delivered On' : 'Estimated Delivery';
    final color = isDelivered ? AppColors.success : AppColors.info;
    final icon =
        isDelivered ? Icons.check_circle_outline : Icons.calendar_today;

    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.userPagePadding),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: PremiumDecorations.glassCard(),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTimeline() {
    final activities = (_tracking!['activities'] as List<dynamic>?) ?? [];

    if (activities.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.userPagePadding),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: PremiumDecorations.glassCard(),
        child: const Column(
          children: [
            Icon(Icons.info_outline, size: 32, color: AppColors.textHint),
            SizedBox(height: AppSpacing.sm),
            Text(
              'No tracking activities available yet.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // Sort activities by date, latest first
    final sortedActivities = List<Map<String, dynamic>>.from(
      activities.map((a) => a as Map<String, dynamic>),
    );
    sortedActivities.sort((a, b) {
      final dateA = DateTime.tryParse(a['date'] as String? ?? '');
      final dateB = DateTime.tryParse(b['date'] as String? ?? '');
      if (dateA == null || dateB == null) return 0;
      return dateB.compareTo(dateA);
    });

    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.userPagePadding),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: PremiumDecorations.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timeline, size: 18, color: AppColors.userPrimary),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Tracking History',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.lg, color: AppColors.divider),
          ...List.generate(sortedActivities.length, (index) {
            final activity = sortedActivities[index];
            final isFirst = index == 0;
            final isLast = index == sortedActivities.length - 1;

            final status = activity['status'] as String? ?? '';
            final location = activity['location'] as String? ?? '';
            final dateStr = activity['date'] as String? ?? '';

            DateTime? date;
            try {
              date = DateTime.parse(dateStr);
            } catch (_) {}

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline indicator
                  Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isFirst
                              ? AppColors.userPrimary
                              : AppColors.surfaceVariant,
                          shape: BoxShape.circle,
                          border: isFirst
                              ? null
                              : Border.all(color: AppColors.border),
                          boxShadow: isFirst
                              ? [
                                  BoxShadow(
                                    color: AppColors.userPrimary
                                        .withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          isFirst ? Icons.circle : Icons.circle,
                          size: isFirst ? 10 : 8,
                          color: isFirst
                              ? Colors.white
                              : AppColors.textHint,
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            constraints:
                                const BoxConstraints(minHeight: 30),
                            color: isFirst
                                ? AppColors.userPrimary
                                    .withValues(alpha: 0.3)
                                : AppColors.border,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Activity details
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: isLast ? 0 : AppSpacing.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            status,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  isFirst ? FontWeight.w700 : FontWeight.w500,
                              color: isFirst
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          if (location.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: isFirst
                                        ? AppColors.userPrimary
                                        : AppColors.textHint,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      location,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isFirst
                                            ? AppColors.textPrimary
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (date != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                DateFormat('dd MMM yyyy, hh:mm a')
                                    .format(date),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getStatusColor(int statusCode) {
    // Shiprocket status codes:
    // 1 = Pickup pending, 2 = Pickup scheduled, 3 = Pickup generated
    // 4 = Pickup completed, 5 = In transit, 6 = Out for delivery
    // 7 = Delivered, 8 = Cancelled, 9 = RTO
    if (statusCode == 7) return AppColors.success;
    if (statusCode >= 8) return AppColors.error;
    if (statusCode >= 5) return AppColors.info;
    return AppColors.warning;
  }

  IconData _getStatusIcon(int statusCode) {
    if (statusCode == 7) return Icons.check_circle;
    if (statusCode >= 8) return Icons.cancel;
    if (statusCode == 6) return Icons.delivery_dining;
    if (statusCode >= 4) return Icons.local_shipping;
    return Icons.inventory_2_outlined;
  }

  String _getStatusLabel(int statusCode) {
    switch (statusCode) {
      case 1:
        return 'Pickup Pending';
      case 2:
        return 'Pickup Scheduled';
      case 3:
        return 'Pickup Generated';
      case 4:
        return 'Picked Up';
      case 5:
        return 'In Transit';
      case 6:
        return 'Out for Delivery';
      case 7:
        return 'Delivered';
      case 8:
        return 'Cancelled';
      case 9:
        return 'RTO';
      default:
        return 'Processing';
    }
  }
}
