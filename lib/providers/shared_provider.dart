import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks the products the user has shared (to other apps/platforms as
/// suggestions). Surfaced as the "Shared" tab on the wishlist page.
///
/// This is a device-local list persisted with [SharedPreferences] — there's no
/// backend for it, since it's just a personal "things I recommended" collection.
class SharedProvider extends ChangeNotifier {
  static const _prefsKey = 'shared_product_ids';

  final List<String> _productIds = [];
  Set<String> _lookup = {};

  /// Most-recently-shared first.
  List<String> get productIds => List.unmodifiable(_productIds);
  int get count => _productIds.length;
  bool isShared(String productId) => _lookup.contains(productId);

  /// Load the persisted list. Call once at app start.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_prefsKey) ?? const [];
      _productIds
        ..clear()
        ..addAll(saved);
      _rebuild();
      notifyListeners();
    } catch (e) {
      debugPrint('SharedProvider.load: $e');
    }
  }

  /// Record a product as shared (no-op if already there). Newest first.
  Future<void> add(String productId) async {
    if (productId.isEmpty || _lookup.contains(productId)) return;
    _productIds.insert(0, productId);
    _rebuild();
    notifyListeners();
    await _persist();
  }

  Future<void> remove(String productId) async {
    if (!_lookup.contains(productId)) return;
    _productIds.remove(productId);
    _rebuild();
    notifyListeners();
    await _persist();
  }

  void _rebuild() => _lookup = _productIds.toSet();

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, _productIds);
    } catch (e) {
      debugPrint('SharedProvider._persist: $e');
    }
  }
}
