import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

import '../models/product_model.dart';

class OfferScraperService {
  static const String _startechOfferUrl =
      'https://www.startech.com.bd/information/offer';
  static const String _techlandOfferUrl =
      'https://www.techlandbd.com/offers';
  static const String _appleGadgetsOfferUrl =
      'https://www.applegadgetsbd.com/offer';
  static const String _ryansOfferUrl =
      'https://www.ryans.com/offers';
  static const String _sumashtechOfferUrl =
      'https://www.sumashtech.com/offer';

  // ----------------- Startech -----------------

  Future<List<Product>> fetchStartechOffers() async {
    try {
      print('🔥 [Scraper] Startech offers → $_startechOfferUrl');
      final response = await http.get(Uri.parse(_startechOfferUrl));

      if (response.statusCode != 200) {
        print('❌ [Scraper] Startech HTTP ${response.statusCode}');
        return [];
      }

      final document = html_parser.parse(response.body);
      final offerCards = document.querySelectorAll('.offer-page .offer');

      print('📦 [Scraper] Startech cards: ${offerCards.length}');

      final products = <Product>[];

      for (final card in offerCards) {
        final imgEl = card.querySelector('.offer-content > a > img');
        final titleEl = card.querySelector('.details h4.title');
        dom.Element? linkEl =
            card.querySelector('.details a.view-details') ??
                card.querySelector('.offer-content > a');

        if (titleEl == null || linkEl == null) continue;

        final rawLink = linkEl.attributes['href'] ?? '';
        final link = _normalizeStartechUrl(rawLink);

        final imageUrl = imgEl?.attributes['src'] ??
            imgEl?.attributes['data-src'] ??
            '';

        final descEl = card.querySelector('.details p.short-desc');
        final desc = descEl?.text.trim() ?? '';

        final title = titleEl.text.trim();

        products.add(
          Product(
            title: title,
            link: link,
            price: null,
            source: 'startech.com.bd',
            thumbnail: imageUrl.isNotEmpty ? imageUrl : null,
            snippet: desc.isNotEmpty ? desc : 'Special offer on Startech',
            priceValue: null,
            note: null,
          ),
        );
      }

      print('✅ [Scraper] Startech products: ${products.length}');
      return products;
    } catch (e) {
      print('❌ [Scraper] Startech error: $e');
      return [];
    }
  }

  String _normalizeStartechUrl(String raw) {
    if (raw.startsWith('http')) return raw;
    if (raw.startsWith('/')) {
      return 'https://www.startech.com.bd$raw';
    }
    return 'https://www.startech.com.bd/$raw';
  }

  // ----------------- Techland -----------------

  Future<List<Product>> fetchTechlandOffers() async {
    try {
      print('🔥 [Scraper] Techland offers → $_techlandOfferUrl');
      final response = await http.get(Uri.parse(_techlandOfferUrl));

      if (response.statusCode != 200) {
        print('❌ [Scraper] Techland HTTP ${response.statusCode}');
        return [];
      }

      final document = html_parser.parse(response.body);
      // Each card: <div class="group cursor-pointer" onclick="window.location.href='...'>
      final cards = document.querySelectorAll('.group.cursor-pointer');

      print('📦 [Scraper] Techland cards: ${cards.length}');

      final products = <Product>[];

      for (final card in cards) {
        final imgEl = card.querySelector('img');
        final onclick = card.attributes['onclick'] ?? '';

        final link = _extractTechlandLink(onclick);
        if (link == null) continue;

        final imageUrl = imgEl?.attributes['src'] ?? '';
        final alt = imgEl?.attributes['alt']?.trim() ?? '';

        final title = alt.isNotEmpty ? alt : 'Techland Offer';

        products.add(
          Product(
            title: title,
            link: link,
            price: null,
            source: 'techlandbd.com',
            thumbnail: imageUrl.isNotEmpty ? imageUrl : null,
            snippet: 'Special offer on Techland',
            priceValue: null,
            note: null,
          ),
        );
      }

      print('✅ [Scraper] Techland products: ${products.length}');
      return products;
    } catch (e) {
      print('❌ [Scraper] Techland error: $e');
      return [];
    }
  }

