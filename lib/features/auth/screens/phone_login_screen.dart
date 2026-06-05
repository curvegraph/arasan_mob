import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/config/firebase_availability.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/phone_auth_provider.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  final _otpFocusNode = FocusNode();

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _phoneFocusNode.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    final phoneAuth = context.read<PhoneAuthProvider>();
    await phoneAuth.sendOTP(_phoneController.text);
    if (phoneAuth.codeSent && mounted) {
      _otpFocusNode.requestFocus();
    }
  }

  Future<void> _verifyOTP() async {
    final phoneAuth = context.read<PhoneAuthProvider>();
    final success = await phoneAuth.verifyOTP(_otpController.text);
    if (success && mounted) {
      // Sync Firebase user with main AuthProvider
      final userInfo = phoneAuth.firebaseUserInfo;
      final auth = context.read<AuthProvider>();

      // Sign in to main app auth using Firebase phone user info
      await auth.loginWithFirebasePhone(
        uid: userInfo['uid']!,
        phone: userInfo['phone'] ?? '+91${phoneAuth.phoneNumber}',
        name: userInfo['name'],
      );

      phoneAuth.reset();
      if (!mounted) return;
      context.go('/shop');
    }
  }

  @override
  Widget build(BuildContext context) {
    final phoneAuth = context.watch<PhoneAuthProvider>();

    if (!FirebaseAvailability.isAvailable) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.phonelink_erase,
                      size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Phone login is not configured',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Firebase Auth is not set up for this build. '
                    'Please sign in using another method.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                  if (FirebaseAvailability.lastError != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        FirebaseAvailability.lastError!,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textHint),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            phoneAuth.reset();
            context.pop();
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.xl + AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/logo.png',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Arasan Mobiles',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.userPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Title
                  Text(
                    phoneAuth.codeSent ? 'Verify OTP' : 'Phone Login',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    phoneAuth.codeSent
                        ? 'Enter the 6-digit OTP sent to +91 ${phoneAuth.phoneNumber}'
                        : 'Enter your mobile number to receive OTP',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Phone Number Input
                  if (!phoneAuth.codeSent) ...[
                    TextFormField(
                      controller: _phoneController,
                      focusNode: _phoneFocusNode,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Mobile Number',
                        hintText: '9876543210',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        prefixText: '+91 ',
                        prefixStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onFieldSubmitted: (_) => _sendOTP(),
                    ),
                  ],

                  // OTP Input
                  if (phoneAuth.codeSent) ...[
                    TextFormField(
                      controller: _otpController,
                      focusNode: _otpFocusNode,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 12,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Enter OTP',
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onFieldSubmitted: (_) => _verifyOTP(),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Resend & Change number
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: phoneAuth.isLoading
                              ? null
                              : () {
                                  phoneAuth.reset();
                                  _otpController.clear();
                                  _phoneFocusNode.requestFocus();
                                },
                          child: const Text(
                            'Change Number',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                        TextButton(
                          onPressed:
                              phoneAuth.isLoading ? null : phoneAuth.resendOTP,
                          child: const Text(
                            'Resend OTP',
                            style: TextStyle(color: AppColors.userPrimary),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Error message
                  if (phoneAuth.error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.error, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              phoneAuth.error!,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.lg),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: phoneAuth.isLoading
                          ? null
                          : phoneAuth.codeSent
                              ? _verifyOTP
                              : _sendOTP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.userPrimary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.userPrimary.withValues(alpha: 0.6),
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: phoneAuth.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              phoneAuth.codeSent ? 'Verify OTP' : 'Send OTP',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Back to email login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Prefer email login?',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      TextButton(
                        onPressed: () {
                          phoneAuth.reset();
                          context.pop();
                        },
                        child: const Text(
                          'Sign in with Email',
                          style: TextStyle(
                            color: AppColors.userPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
