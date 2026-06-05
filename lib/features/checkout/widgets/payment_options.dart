import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_animations.dart';
import '../../../providers/checkout_provider.dart';
import '../../../providers/store_settings_provider.dart';

/// Two-option payment selector: Online (Razorpay) and Cash on Delivery.
class PaymentOptions extends StatelessWidget {
  const PaymentOptions({super.key});

  @override
  Widget build(BuildContext context) {
    final checkoutProvider = context.watch<CheckoutProvider>();
    final settings = context.watch<StoreSettingsProvider>();
    final selected = checkoutProvider.paymentMethod;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (settings.onlineEnabled)
          FadeSlideIn(
            index: 0,
            child: _PaymentOptionTile(
              icon: Icons.lock_outline,
              label: 'Online Payment',
              description: 'UPI, Cards, Netbanking, Wallets via Razorpay',
              isSelected: checkoutProvider.requiresOnlinePayment,
              onTap: () =>
                  checkoutProvider.setPaymentMethod(PaymentMethod.online),
            ),
          ),
        if (settings.codEnabled)
          FadeSlideIn(
            index: 1,
            child: _PaymentOptionTile(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Cash on Delivery',
              description: 'Pay when you receive your order',
              isSelected: selected == PaymentMethod.cod,
              onTap: () => checkoutProvider.setPaymentMethod(PaymentMethod.cod),
            ),
          ),
      ],
    );
  }
}

class _PaymentOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentOptionTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleOnTap(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceVariant : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.userPrimary.withValues(alpha: 0.6)
                : AppColors.glassWhite,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.userPrimary.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.userPrimary
                        : AppColors.textHint,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.userPrimary,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.userPrimary.withValues(alpha: 0.12)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? AppColors.userPrimary
                      : AppColors.textSecondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: AppColors.userPrimary,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
