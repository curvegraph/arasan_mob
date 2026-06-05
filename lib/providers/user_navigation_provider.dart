import 'package:flutter/material.dart';

class UserNavigationProvider extends ChangeNotifier {
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  void setIndex(int index) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();
    }
  }

  // 5-tab bottom nav: Home, Offers, Cart, My Orders, Account.
  // Wishlist / Notifications live in the header.
  static const List<String> tabRoutes = [
    '/shop',
    '/shop/offers',
    '/shop/cart',
    '/shop/account/orders',
    '/shop/account',
  ];

  String getRouteForIndex(int index) {
    if (index >= 0 && index < tabRoutes.length) {
      return tabRoutes[index];
    }
    return tabRoutes[0];
  }

  int getIndexForRoute(String route) {
    // Check more-specific routes before their prefixes.
    if (route.startsWith('/shop/account/orders')) return 3;
    if (route.startsWith('/shop/offers')) return 1;
    if (route.startsWith('/shop/cart') || route.startsWith('/shop/checkout')) return 2;
    if (route.startsWith('/shop/account')) return 4;
    if (route == '/shop' || route.startsWith('/shop?')) return 0;
    // Header destinations (wishlist/notifications) and deep routes don't
    // highlight any tab.
    return -1;
  }
}
