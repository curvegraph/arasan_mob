import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/store_settings_provider.dart';

/// Small line that shows the admin-configured delivery charge on a product
/// surface. Reads from [StoreSettingsProvider] which is realtime-subscribed
/// to `store_settings`, so the label updates live when the admin saves a
/// new base charge.
///
///   * `deliveryChargeBase == 0` → "Free Delivery" (green)
///   * otherwise                  → "Delivery: ₹{base}"
class DeliveryBadge extends StatelessWidget {
  final double iconSize;
  final double fontSize;
  final MainAxisAlignment alignment;

  const DeliveryBadge({
    super.key,
    this.iconSize = 12,
    this.fontSize = 11,
    this.alignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<StoreSettingsProvider>();
    final base = settings.deliveryChargeBase;
    final isFree = base <= 0;

    final color = isFree ? AppColors.freeDeliveryGreen : AppColors.textSecondary;
    final label =
        isFree ? 'Free Delivery' : 'Delivery: ${CurrencyFormatter.format(base)}';

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignment,
      children: [
        Icon(Icons.local_shipping_outlined, size: iconSize, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
