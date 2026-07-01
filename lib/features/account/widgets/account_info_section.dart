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
        // Help Center — expands inline to show two simple actions.
        const _ExpandableTile(
          icon: Icons.support_agent_outlined,
          label: 'Help Center',
          children: [
            _BoxActionRow(
              icon: Icons.phone_outlined,
              label: 'Call us',
              url: 'tel:+919944404603',
            ),
            _BoxDivider(),
            _BoxActionRow(
              icon: Icons.mail_outline,
              label: 'Email us',
              url: 'mailto:arasanmobile2012@gmail.com',
            ),
          ],
        ),
        _LinkTile(
          icon: Icons.local_shipping_outlined,
          label: 'Track Order',
          route: '/shop/account/orders',
        ),
        // About Us — expands inline to show the contact details.
        const _ExpandableTile(
          icon: Icons.info_outline,
          label: 'About Us',
          children: [
            _BoxActionRow(
              icon: Icons.phone_outlined,
              label: '+91 99444 04603',
              url: 'tel:+919944404603',
            ),
            _BoxDivider(),
            _BoxActionRow(
              icon: Icons.mail_outline,
              label: 'arasanmobile2012@gmail.com',
              url: 'mailto:arasanmobile2012@gmail.com',
            ),
            _BoxDivider(),
            _BoxActionRow(
              icon: Icons.location_on_outlined,
              label:
                  'ASR Complex, Near Periyar Silai,\nOld Bus Stand, Perambalur — 621212,\nTamil Nadu',
              url:
                  'https://maps.google.com/?q=ASR+Complex+Near+Periyar+Silai+Old+Bus+Stand+Perambalur',
            ),
          ],
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

/// A tile that toggles a simple bordered box open/closed inline (no navigation).
class _ExpandableTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final List<Widget> children;

  const _ExpandableTile({
    required this.icon,
    required this.label,
    required this.children,
  });

  @override
  State<_ExpandableTile> createState() => _ExpandableTileState();
}

class _ExpandableTileState extends State<_ExpandableTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: Icon(widget.icon, size: 22, color: AppColors.primary),
          title: Text(
            widget.label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          trailing: Icon(
            _expanded ? Icons.expand_less : Icons.expand_more,
            size: 20,
            color: AppColors.textTertiary,
          ),
          onTap: () => setState(() => _expanded = !_expanded),
          dense: true,
          visualDensity: const VisualDensity(vertical: -1),
        ),
        if (_expanded)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.children,
            ),
          ),
      ],
    );
  }
}

/// A plain, colourless tappable row inside an expandable box.
class _BoxActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;

  const _BoxActionRow({
    required this.icon,
    required this.label,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => launcher.launchUrl(Uri.parse(url)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoxDivider extends StatelessWidget {
  const _BoxDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: AppColors.border);
  }
}
