import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/google_logo.dart';

class UserLoginScreen extends StatefulWidget {
  const UserLoginScreen({super.key});

  @override
  State<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _resendingVerification = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resendVerificationEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _resendingVerification = true);
    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: email,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent! Check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resend: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    if (mounted) setState(() => _resendingVerification = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    bool success;

    if (_isSignUp) {
      success = await auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );
    } else {
      success = await auth.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }

    if (mounted && success) {
      TextInput.finishAutofillContext(shouldSave: true);
      context.go('/shop');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
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
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  onDisposeAction: AutofillContextAction.commit,
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: const Color(0x331400E0), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.10),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset('assets/logo.png', fit: BoxFit.cover),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'Arasan ',
                              style: TextStyle(
                                color: Color(0xFFD32F2F),
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            TextSpan(
                              text: 'Mobiles',
                              style: TextStyle(
                                color: Color(0xFF2E7D32),
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.aboveBaseline,
                              baseline: TextBaseline.alphabetic,
                              child: Padding(
                                padding: EdgeInsets.only(left: 2),
                                child: Text(
                                  '®',
                                  style: TextStyle(
                                    color: Color(0xFFCBD5E1),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    Text(
                      _isSignUp ? 'Create your account' : 'Welcome back',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: -0.6,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSignUp
                          ? 'Sign up to start shopping'
                          : 'Sign in to continue shopping',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Name field (only for signup)
                    if (_isSignUp) ...[
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) {
                          if (_isSignUp && (v == null || v.isEmpty)) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Email field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username, AutofillHints.email],
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!v.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: _isSignUp ? TextInputAction.next : TextInputAction.done,
                      autofillHints: _isSignUp
                          ? const [AutofillHints.newPassword]
                          : const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (_isSignUp && v.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                      onFieldSubmitted: _isSignUp ? null : (_) => _submit(),
                    ),

                    // Confirm password field (only for signup)
                    if (_isSignUp) ...[
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (v != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _submit(),
                      ),
                    ],

                    // Error message
                    if (auth.error != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: auth.error!.contains('check your email') || auth.error!.contains('verification link')
                              ? Colors.orange.withValues(alpha: 0.1)
                              : AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  auth.error!.contains('check your email') || auth.error!.contains('verification link')
                                      ? Icons.mail_outline
                                      : Icons.error_outline,
                                  color: auth.error!.contains('check your email') || auth.error!.contains('verification link')
                                      ? Colors.orange
                                      : AppColors.error,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    auth.error!,
                                    style: TextStyle(
                                      color: auth.error!.contains('check your email') || auth.error!.contains('verification link')
                                          ? Colors.orange.shade800
                                          : AppColors.error,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (auth.error!.contains('check your email') || auth.error!.contains('verification link')) ...[
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: TextButton.icon(
                                  onPressed: _resendingVerification ? null : _resendVerificationEmail,
                                  icon: _resendingVerification
                                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Icon(Icons.send, size: 16),
                                  label: Text(_resendingVerification ? 'Sending...' : 'Resend Verification Email'),
                                  style: TextButton.styleFrom(foregroundColor: Colors.orange.shade800),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.lg),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.userPrimary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.userPrimary.withValues(alpha: 0.6),
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: auth.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _isSignUp ? 'Create Account' : 'Sign In',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Toggle sign in / sign up
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isSignUp ? 'Already have an account?' : "Don't have an account?",
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isSignUp = !_isSignUp;
                              auth.clearError();
                            });
                          },
                          child: Text(
                            _isSignUp ? 'Sign In' : 'Sign Up',
                            style: const TextStyle(
                              color: AppColors.userPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          child: Text(
                            'or',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Sign in with Google
                    Center(
                      child: GestureDetector(
                        onTap: auth.isLoading
                            ? null
                            : () async {
                                final success = await auth.signInWithGoogle();
                                if (mounted && success) {
                                  context.go('/shop');
                                }
                              },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: GoogleLogo(size: 24),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // Login with Phone — always visible; the phone-login
                    // screen itself handles the case where Firebase init failed.
                    OutlinedButton.icon(
                      onPressed: () => context.push('/shop/phone-login'),
                      icon: const Icon(Icons.phone, size: 20),
                      label: const Text(
                        'Login with Phone',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.userPrimary,
                        side: const BorderSide(color: AppColors.userPrimary),
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // Continue as guest
                    OutlinedButton(
                      onPressed: () => context.go('/shop'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Continue as Guest',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
