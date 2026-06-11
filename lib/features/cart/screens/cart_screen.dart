import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/cart.dart';
import '../../../data/models/product.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/store_settings_provider.dart';
import '../../../providers/wishlist_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/image_placeholder.dart';
import '../../auth/screens/login_dialog.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Re-fetch settings on every cart visit so admin toggles (tax, delivery,
    // payment methods) take effect immediately instead of waiting for the
    // 60s background poll. Fired once per build via post-frame callback.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoreSettingsProvider>().loadSettings(force: true);
    });
    final cartProvider = context.watch<CartProvider>();
    final cart = cartProvider.cart;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 860;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      body: cart.isEmpty
          ? _buildEmptyCart(context)
          : isWide
              ? _buildWideLayout(context, cart, cartProvider)
              : _buildNarrowLayout(context, cart, cartProvider),
      bottomNavigationBar:
          (cart.isEmpty || isWide) ? null : _buildCartBottomBar(context, cart),
    );
  }

  /// Sticky bottom bar (Flipkart-style): savings note + struck total + payable
  /// + Place Order. Delivery/tax are applied on the checkout page.
  Widget _buildCartBottomBar(BuildContext context, Cart cart) {
    final original = cart.totalOriginalPrice;
    final payable = cart.totalAmountBeforeTax;
    final savings = cart.totalSavings;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (savings > 0)
              Container(
                width: double.infinity,
                color: const Color(0xFFE8F8EE),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.savings_outlined,
                        size: 16, color: Color(0xFF16A34A)),
                    const SizedBox(width: 6),
                    Text(
                      "You'll save ${CurrencyFormatter.format(savings)} on this order!",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (savings > 0)
                        Text(
                          CurrencyFormatter.format(original),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF94A3B8),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      Text(
                        CurrencyFormatter.format(payable),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A1A1A),
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => context.push('/shop/checkout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    child: const Text('Place Order'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1400E0).withValues(alpha: 0.10),
                  ),
                ),
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1400E0), Color(0xFF2962FF)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x4D1400E0),
                        blurRadius: 24,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A1A1A),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Browse the catalog and add items you like — they\'ll show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/shop'),
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('Start shopping'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1400E0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                elevation: 4,
                shadowColor: const Color(0x4D1400E0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context, Cart cart, CartProvider cartProvider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    // Breadcrumb
                    _buildBreadcrumb(context),
                    // Title
                    Padding(
                      padding: const EdgeInsets.fromLTRB(40, 20, 40, 0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Your Cart',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF1A1A1A),
                            letterSpacing: -0.7,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: cart.activeItems
                                  .map((item) => _CartItemCard(item: item, cartProvider: cartProvider))
                                  .toList(),
                            ),
                          ),
                          const SizedBox(width: 28),
                          SizedBox(
                            width: 340,
                            child: _OrderSummaryCard(cart: cart),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNarrowLayout(BuildContext context, Cart cart, CartProvider cartProvider) {
    return ListView(
      children: [
        _buildBreadcrumb(context),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR SELECTION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text(
                    'Shopping Cart',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: -0.6,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '· ${cart.itemCount} item${cart.itemCount == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ...cart.activeItems.map((item) => _CartItemCard(item: item, cartProvider: cartProvider)),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBreadcrumb(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: AppColors.primary,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/shop'),
            child: const Text('Home', style: TextStyle(fontSize: 13, color: Colors.white70)),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Icon(Icons.chevron_right, size: 16, color: Colors.white54),
          ),
          const Text('Cart', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
          const Spacer(),
          GestureDetector(
            onTap: () => context.go('/shop'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white54),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text('Continue Shopping', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}

/// Reached from "Buy Now" — a SINGLE-product order summary (image #14). The
/// product is passed directly and is NOT added to the cart (standard Flipkart
/// flow); it only enters the cart when the user hits Secure Checkout.
class OrderSummaryScreen extends StatefulWidget {
  final Product product;
  const OrderSummaryScreen({super.key, required this.product});

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final unit = p.effectivePrice;
    final original = p.price;
    final discount = p.discountPercent.toInt();
    final subtotal = unit * _qty;
    final saved = (original - unit) * _qty;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      body: ListView(
        // Add the status-bar inset to the top padding so the "Order Summary"
        // heading sits below the notch (this page has no app bar, and the
        // global header is suppressed on non-browsing pages).
        padding: EdgeInsets.fromLTRB(
            16, MediaQuery.paddingOf(context).top + 16, 16, 28),
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('YOUR SELECTION',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                          letterSpacing: 1.0)),
                  const SizedBox(height: 2),
                  const Text('Order Summary',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: -0.6,
                          height: 1.0)),
                ],
              ),
              if (saved > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F8EE),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text("You're saving ${CurrencyFormatter.format(saved)}",
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF16A34A))),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Product card
          Container(
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ImagePlaceholder(
                        imageUrl: p.imageUrl,
                        width: 96,
                        height: 96,
                        icon: Icons.phone_android,
                      ),
                    ),
                    if (discount > 0)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6)),
                          child: Text('$discount% OFF',
                              style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1A1A))),
                      if ((p.variantLabel ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8)),
                          child: Text(p.variantLabel!,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF475569))),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(CurrencyFormatter.format(unit),
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1A1A1A))),
                          if (discount > 0) ...[
                            const SizedBox(width: 8),
                            Text(CurrencyFormatter.format(original),
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF94A3B8),
                                    decoration: TextDecoration.lineThrough)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Quantity stepper
                      Container(
                        decoration: BoxDecoration(
                            border:
                                Border.all(color: const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _qtyBtn(Icons.remove,
                                _qty > 1 ? () => setState(() => _qty--) : null),
                            SizedBox(
                                width: 36,
                                child: Center(
                                    child: Text('$_qty',
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900)))),
                            _qtyBtn(Icons.add, () => setState(() => _qty++)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Order Summary box
          Container(
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('ORDER SUMMARY',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: 0.3)),
                ),
                const SizedBox(height: 16),
                _sumRow('Subtotal', CurrencyFormatter.format(subtotal)),
                if (saved > 0) ...[
                  const SizedBox(height: 10),
                  _sumRow('Discount', '- ${CurrencyFormatter.format(saved)}',
                      valueColor: const Color(0xFF16A34A)),
                ],
                const SizedBox(height: 10),
                _sumRow('Delivery', 'At checkout'),
                const SizedBox(height: 14),
                Container(height: 1, color: const Color(0xFFE2E8F0)),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Payable',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B))),
                    Text(CurrencyFormatter.format(subtotal),
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Only now does it enter the cart, then on to checkout.
                      context.read<CartProvider>().addToCart(p, quantity: _qty);
                      context.push('/shop/checkout');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline, size: 16),
                        SizedBox(width: 8),
                        Text('Secure Checkout',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w900)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_user_outlined,
                        size: 13, color: Color(0xFF64748B)),
                    SizedBox(width: 5),
                    Text('100% safe & encrypted payment',
                        style:
                            TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Text('← Continue shopping',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sumRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: valueColor ?? const Color(0xFF1E293B))),
      ],
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon,
            size: 16,
            color: onTap == null
                ? const Color(0xFFCBD5E1)
                : const Color(0xFF1A1A1A)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Cart Item Card — Premium design
