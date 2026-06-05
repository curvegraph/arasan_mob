import 'product.dart';

class CartItem {
  final String id;
  final Product product;
  final int quantity;
  final bool isSavedForLater;

  CartItem({
    required this.id,
    required this.product,
    this.quantity = 1,
    this.isSavedForLater = false,
  });

  CartItem copyWith({
    int? quantity,
    bool? isSavedForLater,
  }) {
    return CartItem(
      id: id,
      product: product,
      quantity: quantity ?? this.quantity,
      isSavedForLater: isSavedForLater ?? this.isSavedForLater,
    );
  }

  double get totalPrice => product.effectivePrice * quantity;
  double get totalOriginalPrice => product.price * quantity;
  double get savings => totalOriginalPrice - totalPrice;
}

class Cart {
  final List<CartItem> items;
  final String? appliedCouponCode;
  final double couponDiscount;

  Cart({
    this.items = const [],
    this.appliedCouponCode,
    this.couponDiscount = 0,
  });

  List<CartItem> get activeItems =>
      items.where((i) => !i.isSavedForLater).toList();

  List<CartItem> get savedItems =>
      items.where((i) => i.isSavedForLater).toList();

  int get itemCount =>
      activeItems.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      activeItems.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get totalOriginalPrice =>
      activeItems.fold(0.0, (sum, item) => sum + item.totalOriginalPrice);

  double get productDiscount => totalOriginalPrice - subtotal;

  /// Delivery is configured per-store. The UI/checkout layer reads the rule
  /// from [StoreSettingsProvider.deliveryChargeFor] and passes the result
  /// into [totalAmountWithDelivery] / [totalAmountWith]. Returning 0 here
  /// keeps the model self-consistent for callers that don't have access to
  /// the provider.
  double get deliveryCharge => 0;

  /// Apply an admin-configured delivery rule to this cart's subtotal.
  double deliveryChargeFor(double base, double freeAbove) {
    if (freeAbove > 0 && subtotal >= freeAbove) return 0;
    return base;
  }

  /// Tax is configured per-store — the UI layer computes it from
  /// [StoreSettingsProvider.taxFor] and passes it into [totalAmountWith].
  /// Kept as a getter returning 0 for callers that haven't migrated yet.
  double get taxAmount => 0;

  /// Total excluding tax & delivery. Prefer [totalAmountWith].
  double get totalAmountBeforeTax => subtotal - couponDiscount;

  double totalAmountWith(double tax, {double delivery = 0}) =>
      totalAmountBeforeTax + tax + delivery;

  /// Legacy getter — subtotal minus coupon, no tax, no delivery.
  double get totalAmount => totalAmountBeforeTax;

  double get totalSavings => productDiscount + couponDiscount;

  bool get isEmpty => activeItems.isEmpty;
}
