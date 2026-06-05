import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_animations.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/glass_morphism.dart';
import '../../../providers/user_profile_provider.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<UserProfileProvider>();
    final profile = profileProvider.profile;
    final initial = profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'U';

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: const Text(
          'My Profile',
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
            // Profile avatar section - dark background with gold accent
            FadeSlideIn(
              index: 0,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  border: Border(
                    bottom: BorderSide(color: AppColors.glassWhite),
                  ),
                ),
                padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppColors.userPrimary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.userPrimary, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.userPrimary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            color: AppColors.userPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      profile.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Member since ${DateFormatter.format(profile.joinedAt)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Profile info cards
            FadeSlideIn(
              index: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.userPagePadding),
                child: Container(
                  decoration: PremiumDecorations.darkCard(),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        icon: Icons.person_outline,
                        label: 'Full Name',
                        value: profile.name,
                      ),
                      Divider(height: 1, color: AppColors.glassWhite, indent: 56),
                      _buildInfoRow(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: profile.email,
                      ),
                      Divider(height: 1, color: AppColors.glassWhite, indent: 56),
                      _buildInfoRow(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        value: profile.phone,
                      ),
                      Divider(height: 1, color: AppColors.glassWhite, indent: 56),
                      _buildInfoRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Member Since',
                        value: DateFormatter.format(profile.joinedAt),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Edit profile button - gold gradient
            FadeSlideIn(
              index: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.userPagePadding),
                child: ScaleOnTap(
                  onTap: () => context.push('/shop/account/edit-profile'),
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: PremiumDecorations.goldGlowButton(),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit_outlined, size: 20, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Edit Profile',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.sectionSpacing),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.userPrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.userPrimary.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: AppColors.userPrimary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
