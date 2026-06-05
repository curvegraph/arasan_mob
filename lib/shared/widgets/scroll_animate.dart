import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Animation types for scroll-triggered section animations
enum SectionAnimation {
  fadeSlideUp,
  fadeScaleUp,
  fadeIn,
  slideFromLeft,
  slideFromRight,
}

/// Wraps a child widget and animates it when it scrolls into view.
/// Uses a [VisibilityDetector]-like approach via [LayoutBuilder] + [NotificationListener].
class ScrollAnimate extends StatefulWidget {
  final Widget child;
  final SectionAnimation animation;
  final Duration duration;
  final Duration delay;
  final Curve curve;

  const ScrollAnimate({
    super.key,
    required this.child,
    this.animation = SectionAnimation.fadeSlideUp,
    this.duration = const Duration(milliseconds: 400),
    this.delay = Duration.zero,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<ScrollAnimate> createState() => _ScrollAnimateState();
}

class _ScrollAnimateState extends State<ScrollAnimate>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerAnimation() {
    if (_hasAnimated) return;
    _hasAnimated = true;

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Trigger animation once the widget is laid out (i.e., visible)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final renderObject = context.findRenderObject();
          if (renderObject == null) return;

          final viewport = RenderAbstractViewport.of(renderObject);
          final revealedOffset = viewport.getOffsetToReveal(renderObject, 0.0);
          final scrollable = Scrollable.maybeOf(context);
          if (scrollable == null) {
            _triggerAnimation();
            return;
          }

          final scrollPosition = scrollable.position.pixels;
          final viewportHeight = scrollable.position.viewportDimension;
          final widgetTop = revealedOffset.offset;

          // Trigger when the widget is within the viewport
          if (widgetTop < scrollPosition + viewportHeight + 50) {
            _triggerAnimation();
          }
        });

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final curved = widget.curve.transform(_controller.value);

            switch (widget.animation) {
              case SectionAnimation.fadeSlideUp:
                return Opacity(
                  opacity: curved,
                  child: Transform.translate(
                    offset: Offset(0, 30 * (1 - curved)),
                    child: child,
                  ),
                );
              case SectionAnimation.fadeScaleUp:
                return Opacity(
                  opacity: curved,
                  child: Transform.scale(
                    scale: 0.92 + 0.08 * curved,
                    child: child,
                  ),
                );
              case SectionAnimation.fadeIn:
                return Opacity(
                  opacity: curved,
                  child: child,
                );
              case SectionAnimation.slideFromLeft:
                return Opacity(
                  opacity: curved,
                  child: Transform.translate(
                    offset: Offset(-40 * (1 - curved), 0),
                    child: child,
                  ),
                );
              case SectionAnimation.slideFromRight:
                return Opacity(
                  opacity: curved,
                  child: Transform.translate(
                    offset: Offset(40 * (1 - curved), 0),
                    child: child,
                  ),
                );
            }
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Wraps a child with scroll-triggered animation that listens to scroll notifications.
/// This version actively checks visibility on scroll events.
class ScrollTriggeredAnimation extends StatefulWidget {
  final Widget child;
  final SectionAnimation animation;
  final Duration duration;
  final Duration delay;
  final Curve curve;

  const ScrollTriggeredAnimation({
    super.key,
    required this.child,
    this.animation = SectionAnimation.fadeSlideUp,
    this.duration = const Duration(milliseconds: 400),
    this.delay = Duration.zero,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<ScrollTriggeredAnimation> createState() =>
      _ScrollTriggeredAnimationState();
}

class _ScrollTriggeredAnimationState extends State<ScrollTriggeredAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _hasAnimated = false;
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    // Check visibility after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkVisibility() {
    if (_hasAnimated || !mounted) return;

    final renderObject = _key.currentContext?.findRenderObject();
    if (renderObject == null || !renderObject.attached) return;

    final viewport = RenderAbstractViewport.maybeOf(renderObject);
    if (viewport == null) {
      _trigger();
      return;
    }

    final revealedOffset = viewport.getOffsetToReveal(renderObject, 0.0);
    final scrollable = Scrollable.maybeOf(_key.currentContext!);
    if (scrollable == null) {
      _trigger();
      return;
    }

    final scrollPixels = scrollable.position.pixels;
    final viewportDim = scrollable.position.viewportDimension;
    final widgetTop = revealedOffset.offset;

    if (widgetTop < scrollPixels + viewportDim + 100) {
      _trigger();
    }
  }

  void _trigger() {
    if (_hasAnimated) return;
    _hasAnimated = true;
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _checkVisibility();
        return false;
      },
      child: AnimatedBuilder(
        key: _key,
        animation: _controller,
        builder: (context, child) {
          final curved = widget.curve.transform(_controller.value);

          switch (widget.animation) {
            case SectionAnimation.fadeSlideUp:
              return Opacity(
                opacity: curved,
                child: Transform.translate(
                  offset: Offset(0, 30 * (1 - curved)),
                  child: child,
                ),
              );
            case SectionAnimation.fadeScaleUp:
              return Opacity(
                opacity: curved,
                child: Transform.scale(
                  scale: 0.92 + 0.08 * curved,
                  child: child,
                ),
              );
            case SectionAnimation.fadeIn:
              return Opacity(
                opacity: curved,
                child: child,
              );
            case SectionAnimation.slideFromLeft:
              return Opacity(
                opacity: curved,
                child: Transform.translate(
                  offset: Offset(-40 * (1 - curved), 0),
                  child: child,
                ),
              );
            case SectionAnimation.slideFromRight:
              return Opacity(
                opacity: curved,
                child: Transform.translate(
                  offset: Offset(40 * (1 - curved), 0),
                  child: child,
                ),
              );
          }
        },
        child: widget.child,
      ),
    );
  }
}
