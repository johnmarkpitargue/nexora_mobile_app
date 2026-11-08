import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/api_constants.dart';
import '../network/api_client.dart';
import '../utils/image_url_helper.dart';
import '../utils/variant_helper.dart';
import 'buyer_account_service.dart';

class CartItemModel {
  final String id;
  final String? productId;
  final int? sellerId;
  final String storeName;
  final String storeBadge;
  final String title;
  final String variant;
  final dynamic variantData;
  final String imageUrl;
  final double price;
  final double? originalPrice;
  final String? discountTag;
  final String? subBadge;
  final String? topPickBadge;
  final String? shopVoucherText;
  final String? storePromoBanner;
  final String? freeShippingBadge;
  final int? stock;
  final bool isVacationMode;
  int quantity;
  bool isChecked;

  CartItemModel({
    required this.id,
    this.productId,
    this.sellerId,
    required this.storeName,
    this.storeBadge = '',
    required this.title,
    required this.variant,
    this.variantData,
    required this.imageUrl,
    required this.price,
    this.originalPrice,
    this.discountTag,
    this.subBadge,
    this.topPickBadge,
    this.shopVoucherText,
    this.storePromoBanner,
    this.freeShippingBadge,
    this.stock,
    this.isVacationMode = false,
    this.quantity = 1,
    this.isChecked = true,
  });

  CartItemModel copyWith({
    String? id,
    String? productId,
    int? sellerId,
    String? storeName,
    String? storeBadge,
    String? title,
    String? variant,
    dynamic variantData,
    String? imageUrl,
    double? price,
    double? originalPrice,
    String? discountTag,
    String? subBadge,
    String? topPickBadge,
    String? shopVoucherText,
    String? storePromoBanner,
    String? freeShippingBadge,
    int? stock,
    bool? isVacationMode,
    int? quantity,
    bool? isChecked,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      sellerId: sellerId ?? this.sellerId,
      storeName: storeName ?? this.storeName,
      storeBadge: storeBadge ?? this.storeBadge,
      title: title ?? this.title,
      variant: variant ?? this.variant,
      variantData: variantData ?? this.variantData,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      discountTag: discountTag ?? this.discountTag,
      subBadge: subBadge ?? this.subBadge,
      topPickBadge: topPickBadge ?? this.topPickBadge,
      shopVoucherText: shopVoucherText ?? this.shopVoucherText,
      storePromoBanner: storePromoBanner ?? this.storePromoBanner,
      freeShippingBadge: freeShippingBadge ?? this.freeShippingBadge,
      stock: stock ?? this.stock,
      isVacationMode: isVacationMode ?? this.isVacationMode,
      quantity: quantity ?? this.quantity,
      isChecked: isChecked ?? this.isChecked,
    );
  }

  factory CartItemModel.fromApiJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>? ?? {};
    final seller = json['seller'] as Map<String, dynamic>? ?? {};

    final id = json['id'].toString();
    final pId = json['product_id']?.toString() ?? product['id']?.toString();
    final rawSellerId = json['seller_id'] ?? product['seller_id'] ?? seller['id'];
    final sId = rawSellerId != null ? int.tryParse(rawSellerId.toString()) : null;
    final name = json['name'] as String? ??
        product['title'] as String? ??
        product['name'] as String? ??
        'Unavailable Product';
    final rawPrimaryImg = json['image'] as String? ??
        product['primary_image'] as String? ??
        (product['images'] is List && (product['images'] as List).isNotEmpty
            ? product['images'][0].toString()
            : '');
    final primaryImg = ImageUrlHelper.resolve(rawPrimaryImg);
    final priceVal = (json['price'] as num?)?.toDouble() ??
        (product['price'] as num?)?.toDouble() ??
        0.0;
    final rawRegular = (json['regular_price'] as num?)?.toDouble() ??
        (product['regular_price'] as num?)?.toDouble();
    final regularPrice =
        (rawRegular != null && rawRegular > priceVal) ? rawRegular : null;
    final qty = (json['quantity'] as num?)?.toInt() ?? 1;
    final isSelected = json['selected'] == true ||
        json['selected'] == 1 ||
        json['is_selected'] == true ||
        json['is_selected'] == 1;

    final sellerName = (json['seller_name'] as String?)?.trim().isNotEmpty == true
        ? json['seller_name'].toString().trim()
        : ((seller['store_name'] as String?)?.trim().isNotEmpty == true
            ? seller['store_name'].toString().trim()
            : ((seller['business_name'] as String?)?.trim().isNotEmpty == true
                ? seller['business_name'].toString().trim()
                : (seller['name'] as String?)?.trim() ?? ''));

