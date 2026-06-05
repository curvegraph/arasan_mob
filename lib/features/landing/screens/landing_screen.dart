import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/logo.png',
                  width: 88,
                  height: 88,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(height: 24),

              // Brand name
              const Text(
                'Arasan Mobiles',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 8),

              // Tagline
              Text(
                'Your Trusted Mobile Store',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),

              const SizedBox(height: 48),

              // Login card
              _LandingCard(
                title: 'Login / Sign Up',
                subtitle: 'Access your account, orders & wishlist',
                icon: Icons.person_rounded,
                color: Colors.white,
                textColor: AppColors.primary,
                onTap: () => context.go('/shop/login'),
              ),

              const SizedBox(height: 16),

              // Browse as Guest card
              _LandingCard(
                title: 'Browse as Guest',
                subtitle: 'Explore phones, deals & latest arrivals',
                icon: Icons.shopping_bag_rounded,
                color: AppColors.primaryLight,
                textColor: Colors.white,
                onTap: () => context.go('/shop'),
              ),

              const SizedBox(height: 40),

              // Footer
              Text(
                'Premium Smartphones at Best Prices',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LandingCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _LandingCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 28, color: textColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: textColor.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
