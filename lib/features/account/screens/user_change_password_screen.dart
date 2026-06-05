import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_animations.dart';
import '../../../core/utils/glass_morphism.dart';

class UserChangePasswordScreen extends StatefulWidget {
  const UserChangePasswordScreen({super.key});

  @override
  State<UserChangePasswordScreen> createState() =>
      _UserChangePasswordScreenState();
}

class _UserChangePasswordScreenState extends State<UserChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateCurrentPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Current password is required';
    }
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'New password is required';
    }
    if (value.length < 6) return 'Password must be at least 6 characters';
    if (value == _currentPasswordController.text) {
      return 'New password must be different from current password';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please confirm your new password';
    }
    if (value != _newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Password changed successfully'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(AppSpacing.md),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: const Text(
          'Change Password',
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
        padding: const EdgeInsets.all(AppSpacing.userPagePadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.sm),
              // Security icon with gold accent
              FadeSlideIn(
                index: 0,
                child: Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.userPrimary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.userPrimary.withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.userPrimary.withValues(alpha: 0.2),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      size: 36,
                      color: AppColors.userPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FadeSlideIn(
                index: 1,
                child: const Center(
                  child: Text(
                    'Create a strong password to\nsecure your account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sectionSpacing),

              // Current Password
              FadeSlideIn(
                index: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Current Password'),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _currentPasswordController,
                      obscureText: _obscureCurrent,
                      validator: _validateCurrentPassword,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _inputDecoration(
                        hint: 'Enter current password',
                        prefixIcon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureCurrent
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _obscureCurrent = !_obscureCurrent),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // New Password
              FadeSlideIn(
                index: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('New Password'),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: _obscureNew,
                      validator: _validateNewPassword,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _inputDecoration(
                        hint: 'Enter new password (min 6 characters)',
                        prefixIcon: Icons.lock_reset_outlined,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNew
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _obscureNew = !_obscureNew),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Confirm Password
              FadeSlideIn(
                index: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Confirm New Password'),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      validator: _validateConfirmPassword,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _inputDecoration(
                        hint: 'Re-enter new password',
                        prefixIcon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Save button - gold gradient
              FadeSlideIn(
                index: 5,
                child: ScaleOnTap(
                  onTap: _isSaving ? null : _changePassword,
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: PremiumDecorations.goldGlowButton(),
                    child: Center(
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Change Password',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
      prefixIcon: Icon(prefixIcon, color: AppColors.textSecondary, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.surfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.glassWhite),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.glassWhite),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.userPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }
}
