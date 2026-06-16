import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/config/firebase_availability.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/phone_auth_provider.dart';
import '../../../shared/widgets/google_logo.dart';

/// Unified login screen — phone OTP + Google sign-in.
/// Matches the Svelte web login page: dark navy gradient mesh,
/// floating phone icons, and a glassmorphism card.
class UnifiedLoginScreen extends StatefulWidget {
  const UnifiedLoginScreen({super.key});

  @override
  State<UnifiedLoginScreen> createState() => _UnifiedLoginScreenState();
}

class _UnifiedLoginScreenState extends State<UnifiedLoginScreen>
    with TickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  final _otpFocusNode = FocusNode();

  late final AnimationController _meshController;
  late final AnimationController _floatController;

  /// True between OTP verify success and the navigation away from this
  /// screen. Drives the full-screen "Signing you in" overlay so the user
  /// doesn't see the phone-entry view flash back while the backend exchange
  /// + profile hydration are still in flight.
  bool _finalizing = false;

  @override
  void initState() {
    super.initState();
    _meshController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _phoneFocusNode.dispose();
    _otpFocusNode.dispose();
    _meshController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    final phoneAuth = context.read<PhoneAuthProvider>();
    await phoneAuth.sendOTP(_phoneController.text);
    if (phoneAuth.codeSent && mounted) {
      _otpFocusNode.requestFocus();
    }
  }

  void _exitAfterLogin() {
    if (context.canPop()) {
      context.pop(true);
    } else {
      context.go('/shop');
    }
  }

  Future<void> _verifyOTP() async {
    final phoneAuth = context.read<PhoneAuthProvider>();
    final success = await phoneAuth.verifyOTP(_otpController.text);
    if (!success || !mounted) return;

    setState(() => _finalizing = true);
    try {
      final idToken = await phoneAuth.getIdToken();
      if (idToken == null || !mounted) return;
      final auth = context.read<AuthProvider>();
      await auth.loginWithFirebasePhone(idToken: idToken);
      if (!mounted) return;
      if (auth.isLoggedIn && auth.needsProfileCompletion) {
        context.go('/shop/complete-profile');
      } else {
        _exitAfterLogin();
      }
      phoneAuth.reset();
    } catch (_) {
      if (mounted) setState(() => _finalizing = false);
    }
  }

  Future<void> _googleSignIn() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithGoogle();
    if (success && mounted) _exitAfterLogin();
  }

  void _backToPhone() {
    final phoneAuth = context.read<PhoneAuthProvider>();
    _otpController.clear();
    phoneAuth.reset();
  }

  @override
  Widget build(BuildContext context) {
    final phoneAuth = context.watch<PhoneAuthProvider>();
    final isOtpStep = phoneAuth.codeSent;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: Stack(
        children: [
          // Layer 1: animated mesh gradient
          AnimatedBuilder(
            animation: _meshController,
            builder: (_, __) => CustomPaint(
              size: Size.infinite,
              painter: _MeshPainter(_meshController.value),
            ),
          ),
          // Layer 2: floating phone outlines (decorative)
          AnimatedBuilder(
            animation: _floatController,
            builder: (_, __) {
              final t = _floatController.value * 2 * math.pi;
              return Stack(
                children: [
                  Positioned(
                    top: 80 + 16 * math.sin(t),
                    left: 24,
                    child: Icon(Icons.phone_iphone,
                        size: 110,
                        color: Colors.blue.shade300.withOpacity(0.18)),
                  ),
                  Positioned(
                    top: 140 + 20 * math.sin(t + 1),
                    right: 30,
                    child: Icon(Icons.phone_iphone,
                        size: 140,
                        color: Colors.lightBlue.shade200.withOpacity(0.14)),
                  ),
                  Positioned(
                    bottom: 60 + 14 * math.sin(t + 2),
                    left: 40,
                    child: Icon(Icons.phone_iphone,
                        size: 90,
                        color: Colors.indigo.shade200.withOpacity(0.18)),
                  ),
                ],
              );
            },
          ),
          // Layer 3: back button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white70),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/shop');
                  }
                },
              ),
            ),
          ),
          // Layer 4: glass card
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: _GlassCard(
                    child: isOtpStep
                        ? _buildOtpStep(phoneAuth)
                        : _buildPhoneStep(phoneAuth),
                  ),
                ),
              ),
            ),
          ),
          // Layer 5: finalize overlay — blocks input + hides UI flashes
          // between OTP success and navigation
          if (_finalizing)
            Positioned.fill(
              child: AbsorbPointer(
                child: ColoredBox(
                  color: Colors.black54,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        SizedBox(
                          height: 44,
                          width: 44,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Signing you in…',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhoneStep(PhoneAuthProvider phoneAuth) {
    final disabled = phoneAuth.isLoading || !FirebaseAvailability.isAvailable;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LogoHeader(),
        const SizedBox(height: 8),
        const Text(
          'Welcome back',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Sign in to continue shopping',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 24),
        if (!FirebaseAvailability.isAvailable)
          _ErrorBanner(
              message: 'Phone login is not configured for this build.'),
        _PhoneInput(controller: _phoneController, focusNode: _phoneFocusNode),
        const SizedBox(height: 14),
        if (phoneAuth.error != null) _ErrorBanner(message: phoneAuth.error!),
        _PrimaryButton(
          label: 'Send OTP',
          loading: phoneAuth.isLoading,
          onTap: disabled ? null : _sendOTP,
        ),
        const SizedBox(height: 18),
        const _OrDivider(),
        const SizedBox(height: 14),
        _GoogleButton(onTap: phoneAuth.isLoading ? null : _googleSignIn),
        const SizedBox(height: 12),
        const Text(
          'By signing in you agree to our Terms & Privacy Policy',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }

  Widget _buildOtpStep(PhoneAuthProvider phoneAuth) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LogoHeader(),
        const SizedBox(height: 8),
        const Text(
          'Enter verification code',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Sent to +91 ${phoneAuth.phoneNumber}',
          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 22),
        _OtpInput(controller: _otpController, focusNode: _otpFocusNode),
        const SizedBox(height: 14),
        if (phoneAuth.error != null) _ErrorBanner(message: phoneAuth.error!),
        _PrimaryButton(
          label: 'Verify & Sign in',
          loading: phoneAuth.isLoading,
          onTap: phoneAuth.isLoading ? null : _verifyOTP,
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: phoneAuth.isLoading ? null : _backToPhone,
          child: const Text(
            'Change number',
            style: TextStyle(
                color: Color(0xFF1D4ED8), fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

/// Glassmorphism container.
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.6), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _LogoHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            'assets/logo.png',
            width: 64,
            height: 64,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 10),
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Arasan ',
                style: TextStyle(
                  color: Color(0xFFDC2626),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
              TextSpan(
                text: 'Mobiles',
                style: TextStyle(
                  color: Color(0xFF16A34A),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}

class _PhoneInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  const _PhoneInput({required this.controller, required this.focusNode});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(color: Color(0xFFCBD5E1)),
              ),
            ),
            child: const Text(
              '+91',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                hintText: '10-digit mobile number',
                hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  const _OtpInput({required this.controller, required this.focusNode});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        style: const TextStyle(
          fontSize: 22,
          color: Color(0xFF0F172A),
          fontWeight: FontWeight.w800,
          letterSpacing: 8,
        ),
        decoration: const InputDecoration(
          hintText: '------',
          hintStyle: TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 22,
            letterSpacing: 8,
            fontWeight: FontWeight.w800,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onTap;
  const _PrimaryButton(
      {required this.label, this.loading = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !loading;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFCBD5E1),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : Text(
                label,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800),
              ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _GoogleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const GoogleLogo(size: 20),
        label: const Text(
          'Continue with Google',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: const BorderSide(color: Color(0xFFCBD5E1)),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'or continue with',
            style: TextStyle(
              fontSize: 11,
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              size: 16, color: Color(0xFFB91C1C)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFB91C1C),
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated mesh gradient background — soft drifting blobs over navy.
class _MeshPainter extends CustomPainter {
  final double t;
  _MeshPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // Base dark navy fill
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0B1220),
    );

    void blob(Offset center, double radius, Color color) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(colors: [
            color,
            color.withOpacity(0),
          ]).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    final angle = t * 2 * math.pi;
    final cx = size.width / 2;
    final cy = size.height / 2;
    blob(
      Offset(cx + 80 * math.sin(angle), cy * 0.45 + 30 * math.cos(angle)),
      size.width * 0.55,
      const Color(0xFF3B82F6).withOpacity(0.35),
    );
    blob(
      Offset(cx - 60 * math.cos(angle), cy * 1.55 + 40 * math.sin(angle)),
      size.width * 0.6,
      const Color(0xFF6366F1).withOpacity(0.32),
    );
    blob(
      Offset(cx + 100 * math.sin(angle + 1),
          cy + 60 * math.cos(angle + 1)),
      size.width * 0.5,
      const Color(0xFF1E40AF).withOpacity(0.28),
    );
  }

  @override
  bool shouldRepaint(covariant _MeshPainter old) => old.t != t;
}
