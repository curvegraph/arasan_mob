import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_animations.dart';
import '../../../core/utils/glass_morphism.dart';

class UserStoreInfoScreen extends StatelessWidget {
  const UserStoreInfoScreen({super.key});

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not open the link'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(AppSpacing.md),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: const Text(
          'About Us',
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
        surfaceTintColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Store header - dark surface with gold accent
            FadeSlideIn(
              index: 0,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    bottom: BorderSide(color: AppColors.glassWhite),
                  ),
                ),
                padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.userPrimary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.userPrimary, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.userPrimary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'A',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppColors.userPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'Arasan Mobiles',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Your Trusted Mobile Store',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Map placeholder
            FadeSlideIn(
              index: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.userPagePadding,
                ),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: PremiumDecorations.darkCard(borderRadius: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.map_outlined,
                        size: 48,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        'Map View',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textHint,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      TextButton.icon(
                        onPressed: () => _launchUrl(
                          context,
                          'https://maps.google.com/?q=Arasan+Mobiles',
                        ),
                        icon: const Icon(Icons.directions, size: 18),
                        label: const Text('Get Directions'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.userPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Store Address
            FadeSlideIn(
              index: 2,
              child: _buildInfoCard(
                icon: Icons.location_on_outlined,
                title: 'Store Address',
                children: [
                  const Text(
                    'Tamil Nadu, India',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Store Timings
            FadeSlideIn(
              index: 3,
              child: _buildInfoCard(
                icon: Icons.access_time_outlined,
                title: 'Store Timings',
                children: [
                  const Text(
                    'Store timings coming soon.',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isStoreOpen()
                          ? AppColors.success.withValues(alpha: 0.15)
                          : AppColors.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _isStoreOpen() ? AppColors.success : AppColors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isStoreOpen() ? 'Open Now' : 'Closed Now',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _isStoreOpen() ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Contact Info
            FadeSlideIn(
              index: 4,
              child: _buildInfoCard(
                icon: Icons.contact_phone_outlined,
                title: 'Contact Us',
                children: [
                  const Text(
                    'Contact details coming soon.',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Social Media
            FadeSlideIn(
              index: 5,
              child: _buildInfoCard(
                icon: Icons.share_outlined,
                title: 'Follow Us',
                children: [
                  const Text(
                    'Social media links coming soon.',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.sectionSpacing),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.userPagePadding),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: PremiumDecorations.darkCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.userPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.userPrimary.withValues(alpha: 0.2)),
                ),
                child: Icon(icon, color: AppColors.userPrimary, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }

  bool _isStoreOpen() {
    final now = DateTime.now();
    final hour = now.hour;
    final weekday = now.weekday;

    if (weekday == DateTime.sunday) {
      return hour >= 11 && hour < 19;
    }
    return hour >= 10 && hour < 21;
  }
}
