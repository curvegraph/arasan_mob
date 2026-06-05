import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:math' as math;

/// Custom scroll physics that provides buttery smooth scrolling
/// with natural deceleration for both slow and fast scrolling
class SmoothScrollPhysics extends ScrollPhysics {
  /// Friction coefficient - lower = more momentum (smoother)
  final double frictionCoefficient;

  /// Spring description for overscroll
  final SpringDescription? springDescription;

  const SmoothScrollPhysics({
    super.parent,
    this.frictionCoefficient = 0.015,
    this.springDescription,
  });

  @override
  SmoothScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SmoothScrollPhysics(
      parent: buildParent(ancestor),
      frictionCoefficient: frictionCoefficient,
      springDescription: springDescription,
    );
  }

  @override
  SpringDescription get spring => springDescription ?? SpringDescription(
    mass: 0.5,
    stiffness: 100.0,
    damping: 1.1,
  );

  @override
  double get dragStartDistanceMotionThreshold => 3.5;

  @override
  double get minFlingVelocity => 50.0;

  @override
  double get maxFlingVelocity => 8000.0;

  @override
  double carriedMomentum(double existingVelocity) {
    return existingVelocity.sign *
        math.min(0.000816 * math.pow(existingVelocity.abs(), 1.967).toDouble(),
            40000.0);
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    final tolerance = toleranceFor(position);

    if (velocity.abs() < tolerance.velocity) {
      return null;
    }

    // Use friction simulation for natural deceleration
    return ClampingScrollSimulation(
      position: position.pixels,
      velocity: velocity,
      friction: frictionCoefficient,
      tolerance: tolerance,
    );
  }
}

/// Smooth scroll physics that always allows scrolling (for RefreshIndicator)
class AlwaysSmoothScrollPhysics extends SmoothScrollPhysics {
  const AlwaysSmoothScrollPhysics({
    super.parent,
    super.frictionCoefficient = 0.015,
    super.springDescription,
  });

  @override
  AlwaysSmoothScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return AlwaysSmoothScrollPhysics(
      parent: buildParent(ancestor),
      frictionCoefficient: frictionCoefficient,
      springDescription: springDescription,
    );
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) => true;
}

/// Custom scroll behavior that removes scrollbar and provides smooth scrolling
class SmoothScrollBehavior extends MaterialScrollBehavior {
  const SmoothScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const AlwaysSmoothScrollPhysics();
  }

  @override
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) {
    // No scrollbar - return child directly for smooth experience
    return child;
  }
}

/// Mixin for preloading pagination without loading indicators
/// Preloads next page when user is near the end
mixin PreloadingPaginationMixin<T extends StatefulWidget> on State<T> {
  ScrollController? _preloadScrollController;
  bool _isPreloading = false;

  /// Override in subclass to specify preload buffer (pixels before end)
  double get preloadBuffer => 800.0;

  /// Override in subclass to check if more data is available
  bool get hasMoreData;

  /// Override in subclass to check if currently loading
  bool get isLoading;

  /// Override in subclass to load more data
  Future<void> loadMoreData();

  void initPreloadingPagination(ScrollController controller) {
    _preloadScrollController = controller;
    controller.addListener(_onPreloadScroll);
  }

  void disposePreloadingPagination() {
    _preloadScrollController?.removeListener(_onPreloadScroll);
  }

  void _onPreloadScroll() {
    if (!mounted) return;
    if (_isPreloading || isLoading || !hasMoreData) return;

    final controller = _preloadScrollController;
    if (controller == null || !controller.hasClients) return;

    final position = controller.position;
    final maxScroll = position.maxScrollExtent;
    final currentScroll = position.pixels;

    // Preload when within buffer distance of end
    if (maxScroll - currentScroll <= preloadBuffer) {
      _preloadNextPage();
    }
  }

  Future<void> _preloadNextPage() async {
    if (_isPreloading) return;
    _isPreloading = true;

    try {
      await loadMoreData();
    } finally {
      if (mounted) {
        _isPreloading = false;
      }
    }
  }
}

/// Optimized scroll controller that batches notifications
class OptimizedScrollController extends ScrollController {
  DateTime? _lastNotification;
  static const _throttleDuration = Duration(milliseconds: 16); // ~60fps

  OptimizedScrollController({
    super.initialScrollOffset,
    super.keepScrollOffset,
    super.debugLabel,
  });

  @override
  void notifyListeners() {
    final now = DateTime.now();
    if (_lastNotification != null &&
        now.difference(_lastNotification!) < _throttleDuration) {
      return;
    }
    _lastNotification = now;
    super.notifyListeners();
  }
}

/// Extension for easy smooth scroll configuration
extension SmoothScrollExtension on ScrollController {
  /// Animate scroll with smooth physics
  Future<void> smoothScrollTo(
    double offset, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOutCubic,
  }) {
    return animateTo(
      offset,
      duration: duration,
      curve: curve,
    );
  }

  /// Smooth scroll to top
  Future<void> smoothScrollToTop({
    Duration duration = const Duration(milliseconds: 400),
  }) {
    return smoothScrollTo(0, duration: duration, curve: Curves.easeOutQuart);
  }
}

/// Widget wrapper that applies smooth scroll behavior to its subtree
class SmoothScrollWrapper extends StatelessWidget {
  final Widget child;

  const SmoothScrollWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const SmoothScrollBehavior(),
      child: child,
    );
  }
}
