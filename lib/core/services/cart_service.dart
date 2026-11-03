import 'package:flutter/material.dart';
import 'buyer_account_service.dart';
import '../constants/api_constants.dart';
import '../network/api_client.dart';

class CartItemModel {
  final String id;
  final String storeName;
  final String storeBadge; // 'MALL', 'PREFERRED+', or ''
  final String title;
  final String variant;
  final String imageUrl;
  final double price;
  final double? originalPrice;
  final String? discountTag;
  final String? subBadge;
  final String? topPickBadge;
  final String? shopVoucherText;
  final String? storePromoBanner;
  final String? freeShippingBadge;
  int quantity;
  bool isChecked;

  CartItemModel({
    required this.id,
    required this.storeName,
    this.storeBadge = '',
    required this.title,
    required this.variant,
    required this.imageUrl,
    required this.price,
    this.originalPrice,
    this.discountTag,
    this.subBadge,
    this.topPickBadge,
    this.shopVoucherText,
    this.storePromoBanner,
    this.freeShippingBadge,
    this.quantity = 1,
    this.isChecked = true,
  });

  CartItemModel copyWith({
    String? id,
    String? storeName,
    String? storeBadge,
    String? title,
    String? variant,
    String? imageUrl,
    double? price,
    double? originalPrice,
    String? discountTag,
    String? subBadge,
    String? topPickBadge,
    String? shopVoucherText,
    String? storePromoBanner,
    String? freeShippingBadge,
    int? quantity,
    bool? isChecked,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      storeName: storeName ?? this.storeName,
      storeBadge: storeBadge ?? this.storeBadge,
      title: title ?? this.title,
      variant: variant ?? this.variant,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      discountTag: discountTag ?? this.discountTag,
      subBadge: subBadge ?? this.subBadge,
      topPickBadge: topPickBadge ?? this.topPickBadge,
      shopVoucherText: shopVoucherText ?? this.shopVoucherText,
      storePromoBanner: storePromoBanner ?? this.storePromoBanner,
      freeShippingBadge: freeShippingBadge ?? this.freeShippingBadge,
      quantity: quantity ?? this.quantity,
      isChecked: isChecked ?? this.isChecked,
    );
  }

  factory CartItemModel.fromApiJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>? ?? {};
    final seller = json['seller'] as Map<String, dynamic>? ?? {};
    final priceVal = (json['price'] as num?)?.toDouble() ??
        (product['price'] as num?)?.toDouble() ??
        0.0;
    final primaryImg = product['primary_image'] as String? ??
        (product['images'] is List && (product['images'] as List).isNotEmpty
            ? product['images'][0].toString()
            : '');

    return CartItemModel(
      id: json['id'].toString(),
      storeName: seller['store_name'] as String? ?? 'Nexora Store',
      storeBadge: 'MALL',
      title: product['title'] as String? ?? product['name'] as String? ?? 'Product',
      variant: 'Standard',
      imageUrl: primaryImg.isNotEmpty
          ? primaryImg
          : 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=300&q=80',
      price: priceVal,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      isChecked: json['is_selected'] == true || json['is_selected'] == 1,
    );
  }
}

class CartService extends ChangeNotifier {
  static final CartService instance = CartService._internal();
  CartService._internal() {
    BuyerAccountService.instance.addListener(_onBuyerChanged);
  }

  void _onBuyerChanged() {
    _directBuyItem = null;
    loadCartRemote();
    notifyListeners();
  }