    final rawBadge = (json['store_badge'] as String?)?.trim() ??
        (seller['badge'] as String?)?.trim() ??
        '';

    final rawVariant = json['variant'];
    final variantStr = VariantHelper.formatVariantDisplay(rawVariant);

    return CartItemModel(
      id: id,
      productId: pId,
      sellerId: sId,
      storeName: sellerName,
      storeBadge: rawBadge,
      title: name,
      variant: variantStr,
      variantData: rawVariant,
      imageUrl: primaryImg,
      price: priceVal,
      originalPrice: regularPrice,
      stock: (json['stock'] as num?)?.toInt(),
      isVacationMode: json['is_vacation_mode'] == true,
      quantity: qty,
      isChecked: isSelected,
    );
  }
}

class CartService extends ChangeNotifier {
  static final CartService instance = CartService._internal();
  CartService._internal() {
    BuyerAccountService.instance.addListener(_onBuyerChanged);
  }

  final Map<String, List<CartItemModel>> _userItems = {};
  final Map<String, Map<String, int>> _userPurchaseHistory = {};
  String? _lastSyncedUserKey;

  bool _isLoadingCart = false;
  bool _reloadQueued = false;
  Completer<void>? _activeLoadCompleter;
  String? _cartError;

  bool get isLoadingCart => _isLoadingCart;
  String? get cartError => _cartError;

  String? get _currentUserKeyOrNull {
    if (!ApiClient.instance.hasToken) return null;
    final b = BuyerAccountService.instance.currentBuyer ??
        BuyerAccountService.instance.currentUnverifiedBuyer;
    if (b != null && b.email.trim().isNotEmpty) {
      return b.email.toLowerCase().trim();
    }
    return null;
  }

  void _onBuyerChanged() {
    final key = _currentUserKeyOrNull;
    if (key == null) {
      // Session logged out or not yet established: clear local cache, never write under 'guest'.
      if (_lastSyncedUserKey != null || _userItems.isNotEmpty || _directBuyItem != null) {
        _userItems.clear();
        _userPurchaseHistory.clear();
        _directBuyItem = null;
        _cartError = null;
        _lastSyncedUserKey = null;
        notifyListeners();
      }
      return;
    }

    if (key != _lastSyncedUserKey) {
      _lastSyncedUserKey = key;
      _directBuyItem = null;
      _cartError = null;
      notifyListeners();
      unawaited(loadCartRemote());
    }
  }

  List<CartItemModel> get _items {
    final key = _currentUserKeyOrNull;
    if (key == null) return const <CartItemModel>[];
    return _userItems[key] ?? const <CartItemModel>[];
  }

  Map<String, int> get _buyerPurchaseHistory {
    final key = _currentUserKeyOrNull;
    if (key == null) return const <String, int>{};
    return _userPurchaseHistory.putIfAbsent(key, () => <String, int>{});
  }

  void _setServerItems(List<CartItemModel> list) {
    final key = _currentUserKeyOrNull;
    if (key == null) {
      // Buyer profile is not loaded yet; do not populate under 'guest'.
      return;
    }
    _userItems[key] = list;
  }

  List<CartItemModel>? _syncFromResponsePayload(dynamic data) {
    if (data is Map<String, dynamic> && data['items'] is List) {
      final list = (data['items'] as List)
          .whereType<Map<String, dynamic>>()
          .map(CartItemModel.fromApiJson)
          .toList();
      _setServerItems(list);
      _cartError = null;
      notifyListeners();
      return list;
    }
    return null;
  }

  String _formatError(Object e) {
    if (e is ApiException) return e.message;
    return e.toString().replaceFirst('Exception: ', '');
  }

  /// Load cart from backend API. Queues one trailing reload if invoked while already loading.
  Future<void> loadCartRemote({bool throwOnError = false}) async {
    if (!ApiClient.instance.hasToken) return;
    if (_currentUserKeyOrNull == null) {
      // Wait until the buyer session is known before populating cart.
      return;
    }

    if (_isLoadingCart) {
      _reloadQueued = true;
      return _activeLoadCompleter?.future;
    }

    _isLoadingCart = true;
    final completer = Completer<void>();
    _activeLoadCompleter = completer;
    notifyListeners();

    Object? lastError;
    try {
      do {
        _reloadQueued = false;
        try {
          final res = await ApiClient.instance.get(ApiConstants.buyerCart);
          final synced = _syncFromResponsePayload(res['data']);
          if (synced == null) {
            _cartError = null;
          }
          lastError = null;
        } catch (e) {
          lastError = e;
          _cartError = _formatError(e);
          debugPrint('loadCartRemote error: $e');
          notifyListeners();
        }
      } while (_reloadQueued);

      if (lastError != null && throwOnError) {
        throw lastError;
      }
    } finally {
      _isLoadingCart = false;
      _activeLoadCompleter = null;
      if (!completer.isCompleted) {
        completer.complete();
      }
      notifyListeners();
    }
  }

