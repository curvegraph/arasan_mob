import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/wishlist_provider.dart';

class ArasanUserApp extends StatefulWidget {
  const ArasanUserApp({super.key});

  @override
  State<ArasanUserApp> createState() => _ArasanUserAppState();
}

class _ArasanUserAppState extends State<ArasanUserApp> {
  GoRouter? _router;
  bool _wishlistLoaded = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // Wait for auth to initialize before showing the app
    // This ensures auto-login completes before routing decisions are made
    if (!authProvider.isInitialized) {
      return MaterialApp(
        title: 'Arasan Mobiles',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const _SplashScreen(),
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
    _router ??= createRouter(authProvider);

    return MaterialApp.router(
      title: 'Arasan Mobiles',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router!,
    );
  }
}

/// Splash screen shown while auth is initializing
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo/icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.phone_android,
                size: 50,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Arasan Mobiles',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
