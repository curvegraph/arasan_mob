import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary - Arasan Mobiles Royal Blue
  static const Color primary = Color(0xFF1400E0);        // Vivid royal blue
  static const Color primaryLight = Color(0xFF2962FF);   // Bright blue
  static const Color primaryDark = Color(0xFF0D00B3);    // Darker blue

  // Header
  static const Color headerBg = Color(0xFF1400E0);       // Royal blue header
  static const Color headerText = Color(0xFFFFFFFF);     // White

  // Background
  static const Color background = Color(0xFFEEF2FF);     // Very light blue
  static const Color surface = Color(0xFFFFFFFF);        // White
  static const Color surfaceVariant = Color(0xFFF1F5F9); // Subtle gray

  // Accent - Lime Green (from static site CTA buttons)
  static const Color accent = Color(0xFFA0D911);         // Lime green
  static const Color accentLight = Color(0xFFC6EA5B);    // Light lime
  static const Color accentOrange = Color(0xFFF97316);   // Orange for badges

  // Text
  static const Color textPrimary = Color(0xFF1A1A1A);    // Almost black
  static const Color textSecondary = Color(0xFF64748B);  // Gray
  static const Color textTertiary = Color(0xFF94A3B8);   // Light gray
  static const Color textHint = Color(0xFFCBD5E1);       // Very light
  static const Color textWhite = Color(0xFFFFFFFF);      // White

  // Price
  static const Color priceMain = Color(0xFF1A1A1A);      // Dark for current price
  static const Color priceMRP = Color(0xFF94A3B8);       // Gray strikethrough
  static const Color discount = Color(0xFF16A34A);       // Green for discount

  // Rating
  static const Color rating = Color(0xFFFBBF24);         // Gold stars
  static const Color ratingBg = Color(0xFF16A34A);       // Green badge

  // Status
  static const Color success = Color(0xFF16A34A);        // Green
  static const Color error = Color(0xFFDC2626);          // Red
  static const Color warning = Color(0xFFF59E0B);        // Amber
  static const Color info = Color(0xFF2962FF);           // Blue

  // Border & Divider
  static const Color border = Color(0xFFE2E8F0);         // Light border
  static const Color divider = Color(0xFFF1F5F9);        // Very light
  static const Color cardBorder = Color(0xFFE2E8F0);     // Card border

  // Shimmer
  static const Color shimmerBase = Color(0xFFE2E8F0);
  static const Color shimmerHighlight = Color(0xFFF8FAFC);

  // Cart & Wishlist
  static const Color wishlistRed = Color(0xFFEF4444);    // Red heart
  static const Color cartBlue = Color(0xFF2962FF);       // Blue cart
  static const Color freeDelivery = Color(0xFF16A34A);   // Green

  // Navigation
  static const Color navActive = Color(0xFF1400E0);      // Active blue
  static const Color navInactive = Color(0xFF64748B);    // Inactive gray

  // Offer & Badge
  static const Color offerBadge = Color(0xFFEF4444);     // Red
  static const Color newBadge = Color(0xFF8B5CF6);       // Purple
  static const Color dealBadge = Color(0xFFF97316);      // Orange

  // Category Icons Background
  static const Color categoryBg1 = Color(0xFFDBEAFE);    // Light blue
  static const Color categoryBg2 = Color(0xFFFCE7F3);    // Light pink
  static const Color categoryBg3 = Color(0xFFD1FAE5);    // Light green
  static const Color categoryBg4 = Color(0xFFFEF3C7);    // Light yellow
  static const Color categoryBg5 = Color(0xFFE0E7FF);    // Light indigo
  static const Color categoryBg6 = Color(0xFFFFE4E6);    // Light rose

  // Legacy aliases for compatibility
  static const Color userPrimary = primary;
  static const Color userPrimaryDark = primaryDark;
  static const Color userPrimaryLight = primaryLight;
  static const Color userSurface = surface;
  static const Color userBackground = background;
  static const Color userAccent = accent;
  static const Color starYellow = rating;
  static const Color goldGlow = Color(0x1A1400E0);
  static const Color glassWhite = border;
  static const Color glassWhiteLight = surfaceVariant;
  static const Color obsidian = textPrimary;
  static const Color snow = background;
  static const Color smoke = textSecondary;
  static const Color ash = Color(0xFF475569);
  static const Color mist = surfaceVariant;
  static const Color steel = border;
  static const Color surfaceDark = headerBg;
  static const Color surfaceLight = surface;
  static const Color accentBlue = primaryLight;
  static const Color accentBlueLight = Color(0xFF82B1FF);
  static const Color addToCartGreen = accent;
  static const Color freeDeliveryGreen = success;
  static const Color bottomNavActive = primary;
  static const Color bottomNavInactive = navInactive;
  static const Color priceGreen = discount;
  static const Color dealRed = Color(0xFFEF4444);
}
