import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/firestore_service.dart';

class WishlistProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<Product> _wishlist = [];
  List<Product> _originalWishlist = [];
  Set<String> _wishlistIds = {};

  // DEMO: remember old prices when we simulate a price drop
  final Map<String, double> _oldPrices = {};

  List<Product> get wishlist => _wishlist;

  bool isInWishlist(String productId) {
    return _wishlistIds.contains(productId);
  }

  void loadWishlist(String userId) {
    _firestoreService.getWishlist(userId).listen((products) {
      _originalWishlist = products;
      _wishlist = products;
      _wishlistIds =
          products.map((p) => p.link.hashCode.toString()).toSet();
      _oldPrices.clear();
      notifyListeners();
    });
  }

  Future<void> toggleWishlist(String userId, Product product) async {
    final productId = product.link.hashCode.toString();

    if (_wishlistIds.contains(productId)) {
      await _firestoreService.removeFromWishlist(userId, productId);
    } else {
      await _firestoreService.addToWishlist(userId, product);
    }
  }

  Future<void> updateNote(
      String userId, Product product, String note) async {
    final productId = product.link.hashCode.toString();
    await _firestoreService.updateWishlistNote(userId, productId, note);
  }

  Future<void> updateCategory(
      String userId, Product product, String? category) async {
    final productId = product.link.hashCode.toString();
    await _firestoreService.updateWishlistCategory(
        userId, productId, category);
  }

  // ---------- DEMO helpers for price drop ----------

  bool hasPriceDrop(String productId) {
    return _oldPrices.containsKey(productId);
  }

  double? getOldPrice(String productId) {
    return _oldPrices[productId];
  }

  /// DEMO ONLY:
  /// Artificially lower the price of all wishlist items that have a price,
  /// and remember the old price so we can show "price dropped" in the UI.
  ///
  /// Returns how many products were changed.
  Future<int> simulatePriceDropForAll() async {
    int changedCount = 0;

    final List<Product> updated = [];

    for (final p in _wishlist) {
      if (p.priceValue == null) {
        updated.add(p);
        continue;
      }

      final productId = p.link.hashCode.toString();

      // Save the old price
      _oldPrices[productId] = p.priceValue!;

      // New price: 20% cheaper
      final newPrice = (p.priceValue! * 0.8).roundToDouble();
      changedCount++;

      final newPriceString = '৳ ${newPrice.toStringAsFixed(0)}';

      updated.add(
        Product(
          title: p.title,
          link: p.link,
          price: newPriceString,
          source: p.source,
          thumbnail: p.thumbnail,
          snippet: p.snippet,
          priceValue: newPrice,
          note: p.note,
          category: p.category,
        ),
      );
    }

    _wishlist = updated;
    notifyListeners();
    return changedCount;
  }

  /// DEMO ONLY:
  /// Reset prices back to what came from Firestore (original wishlist),
  /// and clear simulated price drop info.
  void resetPriceDropSimulation() {
    _wishlist = List<Product>.from(_originalWishlist);
    _oldPrices.clear();
    notifyListeners();
  }
}