  String? _extractTechlandLink(String onclick) {
    final match =
        RegExp(r"window\.location\.href='([^']+)'").firstMatch(onclick);
    if (match != null && match.groupCount >= 1) {
      return _normalizeTechlandUrl(match.group(1)!);
    }
    return null;
  }

  String _normalizeTechlandUrl(String raw) {
    if (raw.startsWith('http')) return raw;
    if (raw.startsWith('/')) {
      return 'https://www.techlandbd.com$raw';
    }
    return 'https://www.techlandbd.com/$raw';
  }

  // ----------------- Apple Gadgets -----------------

  Future<List<Product>> fetchAppleGadgetsOffers() async {
    try {
      print('🔥 [Scraper] Apple Gadgets offers → $_appleGadgetsOfferUrl');
      final response = await http.get(Uri.parse(_appleGadgetsOfferUrl));

      if (response.statusCode != 200) {
        print('❌ [Scraper] Apple Gadgets HTTP ${response.statusCode}');
        return [];
      }

      final document = html_parser.parse(response.body);
      // Each banner offer is in a <figure> that has an <a href="/offer/...">
      final figures = document.querySelectorAll('figure');

      print('📦 [Scraper] Apple Gadgets figures: ${figures.length}');

      final products = <Product>[];

      for (final fig in figures) {
        final linkEl = fig.querySelector('a[href^="/offer/"]');
        final imgEl = fig.querySelector('img');

        if (linkEl == null || imgEl == null) continue;

        final rawLink = linkEl.attributes['href'] ?? '';
        final link = _normalizeAppleGadgetsUrl(rawLink);

        final src = imgEl.attributes['src'] ?? '';
        final imageUrl = _normalizeAppleGadgetsImageUrl(src);

        final alt = imgEl.attributes['alt']?.trim() ?? '';
        final title =
            alt.isNotEmpty ? alt : 'Apple Gadgets Offer';

        products.add(
          Product(
            title: title,
            link: link,
            price: null,
            source: 'applegadgetsbd.com',
            thumbnail: imageUrl.isNotEmpty ? imageUrl : null,
            snippet: 'Offer from Apple Gadgets BD',
            priceValue: null,
            note: null,
          ),
        );
      }

      print('✅ [Scraper] Apple Gadgets products: ${products.length}');
      return products;
    } catch (e) {
      print('❌ [Scraper] Apple Gadgets error: $e');
      return [];
    }
  }

  String _normalizeAppleGadgetsUrl(String raw) {
    if (raw.startsWith('http')) return raw;
    if (raw.startsWith('/')) {
      return 'https://www.applegadgetsbd.com$raw';
    }
    return 'https://www.applegadgetsbd.com/$raw';
  }

  String _normalizeAppleGadgetsImageUrl(String raw) {
    if (raw.startsWith('http')) return raw;
    if (raw.startsWith('/')) {
      return 'https://www.applegadgetsbd.com$raw';
    }
    return raw;
  }

  // ----------------- Ryans -----------------

  Future<List<Product>> fetchRyansOffers() async {
    try {
      print('🔥 [Scraper] Ryans offers → $_ryansOfferUrl');
      final response = await http.get(Uri.parse(_ryansOfferUrl));

      if (response.statusCode != 200) {
        print('❌ [Scraper] Ryans HTTP ${response.statusCode}');
        return [];
      }

      final document = html_parser.parse(response.body);
      // Each: <div class="col-lg-6 col-12 offers"><a href="..."><img ...></a></div>
      final cards = document.querySelectorAll('.offers');

      print('📦 [Scraper] Ryans cards: ${cards.length}');

      final products = <Product>[];

      for (final card in cards) {
        final linkEl = card.querySelector('a[href]');
        final imgEl = card.querySelector('img');

        if (linkEl == null || imgEl == null) continue;

        final rawLink = linkEl.attributes['href'] ?? '';
        final link = _normalizeRyansUrl(rawLink);

        final imageUrl = imgEl.attributes['src'] ?? '';

        final title = _titleFromSlug(rawLink);

        products.add(
          Product(
            title: title,
            link: link,
            price: null,
            source: 'ryans.com',
            thumbnail: imageUrl.isNotEmpty ? imageUrl : null,
            snippet: 'Offer from Ryans',
            priceValue: null,
            note: null,
          ),
        );
      }

      print('✅ [Scraper] Ryans products: ${products.length}');
      return products;
    } catch (e) {
      print('❌ [Scraper] Ryans error: $e');
      return [];
    }
  }

