import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/cart_provider.dart';
import 'search_bar_button.dart';
import 'user_app_bar.dart';
import 'user_bottom_nav.dart';

class UserScaffold extends StatefulWidget {
  final Widget child;

  const UserScaffold({super.key, required this.child});

  static const double _mobileBreakpoint = 768;

  // Routes whose inner Scaffold owns the bottom area (sticky CTA bar,
  // payment button, etc.). On these we suppress the global UserBottomNav so
  // the page's own action bar isn't double-stacked.
  static const _routesWithOwnBottomBar = <String>[
    '/shop/product/',
    '/shop/checkout',
    '/shop/order-success',
  ];

  // Routes where the inline search bar below the header would be redundant
  // or distracting (the search screen itself, checkout/order-success flow).
  static const _routesWithoutSearchBar = <String>[
    '/shop/search',
    '/shop/checkout',
    '/shop/order-success',
    '/shop/login',
    '/shop/phone-login',
    '/shop/login-email',
  ];

  @override
  State<UserScaffold> createState() => _UserScaffoldState();
}

class _UserScaffoldState extends State<UserScaffold> {
  DateTime? _lastBackAt;

  @override
  Widget build(BuildContext context) {
    final isMobile =
        MediaQuery.sizeOf(context).width < UserScaffold._mobileBreakpoint;
    final router = GoRouter.of(context);
    final path = GoRouterState.of(context).uri.path;
    final hasOwnBottomBar = UserScaffold._routesWithOwnBottomBar
        .any((r) => path.startsWith(r));
    final showBottomNav = isMobile && !hasOwnBottomBar;
    final showSearchBar = isMobile &&
        !UserScaffold._routesWithoutSearchBar.any((r) => path.startsWith(r));
    // The product detail page gets a dedicated header (back + search + cart)
    // instead of the home-style logo header. Only this page — the home page and
    // other inner pages keep their existing headers.
    final isProductDetail = isMobile && path.startsWith('/shop/product/');
    final isHomeTab = path == '/shop';
    final canShellPop = router.canPop();

    return PopScope(
      // Let the system pop normally when the shell navigator has something to
      // pop (deep screens reached via context.push). Intercept only when we're
      // at a tab root with nothing on the stack.
      canPop: canShellPop,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (!isHomeTab) {
          // Non-home tabs (Cart/Wishlist/Account/Products/etc.) bounce to Home
          // instead of exiting — matches the Android convention.
          router.go('/shop');
          return;
        }
        // On Home: require two back presses within 2s to exit.
        final now = DateTime.now();
        if (_lastBackAt != null &&
            now.difference(_lastBackAt!) < const Duration(seconds: 2)) {
          await SystemNavigator.pop();
          return;
        }
        _lastBackAt = now;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Press back again to exit'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            if (isProductDetail)
              const _ProductDetailHeader()
            else ...[
              const UserAppBar(),
              if (showSearchBar) const SearchBarButton(),
            ],
            Expanded(child: widget.child),
          ],
        ),
        bottomNavigationBar: showBottomNav ? const UserBottomNav() : null,
      ),
    );
  }
}

/// Compact header shown ONLY on the product detail page:
/// back button (left) · tappable search bar (center) · cart (right).
class _ProductDetailHeader extends StatelessWidget {
  const _ProductDetailHeader();

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartProvider>().itemCount;
    final router = GoRouter.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 58,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                // Back
                GestureDetector(
                  onTap: () {
                    if (router.canPop()) {
                      router.pop();
                    } else {
                      router.go('/shop');
                    }
                  },
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(Icons.arrow_back,
                        color: Color(0xFF1A1A1A), size: 24),
                  ),
                ),
                // Inline live search (same behaviour as the home search bar) —
                // typing shows product suggestions here, no navigation.
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: SearchBarButton(compact: true),
                  ),
                ),
                // Cart
                GestureDetector(
                  onTap: () => context.go('/shop/cart'),
                  child: SizedBox(
                    width: 48,
                    height: 44,
                    child: Center(
                      child: Badge(
                        isLabelVisible: cartCount > 0,
                        offset: const Offset(6, -6),
                        backgroundColor: const Color(0xFFA0D911),
                        label: Text(
                          cartCount > 9 ? '9+' : '$cartCount',
                          style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                        child: const Icon(Icons.shopping_cart_outlined,
                            color: Color(0xFF1A1A1A), size: 24),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
