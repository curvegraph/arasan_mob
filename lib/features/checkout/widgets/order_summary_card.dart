import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_animations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/glass_morphism.dart';
import '../../../data/models/cart.dart';
import '../../../data/models/address.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/checkout_provider.dart';
import '../../../providers/store_settings_provider.dart';
import '../../../shared/widgets/image_placeholder.dart';

class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final checkoutProvider = context.watch<CheckoutProvider>();
    final cart = cartProvider.cart;
    final address = checkoutProvider.selectedAddress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeSlideIn(
          index: 0,
          child: const Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Cart items
        FadeSlideIn(
          index: 1,
          child: Container(
            decoration: PremiumDecorations.glassCard(borderRadius: 16),
            child: Column(
              children: [
                // Items header
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.divider),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.userPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.shopping_bag_outlined,
                          size: 16,
                          color: AppColors.userPrimary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '${cart.activeItems.length} item${cart.activeItems.length == 1 ? '' : 's'} in order',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Item list
                ...cart.activeItems.map(
                  (item) => _buildMiniItem(item),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Delivery address
        if (address != null)
          FadeSlideIn(
            index: 2,
            child: _buildAddressCard(address, checkoutProvider),
          ),

        const SizedBox(height: AppSpacing.md),

        // Payment method
        FadeSlideIn(
          index: 3,
          child: _buildPaymentMethodCard(checkoutProvider),
        ),

        const SizedBox(height: AppSpacing.md),

        // Price breakdown
        FadeSlideIn(
          index: 4,
          child: Builder(builder: (ctx) {
            final settings = ctx.watch<StoreSettingsProvider>();
            return _buildPriceBreakdown(cart, checkoutProvider, settings);
          }),
        ),
      ],
    );
  }

  Widget _buildMiniItem(CartItem item) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ImagePlaceholder(
              imageUrl: item.product.imageUrls.isNotEmpty
                  ? item.product.imageUrls.first
                  : null,
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
                  item.product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
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
          Text(
            CurrencyFormatter.format(item.totalPrice),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(
      UserAddress address, CheckoutProvider checkoutProvider) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: PremiumDecorations.glassCard(borderRadius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.userPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: AppColors.userPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Text(
                'Delivery Address',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  address.label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.lg, color: AppColors.divider),
          Text(
            address.fullName,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            address.formattedAddress,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Phone: ${address.phone}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_shipping_outlined,
                  size: 14,
                  color: AppColors.success,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Estimated delivery: ${checkoutProvider.deliveryEstimate}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(CheckoutProvider checkoutProvider) {
    final paymentIcon = checkoutProvider.paymentMethod == PaymentMethod.cod
        ? Icons.account_balance_wallet_outlined
        : Icons.lock_outline;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: PremiumDecorations.glassCard(borderRadius: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.userPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(paymentIcon, size: 20, color: AppColors.userPrimary),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                checkoutProvider.paymentMethodLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdown(
      Cart cart, CheckoutProvider checkoutProvider, StoreSettingsProvider settings) {
    // Standard delivery follows the admin's configured rule. Express adds a
    // flat surcharge on top.
    final standardDelivery = settings.deliveryChargeFor(cart.subtotal);
    final deliveryCharge =
        checkoutProvider.deliveryOption == DeliveryOption.express
            ? standardDelivery + checkoutProvider.expressSurcharge
            : standardDelivery;

    final tax = settings.taxFor(cart.subtotal);
    final totalWithDelivery = cart.subtotal -
        cart.couponDiscount +
        deliveryCharge +
        tax;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: PremiumDecorations.glassCard(borderRadius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.userPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.receipt_outlined,
                  size: 16,
                  color: AppColors.userPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Text(
                'Price Details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.lg, color: AppColors.divider),
          _buildRow(
            'Subtotal',
            CurrencyFormatter.format(cart.totalOriginalPrice),
          ),
          if (cart.productDiscount > 0)
            _buildRow(
              'Product Discount',
              '- ${CurrencyFormatter.format(cart.productDiscount)}',
              valueColor: AppColors.success,
            ),
          if (cart.couponDiscount > 0)
            _buildRow(
              'Coupon Discount',
              '- ${CurrencyFormatter.format(cart.couponDiscount)}',
              valueColor: AppColors.success,
            ),
          _buildRow(
            'Delivery',
            deliveryCharge == 0
                ? 'FREE'
                : CurrencyFormatter.format(deliveryCharge),
            valueColor: deliveryCharge == 0 ? AppColors.success : null,
          ),
          if (tax > 0)
            _buildRow(
              settings.taxLabel(),
              CurrencyFormatter.format(tax),
            ),
          const Divider(height: AppSpacing.lg, color: AppColors.divider),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                CurrencyFormatter.format(totalWithDelivery),
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

  Widget _buildRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
