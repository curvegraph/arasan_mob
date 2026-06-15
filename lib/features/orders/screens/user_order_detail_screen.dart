import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_animations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/glass_morphism.dart';
import '../../../data/models/order.dart';
import '../../../providers/user_order_provider.dart';
import '../../../shared/widgets/image_placeholder.dart';

class UserOrderDetailScreen extends StatelessWidget {
  final String orderId;

  const UserOrderDetailScreen({super.key, required this.orderId});

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.warning;
      case OrderStatus.confirmed:
        return AppColors.info;
      case OrderStatus.shipped:
        return AppColors.info;
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

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<UserOrderProvider>();
    final order = orderProvider.getOrderById(orderId);

    if (order == null) {
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: 70,
          title: const Text(
            'Order Details',
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
        body: Center(
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
                  Icons.receipt_long_outlined,
                  size: 40,
                  color: AppColors.textHint,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Order not found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'This order may have been removed or is unavailable.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: () => context.go('/shop/account/orders'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text('Back to Orders'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: const Text(
          'Order Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.4,
            height: 1.0,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeSlideIn(index: 0, child: _buildOrderInfoHeader(order)),
            const SizedBox(height: AppSpacing.md),
            FadeSlideIn(index: 1, child: _buildTrackingTimeline(order)),
            const SizedBox(height: AppSpacing.md),
            FadeSlideIn(index: 2, child: _buildItemsList(context, order)),
            const SizedBox(height: AppSpacing.md),
            FadeSlideIn(index: 3, child: _buildShippingAddress(order)),
            const SizedBox(height: AppSpacing.md),
            FadeSlideIn(index: 4, child: _buildPaymentInfo(order)),
            const SizedBox(height: AppSpacing.md),
            FadeSlideIn(index: 5, child: _buildPriceBreakdown(order)),
            const SizedBox(height: AppSpacing.md),
            FadeSlideIn(
              index: 6,
              child: _buildActionButtons(context, order,
                  context.read<UserOrderProvider>()),
            ),
            const SizedBox(height: AppSpacing.sectionSpacing),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfoHeader(Order order) {
    final statusColor = _statusColor(order.status);

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.userPagePadding,
        AppSpacing.md,
        AppSpacing.userPagePadding,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: PremiumDecorations.glassCard(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Order Placed',
                style:
                    TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormatter.formatWithTime(order.createdAt),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              order.statusLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingTimeline(Order order) {
    final steps = <_TimelineStep>[
      _TimelineStep(
        title: 'Order Placed',
        date: order.createdAt,
        isCompleted: true,
      ),
      _TimelineStep(
        title: 'Confirmed',
        date: order.confirmedAt,
        isCompleted: order.confirmedAt != null ||
            order.status == OrderStatus.confirmed ||
            order.status == OrderStatus.shipped ||
            order.status == OrderStatus.outForDelivery ||
            order.status == OrderStatus.delivered,
      ),
      _TimelineStep(
        title: 'Shipped',
        date: order.shippedAt,
        isCompleted: order.shippedAt != null ||
            order.status == OrderStatus.shipped ||
            order.status == OrderStatus.outForDelivery ||
            order.status == OrderStatus.delivered,
      ),
      _TimelineStep(
        title: 'Out for Delivery',
        date: null,
        isCompleted: order.status == OrderStatus.outForDelivery ||
            order.status == OrderStatus.delivered,
      ),
      _TimelineStep(
        title: 'Delivered',
        date: order.deliveredAt,
        isCompleted: order.status == OrderStatus.delivered,
      ),
    ];

    if (order.status == OrderStatus.cancelled) {
      steps.clear();
      steps.addAll([
        _TimelineStep(
          title: 'Order Placed',
          date: order.createdAt,
          isCompleted: true,
        ),
        _TimelineStep(
          title: 'Cancelled',
          date: order.cancelledAt,
          isCompleted: true,
          isCancelled: true,
        ),
      ]);
    }

    if (order.status == OrderStatus.returned) {
      steps.add(_TimelineStep(
        title: 'Returned',
        date: null,
        isCompleted: true,
        isCancelled: true,
      ));
    }

    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.userPagePadding),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: PremiumDecorations.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.timeline,
                size: 18,
                color: AppColors.userPrimary,
              ),
              const SizedBox(width: AppSpacing.sm),
              const Text(
                'Order Tracking',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          if (order.trackingId != null) ...[
            const SizedBox(height: 4),
            Text(
              'Tracking ID: ${order.trackingId}',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          ...List.generate(steps.length, (index) {
            final step = steps[index];
            final isLast = index == steps.length - 1;

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
                          color: step.isCancelled
                              ? AppColors.error
                              : step.isCompleted
                                  ? AppColors.success
                                  : AppColors.surfaceVariant,
                          shape: BoxShape.circle,
                          border: step.isCompleted || step.isCancelled
                              ? null
                              : Border.all(color: AppColors.border),
                          boxShadow: step.isCompleted && !step.isCancelled
                              ? [
                                  BoxShadow(
                                    color: AppColors.success
                                        .withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          step.isCancelled
                              ? Icons.close
                              : step.isCompleted
                                  ? Icons.check
                                  : Icons.circle,
                          size: step.isCompleted || step.isCancelled
                              ? 14
                              : 8,
                          color: step.isCompleted || step.isCancelled
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
                            color: step.isCompleted
                                ? AppColors.success
                                    .withValues(alpha: 0.4)
                                : AppColors.border,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Step details
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: isLast ? 0 : AppSpacing.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: step.isCancelled
                                  ? AppColors.error
                                  : step.isCompleted
                                      ? AppColors.textPrimary
                                      : AppColors.textHint,
                            ),
                          ),
                          if (step.date != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                DateFormatter.formatWithTime(step.date!),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          if (step.isCancelled &&
                              order.cancelReason != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Reason: ${order.cancelReason}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.error,
                                  fontStyle: FontStyle.italic,
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

  Widget _buildItemsList(BuildContext context, Order order) {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.userPagePadding),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: PremiumDecorations.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 18,
                color: AppColors.userPrimary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Items (${order.itemCount})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.lg, color: AppColors.divider),
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: ImagePlaceholder(
                        imageUrl: item.imageUrl,
                        width: 56,
                        height: 56,
                        icon: Icons.phone_android,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Qty: ${item.quantity}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      CurrencyFormatter.format(item.total),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildShippingAddress(Order order) {
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
              Icon(Icons.location_on_outlined,
                  size: 20, color: AppColors.userPrimary),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Shipping Address',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.lg, color: AppColors.divider),
          if (order.customerName.trim().isNotEmpty) ...[
            Text(
              order.customerName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
          ],
          if (order.customerPhone.trim().isNotEmpty) ...[
            Text(
              order.customerPhone,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
          ],
          // Fall back to a clear message instead of a blank box when the order
          // carries no saved address (e.g. an abandoned/unpaid order).
          Text(
            order.shippingAddress.trim().isNotEmpty
                ? order.shippingAddress
                : 'No shipping address on file for this order.',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo(Order order) {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.userPagePadding),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: PremiumDecorations.glassCard(),
      child: Row(
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
            child: const Icon(Icons.payment,
                size: 20, color: AppColors.userPrimary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Method',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  order.paymentMethod,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: order.isPaid
                  ? AppColors.success.withValues(alpha: 0.15)
                  : AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: order.isPaid
                    ? AppColors.success.withValues(alpha: 0.3)
                    : AppColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              order.isPaid ? 'Paid' : 'Unpaid',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color:
                    order.isPaid ? AppColors.success : AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdown(Order order) {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.userPagePadding),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: PremiumDecorations.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_outlined,
                size: 18,
                color: AppColors.userPrimary,
              ),
              const SizedBox(width: AppSpacing.sm),
              const Text(
                'Price Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.lg, color: AppColors.divider),
          _priceRow('Subtotal', order.subtotal),
          const SizedBox(height: AppSpacing.sm),
          _priceRow(
            'Delivery Charge',
            order.deliveryCharge,
            valueColor: order.deliveryCharge == 0
                ? AppColors.success
                : null,
            displayValue: order.deliveryCharge == 0
                ? 'FREE'
                : CurrencyFormatter.format(order.deliveryCharge),
          ),
          const SizedBox(height: AppSpacing.sm),
          _priceRow('Tax', order.taxAmount),
          const Padding(
            padding:
                EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Divider(color: AppColors.divider),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                CurrencyFormatter.format(order.totalAmount),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, double amount,
      {Color? valueColor, String? displayValue}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 14, color: AppColors.textSecondary),
        ),
        Text(
          displayValue ?? CurrencyFormatter.format(amount),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    Order order,
    UserOrderProvider provider,
  ) {
    final canCancel = order.status == OrderStatus.pending ||
        order.status == OrderStatus.confirmed;
    final isDelivered = order.status == OrderStatus.delivered;
    final canTrack = (order.status == OrderStatus.shipped ||
            order.status == OrderStatus.outForDelivery) &&
        order.trackingId != null;

    if (!canCancel && !isDelivered && !canTrack) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.userPagePadding),
      child: Column(
        children: [
          if (canTrack) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => context.push(
                    '/shop/account/orders/${order.id}/tracking'),
                icon: const Icon(Icons.local_shipping_outlined, size: 20),
                label: const Text(
                  'Track Shipment',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (canCancel)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () =>
                    _showCancelDialog(context, order, provider),
                icon: const Icon(Icons.cancel_outlined, size: 20),
                label: const Text(
                  'Cancel Order',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          if (isDelivered) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (order.items.isNotEmpty) {
                    context.push(
                        '/shop/product/${order.items.first.productId}/write-review');
                  }
                },
                icon: const Icon(Icons.rate_review_outlined, size: 20),
                label: const Text(
                  'Write a Review',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                          'Return/Refund request feature coming soon'),
                      backgroundColor: AppColors.info,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.assignment_return_outlined,
                    size: 20),
                label: const Text(
                  'Return / Refund',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.warning,
                  side: const BorderSide(color: AppColors.warning),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showCancelDialog(
    BuildContext context,
    Order order,
    UserOrderProvider provider,
  ) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Cancel Order',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to cancel this order?',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: reasonController,
              maxLines: 3,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Reason for cancellation (optional)',
                hintStyle: const TextStyle(
                    fontSize: 13, color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppColors.userPrimary),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'No, Keep Order',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              final reason = reasonController.text.trim().isEmpty
                  ? 'Customer requested cancellation'
                  : reasonController.text.trim();
              provider.cancelOrder(order.id, reason);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Order cancelled successfully'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin: const EdgeInsets.all(AppSpacing.md),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}

class _TimelineStep {
  final String title;
  final DateTime? date;
  final bool isCompleted;
  final bool isCancelled;

  _TimelineStep({
    required this.title,
    this.date,
    this.isCompleted = false,
    this.isCancelled = false,
  });
}
