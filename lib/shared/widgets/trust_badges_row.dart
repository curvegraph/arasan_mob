import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/product.dart';

/// Renders up to 3 trust badges on a product surface.
///
/// Shows ONLY the badges the admin explicitly set on THIS product — there is no
/// store-default fallback, so a product with no configured badges shows none.
/// Per slot:
///   * If `enabled` is `false`, or the title is blank/absent → skip the slot.
///   * Otherwise → show the slot with the product's own title/subtitle.
class TrustBadgesRow extends StatelessWidget {
  final Product product;

  const TrustBadgesRow({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final badges = product.badges;

    final slots = <_BadgeSlot>[];

    void addSlot({
      required bool? overrideEnabled,
      required String? overrideTitle,
      required String? overrideSubtitle,
      required IconData icon,
    }) {
      if (overrideEnabled == false) return;
      final title = overrideTitle?.trim() ?? '';
      // Only admin-added (per-product) badges show — no store default.
      if (title.isEmpty) return;
      slots.add(_BadgeSlot(
        icon: icon,
        title: title,
        subtitle: overrideSubtitle?.trim() ?? '',
      ));
    }

    addSlot(
      overrideEnabled: badges.badge1Enabled,
      overrideTitle: badges.badge1Title,
      overrideSubtitle: badges.badge1Subtitle,
      icon: Icons.local_shipping_outlined,
    );
    addSlot(
      overrideEnabled: badges.badge2Enabled,
      overrideTitle: badges.badge2Title,
      overrideSubtitle: badges.badge2Subtitle,
      icon: Icons.replay_outlined,
    );
    addSlot(
      overrideEnabled: badges.badge3Enabled,
      overrideTitle: badges.badge3Title,
      overrideSubtitle: badges.badge3Subtitle,
      icon: Icons.verified_outlined,
    );

    if (slots.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassWhite),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: slots
            .map((s) => Expanded(child: _badgeTile(s)))
            .toList(),
      ),
    );
  }

  Widget _badgeTile(_BadgeSlot slot) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(slot.icon, size: 22, color: AppColors.userPrimary),
        const SizedBox(height: 6),
        Text(
          slot.title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        if (slot.subtitle.trim().isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            slot.subtitle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _BadgeSlot {
  final IconData icon;
  final String title;
  final String subtitle;
  _BadgeSlot({required this.icon, required this.title, required this.subtitle});
}
