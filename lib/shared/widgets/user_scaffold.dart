import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
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
            const UserAppBar(),
            if (showSearchBar) const SearchBarButton(),
            Expanded(child: widget.child),
          ],
        ),
        bottomNavigationBar: showBottomNav ? const UserBottomNav() : null,
      ),
    );
  }
}
