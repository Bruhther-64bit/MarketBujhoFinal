import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

class SerpApiService {
  static const String _apiKey =
      '21004390151d5274b857b5d277c7995a1a7d96b5'; // Serper API key
  static const String _baseUrl = 'https://google.serper.dev/search';

  /// MAIN: Search products using Serper (Bangladesh-focused)
  Future<List<Product>> searchProducts(String query) async {
    try {
      print('🔍 [Serper] Searching for: $query in Bangladesh');

      final List<Product> allProducts = [];

      // Strategy 1: base query with "price in Bangladesh"
      final enhancedQuery = '$query price in Bangladesh';
      print('📍 [Serper] Strategy 1: $enhancedQuery');
      final s1 = await _searchOnce(enhancedQuery);
      allProducts.addAll(s1);
      print('🛍️ [Serper] Strategy 1 results: ${s1.length}');

      // Strategy 2: "buy {query} in Bangladesh" if few results
      if (allProducts.length < 10) {
        final buyQuery = 'buy $query in Bangladesh';
        print('📍 [Serper] Strategy 2: $buyQuery');
        final s2 = await _searchOnce(buyQuery);
        allProducts.addAll(s2);
        print('🛒 [Serper] Strategy 2 results: ${s2.length}');
      }

      // Strategy 3: specific BD e-commerce sites if still few results
      if (allProducts.length < 15) {
        print('📍 [Serper] Strategy 3: BD e-commerce sites');
        final s3 = await _searchBDSites(query);
        allProducts.addAll(s3);
        print('🏪 [Serper] Strategy 3 results: ${s3.length}');
      }

      // De-duplicate by link
      final uniqueProducts = <String, Product>{};
      for (var product in allProducts) {
        if (product.link.isNotEmpty) {
          uniqueProducts[product.link] = product;
        }
      }

      final finalList = uniqueProducts.values.toList();
      print('✅ [Serper] Total unique products: ${finalList.length}');
      return finalList;
    } catch (e) {
      print('❌ [Serper] Error searching products: $e');
      return [];
    }
  }

  /// Single Serper search call for a given query
  Future<List<Product>> _searchOnce(String query) async {
    try {
      final body = jsonEncode({
        'q': query,
        'gl': 'bd', // Bangladesh
        'hl': 'en',
        'type': 'search', // standard search
      });

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'X-API-KEY': _apiKey,
          'Content-Type': 'application/json',
        },
        body: body,
      );

      print('📡 [Serper] Request for "$query" → ${response.statusCode}');

