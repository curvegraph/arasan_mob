import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// Receives inbound deep links and routes them to the matching in-app screen.
///
/// Two link shapes resolve to the product detail page:
///
///  * Custom scheme (what the web landing page's "Open in App" button fires):
///    `com.arasanmobiles.user://product/<id>?variant=<variantId>`
///  * The web permalink (in case Android App Links / iOS Universal Links are
///    enabled later — harmless until then):
///    `https://arasanmobiles.in/product/<slug>/p/<id>?variant=<variantId>`
///
/// Both map to `/shop/product/<id>?variant=<variantId>`, the route already
/// declared in [createRouter] (lib/core/routing/app_router.dart).
///
/// OAuth callbacks (`…://login-callback`, or any link carrying `?code=`) are
/// deliberately ignored here — Supabase + the router's redirect own that flow.
class DeepLinkHandler {
  DeepLinkHandler._();
  static final DeepLinkHandler instance = DeepLinkHandler._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  bool _initialized = false;

  /// Wire up the cold-start link and the warm-running link stream. Safe to call
  /// more than once (e.g. on widget rebuilds) — only the first call takes effect.
  Future<void> init(GoRouter router) async {
    if (_initialized) return;
    _initialized = true;

    // Warm path: links delivered while the app is already running.
    _sub = _appLinks.uriLinkStream.listen(
      (uri) => _handle(uri, router),
      onError: (Object e) => debugPrint('DeepLinkHandler stream error: $e'),
    );

    // Cold path: the link that launched the app (null if launched normally).
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handle(initial, router);
    } catch (e) {
      debugPrint('DeepLinkHandler initial link error: $e');
    }
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    _initialized = false;
  }

  void _handle(Uri uri, GoRouter router) {
    final location = locationFor(uri);
    if (location == null) return;
    debugPrint('DeepLinkHandler: $uri -> $location');
    router.go(location);
  }

  /// Pure URI → in-app location mapper (also unit-testable in isolation).
  /// Returns null for links we don't own (OAuth callbacks, unknown shapes).
  @visibleForTesting
  static String? locationFor(Uri uri) {
    // Never hijack the auth callback.
    if (uri.host == 'login-callback' ||
        uri.path == '/login-callback' ||
        uri.queryParameters.containsKey('code')) {
      return null;
    }

    final productId = _productIdFrom(uri);
    if (productId == null || productId.isEmpty) return null;

    final variant = uri.queryParameters['variant'];
    final query = (variant != null && variant.isNotEmpty)
        ? '?variant=${Uri.encodeQueryComponent(variant)}'
        : '';
    return '/shop/product/$productId$query';
  }

  /// Extracts the product id from either supported link shape.
  static String? _productIdFrom(Uri uri) {
    final segments = uri.pathSegments;

    // Custom scheme: com.arasanmobiles.user://product/<id>
    // host == 'product', first path segment is the id.
    if (uri.host == 'product' && segments.isNotEmpty) {
      return segments.first;
    }

    // Web permalink: /product/<slug>/p/<id>  → id is the segment after 'p'.
    final pIndex = segments.indexOf('p');
    if (pIndex != -1 && pIndex + 1 < segments.length) {
      return segments[pIndex + 1];
    }

    return null;
  }
}
