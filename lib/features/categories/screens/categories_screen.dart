import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/product_provider.dart';
import '../../../data/models/product.dart';
import '../../products/screens/product_detail_screen.dart';
import '../../../core/utils/currency_formatter.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 70,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Consumer<ProductProvider>(
          builder: (context, provider, _) => Text(
            provider.selectedCategory == 'All' ? 'Categories' : provider.selectedCategory,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.5,
              height: 1.0,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF1A1A1A)),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF1A1A1A)),
            onPressed: () {},
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, _) {
          return Row(
            children: [
              // Slim Sidebar - Flipkart style
              Container(
                width: 80,
                color: Colors.white,
                child: ListView.builder(
                  itemCount: productProvider.categories.length,
                  itemBuilder: (context, index) {
                    final category = productProvider.categories[index];
                    final isSelected = category == productProvider.selectedCategory;
                    return GestureDetector(
                      onTap: () => productProvider.setCategory(category),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFE3F2FD) : Colors.transparent,
                          border: Border(
                            left: BorderSide(
                              color: isSelected ? const Color(0xFF2874F0) : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? const Color(0xFF2874F0) : const Color(0xFF666666),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Divider
              Container(width: 1, color: Colors.grey.shade200),
              // Product Grid
              Expanded(
                child: productProvider.products.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                            SizedBox(height: 12),
                            Text('No products found', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          // Responsive columns
                          int crossAxisCount;
                          if (constraints.maxWidth > 800) {
                            crossAxisCount = 5;
                          } else if (constraints.maxWidth > 600) {
                            crossAxisCount = 4;
                          } else if (constraints.maxWidth > 400) {
                            crossAxisCount = 3;
                          } else {
                            crossAxisCount = 2;
                          }

                          return GridView.builder(
                            padding: const EdgeInsets.all(8),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              childAspectRatio: 0.58,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: productProvider.products.length,
                            itemBuilder: (context, index) {
                              final product = productProvider.products[index];
                              return _CompactProductCard(
                                product: product,
                                onTap: () => _openProductDetail(context, product),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openProductDetail(BuildContext context, Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: product.id)),
    );
  }
}

// Compact Product Card - Flipkart/Amazon style
class _CompactProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _CompactProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: Colors.grey.shade200, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image - compact
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                child: Image.network(
                  product.imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.phone_android,
                    size: 32,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            // Details - compact
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Product name
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF212121),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Rating
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF388E3C),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                product.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Icon(Icons.star, size: 8, color: Colors.white),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${_formatCount(product.reviewCount)})',
                          style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Price
                    Text(
                      CurrencyFormatter.format(product.price),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF212121),
                      ),
                    ),
                    if (product.hasDiscount)
                      Row(
                        children: [
                          Text(
                            CurrencyFormatter.format(product.originalPrice!),
                            style: TextStyle(
                              fontSize: 10,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${product.discountPercent}% off',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF388E3C),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}
