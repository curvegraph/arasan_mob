import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/responsive_helper.dart';

/// "Services To Help You Shop" section with 3 info cards.
class ServicesSection extends StatelessWidget {
  const ServicesSection({super.key});

  static const List<_ServiceData> _services = [
    _ServiceData(
      title: 'Frequently Asked Questions',
      description: 'Find answers to common questions about our products and services.',
      icon: Icons.help_outline,
      bgColor: Color(0xFFFFF3E0),
      iconColor: Color(0xFFE65100),
    ),
    _ServiceData(
      title: 'Online Payment',
      description: 'Secure payment options available.',
      icon: Icons.payment,
      bgColor: Color(0xFFE8F5E9),
      iconColor: Color(0xFF2E7D32),
    ),
    _ServiceData(
      title: 'Home Delivery',
      description: 'We deliver to your doorstep.',
      icon: Icons.local_shipping_outlined,
      bgColor: Color(0xFFE3F2FD),
      iconColor: Color(0xFF1565C0),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Services To Help You Shop',
          style: AppTextStyles.sectionTitle,
        ),
        const SizedBox(height: AppSpacing.md),
        if (isMobile)
          Column(
            children: _services.map((service) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _ServiceCard(service: service),
              );
            }).toList(),
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _services.map((service) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: service == _services.last ? 0 : AppSpacing.md,
                  ),
                  child: _ServiceCard(service: service),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final _ServiceData service;

  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: service.bgColor,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(
              service.icon,
              size: 24,
              color: service.iconColor,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Title
          Text(
            service.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Description
          Text(
            service.description,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceData {
  final String title;
  final String description;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;

  const _ServiceData({
    required this.title,
    required this.description,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
  });
}
