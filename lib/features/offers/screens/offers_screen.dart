import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../data/models/offer.dart';
import '../../../providers/offer_provider.dart';
import '../widgets/coupon_card.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OfferProvider>().loadOffers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        toolbarHeight: 70,
        title: const Text(
          'Offers',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.5,
            height: 1.0,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: Consumer<OfferProvider>(
        builder: (context, offerProvider, _) {
          if (offerProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- Offers & Deals section ----
                const Text(
                  'Offers & Deals',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                if (offerProvider.activeOffers.isEmpty)
                  _buildEmptyState(
                    icon: Icons.local_offer_outlined,
                    message: 'No active offers right now',
                  )
                else
                  ...offerProvider.activeOffers.map(
                    (offer) => _buildOfferCard(offer),
                  ),

                const SizedBox(height: AppSpacing.xl),

                // ---- Coupons section ----
                const Text(
                  'Coupons',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                if (offerProvider.activeCoupons.isEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Center(
                      child: Text(
                        'No coupons available',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                else
                  ...offerProvider.activeCoupons.map(
                    (coupon) => CouponCard(coupon: coupon),
                  ),

                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Offer card
  // ---------------------------------------------------------------------------
  Widget _buildOfferCard(Offer offer) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row with discount badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (offer.description != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          offer.description!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Discount badge (orange background)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    offer.discountLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Validity
            Row(
              children: [
                const Icon(
                  Icons.schedule,
                  size: 14,
                  color: AppColors.textHint,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Valid till ${DateFormat('dd MMM yyyy').format(offer.endDate)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Shop Now button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                ),
                child: const Text(
                  'Shop Now',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Empty state for offers
  // ---------------------------------------------------------------------------
  Widget _buildEmptyState({
    required IconData icon,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppColors.textHint.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
