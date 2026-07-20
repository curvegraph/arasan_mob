import 'package:flutter/material.dart';

/// Branded splash rendered by Flutter — just the Arasan peacock logo, centred on
/// the launch navy (#1F5593). It is a pixel-for-pixel continuation of the native
/// OS launch splash (same navy, same centred logo), so the hand-off from the OS
/// splash to Flutter is invisible: the user sees ONE logo splash and then the
/// home page (Flipkart-style), never two separate screens.
///
/// Rendering the logo in Flutter (instead of relying only on the OS splash) is
/// what makes it show on OEM builds — notably Vivo/Oppo/Realme — that suppress
/// the Android 12+ native splash icon and would otherwise show a bare colour.
class BrandedSplash extends StatelessWidget {
  const BrandedSplash({super.key});

  // Sampled from assets/logo_round.png's ring so the circular logo blends
  // seamlessly into the background (no visible rectangle).
  static const Color _navy = Color(0xFF1F5593);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: _navy,
      body: Center(
        // logo_round has transparent corners, so it renders as a clean disc on
        // the matching navy instead of a rectangle. Sized to sit close to the
        // native splash icon so the OS→Flutter hand-off isn't noticeable.
        child: Image(
          image: AssetImage('assets/logo_round.png'),
          width: 180,
        ),
      ),
    );
  }
}
