import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';

class RatingBar extends StatelessWidget {
  final int starNumber;
  final double percentage;
  final int count;

  const RatingBar({
    super.key,
    required this.starNumber,
    required this.percentage,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 14,
            child: Text(
              '$starNumber',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.star, size: 12, color: AppColors.starYellow),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 600),
                tween: Tween<double>(begin: 0, end: percentage / 100),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return LinearProgressIndicator(
                    value: value,
                    minHeight: 8,
                    backgroundColor: AppColors.glassWhite,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _barColor(starNumber),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 30,
            child: Text(
              '$count',
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _barColor(int star) {
    switch (star) {
      case 5:
        return AppColors.success;
      case 4:
        return const Color(0xFF66BB6A);
      case 3:
        return AppColors.starYellow;
      case 2:
        return AppColors.warning;
      case 1:
        return AppColors.error;
      default:
        return AppColors.textHint;
    }
  }
}
