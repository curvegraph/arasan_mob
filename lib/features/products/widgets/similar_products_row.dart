import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/product.dart';
import '../../../shared/widgets/product_card_mini.dart';

/// Horizontal "You May Also Like" row -- filters similar products by brand or
/// category and renders them in a scrollable list using [ProductCardMini].
class SimilarProductsRow extends StatelessWidget {
  final Product currentProduct;
  final List<Product> allProducts;

  const SimilarProductsRow({
    super.key,
    required this.currentProduct,
    required this.allProducts,
  });

  List<Product> get _similarProducts {
    return allProducts
        .where((p) =>
            p.id != currentProduct.id &&
            p.isActive &&
            (p.brand == currentProduct.brand ||
                p.category == currentProduct.category))
        .take(8)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final products = _similarProducts;

    if (products.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.userPagePadding,
          ),
          child: Text(
            'YOU MAY ALSO LIKE',
            style: AppTextStyles.overline.copyWith(
              color: AppColors.smoke,
              letterSpacing: 2.0,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 290,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.userPagePadding,
            ),
            itemCount: products.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: AppSpacing.sm + 4),
            itemBuilder: (context, index) {
              return ProductCardMini(
                product: products[index],
                width: 170,
                staggerIndex: index,
              );
            },
          ),
        ),
      ],
    );
  }
}
