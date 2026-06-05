import 'package:flutter/material.dart';
import '../constants/app_spacing.dart';

/// Fade + Slide in animation for staggered list items
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration duration;
  final Offset beginOffset;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.duration = const Duration(milliseconds: 350),
    this.beginOffset = const Offset(0, 0.15),
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(
      Duration(milliseconds: widget.index * AppSpacing.staggerDelay),
      () {
        if (mounted) _controller.forward();
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}

/// Scale on tap effect for cards/buttons
class ScaleOnTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;

  const ScaleOnTap({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.96,
  });

  @override
  State<ScaleOnTap> createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<ScaleOnTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: widget.scaleDown,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.reverse(),
      onTapUp: (_) {
        _controller.forward();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.forward(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

/// Pulse badge for notifications/cart count
class PulseBadge extends StatefulWidget {
  final Widget child;
  final bool shouldPulse;

  const PulseBadge({super.key, required this.child, this.shouldPulse = true});

  @override
  State<PulseBadge> createState() => _PulseBadgeState();
}

class _PulseBadgeState extends State<PulseBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.shouldPulse) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(PulseBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldPulse && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.shouldPulse && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.shouldPulse) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_controller.value * 0.15),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Horizontal shake animation triggered via [ShakeAnimationController]
class ShakeAnimation extends StatefulWidget {
  final Widget child;
  final ShakeAnimationController? controller;

  const ShakeAnimation({super.key, required this.child, this.controller});

  @override
  State<ShakeAnimation> createState() => _ShakeAnimationState();
}

class _ShakeAnimationState extends State<ShakeAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -6), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -6, end: 6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6, end: -4), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -4, end: 4), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 4, end: -2), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -2, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    widget.controller?._attach(this);
  }

  @override
  void didUpdateWidget(ShakeAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?._detach();
      widget.controller?._attach(this);
    }
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _animController.dispose();
    super.dispose();
  }

  void shake() => _animController.forward(from: 0);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Controller to trigger [ShakeAnimation] from outside
class ShakeAnimationController {
  _ShakeAnimationState? _state;
  void _attach(_ShakeAnimationState state) => _state = state;
  void _detach() => _state = null;
  void shake() => _state?.shake();
}

/// Bounce tap with spring physics
class BounceTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;

  const BounceTap({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.95,
  });

  @override
  State<BounceTap> createState() => _BounceTapState();
}

class _BounceTapState extends State<BounceTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown() {
    _scaleAnim = Tween<double>(begin: 1.0, end: widget.scaleFactor).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward(from: 0);
  }

  void _onTapUp() {
    _scaleAnim = Tween<double>(begin: widget.scaleFactor, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward(from: 0);
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _scaleAnim = Tween<double>(begin: _scaleAnim.value, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _onTapDown(),
      onTapUp: (_) => _onTapUp(),
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnim.value, child: child);
        },
        child: widget.child,
      ),
    );
  }
}

/// ScrollReveal — fades + slides in when scrolled into viewport
class ScrollReveal extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Offset offset;

  const ScrollReveal({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.offset = const Offset(0, 30),
  });

  @override
  State<ScrollReveal> createState() => _ScrollRevealState();
}

class _ScrollRevealState extends State<ScrollReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: widget.offset, end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkVisibility(BuildContext context) {
    if (_hasAnimated) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;
    final offset = renderBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.sizeOf(context).height;
    if (offset.dy < screenHeight * 0.85) {
      _hasAnimated = true;
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use a post-frame callback to check visibility
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkVisibility(context);
    });

    return NotificationListener<ScrollNotification>(
      onNotification: (_) {
        _checkVisibility(context);
        return false;
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _opacity.value,
            child: Transform.translate(offset: _slide.value, child: child),
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// CountUpAnimation — animates a number counting up
class CountUpAnimation extends StatefulWidget {
  final int end;
  final Duration duration;
  final TextStyle? style;
  final String suffix;

  const CountUpAnimation({
    super.key,
    required this.end,
    this.duration = const Duration(milliseconds: 1200),
    this.style,
    this.suffix = '',
  });

  @override
  State<CountUpAnimation> createState() => _CountUpAnimationState();
}

class _CountUpAnimationState extends State<CountUpAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<int> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = IntTween(begin: 0, end: widget.end).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text('${_animation.value}${widget.suffix}', style: widget.style);
      },
    );
  }
}
