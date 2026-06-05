import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_order_provider.dart';
import '../../../providers/wishlist_provider.dart';
import '../../auth/screens/login_dialog.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 70,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.5,
            height: 1.0,
          ),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (!auth.isLoggedIn) {
            return _buildGuestView(context);
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildProfileHeader(auth),
                const SizedBox(height: 20),
                _buildStatsSection(context),
                const SizedBox(height: 20),
                _buildMenuSection(context),
                const SizedBox(height: 20),
                _buildLogoutButton(context, auth),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGuestView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Welcome!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Login to access your orders, wishlist, and personalized recommendations',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => LoginDialog.show(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Login',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.push('/shop/login'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Login with OTP',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(AuthProvider auth) {
    final name = auth.userName ?? '';
    final email = auth.userEmail ?? '';
    final phone = auth.userPhone ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name.isNotEmpty ? name : 'User',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              email,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
          ],
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              phone,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Consumer<UserOrderProvider>(
              builder: (context, orderProvider, _) {
                return _buildStatItem(
                  Icons.shopping_bag_outlined,
                  orderProvider.allOrders.length.toString(),
                  'Orders',
                );
              },
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.divider,
          ),
          Expanded(
            child: Consumer<WishlistProvider>(
              builder: (context, wishlist, _) {
                return _buildStatItem(
                  Icons.favorite_border,
                  wishlist.itemCount.toString(),
                  'Wishlist',
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    final menuItems = [
      {'icon': Icons.person_outline, 'title': 'Edit Profile', 'subtitle': 'Update your personal information', 'route': '/shop/account/edit-profile'},
      {'icon': Icons.location_on_outlined, 'title': 'Manage Addresses', 'subtitle': 'Add or edit delivery addresses', 'route': '/shop/account/addresses'},
      {'icon': Icons.shopping_bag_outlined, 'title': 'My Orders', 'subtitle': 'View your order history', 'route': '/shop/account/orders'},
      {'icon': Icons.notifications_outlined, 'title': 'Notifications', 'subtitle': 'Manage notification preferences', 'route': '/shop/notifications'},
      {'icon': Icons.help_outline, 'title': 'Help & Support', 'subtitle': 'Get help with your orders', 'route': '/shop/help'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: menuItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                title: Text(
                  item['title'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  item['subtitle'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: AppColors.textHint,
                ),
                onTap: () => context.push(item['route'] as String),
              ),
              if (index < menuItems.length - 1)
                const Divider(height: 1, indent: 72),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Logout'),
                content: const Text('Are you sure you want to logout?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      auth.logout();
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Logout',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            );
          },
          icon: const Icon(Icons.logout, color: AppColors.error),
          label: const Text(
            'Logout',
            style: TextStyle(color: AppColors.error),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: const BorderSide(color: AppColors.error),
          ),
        ),
      ),
    );
  }
}
