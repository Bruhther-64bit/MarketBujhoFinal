class Product {
  final String title;
  final String link;
  final String? price;
  final String? source;
  final String? thumbnail;
  final String? snippet;
  final double? priceValue;
  final String? note;
  final String? category; // NEW

  Product({
    required this.title,
    required this.link,
    this.price,
    this.source,
    this.thumbnail,
    this.snippet,
    this.priceValue,
    this.note,
    this.category, // NEW
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Extract price value for sorting
    double? priceVal;
    String? priceStr;

    // Try different price fields
    if (json['price'] != null) {
      priceStr = json['price'].toString();
    } else if (json['extracted_price'] != null) {
      priceStr = json['extracted_price'].toString();
    }

    if (priceStr != null) {
      // Remove currency symbols and extract number
      final numStr = priceStr.replaceAll(RegExp(r'[^\d.]'), '');
      priceVal = double.tryParse(numStr);
    }

    return Product(
      title: json['title'] ?? 'No title',
      link: json['link'] ?? json['product_link'] ?? '',
      price: priceStr,
      source: json['source'] ?? json['displayed_link'],
      thumbnail: json['thumbnail'] ?? json['image'],
      snippet: json['snippet'],
      priceValue: priceVal,
      note: null,
      category: null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'link': link,
      'price': price,
      'source': source,
      'thumbnail': thumbnail,
      'snippet': snippet,
      'priceValue': priceValue,
      'note': note,
      'category': category, // NEW
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      title: map['title'] ?? 'No title',
      link: map['link'] ?? '',
      price: map['price'],
      source: map['source'],
      thumbnail: map['thumbnail'],
      snippet: map['snippet'],
      priceValue: map['priceValue']?.toDouble(),
      note: map['note'],
      category: map['category'], // NEW
    );
  }
}