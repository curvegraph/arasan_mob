import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Glass morphism container widget — light variant (default) and dark variant
class GlassMorphism extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final Border? border;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool isDark;

  const GlassMorphism({
    super.key,
    required this.child,
    this.blur = 20,
    this.opacity = 0.85,
    this.borderRadius,
    this.border,
    this.padding,
    this.margin,
    this.isDark = false,
  });

  const GlassMorphism.dark({
    super.key,
    required this.child,
    this.blur = 20,
    this.opacity = 0.75,
    this.borderRadius,
    this.border,
    this.padding,
    this.margin,
  }) : isDark = true;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(16);
    final bgColor = isDark
        ? AppColors.obsidian.withValues(alpha: opacity)
        : Colors.white.withValues(alpha: opacity);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppColors.steel.withValues(alpha: 0.5);

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: radius,
              border: border ?? Border.all(color: borderColor, width: 0.5),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Premium decoration utilities
class PremiumDecorations {
  PremiumDecorations._();

  static BoxDecoration goldGlowCard({
    double borderRadius = 16,
    double glowOpacity = 0.1,
  }) {
    return BoxDecoration(
      color: AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration glassCard({double borderRadius = 16}) {
    return BoxDecoration(
      color: AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static BoxDecoration darkCard({double borderRadius = 16}) {
    return BoxDecoration(
      color: AppColors.surfaceDark,
      borderRadius: BorderRadius.circular(borderRadius),
    );
  }

  static LinearGradient goldGradient() {
    return const LinearGradient(
      colors: [AppColors.accentBlue, AppColors.accentBlueLight],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static LinearGradient blueGradient() {
    return const LinearGradient(
      colors: [AppColors.accentBlue, AppColors.accentBlueLight],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static BoxDecoration radialBackground() {
    return const BoxDecoration(
      color: AppColors.snow,
    );
  }

  static BoxDecoration goldGlowButton({double borderRadius = 980}) {
    return BoxDecoration(
      color: AppColors.accentBlue,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: AppColors.accentBlue.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
