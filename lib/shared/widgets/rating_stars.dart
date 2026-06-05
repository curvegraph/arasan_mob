import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final bool showCount;
  final int? count;
  final bool interactive;
  final ValueChanged<double>? onRatingChanged;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 16,
    this.showCount = false,
    this.count,
    this.interactive = false,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (interactive) {
      return _buildInteractive();
    }
    return _buildCompactBadge();
  }

  Widget _buildCompactBadge() {
    if (rating <= 0) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.ratingBg,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.star, color: Colors.white, size: 10),
            ],
          ),
        ),
        if (showCount && count != null) ...[
          const SizedBox(width: 4),
          Text(
            '($count)',
            style: TextStyle(
              fontSize: size * 0.7,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInteractive() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1.0;
        IconData icon;
        if (rating >= starValue) {
          icon = Icons.star;
        } else if (rating >= starValue - 0.5) {
          icon = Icons.star_half;
        } else {
          icon = Icons.star_border;
        }

        return GestureDetector(
          onTap: interactive ? () => onRatingChanged?.call(starValue) : null,
          child: Icon(icon, color: AppColors.rating, size: size),
        );
      }),
    );
  }
}
