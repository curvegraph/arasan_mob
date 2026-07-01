import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_animations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
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
  String _searchQuery = '';

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
        // Never show an auto back arrow — it shifted the title right when this
        // page was reached from Account (push) vs the bottom-nav tab (go). The
        // heading now sits at the same left position both ways. System back /
        // bottom-nav still navigate away.
        automaticallyImplyLeading: false,
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
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildSearchAndFilter(context),
          Expanded(
              child: _OrdersList(
                  onRefresh: _loadOrders, searchQuery: _searchQuery)),
        ],
      ),
    );
  }

  // Search field + a "Filters" button that opens the status filter sheet
  // (Meesho-style), replacing the old inline scrolling chip row.
  Widget _buildSearchAndFilter(BuildContext context) {
    final currentFilter = context.watch<UserOrderProvider>().statusFilter;
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                // No border line — just a subtle filled pill so it stays
                // visible on the white page.
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 20, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: const InputDecoration(
                        hintText: 'Search orders',
                        border: InputBorder.none,
                        isDense: true,
                        hintStyle: TextStyle(
                            fontSize: 14, color: Color(0xFF94A3B8)),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: () => _showFilterSheet(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: currentFilter != null
                    ? AppColors.primary.withValues(alpha: 0.10)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: currentFilter != null
                      ? AppColors.primary
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.tune,
                      size: 18,
                      color: currentFilter != null
                          ? AppColors.primary
                          : const Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Text('Filters',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: currentFilter != null
                              ? AppColors.primary
                              : const Color(0xFF64748B))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    final provider = context.read<UserOrderProvider>();
    OrderStatus? selected = provider.statusFilter;
    const options = <MapEntry<OrderStatus?, String>>[
      MapEntry(null, 'All'),
      MapEntry(OrderStatus.pending, 'Ordered'),
      MapEntry(OrderStatus.confirmed, 'Confirmed'),
      MapEntry(OrderStatus.shipped, 'Shipped'),
      MapEntry(OrderStatus.outForDelivery, 'Out for Delivery'),
      MapEntry(OrderStatus.delivered, 'Delivered'),
      MapEntry(OrderStatus.cancelled, 'Cancelled'),
      MapEntry(OrderStatus.returned, 'Return'),
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.8,
                ),
                child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 8, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('FILTER BY',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                color: Color(0xFF1A1A1A))),
                        IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Text('Status',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64748B))),
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: options
                            .map((o) => RadioListTile<OrderStatus?>(
                                  value: o.key,
                                  groupValue: selected,
                                  onChanged: (v) =>
                                      setSheet(() => selected = v),
                                  title: Text(o.value),
                                  activeColor: AppColors.primary,
                                  dense: true,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              provider.setStatusFilter(null);
                              Navigator.pop(ctx);
                            },
                            style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10))),
                            child: const Text('Clear',
                                style: TextStyle(
                                    color: Color(0xFF334155),
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              provider.setStatusFilter(selected);
                              Navigator.pop(ctx);
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10))),
                            child: const Text('Apply',
                                style: TextStyle(fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _OrdersList extends StatelessWidget {
  final VoidCallback onRefresh;
  final String searchQuery;

  const _OrdersList({required this.onRefresh, this.searchQuery = ''});

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<UserOrderProvider>();

    if (orderProvider.isLoading) {
      return _buildShimmerLoading();
    }

    var orders = orderProvider.orders;
    // Client-side search across order number / id / product names.
    final q = searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      orders = orders
          .where((o) =>
              o.orderNumber.toLowerCase().contains(q) ||
              o.id.toLowerCase().contains(q) ||
              o.items.any((it) => it.productName.toLowerCase().contains(q)))
          .toList();
    }

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
            child: OrderCard(order: orders[index]),
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

class OrderCard extends StatelessWidget {
  final Order order;

  const OrderCard({super.key, required this.order});

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

  String _paymentLabel(String method) {
    switch (method.toLowerCase()) {
      case 'cod':
        return 'COD';
      case 'online':
      case 'razorpay':
        return 'Online';
      case 'upi':
        return 'UPI';
      case 'card':
        return 'Card';
      default:
        return method.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstItem = order.items.isNotEmpty ? order.items.first : null;
    final statusColor = _statusColor(order.status);
    final isDelivered = order.status == OrderStatus.delivered;
    final canTrack = order.status == OrderStatus.shipped ||
        order.status == OrderStatus.outForDelivery;
    final detailRoute = '/shop/account/orders/${order.id}';

    // Rich product card: status + payment + order # + image + name (variant is
    // baked into the product name by the backend) + date + item count, then a
    // footer with the total and a context action (Track / Rate & Review / View).
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => context.push(detailRoute),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ImagePlaceholder(
                      imageUrl: firstItem?.imageUrl ?? '',
                      width: 76,
                      height: 76,
                      icon: Icons.phone_android,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status + payment + order number
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                order.statusLabel.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: statusColor,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _paymentLabel(order.paymentMethod),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF64748B),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            Text(
                              '#${order.orderNumber}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          firstItem?.productName ?? 'Product',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                size: 13, color: AppColors.textHint),
                            const SizedBox(width: 4),
                            Text(
                              DateFormatter.format(order.createdAt),
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.shopping_bag_outlined,
                                size: 13, color: AppColors.textHint),
                            const SizedBox(width: 4),
                            Text(
                              '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          // Footer: total + context action
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 10),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textHint,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      CurrencyFormatter.format(order.totalAmount),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (isDelivered)
                  _footerAction(
                    icon: Icons.star_outline,
                    label: 'Rate & Review',
                    onTap: () {
                      if (order.items.length == 1 && firstItem != null) {
                        context.push(
                            '/shop/product/${firstItem.productId}/write-review');
                      } else {
                        context.push(detailRoute);
                      }
                    },
                  )
                else if (canTrack)
                  _footerAction(
                    icon: Icons.local_shipping_outlined,
                    label: 'Track',
                    // Open the order details page (which shows the tracking
                    // timeline) rather than the Shiprocket tracking screen,
                    // which errors when live tracking isn't available.
                    onTap: () => context.push(detailRoute),
                  )
                else
                  _footerAction(
                    icon: Icons.chevron_right,
                    label: 'View',
                    onTap: () => context.push(detailRoute),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
