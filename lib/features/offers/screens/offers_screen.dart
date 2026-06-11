import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../data/models/product.dart';
import '../../../data/services/product_service.dart';
import '../../../providers/offer_provider.dart';
import '../../../shared/widgets/product_card_mini.dart';
import '../widgets/coupon_card.dart';

/// Offers page — shows ALL products that currently have an offer as a full
/// product grid (same card as the homepage grid), followed by any coupons.
/// The old promotional "Offers & Deals" cards + heading were removed in favour
/// of showing the actual discounted products.
class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  final ProductService _productService = ProductService();
  List<Product> _saleProducts = [];
  bool _loadingProducts = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Coupons still come from the offer provider.
      context.read<OfferProvider>().loadOffers();
      _loadSaleProducts();
    });
  }

  Future<void> _loadSaleProducts() async {
    try {
      // Includes products whose offer lives on a variant (e.g. vivo 7), not
      // just product-level discounts.
      final products = await _productService.getOfferProducts();
      if (mounted) {
        setState(() {
          _saleProducts = products;
          _loadingProducts = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingProducts = false);
    }
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
      body: _loadingProducts
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : CustomScrollView(
              slivers: [
                if (_saleProducts.isEmpty)
                  SliverToBoxAdapter(
                    child: _buildEmptyState(
                      icon: Icons.local_offer_outlined,
                      message: 'No products on offer right now',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.55,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => ProductCardMini(product: _saleProducts[i]),
                        childCount: _saleProducts.length,
                      ),
                    ),
                  ),

                // ---- Coupons (kept) ----
                SliverToBoxAdapter(child: _buildCoupons()),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
    );
  }

  Widget _buildCoupons() {
    return Consumer<OfferProvider>(
      builder: (context, offerProvider, _) {
        if (offerProvider.activeCoupons.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding, AppSpacing.lg, AppSpacing.pagePadding, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Coupons',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ...offerProvider.activeCoupons.map(
                (coupon) => CouponCard(coupon: coupon),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl * 2),
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
