import 'package:flutter/material.dart';
import '../models/product_model.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final Product? product;
  final double? oldPrice;
  final double? newPrice;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.product,
    this.oldPrice,
    this.newPrice,
    this.isRead = false,
  });
}

class NotificationProvider with ChangeNotifier {
  final List<AppNotification> _notifications = [];

  List<AppNotification> get notifications =>
      List.unmodifiable(_notifications);

  bool get hasUnread => _notifications.any((n) => !n.isRead);

  void addPriceDropNotification(
      Product product, double oldPrice, double newPrice) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _notifications.insert(
      0,
      AppNotification(
        id: id,
        title: 'Price drop on your wishlist',
        body:
            '${product.title} price dropped from ৳${oldPrice.toStringAsFixed(0)} to ৳${newPrice.toStringAsFixed(0)}.',
        timestamp: DateTime.now(),
        product: product,
        oldPrice: oldPrice,
        newPrice: newPrice,
        isRead: false,
      ),
    );
    notifyListeners();
  }

  void markAllAsRead() {
    for (final n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }
}