      if (response.statusCode != 200) {
        print('❌ [Serper] Error body: ${response.body}');
        return [];
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      return _parseSearchResponse(data);
    } catch (e) {
      print('❌ [Serper] _searchOnce error: $e');
      return [];
    }
  }

  /// Search specific Bangladesh e-commerce sites
  Future<List<Product>> _searchBDSites(String query) async {
    final bdSites = [
      'daraz.com.bd',
      'startech.com.bd',
      'pickaboo.com',
      'ryans.com',
      'bikroy.com',
      'ajkerdeal.com',
      'rokomari.com',
      'gadgetnmusic.com',
      'gadgetandmusic.com',
      'sumashtech.com',
      'applegadgetsbd.com',
      'pchouse.com.bd',
      'penguin.com.bd',
    ];

    final allProducts = <Product>[];

    for (final site in bdSites) {
      final siteQuery = 'site:$site $query';
      print('🏪 [Serper] Searching on $site → "$siteQuery"');

      final products = await _searchOnce(siteQuery);
      if (products.isNotEmpty) {
        print('   Found ${products.length} products on $site');
        allProducts.addAll(products);
      }

      if (allProducts.length >= 20) {
        print('   Enough products found, stopping BD site search.');
        break;
      }
    }

    return allProducts;
  }

  Future<List<Product>> fetchTrendingProducts() async {
    try {
      print('🔥 [Serper] Fetching trending offers from BD sites...');

      // Generic query focused on deals/offers
      const trendingQuery = 'latest offers deals discounts';

      // This will run queries like `site:daraz.com.bd latest offers deals discounts`
      // for each BD site in _searchBDSites.
      final products = await _searchBDSites(trendingQuery);

      // De‑duplicate by link
      final unique = <String, Product>{};
      for (final p in products) {
        if (p.link.isNotEmpty) unique[p.link] = p;
      }

      final finalList = unique.values.toList();
      print('✅ [Serper] Trending offers: ${finalList.length} products');
      return finalList;
    } catch (e) {
      print('❌ [Serper] fetchTrendingProducts error: $e');
      return [];
    }
  }

  /// Parse Serper search response (organic + optional shopping)
  List<Product> _parseSearchResponse(Map<String, dynamic> data) {
    final products = <Product>[];

    // If your Serper plan includes shopping results, they might appear here
    if (data['shopping'] is List) {
      final shopping = data['shopping'] as List;
      print('🛍️ [Serper] Shopping results: ${shopping.length}');
      products.addAll(
        shopping
            .map((item) =>
                _parseShoppingItem(item as Map<String, dynamic>))
            .toList(),
      );
    }

    if (data['organic'] is List) {
      final organic = data['organic'] as List;
      print('📄 [Serper] Organic results: ${organic.length}');
      products.addAll(
        organic
            .map((item) => _parseOrganicItem(item as Map<String, dynamic>))
            .where((p) => p.link.isNotEmpty)
            .toList(),
      );
    }

    return products;
  }

  // ---------- Autocomplete (Serper) ----------

  Future<List<String>> getAutocompleteSuggestions(String query) async {
    if (query.trim().isEmpty || query.length < 2) return [];

    try {
      print('💡 [Serper] Autocomplete for: $query');

      final body = jsonEncode({
        'q': query,
        'gl': 'bd',
        'hl': 'en',
        'type': 'autocomplete', // Serper autocomplete mode
      });

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'X-API-KEY': _apiKey,
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode != 200) {
        print('❌ [Serper] Autocomplete error: ${response.body}');
        return [];
      }

      final data = json.decode(response.body) as Map<String, dynamic>;

      // Adjust based on your actual autocomplete response from Serper
      if (data['suggestions'] is List) {
  final raw = data['suggestions'] as List;

  final suggestions = raw.map((s) {
    // Serper suggestions look like: { "value": "realme buds", ... }
    if (s is Map && s['value'] != null) {
      return s['value'].toString();
    }
    // Fallback if it's already a string or some other type
    return s.toString();
  }).toList();

  print('💡 [Serper] Found ${suggestions.length} suggestions');
  return suggestions.take(5).toList();
}

      // Sometimes Serper may return 'organic' or 'relatedSearches' for autocomplete;
      // if needed, we can adapt once you share that JSON.
      return [];
    } catch (e) {
      print('❌ [Serper] getAutocompleteSuggestions error: $e');
      return [];
    }
  }

  // ---------- Parsing helpers ----------

  /// For Serper "shopping" results (if available in your plan)
  Product _parseShoppingItem(Map<String, dynamic> item) {
    // These field names are based on typical Serper shopping results;
    // adjust if your JSON differs.
    final title = item['title']?.toString() ?? 'No title';
    final link = item['link']?.toString() ?? '';

    double? priceValue;
    String? priceText;

    if (item['price'] != null) {
      final num priceNum = item['price'] as num;
      priceValue = priceNum.toDouble();
      final currency = item['currency']?.toString() ?? 'BDT';

      if (currency.toUpperCase() == 'BDT') {
        priceText = '৳ ${priceNum.toString()}';
      } else {
        priceText = '$currency ${priceNum.toString()}';
      }
    }

    return Product(
      title: title,
      link: link,
      price: priceText,
      source: item['source']?.toString() ??
          item['seller']?.toString() ??
          _extractDomain(link),
      thumbnail: item['thumbnail']?.toString() ??
          item['imageUrl']?.toString() ??
          item['image']?.toString(),
      snippet: item['snippet']?.toString() ??
          item['description']?.toString(),
      priceValue: priceValue,
    );
  }

  /// For Serper "organic" results (matches your sample JSON)
  Product _parseOrganicItem(Map<String, dynamic> item) {
    final title = item['title']?.toString() ?? 'No title';
    final link = item['link']?.toString() ?? '';
    final snippet = item['snippet']?.toString() ?? '';

    String? priceText;
    double? priceValue;

    if (item['price'] != null) {
      final num priceNum = item['price'] as num;
      priceValue = priceNum.toDouble();

      final currency = item['currency']?.toString() ?? 'BDT';
      if (currency.toUpperCase() == 'BDT') {
        priceText = '৳ ${priceNum.toString()}';
      } else {
        priceText = '$currency ${priceNum.toString()}';
      }
    } else {
      // Fallback: extract price from snippet text (৳, Tk, BDT, etc.)
      priceText = _extractPrice(snippet);
      priceValue = _extractPriceValue(snippet);
    }

    final thumbnail = item['imageUrl'] ??
      item['thumbnailUrl'] ??
      item['thumbnail'] ??
      item['image'];

  return Product(
    title: title,
    link: link,
    price: priceText,
    source: _extractDomain(link),
    thumbnail: thumbnail?.toString(),
    snippet: snippet,
    priceValue: priceValue,
  );
}

  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.replaceAll('www.', '');
    } catch (_) {
      return '';
    }
  }

  // ---------- BD-specific price parsing (same logic as before) ----------

  String? _extractPrice(String text) {
    final patterns = [
      RegExp(r'৳\s*[\d,]+(?:\.\d{2})?'),
      RegExp(r'Tk\.?\s*[\d,]+(?:\.\d{2})?'),
      RegExp(r'BDT\s*[\d,]+(?:\.\d{2})?'),
      RegExp(r'[\d,]+(?:\.\d{2})?\s*৳'),
      RegExp(r'[\d,]+(?:\.\d{2})?\s*Tk'),
      RegExp(r'[\d,]+(?:\.\d{2})?\s*Taka'),
      RegExp(r'Price:\s*৳?\s*[\d,]+'),
      RegExp(r'Price:\s*Tk\.?\s*[\d,]+'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(0)!.trim();
      }
    }

    return null;
  }

  double? _extractPriceValue(String text) {
    final priceStr = _extractPrice(text);
    if (priceStr == null) return null;

    final numStr = priceStr.replaceAll(RegExp(r'[^\d.]'), '');
    if (numStr.isEmpty) return null;

    return double.tryParse(numStr);
  }
}

  /// Fetch "trending" offers from major BD e‑commerce sites.
  ///
  /// This reuses the existing _searchBDSites() helper, but with a generic
  /// "offers/deals/discounts" query so we get latest promo pages.
  