  /// Load cart from backend API
  Future<void> loadCartRemote() async {
    if (!ApiClient.instance.hasToken) return;
    try {
      final res = await ApiClient.instance.get(ApiConstants.buyerCart);
      if (res['data'] is Map<String, dynamic>) {
        final items = res['data']['items'];
        if (items is List) {
          final list = items
              .map((i) => CartItemModel.fromApiJson(i as Map<String, dynamic>))
              .toList();
          _userItems[_currentUserKey] = list;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('loadCartRemote error: $e');
    }
  }

  /// Add item to cart on backend API
  Future<void> addItemRemote({required int productId, int quantity = 1}) async {
    if (ApiClient.instance.hasToken) {
      try {
        await ApiClient.instance.post(
          ApiConstants.buyerCartItems,
          body: {
            'product_id': productId,
            'quantity': quantity,
          },
        );
        await loadCartRemote();
        return;
      } catch (e) {
        debugPrint('addItemRemote error: $e');
      }
    }
  }

  /// Update item quantity on backend API
  Future<void> updateQuantityRemote(String id, int quantity) async {
    updateQuantity(id, quantity);
    if (ApiClient.instance.hasToken) {
      try {
        await ApiClient.instance.patch(
          ApiConstants.buyerCartItem(id),
          body: {'quantity': quantity},
        );
        await loadCartRemote();
      } catch (e) {
        debugPrint('updateQuantityRemote error: $e');
      }
    }
  }

  /// Toggle item selected on backend API
  Future<void> toggleItemCheckedRemote(String id, bool checked) async {
    toggleItemChecked(id, checked);
    if (ApiClient.instance.hasToken) {
      try {
        await ApiClient.instance.patch(
          ApiConstants.buyerCartItem(id),
          body: {'is_selected': checked},
        );
        await loadCartRemote();
      } catch (e) {
        debugPrint('toggleItemCheckedRemote error: $e');
      }
    }
  }

  /// Remove item on backend API
  Future<void> removeItemRemote(String id) async {
    removeItem(id);
    if (ApiClient.instance.hasToken) {
      try {
        await ApiClient.instance.delete(ApiConstants.buyerCartItem(id));
        await loadCartRemote();
      } catch (e) {
        debugPrint('removeItemRemote error: $e');
      }
    }
  }

  /// Select or deselect all items on backend API
  Future<void> selectAllRemote(bool selected) async {
    toggleSelectAll(selected);
    if (ApiClient.instance.hasToken) {
      try {
        await ApiClient.instance.patch(
          ApiConstants.buyerCartSelectAll,
          body: {'is_selected': selected},
        );
        await loadCartRemote();
      } catch (e) {
        debugPrint('selectAllRemote error: $e');
      }
    }
  }

  /// Remove all checked items on backend API
  Future<void> removeSelectedItemsRemote() async {
    final toRemove = _items.where((i) => i.isChecked).toList();
    removeSelectedItems();
    if (ApiClient.instance.hasToken) {
      for (final item in toRemove) {
        try {
          await ApiClient.instance.delete(ApiConstants.buyerCartItem(item.id));
        } catch (e) {
          debugPrint('removeSelectedItemsRemote item error: $e');
        }
      }
      await loadCartRemote();
    }
  }

  final Map<String, List<CartItemModel>> _userItems = {};
  final Map<String, Map<String, int>> _userPurchaseHistory = {};

  String get _currentUserKey {
    final b = BuyerAccountService.instance.currentBuyer ??
        BuyerAccountService.instance.currentUnverifiedBuyer;
    return (b != null && b.email.isNotEmpty)
        ? b.email.toLowerCase().trim()
        : 'guest';
  }

  List<CartItemModel> get _items {
    return _userItems.putIfAbsent(_currentUserKey, () => <CartItemModel>[]);
  }

  Map<String, int> get _buyerPurchaseHistory {
    return _userPurchaseHistory.putIfAbsent(_currentUserKey, () => <String, int>{});
  }

  List<CartItemModel> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, i) => sum + i.quantity);

  int get selectedCount =>
      _items.where((i) => i.isChecked).fold(0, (sum, i) => sum + i.quantity);

  int get selectedItemsCount => _items.where((i) => i.isChecked).length;

  bool get isAllSelected =>
      _items.isNotEmpty && _items.every((i) => i.isChecked);

  double get subtotal => _items
      .where((i) => i.isChecked)
      .fold(0.0, (sum, i) => sum + (i.price * i.quantity));

  double get originalSubtotal => _items.where((i) => i.isChecked).fold(0.0, (sum, i) {
        final basePrice = i.originalPrice ?? i.price;
        return sum + (basePrice * i.quantity);
      });

