import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;

import '../../../core/constants/app_colors.dart';

class AccountInfoSection extends StatelessWidget {
  const AccountInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('Customer Service'),
        _LinkTile(
          icon: Icons.support_agent_outlined,
          label: 'Help Center',
          route: '/shop/help',
        ),
        _LinkTile(
          icon: Icons.help_outline,
          label: 'FAQs',
          route: '/shop/help/faq',
        ),
        _LinkTile(
          icon: Icons.local_shipping_outlined,
          label: 'Track Order',
          route: '/shop/account/orders',
        ),
        _LinkTile(
          icon: Icons.local_offer_outlined,
          label: "Today's Offers",
          route: '/shop/offers',
        ),
        _LinkTile(
          icon: Icons.info_outline,
          label: 'About Us',
          route: '/shop/store-info',
        ),
        const SizedBox(height: 16),
        const _SectionHeader('Contact Us'),
        _ContactTile(
          icon: Icons.phone_outlined,
          text: '+91 99444 04603',
          url: 'tel:+919944404603',
        ),
        _ContactTile(
          icon: Icons.mail_outline,
          text: 'arasanmobile2012@gmail.com',
          url: 'mailto:arasanmobile2012@gmail.com',
        ),
        _ContactTile(
          icon: Icons.location_on_outlined,
          text:
              'ASR Complex, Near Periyar Silai,\nOld Bus Stand, Perambalur — 621212,\nTamil Nadu',
          url:
              'https://maps.google.com/?q=ASR+Complex+Near+Periyar+Silai+Old+Bus+Stand+Perambalur',
        ),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Wholesale Dealer in All Mobiles & Accessories',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                'மொபைல் உலகின் அரசன் — King of Mobile World',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '© ${DateTime.now().year} Arasan Mobiles®. All rights reserved.',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.textTertiary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;

  const _LinkTile({
    required this.icon,
    required this.label,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 22, color: AppColors.primary),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        size: 20,
        color: AppColors.textTertiary,
      ),
      onTap: () => context.push(route),
      dense: true,
      visualDensity: const VisualDensity(vertical: -1),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String text;
  final String url;

  const _ContactTile({
    required this.icon,
    required this.text,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 22, color: AppColors.primary),
      title: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textPrimary,
          height: 1.4,
        ),
      ),
      onTap: () => launcher.launchUrl(Uri.parse(url)),
      dense: true,
      visualDensity: const VisualDensity(vertical: -1),
    );
  }
}
