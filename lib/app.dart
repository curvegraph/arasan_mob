import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'features/splash/widgets/branded_splash.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'core/routing/deep_link_handler.dart';
import 'core/routing/deferred_deep_link_handler.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/wishlist_provider.dart';
import 'providers/homepage_provider.dart';

class ArasanUserApp extends StatefulWidget {
  const ArasanUserApp({super.key});

  @override
  State<ArasanUserApp> createState() => _ArasanUserAppState();
}

/// Full-screen "You're offline" screen, matching the web storefront's
/// `+layout.svelte` offline overlay (icon · heading · subtitle · Retry).
class _OfflineScreen extends StatelessWidget {
  final VoidCallback onRetry;
  const _OfflineScreen({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF1F5F9), // slate-100
                ),
                child: const Icon(Icons.wifi_off_rounded,
                    size: 28, color: Color(0xFF64748B)), // slate-500
              ),
              const SizedBox(height: 20),
              const Text(
                "You're offline",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Check your internet connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A), // ink-900
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Retry',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArasanUserAppState extends State<ArasanUserApp> {
  GoRouter? _router;
  bool _wishlistLoaded = false;

  // Global messenger so the connectivity watcher can post snackbars from
  // outside any page's Scaffold.
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  final Connectivity _connectivity = Connectivity();
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _connSub = _connectivity.onConnectivityChanged.listen(_onConnectivity);
    // Seed with the current status so an app launched offline shows the screen.
    _connectivity.checkConnectivity().then(_onConnectivity);
  }

  @override
  void dispose() {
    _connSub?.cancel();
    super.dispose();
  }

  /// Mirrors the web storefront: while offline a full-screen "You're offline"
  /// screen replaces the app; coming back online removes it and shows a brief
  /// green "Back online" confirmation toast.
  void _onConnectivity(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (online == _isOnline) return; // no change
    final cameBackOnline = online && !_isOnline;
    setState(() => _isOnline = online);
    if (cameBackOnline) {
      // Auto-recover: reload homepage data so the app "opens" immediately on
      // reconnect instead of staying on an error/empty state. Best-effort.
      if (mounted) {
        try {
          context.read<HomepageProvider>().refresh();
        } catch (_) {}
      }
      _messengerKey.currentState
        ?..clearSnackBars()
        ..showSnackBar(const SnackBar(
          backgroundColor: Color(0xFF15803D), // green
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
          content: Row(
            children: [
              Icon(Icons.wifi_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Back online', style: TextStyle(color: Colors.white)),
            ],
          ),
        ));
    }
  }

  /// Re-check connectivity (Retry button on the offline screen).
  void _recheckConnectivity() => _connectivity.checkConnectivity().then(_onConnectivity);

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // Wait for auth to initialize before showing the app (auto-login must
    // finish before routing). Keep the branded splash (logo + shop name on the
    // launch navy) on screen during this brief init so the logo stays visible
    // and the hand-off to the home page is seamless — no white flash.
    if (!authProvider.isInitialized) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: BrandedSplash(),
      );
    }

    // Load wishlist when user is logged in. After it loads, pre-fetch any
    // products it references so the wishlist tab can render them (otherwise
    // the screen falls back to "Product unavailable" while waiting for the
    // product list to populate).
    if (authProvider.isLoggedIn && authProvider.userId != null && !_wishlistLoaded) {
      _wishlistLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final wishlist = context.read<WishlistProvider>();
        final products = context.read<ProductProvider>();
        await wishlist.loadWishlist(authProvider.userId!);
        for (final item in wishlist.items) {
          if (products.getProductById(item.productId) == null) {
            // Fire-and-forget; UI will rebuild when each one arrives.
            products.fetchProductById(item.productId);
          }
        }
      });
    } else if (!authProvider.isLoggedIn && _wishlistLoaded) {
      _wishlistLoaded = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<WishlistProvider>().onLogout();
      });
    }

    // Create router only once after auth is initialized
    if (_router == null) {
      _router = createRouter(authProvider);
      // Start listening for inbound product deep links (custom scheme /
      // app links). Idempotent — only the first call wires up listeners.
      DeepLinkHandler.instance.init(_router!);
      // Deferred deep linking: if this is the first launch after installing
      // from a shared product link (Play Store install referrer), jump to that
      // product. Self-guarded — runs once per install, Android-only, no-ops
      // otherwise. See DeferredDeepLinkHandler.
      DeferredDeepLinkHandler.instance.checkAndRoute(_router!);
    }

    return MaterialApp.router(
      title: 'Arasan Mobiles',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _messengerKey,
      theme: AppTheme.light,
      routerConfig: _router!,
      // While offline, paint the full-screen offline screen ON TOP of the app
      // (web parity). It's removed the instant connectivity returns.
      builder: (context, child) {
        return Stack(
          children: [
            ?child,
            if (!_isOnline) _OfflineScreen(onRetry: _recheckConnectivity),
          ],
        );
      },
    );
  }
}

