import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BannerCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> banners;
  final bool autoScroll;
  final int intervalSeconds;
  final bool showIndicators;
  final Function(Map<String, dynamic>)? onBannerTap;
  final double? aspectRatio;

  const BannerCarousel({
    super.key,
    required this.banners,
    this.autoScroll = true,
    this.intervalSeconds = 6,
    this.showIndicators = true,
    this.onBannerTap,
    this.aspectRatio,
  });

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  int _active = 0;
  Timer? _timer;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(BannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.banners.length != oldWidget.banners.length) {
      _active = 0;
      _start();
    }
  }

  void _start() {
    _timer?.cancel();
    if (!widget.autoScroll || widget.banners.length <= 1) return;
    _timer = Timer.periodic(Duration(seconds: widget.intervalSeconds), (_) {
      if (!mounted || _hovered) return;
      setState(() => _active = (_active + 1) % widget.banners.length);
    });
  }

  void _go(int i) {
    if (widget.banners.isEmpty) return;
    final n = widget.banners.length;
    setState(() => _active = (i % n + n) % n);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  double _aspectFor(double width) {
    if (widget.aspectRatio != null) return widget.aspectRatio!;
    if (width >= 1280) return 16 / 4;
    if (width >= 1024) return 16 / 5;
    if (width >= 640) return 16 / 6;
    return 2 / 1;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();

    final width = MediaQuery.sizeOf(context).width;
    final aspect = _aspectFor(width);
    final isWide = width >= 768;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 420),
        child: AspectRatio(
          aspectRatio: aspect,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1400E0),
                    Color(0xFF0D00B3),
                    Color(0xFF0F172A),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  for (int i = 0; i < widget.banners.length; i++)
                    AnimatedOpacity(
                      opacity: i == _active ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeInOut,
                      child: _BannerSlide(
                        banner: widget.banners[i],
                        onTap: () => widget.onBannerTap?.call(widget.banners[i]),
                      ),
                    ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.15),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (isWide && widget.banners.length > 1) ...[
                    _NavArrow(
                      icon: Icons.chevron_left,
                      visible: _hovered,
                      alignment: Alignment.centerLeft,
                      onTap: () => _go(_active - 1),
                    ),
                    _NavArrow(
                      icon: Icons.chevron_right,
                      visible: _hovered,
                      alignment: Alignment.centerRight,
                      onTap: () => _go(_active + 1),
                    ),
                  ],
                  if (widget.showIndicators && widget.banners.length > 1)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 16,
                      child: _Indicators(
                        count: widget.banners.length,
                        active: _active,
                        onTap: _go,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BannerSlide extends StatelessWidget {
  final Map<String, dynamic> banner;
  final VoidCallback onTap;

  const _BannerSlide({required this.banner, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final imageUrl = (banner['image_url'] as String?) ??
        (banner['assetPath'] as String?) ??
        '';
    final isNetwork = imageUrl.startsWith('http');

    Widget img;
    if (imageUrl.isEmpty) {
      img = const SizedBox.shrink();
    } else if (isNetwork) {
      img = CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (_, __) => Container(color: const Color(0xFF1E293B)),
        errorWidget: (_, __, ___) => Container(
          color: const Color(0xFF1E293B),
          child: const Center(
            child: Icon(Icons.image_not_supported_outlined,
                color: Color(0xFF64748B), size: 32),
          ),
        ),
      );
    } else {
      img = Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1E293B)),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: img),
    );
  }
}

class _NavArrow extends StatefulWidget {
  final IconData icon;
  final bool visible;
  final Alignment alignment;
  final VoidCallback onTap;

  const _NavArrow({
    required this.icon,
    required this.visible,
    required this.alignment,
    required this.onTap,
  });

  @override
  State<_NavArrow> createState() => _NavArrowState();
}

class _NavArrowState extends State<_NavArrow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: AnimatedOpacity(
          opacity: widget.visible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(_hovered ? 0.25 : 0.15),
                ),
                child: Icon(widget.icon, color: Colors.white, size: 22),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Indicators extends StatelessWidget {
  final int count;
  final int active;
  final ValueChanged<int> onTap;

  const _Indicators({
    required this.count,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == active;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              width: isActive ? 40 : 8,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: isActive
                    ? Colors.white
                    : Colors.white.withOpacity(0.5),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class HeroBanner extends StatefulWidget {
  final String imageUrl;
  final VoidCallback? onTap;
  final double? aspectRatio;

  const HeroBanner({
    super.key,
    required this.imageUrl,
    this.onTap,
    this.aspectRatio,
  });

  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl.isEmpty) return const SizedBox.shrink();

    final isNetwork = widget.imageUrl.startsWith('http');

    Widget img = isNetwork
        ? CachedNetworkImage(
            imageUrl: widget.imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            placeholder: (_, __) => Container(
              height: 150,
              color: const Color(0xFF1E293B),
            ),
            errorWidget: (_, __, ___) => Container(
              height: 150,
              color: const Color(0xFF1E293B),
              child: const Center(
                child: Icon(Icons.image_not_supported_outlined,
                    color: Color(0xFF64748B), size: 32),
              ),
            ),
          )
        : Image.asset(
            widget.imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (_, __, ___) => Container(
              height: 150,
              color: const Color(0xFF1E293B),
            ),
          );

    if (widget.aspectRatio != null) {
      img = AspectRatio(aspectRatio: widget.aspectRatio!, child: img);
    }

    return GestureDetector(
      onTapDown: widget.onTap != null
          ? (_) => setState(() => _isPressed = true)
          : null,
      onTapUp: widget.onTap != null
          ? (_) {
              setState(() => _isPressed = false);
              widget.onTap!();
            }
          : null,
      onTapCancel: widget.onTap != null
          ? () => setState(() => _isPressed = false)
          : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.99 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: img,
      ),
    );
  }
}
