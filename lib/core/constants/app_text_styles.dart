import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Section Headers
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  // Product
  static const TextStyle productName = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle productBrand = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  // Price
  static const TextStyle priceOffer = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle priceMRP = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.priceMRP,
    decoration: TextDecoration.lineThrough,
  );

  static const TextStyle priceDiscount = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.priceGreen,
  );

  static const TextStyle priceLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  // Headlines
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  // Titles
  static const TextStyle titleLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.35,
  );

  // Body
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.3,
  );

  // Labels
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  // Special
  static const TextStyle priceTag = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.0,
    color: AppColors.textSecondary,
  );

  static const TextStyle badge = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  // Legacy aliases
  static const TextStyle displayLarge = headlineLarge;
  static const TextStyle displayMedium = headlineLarge;
  static const TextStyle displaySmall = headlineMedium;
  static const TextStyle heading1 = headlineLarge;
  static const TextStyle heading2 = headlineMedium;
  static const TextStyle heading3 = titleLarge;
  static const TextStyle subtitle = titleMedium;
  static const TextStyle body = bodyMedium;
  static const TextStyle button = labelLarge;
  static const TextStyle statValue = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static const TextStyle statLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
  static const TextStyle goldAccent = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );
}
