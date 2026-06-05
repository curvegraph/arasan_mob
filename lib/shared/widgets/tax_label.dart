import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/store_settings_provider.dart';

/// Shows "Inclusive of all taxes" when the admin has configured tax-inclusive
/// pricing. When tax is added on top at checkout instead, this widget renders
/// nothing — the tax line on the cart/checkout summary is already enough.
///
/// Re-renders live when admin flips the inclusive toggle.
class TaxLabel extends StatelessWidget {
  final double fontSize;

  const TaxLabel({super.key, this.fontSize = 11});

  @override
  Widget build(BuildContext context) {
    final inclusive = context.watch<StoreSettingsProvider>().taxInclusive;
    if (!inclusive) return const SizedBox.shrink();
    return Text(
      'Inclusive of all taxes',
      style: TextStyle(
        fontSize: fontSize,
        color: AppColors.textSecondary,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}
