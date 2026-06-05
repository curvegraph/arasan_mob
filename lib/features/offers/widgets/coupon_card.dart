import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/offer.dart';

class CouponCard extends StatelessWidget {
  final Coupon coupon;

  const CouponCard({super.key, required this.coupon});

  @override
  Widget build(BuildContext context) {
    final isUsable = coupon.isActive && !coupon.isExpired && !coupon.isLimitReached;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: isUsable ? AppColors.userPrimary : AppColors.textHint,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Code row
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: isUsable
                                ? AppColors.userPrimary.withValues(alpha: 0.15)
                                : AppColors.textHint.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isUsable
                                  ? AppColors.userPrimary.withValues(alpha: 0.3)
                                  : AppColors.textHint.withValues(alpha: 0.3),
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Text(
                            coupon.code,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isUsable
                                  ? AppColors.userPrimary
                                  : AppColors.textHint,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: coupon.code));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Coupon copied! ${coupon.code}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: AppColors.success,
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.userPrimary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.copy,
                              size: 18,
                              color: AppColors.userPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Discount badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: isUsable ? AppColors.addToCartGreen : AppColors.textHint,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      coupon.discountType == DiscountType.percentage
                          ? '${coupon.discountValue.toStringAsFixed(0)}% OFF'
                          : '${CurrencyFormatter.format(coupon.discountValue)} OFF',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Description
              Text(
                coupon.description,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Details row
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.xs,
                children: [
                  if (coupon.minOrderAmount != null)
                    _buildDetailChip(
                      Icons.shopping_cart_outlined,
                      'Min: ${CurrencyFormatter.format(coupon.minOrderAmount!)}',
                    ),
                  if (coupon.maxDiscount != null)
                    _buildDetailChip(
                      Icons.savings_outlined,
                      'Max: ${CurrencyFormatter.format(coupon.maxDiscount!)}',
                    ),
                  _buildDetailChip(
                    Icons.calendar_today_outlined,
                    'Expires: ${DateFormat('dd MMM yyyy').format(coupon.endDate)}',
                  ),
                ],
              ),

              // Status indicators
              if (!isUsable) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    coupon.isExpired
                        ? 'Expired'
                        : coupon.isLimitReached
                            ? 'Limit Reached'
                            : 'Inactive',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],

              // Apply button
              if (isUsable) ...[
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.push('/shop/cart'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.userPrimary,
                      side: const BorderSide(color: AppColors.userPrimary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    ),
                    child: const Text(
                      'Apply',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;

  _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(12),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final end = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, end > metric.length ? metric.length : end),
          paint,
        );
        distance = end + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
