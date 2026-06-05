import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../features/auth/screens/login_dialog.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/user_navigation_provider.dart';

/// 5-tab bottom navigation: Home, Offers, Cart, My Orders, Account.
/// Wishlist / Notifications live in the header.
class UserBottomNav extends StatelessWidget {
  const UserBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<UserNavigationProvider>();
    final cartCount = context.watch<CartProvider>().itemCount;
    final isLoggedIn = context.watch<AuthProvider>().isLoggedIn;
    final currentRoute = GoRouterState.of(context).uri.toString();

    int selectedIndex = navProvider.getIndexForRoute(currentRoute);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: Color(0x66E2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                isSelected: selectedIndex == 0,
                onTap: () {
                  navProvider.setIndex(0);
                  context.go('/shop');
                },
              ),
              _NavItem(
                icon: Icons.local_offer_outlined,
                activeIcon: Icons.local_offer,
                label: 'Offers',
                isSelected: selectedIndex == 1,
                onTap: () {
                  navProvider.setIndex(1);
                  context.go('/shop/offers');
                },
              ),
              _NavItem(
                icon: Icons.shopping_cart_outlined,
                activeIcon: Icons.shopping_cart,
                label: 'Cart',
                isSelected: selectedIndex == 2,
                badgeCount: cartCount,
                badgeColor: const Color(0xFFA0D911),
                onTap: () {
                  navProvider.setIndex(2);
                  context.go('/shop/cart');
                },
              ),
              _NavItem(
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long,
                label: 'My Orders',
                isSelected: selectedIndex == 3,
                onTap: () async {
                  if (!isLoggedIn) {
                    final loggedIn = await LoginDialog.show(context);
                    if (!loggedIn || !context.mounted) return;
                  }
                  navProvider.setIndex(3);
                  if (!context.mounted) return;
                  context.go('/shop/account/orders');
                },
              ),
              _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Account',
                isSelected: selectedIndex == 4,
                onTap: () async {
                  if (!isLoggedIn) {
                    final loggedIn = await LoginDialog.show(context);
                    if (!loggedIn || !context.mounted) return;
                  }
                  navProvider.setIndex(4);
                  if (!context.mounted) return;
                  context.go('/shop/account');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final int badgeCount;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    this.badgeCount = 0,
    this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Badge(
              isLabelVisible: badgeCount > 0,
              label: Text(
                badgeCount > 9 ? '9+' : '$badgeCount',
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
              ),
              backgroundColor: badgeColor ?? AppColors.accent,
              child: Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? AppColors.primary : AppColors.bottomNavInactive,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.bottomNavInactive,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
