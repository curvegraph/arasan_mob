class WishlistItem {
  final String id;
  final String productId;
  final DateTime addedAt;
  final bool notifyWhenInStock;

  WishlistItem({
    required this.id,
    required this.productId,
    DateTime? addedAt,
    this.notifyWhenInStock = false,
  }) : addedAt = addedAt ?? DateTime.now();

  WishlistItem copyWith({
    bool? notifyWhenInStock,
  }) {
    return WishlistItem(
      id: id,
      productId: productId,
      addedAt: addedAt,
      notifyWhenInStock: notifyWhenInStock ?? this.notifyWhenInStock,
    );
  }
}
