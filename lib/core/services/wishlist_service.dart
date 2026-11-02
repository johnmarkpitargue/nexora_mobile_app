import 'package:flutter/material.dart';
import '../../features/home/presentation/widgets/product_card.dart';
import '../constants/api_constants.dart';
import '../network/api_client.dart';

class WishlistService extends ChangeNotifier {
  static final WishlistService instance = WishlistService._internal();

  WishlistService._internal();

  final List<ProductModel> _wishlistItems = [];

  List<ProductModel> get items => List.unmodifiable(_wishlistItems);

  int get itemCount => _wishlistItems.length;

  bool isInWishlist(String title) {
    return _wishlistItems.any((item) => item.title == title);
  }

  Future<void> refreshWishlistRemote() async {
    if (!ApiClient.instance.hasToken) return;
    try {
      final res = await ApiClient.instance.get(ApiConstants.buyerWishlist);
      final data = res['data'];
      final List list = data is List
          ? data
          : (data is Map && data['data'] is List ? data['data'] : []);
      final products = list
          .map((item) =>
              ProductModel.fromApiJson(item as Map<String, dynamic>))
          .toList();
      _wishlistItems.clear();
      _wishlistItems.addAll(products);
      notifyListeners();
    } catch (e) {
      debugPrint('refreshWishlistRemote error: $e');
    }
  }

  Future<void> toggleWishlist(ProductModel product) async {
    final index = _wishlistItems.indexWhere((item) =>
        (item.id.isNotEmpty && item.id == product.id) ||
        item.title == product.title);
    if (index >= 0) {
      _wishlistItems.removeAt(index);
    } else {
      _wishlistItems.insert(0, product);
    }
    notifyListeners();

    if (ApiClient.instance.hasToken && product.id.isNotEmpty) {
      try {
        await ApiClient.instance
            .post(ApiConstants.buyerWishlistToggle(product.id));
      } catch (e) {
        debugPrint('toggleWishlist remote error: $e');
      }
    }
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