  /// Add item to cart on backend API and return the created/merged cart item id.
  Future<int?> addItemRemote({
    required int productId,
    int quantity = 1,
    Map<String, dynamic>? variant,
  }) async {
    if (!ApiClient.instance.hasToken) {
      throw const ApiException(
        statusCode: 401,
        message: 'Please sign in to add items to your cart.',
      );
    }

    final body = <String, dynamic>{
      'product_id': productId,
      'quantity': quantity,
    };
    if (variant != null && variant.isNotEmpty) {
      body['variant'] = variant;
    }

    final res = await ApiClient.instance.post(
      ApiConstants.buyerCartItems,
      body: body,
    );

    final data = res['data'];
    int? cartItemId;
    if (data is Map<String, dynamic>) {
      cartItemId = int.tryParse(
            (data['cart_item_id'] ??
                    data['id'] ??
                    (data['item'] is Map ? (data['item'] as Map)['id'] : null))
                ?.toString() ??
                '',
          );
    }

    final synced = _syncFromResponsePayload(data);
    if (synced == null) {
      await loadCartRemote(throwOnError: false);
    }
    return cartItemId;
  }

  /// Update item quantity on backend API (server first, reload on failure).
  Future<void> updateQuantityRemote(String id, int quantity) async {
    if (!ApiClient.instance.hasToken) {
      throw const ApiException(
        statusCode: 401,
        message: 'Please sign in to update your cart.',
      );
    }
    try {
      final res = await ApiClient.instance.patch(
        ApiConstants.buyerCartItem(id),
        body: {'quantity': quantity},
      );
      if (_syncFromResponsePayload(res['data']) == null) {
        await loadCartRemote(throwOnError: true);
      }
    } catch (e) {
      await loadCartRemote();
      rethrow;
    }
  }

  /// Toggle item selected on backend API (server first, reload on failure).
  Future<void> toggleItemCheckedRemote(String id, bool checked) async {
    if (!ApiClient.instance.hasToken) {
      throw const ApiException(
        statusCode: 401,
        message: 'Please sign in to update your cart.',
      );
    }
    try {
      final res = await ApiClient.instance.patch(
        ApiConstants.buyerCartItem(id),
        body: {'selected': checked},
      );
      if (_syncFromResponsePayload(res['data']) == null) {
        await loadCartRemote(throwOnError: true);
      }
    } catch (e) {
      await loadCartRemote();
      rethrow;
    }
  }

  /// Remove item on backend API (server first, reload on failure).
  Future<void> removeItemRemote(String id) async {
    if (!ApiClient.instance.hasToken) {
      throw const ApiException(
        statusCode: 401,
        message: 'Please sign in to remove cart items.',
      );
    }
    try {
      final res = await ApiClient.instance.delete(ApiConstants.buyerCartItem(id));
      if (_syncFromResponsePayload(res['data']) == null) {
        await loadCartRemote(throwOnError: true);
      }
    } catch (e) {
      await loadCartRemote();
      rethrow;
    }
  }

  /// Select or deselect all items for a specific store on backend API (server first).
  Future<void> toggleStoreCheckedRemote(int sellerId, bool checked) async {
    if (!ApiClient.instance.hasToken) {
      throw const ApiException(
        statusCode: 401,
        message: 'Please sign in to update store selection.',
      );
    }
    try {
      final res = await ApiClient.instance.patch(
        ApiConstants.cartSelectStore(sellerId),
        body: {'selected': checked},
      );
      if (_syncFromResponsePayload(res['data']) == null) {
        await loadCartRemote(throwOnError: true);
      }
    } catch (e) {
      await loadCartRemote();
      rethrow;
    }
  }

