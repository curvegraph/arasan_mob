import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key});

  static const List<_CategoryData> _categories = [
    _CategoryData(
      label: 'Smartphones',
      icon: Icons.phone_android,
      color: Color(0xFFE8F5E9),
      textColor: Color(0xFF2E7D32),
    ),
    _CategoryData(
      label: 'Accessories',
      icon: Icons.headphones,
      color: Color(0xFFE3F2FD),
      textColor: Color(0xFF1565C0),
    ),
    _CategoryData(
      label: 'Tablets',
      icon: Icons.tablet_android,
      color: Color(0xFFFFF3E0),
      textColor: Color(0xFFE65100),
    ),
    _CategoryData(
      label: 'Covers',
      icon: Icons.cases_outlined,
      color: Color(0xFFF3E5F5),
      textColor: Color(0xFF7B1FA2),
    ),
    _CategoryData(
      label: 'Chargers',
      icon: Icons.battery_charging_full,
      color: Color(0xFFE0F2F1),
      textColor: Color(0xFF00695C),
    ),
    _CategoryData(
      label: 'Earphones',
      icon: Icons.earbuds,
      color: Color(0xFFFCE4EC),
      textColor: Color(0xFFC62828),
    ),
    _CategoryData(
      label: 'Speakers',
      icon: Icons.speaker,
      color: Color(0xFFE8EAF6),
      textColor: Color(0xFF283593),
    ),
    _CategoryData(
      label: 'Cables',
      icon: Icons.cable,
      color: Color(0xFFFFF8E1),
      textColor: Color(0xFFF57F17),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shop Our Top Categories',
          style: AppTextStyles.sectionTitle,
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              return _CategoryPill(data: _categories[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final _CategoryData data;

  const _CategoryPill({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/shop/products'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: data.color,
          borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(data.icon, size: 18, color: data.textColor),
            const SizedBox(width: 8),
            Text(
              data.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: data.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryData {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;

  const _CategoryData({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
  });
}
