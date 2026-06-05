import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';

/// Minimal specs display -- clean list of key/value rows with subtle dividers.
/// Key in smoke color, value in obsidian bold.
class SpecsTable extends StatelessWidget {
  final Map<String, String> specs;

  const SpecsTable({super.key, required this.specs});

  @override
  Widget build(BuildContext context) {
    if (specs.isEmpty) {
      return const SizedBox.shrink();
    }

    final entries = specs.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SPECIFICATIONS',
          style: AppTextStyles.overline.copyWith(
            color: AppColors.smoke,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...List.generate(entries.length, (index) {
          final entry = entries[index];
          final isLast = index == entries.length - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm + 4,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        entry.key,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.smoke,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.obsidian,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: AppColors.steel.withValues(alpha: 0.6),
                ),
            ],
          );
        }),
      ],
    );
  }
}
