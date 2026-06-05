import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/responsive_helper.dart';

/// Visual "How to Order" section showing 4 steps.
class HowToOrderSection extends StatelessWidget {
  const HowToOrderSection({super.key});

  static const List<_StepData> _steps = [
    _StepData(
      step: '01',
      title: 'Browse Products',
      description: 'Explore our wide range of smartphones, accessories & more.',
      icon: Icons.search,
      color: Color(0xFF1565C0),
      bgColor: Color(0xFFE3F2FD),
    ),
    _StepData(
      step: '02',
      title: 'Add to Cart',
      description: 'Select your favourite items and add them to your cart.',
      icon: Icons.add_shopping_cart,
      color: Color(0xFFE65100),
      bgColor: Color(0xFFFFF3E0),
    ),
    _StepData(
      step: '03',
      title: 'Checkout & Pay',
      description: 'Choose address, delivery option & pay securely online or COD.',
      icon: Icons.payment,
      color: Color(0xFF2E7D32),
      bgColor: Color(0xFFE8F5E9),
    ),
    _StepData(
      step: '04',
      title: 'Get Delivered',
      description: 'Sit back & relax! Your order will arrive at your doorstep.',
      icon: Icons.local_shipping,
      color: Color(0xFF6A1B9A),
      bgColor: Color(0xFFF3E5F5),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How to Order',
          style: AppTextStyles.sectionTitle,
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Get your favourite products in 4 simple steps',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (isMobile)
          // Mobile: 2x2 grid
          _buildMobileGrid()
        else
          // Desktop: 4 in a row with connecting lines
          _buildDesktopRow(),
      ],
    );
  }

  Widget _buildMobileGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _StepCard(data: _steps[0])),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _StepCard(data: _steps[1])),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: _StepCard(data: _steps[2])),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _StepCard(data: _steps[3])),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopRow() {
    return Row(
      children: List.generate(_steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          // Arrow connector between steps
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.arrow_forward,
              size: 20,
              color: AppColors.textHint.withValues(alpha: 0.4),
            ),
          );
        }
        return Expanded(
          child: _StepCard(data: _steps[index ~/ 2]),
        );
      }),
    );
  }
}

class _StepCard extends StatelessWidget {
  final _StepData data;

  const _StepCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Step number badge + icon
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: data.bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  data.icon,
                  size: 26,
                  color: data.color,
                ),
              ),
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: data.color,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      data.step,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Title
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          // Description
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepData {
  final String step;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _StepData({
    required this.step,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}
