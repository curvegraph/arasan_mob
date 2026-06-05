import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_animations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/glass_morphism.dart';
import '../../../data/models/order.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_order_provider.dart';
import '../../../shared/widgets/image_placeholder.dart';

class UserOrdersScreen extends StatefulWidget {
  const UserOrdersScreen({super.key});

  @override
  State<UserOrdersScreen> createState() => _UserOrdersScreenState();
}

class _UserOrdersScreenState extends State<UserOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  void _loadOrders() {
    final authProvider = context.read<AuthProvider>();
    final customerId = authProvider.authToken ?? 'guest';
    context.read<UserOrderProvider>().loadOrders(customerId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: const Text(
          'My Orders',
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
      ),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildFilterTabs(context),
          Expanded(child: _OrdersList(onRefresh: _loadOrders)),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(BuildContext context) {
    final orderProvider = context.watch<UserOrderProvider>();
    final currentFilter = orderProvider.statusFilter;

    final filters = <MapEntry<OrderStatus?, String>>[
      const MapEntry(null, 'All'),
      const MapEntry(OrderStatus.pending, 'Pending'),
      const MapEntry(OrderStatus.confirmed, 'Confirmed'),
      const MapEntry(OrderStatus.shipped, 'Shipped'),
      const MapEntry(OrderStatus.outForDelivery, 'Out for Delivery'),
      const MapEntry(OrderStatus.delivered, 'Delivered'),
      const MapEntry(OrderStatus.cancelled, 'Cancelled'),
    ];

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.userPagePadding),
        child: Row(
          children: filters.map((entry) {
            final isSelected = currentFilter == entry.key;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: FilterChip(
                label: Text(entry.value),
                selected: isSelected,
                onSelected: (_) =>
                    orderProvider.setStatusFilter(entry.key),
                backgroundColor: Colors.white,
                selectedColor: const Color(0xFF1400E0).withValues(alpha: 0.10),
                labelStyle: TextStyle(
                  color: isSelected
                      ? const Color(0xFF1400E0)
                      : const Color(0xFF64748B),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0.1,
                ),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF1400E0)
                      : const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  final VoidCallback onRefresh;

  const _OrdersList({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<UserOrderProvider>();

    if (orderProvider.isLoading) {
      return _buildShimmerLoading();
    }

    final orders = orderProvider.orders;

    if (orders.isEmpty) {
      return _buildEmptyState(context, orderProvider.statusFilter);
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.userPagePadding),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          return FadeSlideIn(
            index: index,
            child: _OrderCard(order: orders[index]),
          );
        },
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.userPagePadding),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // Header shimmer
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 120,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 80,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 70,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Item shimmer
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: 100,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, OrderStatus? filter) {
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
                  Icons.receipt_long,
                  size: 40,
                  color: AppColors.userPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'No Orders Yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Your order history will appear here',
                style: TextStyle(
                    fontSize: 14, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: () => context.go('/shop'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Shop Now',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;

  const _OrderCard({required this.order});

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.warning; // amber instead of gray
      case OrderStatus.confirmed:
        return AppColors.info;
      case OrderStatus.shipped:
        return AppColors.warning;
      case OrderStatus.outForDelivery:
        return Colors.purple;
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.cancelled:
        return AppColors.error;
      case OrderStatus.returned:
        return AppColors.textSecondary;
    }
  }

  // Mini status timeline dots (5 steps now: pending, confirmed, shipped, out_for_delivery, delivered)
  int _statusProgress(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 1;
      case OrderStatus.confirmed:
        return 2;
      case OrderStatus.shipped:
        return 3;
      case OrderStatus.outForDelivery:
        return 4;
      case OrderStatus.delivered:
        return 5;
      case OrderStatus.cancelled:
        return -1;
      case OrderStatus.returned:
        return -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstItem = order.items.isNotEmpty ? order.items.first : null;
    final statusColor = _statusColor(order.status);
    final progress = _statusProgress(order.status);

    return GestureDetector(
      onTap: () => context.push('/shop/account/orders/${order.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: PremiumDecorations.glassCard(),
        child: Column(
          children: [
            // Order header with ID, date, and status badge
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.id}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormatter.format(order.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      order.statusLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Mini status timeline (5 steps: pending, confirmed, shipped, out_for_delivery, delivered)
            if (progress > 0)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                ),
                child: Row(
                  children: List.generate(5, (index) {
                    final isCompleted = index < progress;
                    final isCurrent = index == progress - 1;
                    return Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: isCurrent ? 10 : 8,
                            height: isCurrent ? 10 : 8,
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? statusColor
                                  : AppColors.border,
                              shape: BoxShape.circle,
                            ),
                          ),
                          if (index < 4)
                            Expanded(
                              child: Container(
                                height: 2,
                                color: isCompleted &&
                                        index < progress - 1
                                    ? statusColor.withValues(alpha: 0.4)
                                    : AppColors.border,
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ),
              ),

            const Divider(height: 1, color: AppColors.divider),

            // First item preview
            if (firstItem != null)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: ImagePlaceholder(
                        imageUrl: firstItem.imageUrl,
                        width: 60,
                        height: 60,
                        icon: Icons.phone_android,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            firstItem.productName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (order.items.length > 1)
                            Text(
                              '+${order.items.length - 1} more item${order.items.length - 1 > 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Order footer with items summary, total, and View Details
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${order.itemCount} item${order.itemCount > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.format(order.totalAmount),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () =>
                        context.push('/shop/account/orders/${order.id}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('View Details'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
