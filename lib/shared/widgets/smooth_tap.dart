import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Optimized tap widget that provides instant visual feedback
/// and smooth animations for better perceived performance
class SmoothTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDoubleTap;
  final double scaleDown;
  final Duration duration;
  final Curve curve;
  final bool enableHaptics;
  final BorderRadius? borderRadius;
  final Color? splashColor;
  final Color? highlightColor;
  final bool useMaterial;

  const SmoothTap({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.onDoubleTap,
    this.scaleDown = 0.98,
    this.duration = const Duration(milliseconds: 100),
    this.curve = Curves.easeOutCubic,
    this.enableHaptics = false,
    this.borderRadius,
    this.splashColor,
    this.highlightColor,
    this.useMaterial = false,
  });

  @override
  State<SmoothTap> createState() => _SmoothTapState();
}

class _SmoothTapState extends State<SmoothTap>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleDown,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!_isPressed) {
      _isPressed = true;
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _isPressed = false;
    _controller.reverse();
  }

  void _onTapCancel() {
    _isPressed = false;
    _controller.reverse();
  }

  void _handleTap() {
    if (widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.useMaterial) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap != null ? _handleTap : null,
          onLongPress: widget.onLongPress,
          onDoubleTap: widget.onDoubleTap,
          borderRadius: widget.borderRadius,
          splashColor: widget.splashColor,
          highlightColor: widget.highlightColor,
          child: widget.child,
        ),
      );
    }

    return GestureDetector(
      onTapDown: widget.onTap != null ? _onTapDown : null,
      onTapUp: widget.onTap != null ? _onTapUp : null,
      onTapCancel: widget.onTap != null ? _onTapCancel : null,
      onTap: widget.onTap != null ? _handleTap : null,
      onLongPress: widget.onLongPress,
      onDoubleTap: widget.onDoubleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Card with smooth tap animation and elevation change
class SmoothTapCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double elevation;
  final double pressedElevation;
  final BorderRadius? borderRadius;
  final Color? color;

  const SmoothTapCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.elevation = 2,
    this.pressedElevation = 0,
    this.borderRadius,
    this.color,
  });

  @override
  State<SmoothTapCard> createState() => _SmoothTapCardState();
}

class _SmoothTapCardState extends State<SmoothTapCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _elevationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _elevationAnimation = Tween<double>(
      begin: widget.elevation,
      end: widget.pressedElevation,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => _controller.forward() : null,
      onTapUp: widget.onTap != null ? (_) => _controller.reverse() : null,
      onTapCancel: widget.onTap != null ? () => _controller.reverse() : null,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: widget.margin,
              child: Material(
                elevation: _elevationAnimation.value,
                borderRadius:
                    widget.borderRadius ?? BorderRadius.circular(12),
                color: widget.color ?? Colors.white,
                child: Padding(
                  padding: widget.padding ?? EdgeInsets.zero,
                  child: widget.child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Optimized list tile with instant response
class SmoothListTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? contentPadding;

  const SmoothListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return SmoothTap(
      onTap: onTap,
      useMaterial: true,
      child: Padding(
        padding: contentPadding ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null) title!,
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    subtitle!,
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 16),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