  /// Select or deselect all items on backend API (server first, reload on failure).
  Future<void> selectAllRemote(bool selected) async {
    if (!ApiClient.instance.hasToken) {
      throw const ApiException(
        statusCode: 401,
        message: 'Please sign in to update cart selection.',
      );
    }
    try {
      final res = await ApiClient.instance.patch(
        ApiConstants.buyerCartSelectAll,
        body: {'selected': selected},
      );
      if (_syncFromResponsePayload(res['data']) == null) {
        await loadCartRemote(throwOnError: true);
      }
    } catch (e) {
      await loadCartRemote();
      rethrow;
    }
  }

  /// Remove all checked items on backend API (server first, reload afterwards).
  Future<void> removeSelectedItemsRemote() async {
    if (!ApiClient.instance.hasToken) {
      throw const ApiException(
        statusCode: 401,
        message: 'Please sign in to remove cart items.',
      );
    }
    final toRemove = _items.where((i) => i.isChecked).toList();
    if (toRemove.isEmpty) return;

    Object? firstError;
    for (final item in toRemove) {
      try {
        await ApiClient.instance.delete(ApiConstants.buyerCartItem(item.id));
      } catch (e) {
        firstError ??= e;
      }
    }
    await loadCartRemote();
    if (firstError != null) {
      throw firstError;
    }
  }

  /// Moves selected cart items to server wishlist and removes them from cart.
  Future<int> moveSelectedToLikesRemote() async {
    if (!ApiClient.instance.hasToken) {
      throw const ApiException(
        statusCode: 401,
        message: 'Please sign in to move items to wishlist.',
      );
    }
    final selected = _items.where((i) => i.isChecked).toList();
    if (selected.isEmpty) return 0;

    int moved = 0;
    Object? firstError;
    for (final item in selected) {
      try {
        if (item.productId != null && item.productId!.isNotEmpty) {
          await ApiClient.instance.post(
            ApiConstants.buyerWishlistToggle(item.productId!),
          );
        }
        await ApiClient.instance.delete(ApiConstants.buyerCartItem(item.id));
        moved++;
      } catch (e) {
        firstError ??= e;
      }
    }
    await loadCartRemote();
    if (firstError != null && moved == 0) {
      throw firstError;
    }
    return moved;
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

  double get originalSubtotal =>
      _items.where((i) => i.isChecked).fold(0.0, (sum, i) {
        final basePrice = i.originalPrice ?? i.price;
        return sum + (basePrice * i.quantity);
      });

  // --- Buy Now Direct Checkout Isolation (BUY-PDP-007) ---
  CartItemModel? _directBuyItem;
  CartItemModel? get directBuyItem => _directBuyItem;

  List<CartItemModel> get checkoutItems => _directBuyItem != null
      ? [_directBuyItem!]
      : _items.where((i) => i.isChecked).toList();

  int get cartItemCount => itemCount;

  void buyNow({
    String? productId,
    int? sellerId,
    Map<String, dynamic>? variantData,
    required String title,
    required String variant,
    required double price,
    required String imageUrl,
    required String storeName,
    String storeBadge = '',
    double? originalPrice,
    String? discountTag,
    int quantity = 1,
  }) {
    _directBuyItem = CartItemModel(
      id: 'direct_${DateTime.now().millisecondsSinceEpoch}',
      productId: productId,
      sellerId: sellerId,
      storeName: storeName,
      storeBadge: storeBadge,
      title: title,
      variant: variant,
      variantData: variantData,
      imageUrl: imageUrl,
      price: price,
      originalPrice: originalPrice,
      discountTag: discountTag,
      quantity: quantity,
      isChecked: true,
    );
    notifyListeners();
  }

  Future<int?> addToCart({
    required int productId,
    Map<String, dynamic>? variantPayload,
    int quantity = 1,
  }) async {
    return addItemRemote(
      productId: productId,
      quantity: quantity,
      variant: variantPayload,
    );
  }

  void clearDirectBuy() {
    _directBuyItem = null;
    notifyListeners();
  }

  void clearCart() {
    _userItems.clear();
    _directBuyItem = null;
    _cartError = null;
    notifyListeners();
  }

  int getPurchasedCount(String productIdOrTitle) {
    return _buyerPurchaseHistory[productIdOrTitle] ?? 0;
  }

  void recordPurchase(String productIdOrTitle, int quantity) {
    final key = _currentUserKeyOrNull;
    if (key == null) return;
    _buyerPurchaseHistory[productIdOrTitle] =
        (_buyerPurchaseHistory[productIdOrTitle] ?? 0) + quantity;
    notifyListeners();
  }

  void resetPurchaseHistory() {
    _userPurchaseHistory.clear();
    notifyListeners();
  }
}
