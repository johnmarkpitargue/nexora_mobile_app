import 'package:flutter/material.dart';

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
}

class CartService extends ChangeNotifier {
  static final CartService instance = CartService._internal();
  CartService._internal();

  final List<CartItemModel> _items = [
    CartItemModel(
      id: 'c1',
      storeName: 'Nexora Official Flagship',
      storeBadge: 'MALL',
      freeShippingBadge: 'Free Shipping min. spend ₱0',
      title: 'Nexora Studio Pro Wireless Noise Cancelling Headphone',
      variant: 'Matte Space Grey, Wireless',
      imageUrl:
          'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=300&q=80',
      price: 2450.00,
      originalPrice: 3200.00,
      discountTag: '-23%',
      topPickBadge: 'Top Pick',
      subBadge: '🛡️ 15 Days Free Return Guarantee',
      quantity: 1,
      isChecked: true,
    ),
    CartItemModel(
      id: 'c2',
      storeName: 'Nexora Official Flagship',
      storeBadge: 'MALL',
      title: 'Nexora Aura Mechanical Keyboard RGB - Chalk White',
      variant: 'Chalk White, Red Switch',
      imageUrl:
          'https://images.unsplash.com/photo-1587829741301-dc798b83add3?auto=format&fit=crop&w=300&q=80',
      price: 3200.00,
      shopVoucherText: 'Claim ₱100 OFF coupon',
      quantity: 1,
      isChecked: true,
    ),
    CartItemModel(
      id: 'c3',
      storeName: 'Urban Minimalist Studio',
      storeBadge: 'PREFERRED+',
      storePromoBanner: 'Buy 2 get 5% OFF on select garments',
      title: 'Aura Minimalist Fleece Oversized Hoodie - Warm...',
      variant: 'Warm Stone, Size L',
      imageUrl:
          'https://images.unsplash.com/photo-1556905055-8f358a7a47b2?auto=format&fit=crop&w=300&q=80',
      price: 1250.00,
      originalPrice: 1800.00,
      discountTag: '-30%',
      quantity: 1,
      isChecked: true,
    ),
    CartItemModel(
      id: 'c4',
      storeName: 'Nordic Lifestyle Essentials',
      storeBadge: '',
      title: 'Minimalist Canvas Commuter Tote & Insulated Water Bottle...',
      variant: 'Sandstone Beige',
      imageUrl:
          'https://images.unsplash.com/photo-1544816155-12df9643f363?auto=format&fit=crop&w=300&q=80',
      price: 1420.00,
      quantity: 1,
      isChecked: false,
    ),
  ];

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
    for (var i in _items) {
      i.isChecked = false;
    }
    final item = CartItemModel(
      id: 'bn_${DateTime.now().millisecondsSinceEpoch}',
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
    _items.insert(0, item);
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
}
