import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/user_scaffold.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/products/screens/product_listing_screen.dart';
import '../../features/products/screens/product_detail_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/offers/screens/offers_screen.dart';
import '../../features/cart/screens/cart_screen.dart';
import '../../data/models/product.dart';
import '../../features/checkout/screens/user_checkout_screen.dart';
import '../../features/checkout/screens/order_success_screen.dart';
import '../../features/auth/screens/user_login_screen.dart';
import '../../features/auth/screens/phone_login_screen.dart';
import '../../features/auth/screens/unified_login_screen.dart';
// Register screen removed — phone OTP auto-creates accounts
import '../../features/account/screens/user_account_screen.dart';
import '../../features/account/screens/user_profile_screen.dart';
import '../../features/account/screens/user_edit_profile_screen.dart';
import '../../features/account/screens/user_addresses_screen.dart';
import '../../features/account/screens/user_change_password_screen.dart';
import '../../features/orders/screens/user_orders_screen.dart';
import '../../features/orders/screens/user_order_detail_screen.dart';
import '../../features/orders/screens/user_shipment_tracking_screen.dart';
import '../../features/wishlist/screens/user_wishlist_screen.dart';
import '../../features/notifications/screens/user_notifications_screen.dart';
import '../../features/reviews/screens/user_product_reviews_screen.dart';
import '../../features/reviews/screens/user_write_review_screen.dart';
import '../../features/reviews/screens/user_my_reviews_screen.dart';
import '../../features/help/screens/user_help_screen.dart';
import '../../features/help/screens/user_faq_screen.dart';
import '../../features/help/screens/user_raise_ticket_screen.dart';
import '../../features/store_info/screens/user_store_info_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Standard page transition: fade + subtle horizontal slide (250ms)
CustomTransitionPage<void> _fadeSlideTransition(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      final slide = Tween<Offset>(
        begin: const Offset(0.03, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}

/// Product detail transition: fade + subtle zoom in (300ms)
CustomTransitionPage<void> _fadeZoomTransition(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      final scale = Tween<double>(
        begin: 0.96,
        end: 1.0,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      return FadeTransition(
        opacity: fade,
        child: ScaleTransition(scale: scale, child: child),
      );
    },
  );
}

/// Modal transition: fade + slide up (300ms)
CustomTransitionPage<void> _slideUpTransition(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      final slide = Tween<Offset>(
        begin: const Offset(0, 0.08),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/shop',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final isLoggedIn = authProvider.isLoggedIn;
      final uri = state.uri;
      final path = uri.path;

      // OAuth deep-link callback. The URI arrives as
      // com.arasanmobiles.user://login-callback/?code=... — Supabase did NOT
      // auto-exchange it, so we hand the full URI to getSessionFromUrl here.
      // Fire-and-forget; AuthProvider's listener will pick up the new session.
      final isOAuthCallback = uri.scheme == 'com.arasanmobiles.user' ||
          uri.host == 'login-callback' ||
          path == '/login-callback';
      if (isOAuthCallback) {
        if (uri.queryParameters['code'] != null) {
          Supabase.instance.client.auth.getSessionFromUrl(uri).then(
            (_) => debugPrint('OAuth session established via deep link'),
            onError: (e) => debugPrint('OAuth code exchange failed: $e'),
          );
        }
        return '/shop';
      }

      // Redirect landing page to home
      if (path == '/') return '/shop';

      // Auth routes - redirect if already logged in
      if (path == '/shop/login') {
        if (isLoggedIn) return '/shop';
        return null;
      }
      // Redirect old register route to login (OTP handles registration)
      if (path == '/shop/register') {
        return '/shop/login';
      }

      // Protected routes redirect to home if not logged in
      // Note: checkout is NOT protected - user can browse checkout
      // but will be prompted to login when placing order
      final protectedPrefixes = [
        '/shop/order-success',
        '/shop/account',
        '/shop/wishlist',
        '/shop/notifications',
      ];
      final isProtected = protectedPrefixes.any((p) => path.startsWith(p));
      if (isProtected && !isLoggedIn) {
        return '/shop';
      }

      // Write review requires auth
      if (path.contains('/write-review') && !isLoggedIn) {
        return '/shop';
      }

      // Raise ticket requires auth
      if (path == '/shop/help/ticket' && !isLoggedIn) {
        return '/shop';
      }

      return null;
    },
    routes: [
      // Auth routes (no shell)
      GoRoute(
        path: '/shop/login',
        pageBuilder: (context, state) =>
            _slideUpTransition(state, const UnifiedLoginScreen()),
      ),
      GoRoute(
        path: '/shop/login-email',
        pageBuilder: (context, state) =>
            _slideUpTransition(state, const UserLoginScreen()),
      ),
      GoRoute(
        path: '/shop/phone-login',
        pageBuilder: (context, state) =>
            _slideUpTransition(state, const PhoneLoginScreen()),
      ),
      // User shell
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => UserScaffold(child: child),
        routes: [
          GoRoute(
            path: '/shop',
            pageBuilder: (context, state) =>
                _fadeSlideTransition(state, const UserHomeScreen()),
          ),
          GoRoute(
            path: '/shop/products',
            pageBuilder: (context, state) =>
                _fadeSlideTransition(state, const ProductListingScreen()),
          ),
          // Product detail: fade + zoom
          GoRoute(
            path: '/shop/product/:id',
            pageBuilder: (context, state) => _fadeZoomTransition(
              state,
              ProductDetailScreen(productId: state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/shop/search',
            pageBuilder: (context, state) =>
                _fadeSlideTransition(state, const SearchScreen()),
          ),
          GoRoute(
            path: '/shop/offers',
            pageBuilder: (context, state) =>
                _fadeSlideTransition(state, const OffersScreen()),
          ),
          GoRoute(
            path: '/shop/cart',
            pageBuilder: (context, state) =>
                _fadeSlideTransition(state, const CartScreen()),
          ),
          GoRoute(
            path: '/shop/order-summary',
            pageBuilder: (context, state) {
              final extra = state.extra;
              if (extra is Product) {
                return _fadeSlideTransition(
                    state, OrderSummaryScreen(product: extra));
              }
              // No product passed (e.g. deep link) → fall back to the cart.
              return _fadeSlideTransition(state, const CartScreen());
            },
          ),
          GoRoute(
            path: '/shop/checkout',
            pageBuilder: (context, state) =>
                _fadeSlideTransition(state, const UserCheckoutScreen()),
          ),
          GoRoute(
            path: '/shop/order-success/:orderId',
            pageBuilder: (context, state) => _fadeSlideTransition(
              state,
              OrderSuccessScreen(orderId: state.pathParameters['orderId']!),
            ),
          ),
          GoRoute(
            path: '/shop/account',
            pageBuilder: (context, state) {
              final tab = int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0;
              return _fadeSlideTransition(state, UserAccountScreen(initialTab: tab));
            },
          ),
          GoRoute(
            path: '/shop/account/profile',
            pageBuilder: (context, state) =>
                _fadeSlideTransition(state, const UserProfileScreen()),
          ),
          GoRoute(
            path: '/shop/account/edit-profile',
            pageBuilder: (context, state) =>
                _fadeSlideTransition(state, const UserEditProfileScreen()),
          ),
          GoRoute(
            path: '/shop/account/addresses',
            pageBuilder: (context, state) =>
                _fadeSlideTransition(state, const UserAddressesScreen()),
          ),
          GoRoute(
            path: '/shop/account/change-password',
            pageBuilder: (context, state) =>
                _fadeSlideTransition(state, const UserChangePasswordScreen()),
          ),
          GoRoute(
            path: '/shop/account/orders',
            pageBuilder: (context, state) =>
                _fadeSlideTransition(state, const UserOrdersScreen()),
          ),
          GoRoute(
            path: '/shop/account/orders/:id',
            pageBuilder: (context, state) => _fadeSlideTransition(
              state,
              UserOrderDetailScreen(orderId: state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/shop/account/orders/:id/tracking',
            pageBuilder: (context, state) => _fadeSlideTransition(
              state,
              UserShipmentTrackingScreen(orderId: state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/shop/wishlist',
            pageBuilder: (context, state) =>
                _fadeSlideTransition(state, const UserWishlistScreen()),
          ),
          GoRoute(
            path: '/shop/notifications',
            pageBuilder: (context, state) =>
                _fadeSlideTransition(state, const UserNotificationsScreen()),
          ),
          // Reviews: fade + zoom (same as product detail)
          GoRoute(
            path: '/shop/product/:id/reviews',
            pageBuilder: (context, state) => _fadeZoomTransition(
              state,
              UserProductReviewsScreen(productId: state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/shop/product/:id/write-review',
            pageBuilder: (context, state) => _slideUpTransition(
              state,
              UserWriteReviewScreen(productId: state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/shop/my-reviews',
            pageBuilder: (context, state) =>
                _fadeSlideTransition(state, const UserMyReviewsScreen()),
          ),
          GoRoute(
            path: '/shop/help',
            pageBuilder: (context, state) =>
                _fadeSlideTransition(state, const UserHelpScreen()),
          ),
          GoRoute(
            path: '/shop/help/faq',
            pageBuilder: (context, state) =>
                _fadeSlideTransition(state, const UserFAQScreen()),
          ),
          GoRoute(
            path: '/shop/help/ticket',
            pageBuilder: (context, state) =>
                _slideUpTransition(state, const UserRaiseTicketScreen()),
          ),
          GoRoute(
            path: '/shop/store-info',
            pageBuilder: (context, state) =>
                _fadeSlideTransition(state, const UserStoreInfoScreen()),
          ),
        ],
      ),
    ],
  );
}