// ═══════════════════════════════════════════════════════════════════════════
class _CartItemCard extends StatefulWidget {
  final CartItem item;
  final CartProvider cartProvider;
  const _CartItemCard({required this.item, required this.cartProvider});

  @override
  State<_CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends State<_CartItemCard> {
  bool _hovered = false;

  void _moveToWishlist(BuildContext context) {
    final item = widget.item;
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      LoginDialog.showWithMessage(context, 'Please login to use wishlist');
      return;
    }
    context.read<WishlistProvider>().toggleWishlist(item.product.id);
    widget.cartProvider.removeFromCart(item.id);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${item.product.name} moved to wishlist'),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  void _removeItem(BuildContext context) {
    final item = widget.item;
    widget.cartProvider.removeFromCart(item.id);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${item.product.name} removed'),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () => widget.cartProvider.addToCart(item.product, quantity: item.quantity),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final cartProvider = widget.cartProvider;
    final isCompact = MediaQuery.sizeOf(context).width < 600;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered ? AppColors.primary.withValues(alpha: 0.4) : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: _hovered ? 20 : 10,
              offset: Offset(0, _hovered ? 8 : 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(isCompact ? 12 : 20),
                child: isCompact
                    ? _buildMobileLayout(context, item, cartProvider)
                    : _buildDesktopLayout(context, item, cartProvider),
              ),
              // Bottom accent bar
              Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Mobile: vertical stack ──
  Widget _buildMobileLayout(BuildContext context, CartItem item, CartProvider cartProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image + basic info row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProductImage(imageUrl: item.product.imageUrls.isNotEmpty ? item.product.imageUrls.first : null, size: 130),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.product.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _BrandChip(brand: item.product.brand),
                      if (item.product.hasDiscount) ...[
                        const SizedBox(width: 6),
                        Text('${item.product.discountPercent.toInt()}% off',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF16A34A))),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(CurrencyFormatter.format(item.totalPrice),
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ],
                  ),
                  if (item.product.offerPrice != null)
                    Text(CurrencyFormatter.format(item.totalOriginalPrice),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), decoration: TextDecoration.lineThrough)),
                ],
              ),
            ),
          ],
        ),
        // Key specs from admin data
        if (item.product.specs.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: item.product.specs.entries.take(3).map((e) =>
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${e.key}: ',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                        TextSpan(
                          text: e.value,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B), fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ).toList(),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              _InfoTag(
                icon: item.product.isOutOfStock ? Icons.error_outline : Icons.check_circle,
                text: item.product.isOutOfStock ? 'Out of Stock' : item.product.isLowStock ? 'Only ${item.product.stock} left' : 'In Stock',
                iconColor: item.product.isOutOfStock ? const Color(0xFFEF4444) : item.product.isLowStock ? const Color(0xFFF59E0B) : const Color(0xFF16A34A),
              ),
              if (item.savings > 0) ...[
                const SizedBox(width: 12),
                _InfoTag(icon: Icons.savings_outlined, text: 'Save ${CurrencyFormatter.format(item.savings)}', iconColor: const Color(0xFF16A34A)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 6),
        // Quantity + actions row
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Text('Qty', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  const SizedBox(width: 6),
                  _QuantityDropdown(quantity: item.quantity, onChanged: (qty) => cartProvider.updateQuantity(item.id, qty)),
                ],
              ),
            ),
            const Spacer(),
            _ActionChip(icon: Icons.favorite_border, label: 'Wishlist', color: AppColors.primary, onTap: () => _moveToWishlist(context)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _removeItem(context),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Desktop: horizontal layout ──
  Widget _buildDesktopLayout(BuildContext context, CartItem item, CartProvider cartProvider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProductImage(imageUrl: item.product.imageUrls.isNotEmpty ? item.product.imageUrls.first : null, size: 220),
        const SizedBox(width: 24),
        Expanded(
          child: SizedBox(
            height: 230,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(item.product.name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1E293B), height: 1.3),
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(CurrencyFormatter.format(item.totalPrice),
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
                            if (item.product.offerPrice != null)
                              Text(CurrencyFormatter.format(item.totalOriginalPrice),
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8), decoration: TextDecoration.lineThrough)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _BrandChip(brand: item.product.brand),
                        if (item.product.hasDiscount) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${item.product.discountPercent.toInt()}% off',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF16A34A)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                // Key specs from admin data
                if (item.product.specs.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Wrap(
                      spacing: 14,
                      runSpacing: 8,
                      children: item.product.specs.entries.take(5).map((e) =>
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${e.key}: ',
                                  style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                ),
                                TextSpan(
                                  text: e.value,
                                  style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B), fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ).toList(),
                    ),
                  ),
                // Stock & savings info
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      Icon(
                        item.product.isOutOfStock ? Icons.error_outline : Icons.check_circle,
                        size: 16,
                        color: item.product.isOutOfStock
                            ? const Color(0xFFEF4444)
                            : item.product.isLowStock
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFF16A34A),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        item.product.isOutOfStock
                            ? 'Out of Stock'
                            : item.product.isLowStock
                                ? 'Only ${item.product.stock} left'
                                : 'In Stock',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: item.product.isOutOfStock
                              ? const Color(0xFFEF4444)
                              : item.product.isLowStock
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFF16A34A),
                        ),
                      ),
                      if (item.savings > 0) ...[
                        const SizedBox(width: 20),
                        Icon(Icons.savings_outlined, size: 16, color: const Color(0xFF16A34A)),
                        const SizedBox(width: 5),
                        Text(
                          'You save ${CurrencyFormatter.format(item.savings)}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
                        ),
                      ],
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Text('Qty', style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                          const SizedBox(width: 8),
                          _QuantityDropdown(quantity: item.quantity, onChanged: (qty) => cartProvider.updateQuantity(item.id, qty)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    _ActionChip(icon: Icons.favorite_border, label: 'Wishlist', color: AppColors.primary, onTap: () => _moveToWishlist(context)),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _removeItem(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Product Image with gradient background
// ═══════════════════════════════════════════════════════════════════════════
class _ProductImage extends StatelessWidget {
  final String? imageUrl;
  final double size;
  const _ProductImage({required this.imageUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size * 1.1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.04),
            const Color(0xFFF5F7FF),
            const Color(0xFFEEF0F8),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ImagePlaceholder(
          imageUrl: imageUrl,
          width: size,
          height: size * 1.1,
          icon: Icons.phone_android,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Brand Chip
// ═══════════════════════════════════════════════════════════════════════════
class _BrandChip extends StatelessWidget {
  final String brand;
  const _BrandChip({required this.brand});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        brand,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B), letterSpacing: 0.3),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Action Chip — Wishlist / Remove
// ═══════════════════════════════════════════════════════════════════════════
class _ActionChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  State<_ActionChip> createState() => _ActionChipState();
}

class _ActionChipState extends State<_ActionChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _hovered ? widget.color.withValues(alpha: 0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _hovered ? widget.color.withValues(alpha: 0.3) : const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 15, color: widget.color),
              const SizedBox(width: 5),
              Text(widget.label,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: widget.color)),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Quantity Selector — +/- buttons
// ═══════════════════════════════════════════════════════════════════════════
class _QuantityDropdown extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onChanged;
  const _QuantityDropdown({required this.quantity, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _qtyBtn(Icons.remove, () { if (quantity > 1) onChanged(quantity - 1); }, quantity <= 1),
          Container(
            constraints: const BoxConstraints(minWidth: 36),
            alignment: Alignment.center,
            child: Text('$quantity', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
          ),
          _qtyBtn(Icons.add, () { if (quantity < 10) onChanged(quantity + 1); }, quantity >= 10),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap, bool disabled) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 16, color: disabled ? const Color(0xFFCBD5E1) : const Color(0xFF1E293B)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Order Summary Card — Premium
// ═══════════════════════════════════════════════════════════════════════════
class _OrderSummaryCard extends StatelessWidget {
  final Cart cart;
  const _OrderSummaryCard({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.06),
                  AppColors.primary.withValues(alpha: 0.02),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.receipt_long, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                const Text('Order Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: -0.4,
                      height: 1.0,
                    )),
              ],
            ),
          ),

          // Price rows
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _row('Subtotal', CurrencyFormatter.format(cart.subtotal)),
                if (cart.productDiscount > 0) ...[
                  const SizedBox(height: 10),
                  _row('Discount', '- ${CurrencyFormatter.format(cart.productDiscount)}',
                      valueColor: const Color(0xFF10B981)),
                ],
                const SizedBox(height: 10),
                // Delivery & tax are applied on the checkout page (admin rules).
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Delivery',
                        style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                    Text('At checkout',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B))),
                  ],
                ),
                const SizedBox(height: 14),
                Container(height: 1, color: const Color(0xFFE2E8F0)),
                const SizedBox(height: 14),

                // Total Payable (excludes delivery/tax — added at checkout)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Payable',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                    Text(
                        CurrencyFormatter.format(cart.totalAmountBeforeTax),
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  ],
                ),

                if (cart.totalSavings > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        const Color(0xFF10B981).withValues(alpha: 0.08),
                        const Color(0xFF10B981).withValues(alpha: 0.04),
                      ]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.savings_outlined, size: 15, color: Color(0xFF10B981)),
                        const SizedBox(width: 6),
                        Text('You save ${CurrencyFormatter.format(cart.totalSavings)}!',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF10B981))),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 18),

                // Secure Checkout button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.push('/shop/checkout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline, size: 16),
                        SizedBox(width: 8),
                        Text('Secure Checkout',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.3)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_user_outlined, size: 13, color: Color(0xFF64748B)),
                    SizedBox(width: 5),
                    Text('100% safe & encrypted payment',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
        Text(value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor ?? const Color(0xFF334155))),
      ],
    );
  }
}

/// Small info tag with icon + text — shows dynamic product data
class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? iconColor;
  final bool compact;

  const _InfoTag({
    required this.icon,
    required this.text,
    this.iconColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: compact ? 13 : 14, color: iconColor ?? const Color(0xFF94A3B8)),
        SizedBox(width: compact ? 3 : 5),
        Text(
          text,
          style: TextStyle(
            fontSize: compact ? 11 : 12,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
