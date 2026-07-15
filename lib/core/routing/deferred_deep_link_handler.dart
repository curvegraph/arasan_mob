import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:play_install_referrer/play_install_referrer.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Deferred deep linking for Android via the Google Play **Install Referrer** API.
///
/// Solves the "app NOT installed" half of product sharing:
///
/// ```
/// shared https link  →  web launcher (product.html)  →  Play Store with
///   ?referrer=product%3D<id>%26variant%3D<v>  →  user installs  →  FIRST launch:
///   we read the install referrer, extract the product id, and navigate to
///   /shop/product/<id>  →  the shopper lands on the exact shared product.
/// ```
///
/// This is the free, native, no-third-party equivalent of Branch.io's deferred
/// deep linking — the same mechanism Flipkart/Meesho use on Android. The
/// `referrer` value is set by [product.html]'s store redirect (web_landing).
///
/// Runs at most **once per install**, guarded by a [SharedPreferences] flag:
/// the install referrer is only meaningful on the first launch, and re-reading
/// it later would keep hijacking the user's navigation. No-ops on iOS (the Play
/// referrer is Android-only — iOS deferred linking needs Branch/AppsFlyer), on
/// non-Play installs (sideload/debug → empty referrer or Play's organic
/// `utm_source=...` with no product), and once already consumed.
class DeferredDeepLinkHandler {
  DeferredDeepLinkHandler._();
  static final DeferredDeepLinkHandler instance = DeferredDeepLinkHandler._();

  /// Bumped (`_v1`, `_v2`, …) only if the referrer format ever changes and we
  /// need existing installs to re-read it. Normally stays `_v1`.
  static const String _consumedKey = 'deferred_deeplink_consumed_v1';

  bool _ran = false;

  /// Reads the Play install referrer once and, if it carries product context,
  /// routes to the product page. Safe to call unconditionally at startup — it
  /// self-guards and does nothing on repeat launches or unsupported platforms.
  Future<void> checkAndRoute(GoRouter router) async {
    if (_ran) return;
    _ran = true;

    if (kIsWeb || !Platform.isAndroid) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_consumedKey) ?? false) return;

    String? referrer;
    try {
      final details = await PlayInstallReferrer.installReferrer;
      referrer = details.installReferrer;
    } catch (e) {
      // Play Services missing, sideloaded build, or the referrer window closed.
      debugPrint('DeferredDeepLink: referrer lookup failed: $e');
    }

    // Mark consumed regardless of the outcome: the referrer is a one-shot,
    // first-launch signal. Reading it again on later launches (when it may
    // still be cached by Play) would re-route the user unexpectedly.
    await prefs.setBool(_consumedKey, true);

    final location = locationFromReferrer(referrer);
    if (location == null) return;
    debugPrint('DeferredDeepLink: "$referrer" -> $location');
    router.go(location);
  }

  /// Parses our own `product=<id>&variant=<v>` keys out of the raw install
  /// referrer string and returns the in-app product location — or null when the
  /// referrer carries no product context (organic installs, Play's
  /// `utm_source=google-play&utm_medium=organic`, empty on sideload). Static +
  /// public so it can be unit-tested without the platform channel.
  static String? locationFromReferrer(String? referrer) {
    if (referrer == null || referrer.isEmpty) return null;

    // The referrer is a URL query string, e.g. "product=64fd23&variant=9".
    // Play usually decodes the outer `referrer=` param once, but decode again
    // defensively in case it arrives still-encoded (e.g. "product%3D64fd23").
    var decoded = referrer;
    if (decoded.contains('%')) {
      try {
        decoded = Uri.decodeComponent(decoded);
      } catch (_) {
        // Keep the raw value if it isn't valid percent-encoding.
      }
    }

    final params = Uri.splitQueryString(decoded);
    final id = params['product'];
    if (id == null || id.isEmpty) return null;

    final variant = params['variant'];
    final query = (variant != null && variant.isNotEmpty)
        ? '?variant=${Uri.encodeQueryComponent(variant)}'
        : '';
    return '/shop/product/$id$query';
  }
}
