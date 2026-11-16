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

  bool isInWishlist(String titleOrId) {
    return _wishlistItems.any(
      (item) => item.id == titleOrId || item.title == titleOrId,
    );
  }

  Future<void> refreshWishlistRemote() async {
    if (!ApiClient.instance.hasToken) {
      if (_wishlistItems.isNotEmpty) {
        _wishlistItems.clear();
        notifyListeners();
      }
      return;
    }
    final res = await ApiClient.instance.get(ApiConstants.buyerWishlist);
    final data = res['data'];
    final List list = data is List
        ? data
        : (data is Map && data['data'] is List ? data['data'] : []);
    final products = list
        .whereType<Map<String, dynamic>>()
        .map(ProductModel.fromApiJson)
        .toList();
    _wishlistItems.clear();
    _wishlistItems.addAll(products);
    notifyListeners();
  }

  Future<void> toggleWishlist(ProductModel product) async {
    final index = _wishlistItems.indexWhere((item) =>
        (item.id.isNotEmpty && item.id == product.id) ||
        item.title == product.title);
    final wasSaved = index >= 0;
    if (wasSaved) {
      _wishlistItems.removeAt(index);
    } else {
      _wishlistItems.insert(0, product);
    }
    notifyListeners();

    if (ApiClient.instance.hasToken &&
        product.id.isNotEmpty &&
        int.tryParse(product.id) != null) {
      try {
        await ApiClient.instance
            .post(ApiConstants.buyerWishlistToggle(product.id));
      } catch (e) {
        // Revert optimistic update cleanly on API failure
        if (wasSaved) {
          _wishlistItems.insert(index.clamp(0, _wishlistItems.length), product);
        } else {
          _wishlistItems.removeWhere((item) => item.id == product.id);
        }
        notifyListeners();
        rethrow;
      }
    }
  }

  void addToWishlist(ProductModel product) {
    if (!isInWishlist(product.title)) {
      _wishlistItems.insert(0, product);
      notifyListeners();
    }
  }

  Future<void> removeFromWishlist(String titleOrId) async {
    final index = _wishlistItems.indexWhere(
      (item) => item.id == titleOrId || item.title == titleOrId,
    );
    if (index < 0) return;
    final match = _wishlistItems[index];
    await toggleWishlist(match);
  }

  void clearWishlist() {
    _wishlistItems.clear();
    notifyListeners();
  }
}
