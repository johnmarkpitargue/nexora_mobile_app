import 'package:flutter/material.dart';
import '../../features/home/presentation/widgets/product_card.dart';

class WishlistService extends ChangeNotifier {
  static final WishlistService instance = WishlistService._internal();

  WishlistService._internal();

  final List<ProductModel> _wishlistItems = [];

  List<ProductModel> get items => List.unmodifiable(_wishlistItems);

  int get itemCount => _wishlistItems.length;

  bool isInWishlist(String title) {
    return _wishlistItems.any((item) => item.title == title);
  }

  void toggleWishlist(ProductModel product) {
    final index = _wishlistItems.indexWhere((item) => item.title == product.title);
    if (index >= 0) {
      _wishlistItems.removeAt(index);
    } else {
      _wishlistItems.insert(0, product);
    }
    notifyListeners();
  }

  void addToWishlist(ProductModel product) {
    if (!isInWishlist(product.title)) {
      _wishlistItems.insert(0, product);
      notifyListeners();
    }
  }

  void removeFromWishlist(String title) {
    final index = _wishlistItems.indexWhere((item) => item.title == title);
    if (index >= 0) {
      _wishlistItems.removeAt(index);
      notifyListeners();
    }
  }

  void clearWishlist() {
    _wishlistItems.clear();
    notifyListeners();
  }
}
