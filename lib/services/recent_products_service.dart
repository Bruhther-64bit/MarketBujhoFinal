import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/product_model.dart';

class RecentProductsService {
  static const String _key = 'recent_products';
  static const int _maxItems = 10;

  /// Add a product to the recent list (most recent at top).
  Future<void> addProduct(Product product) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> stored = prefs.getStringList(_key) ?? [];

    // Decode existing entries and remove any with same link
    final List<Map<String, dynamic>> decoded = [];
    for (final s in stored) {
      try {
        final m = jsonDecode(s) as Map<String, dynamic>;
        if (m['link'] != product.link) {
          decoded.add(m);
        }
      } catch (_) {
        // ignore malformed
      }
    }

    // Insert new product at beginning
    decoded.insert(0, product.toMap());

    // Limit to max items
    if (decoded.length > _maxItems) {
      decoded.removeRange(_maxItems, decoded.length);
    }

    final List<String> toStore =
        decoded.map((m) => jsonEncode(m)).toList();
    await prefs.setStringList(_key, toStore);
  }

  /// Get recent products (most recent first).
  Future<List<Product>> getRecentProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> stored = prefs.getStringList(_key) ?? [];
    final List<Product> result = [];

    for (final s in stored) {
      try {
        final m = jsonDecode(s) as Map<String, dynamic>;
        result.add(Product.fromMap(m));
      } catch (_) {
        // ignore malformed entries
      }
    }

    return result;
  }

  /// Clear all recent products.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}