  String _normalizeRyansUrl(String raw) {
    if (raw.startsWith('http')) return raw;
    if (raw.startsWith('/')) {
      return 'https://www.ryans.com$raw';
    }
    return 'https://www.ryans.com/$raw';
  }

  String _titleFromSlug(String href) {
    try {
      final uri = Uri.parse(_normalizeRyansUrl(href));
      final segments = uri.pathSegments;
      if (segments.isEmpty) return 'Ryans Offer';
      final slug =
          segments.lastWhere((s) => s.isNotEmpty, orElse: () => '');
      if (slug.isEmpty) return 'Ryans Offer';
      final words =
          slug.replaceAll(RegExp(r'[-_]'), ' ').split(' ');
      return words
          .map((w) =>
              w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
          .join(' ');
    } catch (_) {
      return 'Ryans Offer';
    }
  }

  // ----------------- Sumashtech -----------------

  Future<List<Product>> fetchSumashtechOffers() async {
    try {
      print('🔥 [Scraper] Sumashtech offers → $_sumashtechOfferUrl');
      final response = await http.get(Uri.parse(_sumashtechOfferUrl));

      if (response.statusCode != 200) {
        print('❌ [Scraper] Sumashtech HTTP ${response.statusCode}');
        return [];
      }

      final document = html_parser.parse(response.body);
      // Each: <div class="offer-box"> ... </div>
      final cards = document.querySelectorAll('.offer-box');

      print('📦 [Scraper] Sumashtech cards: ${cards.length}');

      final products = <Product>[];

      for (final card in cards) {
        final imgEl =
            card.querySelector('.offer-image img') ??
                card.querySelector('img');
        final titleEl = card.querySelector(
                '.offer-content h4.title a') ??
            card.querySelector('.offer-content h4.title');
        dom.Element? linkEl =
            card.querySelector('.offer-content a.view-details') ??
                card.querySelector('.offer-image');

        if (imgEl == null || titleEl == null || linkEl == null) {
          continue;
        }

        final rawLink = linkEl.attributes['href'] ?? '';
        final link = _normalizeSumashtechUrl(rawLink);

        final imageUrl = imgEl.attributes['src'] ?? '';

        final descEl =
            card.querySelector('.offer-content p.short-desc');
        final desc = descEl?.text.trim() ?? '';

        final titleText = titleEl.text.trim();
        final title =
            titleText.isNotEmpty ? titleText : 'Sumashtech Offer';

        products.add(
          Product(
            title: title,
            link: link,
            price: null,
            source: 'sumashtech.com',
            thumbnail: imageUrl.isNotEmpty ? imageUrl : null,
            snippet:
                desc.isNotEmpty ? desc : 'Offer from Sumash Tech',
            priceValue: null,
            note: null,
          ),
        );
      }

      print('✅ [Scraper] Sumashtech products: ${products.length}');
      return products;
    } catch (e) {
      print('❌ [Scraper] Sumashtech error: $e');
      return [];
    }
  }

  String _normalizeSumashtechUrl(String raw) {
    if (raw.startsWith('http')) return raw;
    if (raw.startsWith('/')) {
      return 'https://www.sumashtech.com$raw';
    }
    return 'https://www.sumashtech.com/$raw';
  }
}