import 'package:flutter/material.dart';
import '../../data/models/product.dart';

/// Plays a product's admin-configured [ImageAnimation] continuously.
///
/// On the web the per-product animation is hover-gated, but a touchscreen has
/// no hover — so admin-set effects (bounce, pulse, zoom, fade, slide) would
/// never show on the phone. This wrapper loops them gently so they're actually
/// visible, mirroring the intent configured in the admin panel. Offsets/scales
/// are kept small and the content is clipped by the parent, so layout is never
/// broken. [ImageAnimation.none] renders the child untouched (no controller).
class AnimatedProductImage extends StatefulWidget {
  final ImageAnimation animation;
  final Widget child;

  const AnimatedProductImage({
    super.key,
    required this.animation,
    required this.child,
  });

  @override
  State<AnimatedProductImage> createState() => _AnimatedProductImageState();
}

class _AnimatedProductImageState extends State<AnimatedProductImage>
    with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;

  @override
  void initState() {
    super.initState();
    _maybeInit();
  }

  void _maybeInit() {
    if (widget.animation == ImageAnimation.none) return;
    _ctrl = AnimationController(
      vsync: this,
      duration: _durationFor(widget.animation),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant AnimatedProductImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      _ctrl?.dispose();
      _ctrl = null;
      _maybeInit();
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  static Duration _durationFor(ImageAnimation a) {
    switch (a) {
      case ImageAnimation.bounce:
        return const Duration(milliseconds: 700);
      case ImageAnimation.pulse:
        return const Duration(milliseconds: 850);
      case ImageAnimation.zoomIn:
      case ImageAnimation.zoomOut:
        return const Duration(milliseconds: 1800);
      case ImageAnimation.fadeIn:
      case ImageAnimation.fadeOut:
        return const Duration(milliseconds: 1200);
      case ImageAnimation.slideLeft:
      case ImageAnimation.slideRight:
        return const Duration(milliseconds: 900);
      case ImageAnimation.none:
        return Duration.zero;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _ctrl;
    if (ctrl == null) return widget.child;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: ctrl,
        child: widget.child,
        builder: (context, child) {
          // ctrl.value sweeps 0→1→0 (repeat reverse); ease it for smoothness.
          final t = Curves.easeInOut.transform(ctrl.value);
          double dx = 0, dy = 0, scale = 1, opacity = 1;
          switch (widget.animation) {
            case ImageAnimation.bounce:
              dy = -10 * t;
              break;
            case ImageAnimation.pulse:
              scale = 1 + 0.05 * t;
              break;
            case ImageAnimation.zoomIn:
              scale = 1 + 0.12 * t;
              break;
            case ImageAnimation.zoomOut:
              scale = 1.12 - 0.12 * t;
              break;
            case ImageAnimation.fadeIn:
              opacity = 0.45 + 0.55 * t;
              break;
            case ImageAnimation.fadeOut:
              opacity = 1 - 0.55 * t;
              break;
            case ImageAnimation.slideLeft:
              dx = -8 * t;
              break;
            case ImageAnimation.slideRight:
              dx = 8 * t;
              break;
            case ImageAnimation.none:
              break;
          }

          Widget result = child!;
          if (opacity != 1.0) {
            result = Opacity(opacity: opacity, child: result);
          }
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..translate(dx, dy)
              ..scale(scale),
            child: result,
          );
        },
      ),
    );
  }
}
