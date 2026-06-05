import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';

class PriceDisplay extends StatelessWidget {
  final double price;
  final double? originalPrice;
  final double fontSize;
  final double originalFontSize;
  final bool showDiscount;
  final Color? priceColor;

  const PriceDisplay({
    super.key,
    required this.price,
    this.originalPrice,
    this.fontSize = 16,
    this.originalFontSize = 13,
    this.showDiscount = true,
    this.priceColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasDiscount = originalPrice != null && originalPrice! > price;
    final discountPercent = hasDiscount
        ? ((originalPrice! - price) / originalPrice! * 100)
        : 0.0;

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        Text(
          CurrencyFormatter.format(price),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: priceColor ?? AppColors.textPrimary,
          ),
        ),
        if (hasDiscount) ...[
          Text(
            CurrencyFormatter.format(originalPrice!),
            style: TextStyle(
              fontSize: originalFontSize,
              color: AppColors.priceMRP,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          if (showDiscount)
            Text(
              '${discountPercent.toStringAsFixed(0)}% off',
              style: TextStyle(
                fontSize: originalFontSize,
                fontWeight: FontWeight.w600,
                color: AppColors.priceGreen,
              ),
            ),
        ],
      ],
    );
  }
}
