import 'package:flutter/material.dart';
import 'buyer_account_service.dart';

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
}

class CartService extends ChangeNotifier {
  static final CartService instance = CartService._internal();
  CartService._internal() {
    BuyerAccountService.instance.addListener(_onBuyerChanged);
  }

  void _onBuyerChanged() {
    _directBuyItem = null;
    notifyListeners();
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