  void addItem({
    required String title,
    required String variant,
    required double price,
    required String imageUrl,
    String storeName = 'Nexora Official Flagship',
    String storeBadge = 'MALL',
    double? originalPrice,
    String? discountTag,
    int quantity = 1,
  }) {
    final existingIndex =
        _items.indexWhere((i) => i.title == title && i.variant == variant);
    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
      _items[existingIndex].isChecked = true;
    } else {
      _items.insert(
        0,
        CartItemModel(
          id: 'c_${DateTime.now().millisecondsSinceEpoch}',
          storeName: storeName,
          storeBadge: storeBadge,
          title: title,
          variant: variant,
          imageUrl: imageUrl,
          price: price,
          originalPrice: originalPrice,
          discountTag: discountTag,
          quantity: quantity,
          isChecked: true,
        ),
      );
    }
    notifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  void removeSelectedItems() {
    _items.removeWhere((i) => i.isChecked);
    notifyListeners();
  }

  void moveSelectedToLikes() {
    _items.removeWhere((i) => i.isChecked);
    notifyListeners();
  }

  void updateQuantity(String id, int quantity) {
    final index = _items.indexWhere((i) => i.id == id);
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = quantity;
      }
      notifyListeners();
    }
  }

  void toggleItemChecked(String id, bool checked) {
    final index = _items.indexWhere((i) => i.id == id);
    if (index >= 0) {
      _items[index].isChecked = checked;
      notifyListeners();
    }
  }

  void toggleSelectAll(bool checked) {
    for (var i in _items) {
      i.isChecked = checked;
    }
    notifyListeners();
  }

  void toggleStoreChecked(String storeName, bool checked) {
    for (var i in _items.where((item) => item.storeName == storeName)) {
      i.isChecked = checked;
    }
    notifyListeners();
  }

  List<CartItemModel> removeAndGetSelectedItems() {
    final selected = _items.where((i) => i.isChecked).toList();
    _items.removeWhere((i) => i.isChecked);
    notifyListeners();
    return selected;
  }

  // --- Buy Now Direct Checkout Isolation (BUY-PDP-007) ---
  CartItemModel? _directBuyItem;
  CartItemModel? get directBuyItem => _directBuyItem;

  List<CartItemModel> get checkoutItems =>
      _directBuyItem != null ? [_directBuyItem!] : _items.where((i) => i.isChecked).toList();

  int get cartItemCount => itemCount;

  void buyNow({
    required String title,
    required String variant,
    required double price,
    required String imageUrl,
    String storeName = 'Nexora Official Flagship',
    String storeBadge = 'MALL',
    double? originalPrice,
    String? discountTag,
    int quantity = 1,
  }) {
    _directBuyItem = CartItemModel(
      id: 'direct_${DateTime.now().millisecondsSinceEpoch}',
      storeName: storeName,
      storeBadge: storeBadge,
      title: title,
      variant: variant,
      imageUrl: imageUrl,
      price: price,
      originalPrice: originalPrice,
      discountTag: discountTag,
      quantity: quantity,
      isChecked: true,
    );
    notifyListeners();
  }

  void addToCart({
    required String title,
    required String variant,
    required double price,
    required String imageUrl,
    String storeName = 'Nexora Official Flagship',
    String storeBadge = 'MALL',
    double? originalPrice,
    String? discountTag,
    int quantity = 1,
  }) {
    addItem(
      title: title,
      variant: variant,
      price: price,
      imageUrl: imageUrl,
      storeName: storeName,
      storeBadge: storeBadge,
      originalPrice: originalPrice,
      discountTag: discountTag,
      quantity: quantity,
    );
  }

  void clearDirectBuy() {
    _directBuyItem = null;
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _directBuyItem = null;
    notifyListeners();
  }

  int getPurchasedCount(String productIdOrTitle) {
    return _buyerPurchaseHistory[productIdOrTitle] ?? 0;
  }

  void recordPurchase(String productIdOrTitle, int quantity) {
    _buyerPurchaseHistory[productIdOrTitle] =
        (_buyerPurchaseHistory[productIdOrTitle] ?? 0) + quantity;
    notifyListeners();
  }

  void resetPurchaseHistory() {
    _buyerPurchaseHistory.clear();
    notifyListeners();
  }
}

