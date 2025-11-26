import 'package:flutter/material.dart';
import '../models/product_model.dart';

class CompareProvider with ChangeNotifier {
  final Map<String, Product> _selected = {};

  List<Product> get selected =>
      _selected.values.toList(growable: false);

  int get count => _selected.length;

  bool isSelected(String productId) => _selected.containsKey(productId);

  void toggleProduct(Product product) {
    final id = product.link.hashCode.toString();
    if (_selected.containsKey(id)) {
      _selected.remove(id);
    } else {
      _selected[id] = product;
    }
    notifyListeners();
  }

  void clear() {
    _selected.clear();
    notifyListeners();
  }
}