import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;
    final hPad = width < 600 ? 20.0 : (width < 1024 ? 32.0 : 60.0);

    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            border: Border(
              top: BorderSide(color: Color(0x66334155), width: 1),
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 28),
          child: isWide
              ? const _WideLayout()
              : const _NarrowLayout(),
        ),
        Container(
          color: const Color(0x66020617),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(
            '© ${DateTime.now().year} Arasan Mobiles®. All rights reserved.',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.1,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _WideLayout extends StatelessWidget {
  const _WideLayout();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Expanded(flex: 4, child: _BrandBlock()),
        SizedBox(width: 24),
        Expanded(flex: 1, child: _LinkColumn(title: 'Shop', links: _shopLinks)),
        SizedBox(width: 16),
        Expanded(flex: 1, child: _LinkColumn(title: 'Help', links: _helpLinks)),
        SizedBox(width: 16),
        Expanded(flex: 1, child: _LinkColumn(title: 'Company', links: _companyLinks)),
      ],
    );
  }
}

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _BrandBlock(),
        SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _LinkColumn(title: 'Shop', links: _shopLinks)),
            SizedBox(width: 12),
            Expanded(child: _LinkColumn(title: 'Help', links: _helpLinks)),
            SizedBox(width: 12),
            Expanded(child: _LinkColumn(title: 'Company', links: _companyLinks)),
          ],
        ),
      ],
    );
  }
}

class _BrandBlock extends StatelessWidget {
  const _BrandBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: const Color(0x331400E0), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset('assets/logo.png', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Arasan ',
                    style: TextStyle(
                      color: Color(0xFFD32F2F),
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  TextSpan(
                    text: 'Mobiles',
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.aboveBaseline,
                    baseline: TextBaseline.alphabetic,
                    child: Padding(
                      padding: EdgeInsets.only(left: 2),
                      child: Text(
                        '®',
                        style: TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'Wholesale Dealer in All Mobiles & Accessories',
          style: TextStyle(
            fontSize: 15,
            color: Color(0xFFCBD5E1),
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'மொபைல் உலகின் அரசன் — King of Mobile World',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF94A3B8),
            fontStyle: FontStyle.italic,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        const _ContactRow(
          icon: Icons.phone,
          text: '+91 99444 04603',
          launchUrl: 'tel:+919944404603',
        ),
        const SizedBox(height: 8),
        const _ContactRow(
          icon: Icons.mail_outline,
          text: 'arasanmobile2012@gmail.com',
          launchUrl: 'mailto:arasanmobile2012@gmail.com',
        ),
        const SizedBox(height: 8),
        const _ContactRow(
          icon: Icons.location_on_outlined,
          text:
              'ASR Complex, Near Periyar Silai, Old Bus Stand,\nPerambalur — 621212, Tamil Nadu',
        ),
      ],
    );
  }
}

class _ContactRow extends StatefulWidget {
  final IconData icon;
  final String text;
  final String? launchUrl;

  const _ContactRow({
    required this.icon,
    required this.text,
    this.launchUrl,
  });

  @override
  State<_ContactRow> createState() => _ContactRowState();
}

class _ContactRowState extends State<_ContactRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tappable = widget.launchUrl != null;
    final color = tappable && _hovered
        ? const Color(0xFF2962FF)
        : const Color(0xFF94A3B8);

    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(widget.icon, size: 16, color: const Color(0xFF2962FF)),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            widget.text,
            style: TextStyle(fontSize: 14, color: color, height: 1.4),
          ),
        ),
      ],
    );

    if (!tappable) return row;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => launchUrl(Uri.parse(widget.launchUrl!)),
        child: row,
      ),
    );
  }
}

class _LinkColumn extends StatelessWidget {
  final String title;
  final List<_FooterLinkData> links;

  const _LinkColumn({required this.title, required this.links});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 14),
        for (final link in links) ...[
          _FooterLink(label: link.label, route: link.route),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _FooterLinkData {
  final String label;
  final String route;
  const _FooterLinkData(this.label, this.route);
}

const _shopLinks = [
  _FooterLinkData('All Products', '/shop/products'),
  _FooterLinkData('New Arrivals', '/shop/products?sort=new'),
  _FooterLinkData("Today's Offers", '/shop/offers'),
  _FooterLinkData('Best Sellers', '/shop/products?sort=rating'),
];

const _helpLinks = [
  _FooterLinkData('Help Center', '/shop/help'),
  _FooterLinkData('FAQ', '/shop/help/faq'),
  _FooterLinkData('Track order', '/shop/account/orders'),
];

const _companyLinks = [
  _FooterLinkData('About Us', '/shop/store-info'),
  _FooterLinkData('Contact', '/shop/store-info'),
];

class _FooterLink extends StatefulWidget {
  final String label;
  final String route;

  const _FooterLink({required this.label, required this.route});

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.push(widget.route),
        child: Text(
          widget.label,
          style: TextStyle(
            fontSize: 14,
            color: _hovered
                ? const Color(0xFF2962FF)
                : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }
}

class _MapBlock extends StatefulWidget {
  const _MapBlock();

  @override
  State<_MapBlock> createState() => _MapBlockState();
}

class _MapBlockState extends State<_MapBlock> {
  static const _mapsUrl =
      'https://maps.google.com/?q=ASR+Complex+Near+Periyar+Silai+Old+Bus+Stand+Perambalur';
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'FIND US',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 14),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: () => launchUrl(
              Uri.parse(_mapsUrl),
              mode: LaunchMode.externalApplication,
            ),
            child: AspectRatio(
              aspectRatio: 2 / 1,
              child: AnimatedOpacity(
                opacity: _hovered ? 0.92 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x66334155), width: 1),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(painter: _MapGridPainter()),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: Color(0xFF2962FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'View on Google Maps',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Perambalur, Tamil Nadu — click to open in Maps',
          style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), height: 1.4),
        ),
      ],
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x22FFFFFF)
      ..strokeWidth = 1;
    const step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
