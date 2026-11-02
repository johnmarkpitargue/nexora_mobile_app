import 'package:flutter/material.dart';
import '../models/shop_models.dart';
import '../../features/home/presentation/widgets/product_card.dart';
import 'buyer_account_service.dart';
import '../constants/api_constants.dart';
import '../network/api_client.dart';

class SearchFilterParams {
  final String query;
  final String? category;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final String? location;
  final String sortBy; // 'relevance', 'price_asc', 'price_desc', 'best_selling', 'latest'

  const SearchFilterParams({
    this.query = '',
    this.category,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.location,
    this.sortBy = 'relevance',
  });
}

class SearchResult {
  final List<ProductModel> products;
  final String? typoSuggestion;
  final String? errorMessage;

  const SearchResult({
    required this.products,
    this.typoSuggestion,
    this.errorMessage,
  });
}

class ShopService extends ChangeNotifier {
  static final ShopService instance = ShopService._internal();
  ShopService._internal() {
    BuyerAccountService.instance.addListener(_onBuyerChanged);
  }

  void _onBuyerChanged() {
    notifyListeners();
  }

  final Map<String, Set<String>> _userFollowedShopIds = {};
  final Map<String, Set<String>> _userClaimedVoucherIds = {};
  final Map<String, int> _helpfulVotes = {};
  final Set<String> _userUpvotedReviews = {};

  List<ProductModel> _remoteProducts = [];
  bool _isLoadingCatalog = false;
  bool get isLoadingCatalog => _isLoadingCatalog;

  List<ProductModel> get products =>
      _remoteProducts.isNotEmpty ? _remoteProducts : allAppProducts;

  /// Loads catalog from remote Laravel backend and updates listeners
  Future<List<ProductModel>> loadCatalogRemote({
    String? query,
    String? category,
    String? sort,
    double? minPrice,
    double? maxPrice,
    String? sellerId,
  }) async {
    _isLoadingCatalog = true;
    notifyListeners();
    try {
      final fetched = await fetchCatalogRemote(
        query: query,
        category: category,
        sort: sort,
        minPrice: minPrice,
        maxPrice: maxPrice,
        sellerId: sellerId,
      );
      if (fetched.isNotEmpty) {
        _remoteProducts = fetched;
      }
      return fetched;
    } finally {
      _isLoadingCatalog = false;
      notifyListeners();
    }
  }

  /// Search and filter with remote Laravel catalog, falling back to local
  Future<SearchResult> searchAndFilterRemote(SearchFilterParams params) async {
    try {
      final queryParams = <String, String>{};
      if (params.query.isNotEmpty) queryParams['q'] = params.query;
      if (params.category != null &&
          params.category != 'All' &&
          params.category != 'Mall') {
        queryParams['category'] = params.category!;
      }
      if (params.minPrice != null) {
        queryParams['min_price'] = params.minPrice.toString();
      }
      if (params.maxPrice != null) {
        queryParams['max_price'] = params.maxPrice.toString();
      }
      if (params.sortBy.isNotEmpty) queryParams['sort'] = params.sortBy;

      final uri = Uri(
          path: ApiConstants.buyerCatalog,
          queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final res = await ApiClient.instance.get(uri.toString());
      final data = res['data'];
      final List list = data is List
          ? data
          : (data is Map && data['data'] is List ? data['data'] : []);
      final remoteList = list
          .map((item) =>
              ProductModel.fromApiJson(item as Map<String, dynamic>))
          .toList();

      if (remoteList.isNotEmpty) {
        return SearchResult(products: remoteList);
      }
    } catch (e) {
      debugPrint('searchAndFilterRemote error: $e');
    }
    return searchAndFilter(params);
  }

  /// Fetch store detail from Laravel backend API
  Future<ShopModel?> fetchStoreRemote(String sellerId) async {
    try {
      final res =
          await ApiClient.instance.get(ApiConstants.buyerStore(sellerId));
      if (res['data'] is Map<String, dynamic>) {
        final d = res['data'] as Map<String, dynamic>;
        final storeName = d['name'] as String? ?? 'Seller Store';
        final initial = storeName.isNotEmpty ? storeName[0].toUpperCase() : 'S';
        return ShopModel(
          id: d['id'].toString(),
          name: storeName,
          badge: 'VERIFIED SELLER',
          followers: '${d['followers_count'] ?? 0}',
          initials: initial,
          avatarBg: const Color(0xFF0066FF),
          categoryGroupTitle: d['category'] as String? ?? 'STORE MERCHANDISE',
          categories: [],
          vouchers: [],
        );
      }
    } catch (e) {
      debugPrint('fetchStoreRemote error: $e');
    }
    return null;
  }

  String get _currentUserKey {
    final buyer = BuyerAccountService.instance.currentBuyer;
    return (buyer != null && buyer.email.isNotEmpty) ? buyer.email.toLowerCase().trim() : 'guest';
  }

  Set<String> get _currentFollowedShops {
    return _userFollowedShopIds.putIfAbsent(_currentUserKey, () => <String>{});
  }

  Set<String> get _currentClaimedVouchers {
    return _userClaimedVoucherIds.putIfAbsent(_currentUserKey, () => <String>{});
  }

  int get followedShopCount => _currentFollowedShops.length;

  List<String> get followedShopIds => _currentFollowedShops.toList();

  bool isFollowing(String shopId) => _currentFollowedShops.contains(shopId);

  void toggleFollow(String shopId) {
    final set = _currentFollowedShops;
    if (set.contains(shopId)) {
      set.remove(shopId);
    } else {
      set.add(shopId);
    }
    notifyListeners();
  }

  /// Fetch catalog products from Laravel backend API
  Future<List<ProductModel>> fetchCatalogRemote({
    String? query,
    String? category,
    String? sort,
    double? minPrice,
    double? maxPrice,
    String? sellerId,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (query != null && query.isNotEmpty) queryParams['q'] = query;
      if (category != null && category.isNotEmpty && category != 'All' && category != 'Mall') {
        queryParams['category'] = category;
      }
      if (sort != null && sort.isNotEmpty) queryParams['sort'] = sort;
      if (minPrice != null) queryParams['min_price'] = minPrice.toString();
      if (maxPrice != null) queryParams['max_price'] = maxPrice.toString();
      if (sellerId != null && sellerId.isNotEmpty) queryParams['seller_id'] = sellerId;

      final uri = Uri(path: ApiConstants.buyerCatalog, queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final res = await ApiClient.instance.get(uri.toString());
      final data = res['data'];
      final List list = data is List ? data : (data is Map && data['data'] is List ? data['data'] : []);
      return list.map((item) => ProductModel.fromApiJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('fetchCatalogRemote error: $e');
      return [];
    }
  }

  /// Fetch single product detail from Laravel backend API
  Future<ProductModel?> fetchProductRemote(String id) async {
    try {
      final res = await ApiClient.instance.get(ApiConstants.buyerProduct(id));
      if (res['data'] is Map<String, dynamic>) {
        return ProductModel.fromApiJson(res['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('fetchProductRemote error: $e');
      return null;
    }
  }

  /// Toggle wishlist on Laravel backend API
  Future<bool> toggleWishlistRemote(String productId) async {
    if (!ApiClient.instance.hasToken) return false;
    try {
      final res = await ApiClient.instance.post(ApiConstants.buyerWishlistToggle(productId));
      return res['data']?['wishlisted'] == true;
    } catch (e) {
      debugPrint('toggleWishlistRemote error: $e');
      return false;
    }
  }

  /// Toggle follow store on Laravel backend API
  Future<bool> toggleFollowRemote(String sellerId) async {
    toggleFollow(sellerId);
    if (!ApiClient.instance.hasToken) return isFollowing(sellerId);
    try {
      final res = await ApiClient.instance.post(ApiConstants.buyerStoreFollowToggle(sellerId));
      return res['data']?['following'] == true;
    } catch (e) {
      debugPrint('toggleFollowRemote error: $e');
      return isFollowing(sellerId);
    }
  }

  /// Claim voucher on Laravel backend API
  Future<bool> claimVoucherRemote(String voucherId) async {
    claimVoucher(voucherId);
    if (!ApiClient.instance.hasToken) return true;
    try {
      await ApiClient.instance.post(ApiConstants.buyerVoucherClaim(voucherId));
      return true;
    } catch (e) {
      debugPrint('claimVoucherRemote error: $e');
      return false;
    }
  }

  bool isVoucherClaimed(String voucherId) => _currentClaimedVouchers.contains(voucherId);

  void claimVoucher(String voucherId) {
    _currentClaimedVouchers.add(voucherId);
    notifyListeners();
  }

  List<ShopVoucherModel> getClaimedVouchersForShop(String shopId) {
    final shop = getShopById(shopId);
    return shop.vouchers.where((v) => isVoucherClaimed(v.id)).toList();
  }

  List<ShopVoucherModel> getAvailableVouchersForShop(String shopId) {
    final shop = getShopById(shopId);
    return shop.vouchers;
  }

  List<ShopVoucherModel> getAllClaimedVouchers() {
    final List<ShopVoucherModel> list = [];
    for (final s in allShops) {
      for (final v in s.vouchers) {
        if (isVoucherClaimed(v.id)) {
          list.add(v);
        }
      }
    }
    return list;
  }

  bool hasLikedReview(String reviewId) => _userUpvotedReviews.contains(reviewId);

  int getReviewHelpfulCount(String reviewId, int initialCount) {
    return (initialCount) + (_helpfulVotes[reviewId] ?? 0);
  }

  void toggleReviewLike(String reviewId) {
    if (_userUpvotedReviews.contains(reviewId)) {
      _userUpvotedReviews.remove(reviewId);
      _helpfulVotes[reviewId] = (_helpfulVotes[reviewId] ?? 0) - 1;
    } else {
      _userUpvotedReviews.add(reviewId);
      _helpfulVotes[reviewId] = (_helpfulVotes[reviewId] ?? 0) + 1;
    }
    notifyListeners();
  }

  /// Browse, Search, Typo Suggestion, and Multi-Filter Engine
  SearchResult searchAndFilter(SearchFilterParams params) {
    if (!BuyerAccountService.instance.isNetworkConnected) {
      return const SearchResult(
        products: [],
        errorMessage: 'No internet connection. Please check your network and try again.',
      );
    }

    if (params.minPrice != null && params.minPrice! < 0) {
      return const SearchResult(
        products: [],
        errorMessage: 'Price cannot be negative',
      );
    }
    if (params.maxPrice != null && params.maxPrice! < 0) {
      return const SearchResult(
        products: [],
        errorMessage: 'Price cannot be negative',
      );
    }
    if (params.minPrice != null && params.maxPrice != null && params.minPrice! > params.maxPrice!) {
      return const SearchResult(
        products: [],
        errorMessage: 'Minimum price cannot be greater than maximum price',
      );
    }

    final rawQuery = params.query.trim().toLowerCase();
    String? typoSuggestion;

    final isTypoRattan = rawQuery == 'ratan baskit' ||
        rawQuery == 'ratan basket' ||
        rawQuery == 'ratan' ||
        rawQuery == 'rattan baskit';
    if (isTypoRattan) {
      typoSuggestion = 'Did you mean "Rattan Fruit Basket"?';
    }

    List<ProductModel> results = allAppProducts.where((p) => p.isActive).toList();

    if (rawQuery.isNotEmpty) {
      if (isTypoRattan) {
        results = results.where((p) => p.title.toLowerCase().contains('rattan')).toList();
      } else {
        results = results.where((p) {
          final titleMatch = p.title.toLowerCase().contains(rawQuery);
          final descMatch = p.description?.toLowerCase().contains(rawQuery) ?? false;
          final catMatch = p.category.toLowerCase().contains(rawQuery);
          return titleMatch || descMatch || catMatch;
        }).toList();
      }
    }

    if (params.category != null && params.category!.isNotEmpty && params.category != 'All') {
      results = results.where((p) => p.category.toLowerCase() == params.category!.toLowerCase()).toList();
    }

    if (params.location != null && params.location!.isNotEmpty && params.location != 'All') {
      results = results.where((p) => p.location.toLowerCase() == params.location!.toLowerCase()).toList();
    }

    if (params.minRating != null) {
      results = results.where((p) => p.rating >= params.minRating!).toList();
    }

    if (params.minPrice != null) {
      results = results.where((p) {
        final priceNum = _parsePrice(p.price);
        return priceNum >= params.minPrice!;
      }).toList();
    }
    if (params.maxPrice != null) {
      results = results.where((p) {
        final priceNum = _parsePrice(p.price);
        return priceNum <= params.maxPrice!;
      }).toList();
    }

    switch (params.sortBy) {
      case 'price_asc':
        results.sort((a, b) => _parsePrice(a.price).compareTo(_parsePrice(b.price)));
        break;
      case 'price_desc':
        results.sort((a, b) => _parsePrice(b.price).compareTo(_parsePrice(a.price)));
        break;
      case 'best_selling':
        results.sort((a, b) => _parseSoldCount(b.soldCount).compareTo(_parseSoldCount(a.soldCount)));
        break;
      case 'rating':
        results.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'latest':
      default:
        break;
    }

    return SearchResult(
      products: results,
      typoSuggestion: typoSuggestion,
    );
  }

  static double _parsePrice(String priceStr) {
    final clean = priceStr.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(clean) ?? 0.0;
  }

  static int _parseSoldCount(String soldStr) {
    final clean = soldStr.replaceAll(RegExp(r'[^0-9kK.+]'), '').toLowerCase();
    if (clean.contains('k')) {
      final numPart = double.tryParse(clean.replaceAll('k', '').replaceAll('+', '')) ?? 1.0;
      return (numPart * 1000).toInt();
    }
    return int.tryParse(clean.replaceAll('+', '')) ?? 0;
  }

  // -------------------------------------------------------------
  // STORE DIRECTORY & ACCOUNT REGISTRY
  // Separate official accounts for Home & Living, Apparel, Gaming, Audio, and Jewelry
  // -------------------------------------------------------------
  List<ShopModel> get allShops => [
        nexoraLivingStore,
        auraStudiosStore,
        apexGamingStore,
        nexoraAudioStore,
        soundMaxAudioStore,
        mikanaJewelryStore,
        nexoraOfficialStore,
      ];

  ShopModel getShopById(String? shopId) {
    if (shopId == null || shopId.isEmpty) return nexoraOfficialStore;
    final lower = shopId.toLowerCase();
    if (lower == 'logitech_hub') return apexGamingStore;
    if (lower == 'craft_ph' || lower == 'green_tropics') return nexoraLivingStore;
    return allShops.firstWhere(
      (s) => s.id.toLowerCase() == lower,
      orElse: () => nexoraOfficialStore,
    );
  }

  ShopModel getShopForProduct(ProductModel product) {
    return getShopById(product.shopId);
  }

  ProductModel? getProductById(String? id) {
    if (id == null || id.isEmpty) return null;
    try {
      return products.firstWhere(
        (p) => p.id.toLowerCase() == id.toLowerCase(),
      );
    } catch (_) {
      try {
        return allAppProducts.firstWhere(
          (p) => p.id.toLowerCase() == id.toLowerCase(),
        );
      } catch (_) {
        return null;
      }
    }
  }

  // -------------------------------------------------------------
  // 1. HOME & LIVING STORE ACCOUNT: Nexora Living & Essentials
  // -------------------------------------------------------------
  static final ShopModel nexoraLivingStore = ShopModel(
    id: 'nexora_home_living',
    name: 'Nexora Living & Essentials',
    badge: 'OFFICIAL STORE',
    rating: 4.9,
    followers: '112.4K',
    initials: 'NL\nHOME',
    avatarBg: const Color(0xFFD97706),
    categoryGroupTitle: 'NORDIC HOME DECOR & ARTISAN ESSENTIALS',
    categories: const [
      ShopCategoryModel(
        id: 'nl_woven',
        title: 'Handwoven Rattan Organizers',
        itemCount: 18,
        imageUrl:
            'https://images.unsplash.com/photo-1544816155-12df9643f363?auto=format&fit=crop&w=400&q=80',
      ),
      ShopCategoryModel(
        id: 'nl_drink',
        title: 'Thermal Stainless Drinkware',
        itemCount: 12,
        imageUrl:
            'https://images.unsplash.com/photo-1602143407151-7111542de6e8?auto=format&fit=crop&w=400&q=80',
      ),
      ShopCategoryModel(
        id: 'nl_decor',
        title: 'Indoor Planters & Flora Baskets',
        itemCount: 15,
        imageUrl:
            'https://images.unsplash.com/photo-1513519245088-0e12902e5a38?auto=format&fit=crop&w=400&q=80',
      ),
      ShopCategoryModel(
        id: 'nl_dining',
        title: 'Minimalist Dining & Serving Trays',
        itemCount: 9,
        imageUrl:
            'https://images.unsplash.com/photo-1530595467537-0b5996c41f2d?auto=format&fit=crop&w=400&q=80',
      ),
    ],
    vouchers: const [
      ShopVoucherModel(
        id: 'nl_v1',
        discountTitle: '₱100 OFF',
        tag: 'Store Voucher',
        minSpend: 'Min. spend ₱1,200',
        expiry: 'Exp: 31.12.2026',
        buttonColor: Color(0xFF00C2FF),
        discountAmount: 100,
      ),
      ShopVoucherModel(
        id: 'nl_v2',
        discountTitle: '10% OFF',
        tag: 'Home VIP',
        minSpend: 'Min. spend ₱2,500',
        expiry: 'Exp: 31.12.2026',
        buttonColor: Color(0xFFD97706),
        discountAmount: 0.10,
        isPercentage: true,
      ),
    ],
  );

  // -------------------------------------------------------------
  // 2. APPAREL & FASHION STORE ACCOUNT: Aura Streetwear Official
  // -------------------------------------------------------------
  static final ShopModel auraStudiosStore = ShopModel(
    id: 'aura_studios',
    name: 'Aura Streetwear Official',
    badge: 'OFFICIAL STORE',
    rating: 4.9,
    followers: '185.3K',
    initials: 'AS\nURBAN',
    avatarBg: const Color(0xFF1E293B),
    categoryGroupTitle: 'URBAN STREETWEAR & HEAVYWEIGHT BASICS',
    categories: const [
      ShopCategoryModel(
        id: 'as_hoodies',
        title: '450GSM Heavy Fleece Hoodies',
        itemCount: 14,
        imageUrl:
            'https://images.unsplash.com/photo-1556905055-8f358a7a47b2?auto=format&fit=crop&w=400&q=80',
      ),
      ShopCategoryModel(
        id: 'as_tees',
        title: 'Heavyweight Boxy Graphic Tees',
        itemCount: 26,
        imageUrl:
            'https://images.unsplash.com/photo-1583743814966-8936f5b7be1a?auto=format&fit=crop&w=400&q=80',
      ),
      ShopCategoryModel(
        id: 'as_linen',
        title: 'Breathable Natural Linen Shirts',
        itemCount: 16,
        imageUrl:
            'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?auto=format&fit=crop&w=400&q=80',
      ),
      ShopCategoryModel(
        id: 'as_cargos',
        title: 'Tactical Multi-Pocket Cargos',
        itemCount: 10,
        imageUrl:
            'https://images.unsplash.com/photo-1552902865-b72c031ac5ea?auto=format&fit=crop&w=400&q=80',
      ),
    ],
    vouchers: const [
      ShopVoucherModel(
        id: 'as_v1',
        discountTitle: '₱80 OFF',
        tag: 'First Order',
        minSpend: 'Min. spend ₱999',
        expiry: 'Exp: 31.12.2026',
        buttonColor: Color(0xFF00C2FF),
        discountAmount: 80,
      ),
      ShopVoucherModel(
        id: 'as_v2',
        discountTitle: '15% OFF',
        tag: 'Street Drop',
        minSpend: 'Min. spend ₱2,500',
        expiry: 'Exp: 31.12.2026',
        buttonColor: Color(0xFF0F172A),
        discountAmount: 0.15,
        isPercentage: true,
      ),
    ],
  );

  // -------------------------------------------------------------
  // 3. GAMING STORE ACCOUNT: Apex Esports Gear Labs
  // -------------------------------------------------------------
  static final ShopModel apexGamingStore = ShopModel(
    id: 'apex_gaming',
    name: 'Apex Esports Gear Labs',
    badge: 'OFFICIAL STORE',
    rating: 4.9,
    followers: '248.9K',
    initials: 'AP\nGEAR',
    avatarBg: const Color(0xFF0F172A),
    categoryGroupTitle: 'ESPORTS GAMING PERIPHERALS & MODDING',
    categories: const [
      ShopCategoryModel(
        id: 'apex_kb',
        title: 'Custom 75% Mechanical Keyboards',
        itemCount: 18,
        imageUrl:
            'https://images.unsplash.com/photo-1587829741301-dc798b83add3?auto=format&fit=crop&w=400&q=80',
      ),
      ShopCategoryModel(
        id: 'apex_mouse',
        title: 'Ultra-Lightweight 8K Esports Mice',
        itemCount: 14,
        imageUrl:
            'https://images.unsplash.com/photo-1615663245857-ac93bb7c39e7?auto=format&fit=crop&w=400&q=80',
      ),
      ShopCategoryModel(
        id: 'apex_pad',
        title: 'Precision Cordura Desk Mats',
        itemCount: 12,
        imageUrl:
            'https://images.unsplash.com/photo-1541140590914-579f21e6b72d?auto=format&fit=crop&w=400&q=80',
      ),
      ShopCategoryModel(
        id: 'apex_caps',
        title: 'Doubleshot PBT Dye-Sub Keycaps',
        itemCount: 22,
        imageUrl:
            'https://images.unsplash.com/photo-1595225476474-87563907a212?auto=format&fit=crop&w=400&q=80',
      ),
    ],
    vouchers: const [
      ShopVoucherModel(
        id: 'ap_v1',
        discountTitle: '₱150 OFF',
        tag: 'Gamer Pass',
        minSpend: 'Min. spend ₱2,000',
        expiry: 'Exp: 31.12.2026',
        buttonColor: Color(0xFF00C2FF),
        discountAmount: 150,
      ),
      ShopVoucherModel(
        id: 'ap_v2',
        discountTitle: '12% OFF',
        tag: 'Esports VIP',
        minSpend: 'Min. spend ₱3,500',
        expiry: 'Exp: 31.12.2026',
        buttonColor: Color(0xFF050B28),
        discountAmount: 0.12,
        isPercentage: true,
      ),
    ],
  );

  // -------------------------------------------------------------
  // 4. STUDIO & AUDIO STORE ACCOUNT: Nexora Studio Audio Official
  // -------------------------------------------------------------
  static final ShopModel nexoraAudioStore = ShopModel(
    id: 'nexora_audio',
    name: 'Nexora Studio Audio Official',
    badge: 'OFFICIAL STORE',
    rating: 4.9,
    followers: '129.4K',
    initials: 'NS\nAUDIO',
    avatarBg: const Color(0xFF001233),
    categoryGroupTitle: 'BROADCAST & PODCAST STUDIO AUDIO',
    categories: const [
      ShopCategoryModel(
        id: 'aud_mic',
        title: 'Broadcast Dynamic Microphones',
        itemCount: 16,
        imageUrl:
            'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?auto=format&fit=crop&w=400&q=80',
      ),
      ShopCategoryModel(
        id: 'aud_usb',
        title: 'Streaming USB Condenser Mics',
        itemCount: 18,
        imageUrl:
            'https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?auto=format&fit=crop&w=400&q=80',
      ),
      ShopCategoryModel(
        id: 'aud_arms',
        title: 'Heavy Duty Suspension Boom Arms',
        itemCount: 12,
        imageUrl:
            'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=400&q=80',
      ),
      ShopCategoryModel(
        id: 'aud_lav',
        title: 'Wireless Lavalier Lapel Kits',
        itemCount: 10,
        imageUrl:
            'https://images.unsplash.com/photo-1545454675-3531b543be5d?auto=format&fit=crop&w=400&q=80',
      ),
    ],
    vouchers: const [
      ShopVoucherModel(
        id: 'na_v1',
        discountTitle: '₱120 OFF',
        tag: 'Studio',
        minSpend: 'Min. spend ₱1,800',
        expiry: 'Exp: 31.12.2026',
        buttonColor: Color(0xFF00C2FF),
        discountAmount: 120,
      ),
      ShopVoucherModel(
        id: 'na_v2',
        discountTitle: '10% OFF',
        tag: 'Pro Audio',
        minSpend: 'Min. spend ₱3,500',
        expiry: 'Exp: 31.12.2026',
        buttonColor: Color(0xFF050B28),
        discountAmount: 0.10,
        isPercentage: true,
      ),
    ],
  );

  // -------------------------------------------------------------
  // 5. HI-FI AUDIO: SoundMax Pro Audio
  // -------------------------------------------------------------
  static final ShopModel soundMaxAudioStore = ShopModel(
    id: 'soundmax_audio',
    name: 'SoundMax Pro Audio',
    badge: 'OFFICIAL STORE',
    rating: 4.9,
    followers: '84.2K',
    initials: 'SM\nPRO',
    avatarBg: const Color(0xFF1E1B4B),
    categoryGroupTitle: 'PRO HI-FI AUDIO & SOUND SYSTEMS',
    categories: const [
      ShopCategoryModel(
        id: 'sm_headphones',
        title: 'Studio Over-Ear Headphones',
        itemCount: 22,
        imageUrl:
            'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=400&q=80',
      ),
      ShopCategoryModel(
        id: 'sm_speakers',
        title: 'Spatial Audio Speakers',
        itemCount: 16,
        imageUrl:
            'https://images.unsplash.com/photo-1545454675-3531b543be5d?auto=format&fit=crop&w=400&q=80',
      ),
    ],
    vouchers: const [
      ShopVoucherModel(
        id: 'sm_v1',
        discountTitle: '₱150 OFF',
        tag: 'Store',
        minSpend: 'Min. spend ₱2,500',
        expiry: 'Exp: 31.12.2026',
        buttonColor: Color(0xFF00C2FF),
        discountAmount: 150,
      ),
    ],
  );

  // -------------------------------------------------------------
  // 6. JEWELRY: Mikana Jewelry & Co.
  // -------------------------------------------------------------
  static final ShopModel mikanaJewelryStore = ShopModel(
    id: 'mikana_official',
    name: 'Mikana Jewelry & Co.',
    badge: 'OFFICIAL STORE',
    rating: 4.8,
    followers: '96.5K',
    initials: 'MK\nJEWEL',
    avatarBg: const Color(0xFF701A75),
    categoryGroupTitle: 'JAPANESE 18K GOLD & LUXURY PIECES',
    categories: const [
      ShopCategoryModel(
        id: 'mk_necklaces',
        title: 'Pendant Necklaces',
        itemCount: 48,
        imageUrl:
            'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?auto=format&fit=crop&w=400&q=80',
      ),
    ],
    vouchers: const [
      ShopVoucherModel(
        id: 'mk_v1',
        discountTitle: '₱120 OFF',
        tag: 'Store',
        minSpend: 'Min. spend ₱1,800',
        expiry: 'Exp: 31.12.2026',
        buttonColor: Color(0xFF00C2FF),
        discountAmount: 120,
      ),
    ],
  );

  // -------------------------------------------------------------
  // 7. FLAGSHIP: Nexora Official Flagship
  // -------------------------------------------------------------
  static final ShopModel nexoraOfficialStore = ShopModel(
    id: 'nexora_official',
    name: 'Nexora Official Flagship',
    badge: 'OFFICIAL STORE',
    rating: 4.9,
    followers: '320.5K',
    initials: 'N\nMALL',
    avatarBg: const Color(0xFF0066FF),
    categoryGroupTitle: 'FLAGSHIP INNOVATION & TECH ECOSYSTEM',
    categories: const [
      ShopCategoryModel(
        id: 'nx_tech',
        title: 'Flagship Tech & Peripherals',
        itemCount: 45,
        imageUrl:
            'https://images.unsplash.com/photo-1587829741301-dc798b83add3?auto=format&fit=crop&w=400&q=80',
      ),
    ],
    vouchers: const [
      ShopVoucherModel(
        id: 'nx_v1',
        discountTitle: '₱100 OFF',
        tag: 'Welcome',
        minSpend: 'Min. spend ₱1,000',
        expiry: 'Exp: 31.12.2026',
        buttonColor: Color(0xFF050B28),
        discountAmount: 100,
      ),
    ],
  );

  // -------------------------------------------------------------
  // PRODUCTS REPOSITORY
  // -------------------------------------------------------------
  List<ProductModel> getProductsByShop(String shopId) {
    return allAppProducts.where((p) => p.shopId.toLowerCase() == shopId.toLowerCase()).toList();
  }

  List<ProductModel> getFlashDealsByShop(String shopId) {
    final list = getProductsByShop(shopId);
    if (list.length >= 2) return list.take(2).toList();
    return list;
  }

  List<ProductModel> getPopularProductsByShop(String shopId) {
    return getProductsByShop(shopId);
  }

  // -------------------------------------------------------------
  // ALL PRODUCTS IN APPLICATION
  // Every product has unique images, unique descriptions, category specs, and matching shop
  // -------------------------------------------------------------
  static final List<ProductModel> allAppProducts = [
    // 1. BOOM ARM (Nexora Studio Audio) - Genuine boom arm setup
    ProductModel(
      id: 'AUD-BOOM-01',
      title: 'Nexora Pro Heavy Duty Suspension Boom Arm',
      imageUrl:
          'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=600&q=80',
      galleryImages: const [
        'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?auto=format&fit=crop&w=600&q=80',
      ],
      category: 'Audio',
      isMall: true,
      discountTag: '-35%',
      price: '₱899',
      originalPrice: '₱1,400',
      rating: 4.8,
      soldCount: '3.2K',
      shippingTag: 'Free Shipping',
      hasPayLater: false,
      hasVoucher: true,
      shopId: 'nexora_audio',
      shopName: 'Nexora Studio Audio Official',
      shopBadge: 'OFFICIAL STORE',
      stockQuantity: 210,
      description:
          'Heavy-duty alloy suspension boom arm engineered with concealed internal tension springs and integrated cable management channels. Holds up to 2.2kg payload without sagging or squeaking during live broadcasts.',
      specs: const [
        {
          'icon': Icons.fitness_center,
          'title': '2.2kg Payload',
          'subtitle': 'Supports heavy mics like Shure SM7B, Blue Yeti, and Rode Procaster.',
        },
        {
          'icon': Icons.rotate_right,
          'title': '360° Silent Swivel',
          'subtitle': 'Dual-pivot internal springs allow fluid, squeak-free live adjustments.',
        },
        {
          'icon': Icons.cable,
          'title': 'Concealed Channels',
          'subtitle': 'Integrated snap-in cable ducts keep XLR and USB wires completely hidden.',
        },
        {
          'icon': Icons.table_restaurant,
          'title': 'Reinforced C-Clamp',
          'subtitle': 'Padded steel clamp firmly mounts to tabletops up to 60mm thick.',
        },
      ],
      ratingBreakdown: const {5: 0.85, 4: 0.12, 3: 0.03, 2: 0.0, 1: 0.0},
      variantGroups: const [
        ProductVariantGroup(
          groupName: 'Finish',
          options: [
            ProductVariantOption(
              id: 'arm_blk',
              name: 'Matte Industrial Black',
              colorHex: Color(0xFF27272A),
              subtitle: 'Scratch-resistant powder coating',
              stock: 120,
            ),
            ProductVariantOption(
              id: 'arm_slv',
              name: 'Brushed Space Silver',
              colorHex: Color(0xFF94A3B8),
              subtitle: 'Anodized aluminum alloy finish',
              stock: 90,
            ),
          ],
        ),
      ],
      reviews: [
        ProductReviewModel(
          id: 'rev_arm1',
          userName: 'Gabriel Lim',
          initials: 'GL',
          avatarColor: const Color(0xFF16A34A),
          rating: 5.0,
          date: '3 days ago',
          variantName: 'Matte Industrial Black',
          comment:
              'No sagging even with heavy Shure SM7B + Cloudlifter setup! Internal springs mean completely silent adjustments during live calls.',
          helpfulCount: 33,
        ),
      ],
    ),

    // 2. CONDENSER MIC (Nexora Studio Audio) - Genuine USB Condenser Mic
    ProductModel(
      id: 'AUD-MIC-02',
      title: 'Nexora DGM20S USB Condenser Mic with Boom Arm',
      imageUrl:
          'https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?auto=format&fit=crop&w=600&q=80',
      galleryImages: const [
        'https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=600&q=80',
      ],
      category: 'Audio',
      isMall: true,
      discountTag: '-48%',
      price: '₱1,549',
      originalPrice: '₱2,000',
      rating: 4.9,
      soldCount: '10K+',
      shippingTag: 'Free Shipping',
      hasPayLater: false,
      hasVoucher: true,
      shopId: 'nexora_audio',
      shopName: 'Nexora Studio Audio Official',
      shopBadge: 'OFFICIAL STORE',
      stockQuantity: 140,
      description:
          'All-in-one USB streaming condenser microphone featuring one-touch ENC active noise cancellation, zero-latency 3.5mm monitoring jack, responsive tap-to-mute sensor, and dynamic gradient RGB aura.',
      specs: const [
        {
          'icon': Icons.mic,
          'title': 'Cardioid Condenser',
          'subtitle': '14mm custom condenser capsule captures crisp studio voice presence.',
        },
        {
          'icon': Icons.noise_control_off,
          'title': 'One-Touch ENC',
          'subtitle': 'Smart hardware filter cuts AC humming and keyboard clatter instantly.',
        },
        {
          'icon': Icons.headset,
          'title': 'Zero-Latency Jack',
          'subtitle': '3.5mm real-time earphone monitoring with dedicated gain volume dial.',
        },
        {
          'icon': Icons.palette,
          'title': 'RGB Gradient Aura',
          'subtitle': '8 dynamic lighting effects with touch-sensitive top mute sensor.',
        },
      ],
      ratingBreakdown: const {5: 0.91, 4: 0.07, 3: 0.02, 2: 0.0, 1: 0.0},
      variantGroups: const [
        ProductVariantGroup(
          groupName: 'Color Edition',
          options: [
            ProductVariantOption(
              id: 'dgm_blk',
              name: 'Midnight Black',
              colorHex: Color(0xFF0F172A),
              subtitle: 'Stealth black matte body with RGB ring',
              stock: 75,
            ),
            ProductVariantOption(
              id: 'dgm_wht',
              name: 'Pure Arctic White',
              colorHex: Color(0xFFF8FAFC),
              subtitle: 'Frost white ceramic finish',
              stock: 65,
            ),
          ],
        ),
        ProductVariantGroup(
          groupName: 'Filter Package',
          options: [
            ProductVariantOption(
              id: 'pkg_std',
              name: 'Foam Pop Shield',
              subtitle: 'High density acoustic foam windsock',
              stock: 70,
            ),
            ProductVariantOption(
              id: 'pkg_mesh',
              name: 'Metal Mesh Pop Filter',
              subtitle: 'Dual-layer stainless steel dispersion (+₱150)',
              priceOffset: 150,
              stock: 70,
            ),
          ],
        ),
      ],
      reviews: [
        ProductReviewModel(
          id: 'rev_dgm1',
          userName: 'Kevin Matthew Cruz',
          initials: 'KC',
          avatarColor: const Color(0xFF2563EB),
          rating: 5.0,
          date: '2 days ago',
          variantName: 'Midnight Black • Foam Pop Shield',
          comment:
              'The tap-to-mute button on top with the LED status light is so convenient during Valorant calls. Noise cancellation works wonders for my loud mechanical keyboard.',
          helpfulCount: 45,
        ),
      ],
    ),

    // 3. APPAREL: Graphic Streetwear Tee (Yahweh Yireh Black Tee from Screenshot 2)
    ProductModel(
      id: 'APP-TEE-01',
      title: 'Aura Boxy Heavyweight Graphic Streetwear Tee',
      imageUrl:
          'https://images.unsplash.com/photo-1583743814966-8936f5b7be1a?auto=format&fit=crop&w=600&q=80',
      galleryImages: const [
        'https://images.unsplash.com/photo-1583743814966-8936f5b7be1a?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1503342217505-b0a15ec3261c?auto=format&fit=crop&w=600&q=80',
      ],
      category: 'Apparel & Fashion',
      isMall: true,
      discountTag: '-42%',
      price: '₱699.00',
      originalPrice: '₱1,199',
      rating: 4.9,
      soldCount: '4.7K',
      shippingTag: '2-3 Days | Metro Manila',
      hasPayLater: false,
      hasVoucher: true,
      shopId: 'aura_studios',
      shopName: 'Aura Streetwear Official',
      shopBadge: 'OFFICIAL STORE',
      stockQuantity: 180,
      description:
          'Signature 280GSM heavyweight combed organic cotton streetwear t-shirt featuring high-density puff chest typography, thick reinforced ribbed collar that never sags, and an effortless drop-shoulder boxy silhouette.',
      specs: const [
        {
          'icon': Icons.checkroom,
          'title': '280GSM Heavyweight',
          'subtitle': '100% combed ring-spun organic cotton with luxurious substantial hand-feel.',
        },
        {
          'icon': Icons.straighten,
          'title': 'Boxy Drop-Shoulder',
          'subtitle': 'Engineered streetwear drape that holds its structural silhouette all day.',
        },
        {
          'icon': Icons.format_paint,
          'title': 'High-Density Puff Print',
          'subtitle': 'Textured tactile chest lettering guaranteed against cracking in the wash.',
        },
        {
          'icon': Icons.wash,
          'title': 'Pre-Shrunk Cotton',
          'subtitle': 'Pre-washed and enzyme-treated for zero shrinkage and ultra-soft comfort.',
        },
      ],
      variantGroups: const [
        ProductVariantGroup(
          groupName: 'Color',
          options: [
            ProductVariantOption(
              id: 'tee_blk',
              name: 'Vintage Jet Black',
              colorHex: Color(0xFF18181B),
              stock: 90,
            ),
            ProductVariantOption(
              id: 'tee_wht',
              name: 'Pure Chalk White',
              colorHex: Color(0xFFF8FAFC),
              stock: 50,
            ),
            ProductVariantOption(
              id: 'tee_oat',
              name: 'Warm Oat Heather',
              colorHex: Color(0xFFE2E8F0),
              stock: 40,
            ),
          ],
        ),
        ProductVariantGroup(
          groupName: 'Size',
          options: [
            ProductVariantOption(id: 'sz_s', name: 'Size S (Relaxed)', stock: 35),
            ProductVariantOption(id: 'sz_m', name: 'Size M (Boxy)', stock: 55),
            ProductVariantOption(id: 'sz_l', name: 'Size L (Oversized)', stock: 50),
            ProductVariantOption(id: 'sz_xl', name: 'Size XL (Baggy)', stock: 40),
          ],
        ),
      ],
      reviews: [
        ProductReviewModel(
          id: 'rev_tee1',
          userName: 'Christian Reyes',
          initials: 'CR',
          avatarColor: const Color(0xFF8B5CF6),
          rating: 5.0,
          date: 'Yesterday',
          variantName: 'Vintage Jet Black • Size M (Boxy)',
          comment:
              'The fabric thickness is amazing! Feels like a high-end designer tee. The collar stays crisp and the puff print has nice depth.',
          helpfulCount: 29,
        ),
      ],
    ),

    // 4. APPAREL: Minimalist Heavy Fleece Hoodie
    ProductModel(
      id: 'APP-HOOD-02',
      title: 'Aura Minimalist Heavy Fleece Hoodie Streetwear',
      imageUrl:
          'https://images.unsplash.com/photo-1556905055-8f358a7a47b2?auto=format&fit=crop&w=600&q=80',
      galleryImages: const [
        'https://images.unsplash.com/photo-1556905055-8f358a7a47b2?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1503342217505-b0a15ec3261c?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?auto=format&fit=crop&w=600&q=80',
      ],
      category: 'Apparel & Fashion',
      isMall: true,
      discountTag: '-22%',
      price: '₱1,250.00',
      originalPrice: '₱1,600',
      rating: 4.8,
      soldCount: '840',
      shippingTag: '2-3 Days | Metro Manila',
      hasPayLater: false,
      hasVoucher: true,
      shopId: 'aura_studios',
      shopName: 'Aura Streetwear Official',
      shopBadge: 'OFFICIAL STORE',
      stockQuantity: 150,
      description:
          '450GSM ultra-heavy brushed cotton fleece hoodie with a double-layered structured hood, seamless drop shoulders, hidden interior pocket, and ribbed stretch cuffs.',
      specs: const [
        {
          'icon': Icons.ac_unit,
          'title': '450GSM Fleece',
          'subtitle': 'Dense heavyweight fleece for maximum warmth in air-conditioned offices.',
        },
        {
          'icon': Icons.layers,
          'title': 'Double-Layer Hood',
          'subtitle': 'Structured two-panel hood stays upright without flopping.',
        },
        {
          'icon': Icons.lock,
          'title': 'Hidden Tech Pocket',
          'subtitle': 'Concealed zippered pouch inside kangaroo pocket for cards and keys.',
        },
        {
          'icon': Icons.verified,
          'title': 'Reinforced Seams',
          'subtitle': 'Bar-tacked stress points and triple-stitched hems for years of wear.',
        },
      ],
      variantGroups: const [
        ProductVariantGroup(
          groupName: 'Color',
          options: [
            ProductVariantOption(
              id: 'hood_oat',
              name: 'Warm Oatmeal Heather',
              colorHex: Color(0xFFE2E8F0),
              stock: 50,
            ),
            ProductVariantOption(
              id: 'hood_char',
              name: 'Washed Charcoal',
              colorHex: Color(0xFF334155),
              stock: 60,
            ),
            ProductVariantOption(
              id: 'hood_blk',
              name: 'Vintage Jet Black',
              colorHex: Color(0xFF0F172A),
              stock: 40,
            ),
          ],
        ),
        ProductVariantGroup(
          groupName: 'Size',
          options: [
            ProductVariantOption(id: 'h_s', name: 'Size S (Relaxed)', stock: 35),
            ProductVariantOption(id: 'h_m', name: 'Size M (Boxy)', stock: 45),
            ProductVariantOption(id: 'h_l', name: 'Size L (Oversized)', stock: 40),
            ProductVariantOption(id: 'h_xl', name: 'Size XL (Baggy)', stock: 30),
          ],
        ),
      ],
      reviews: [
        ProductReviewModel(
          id: 'rev_aura1',
          userName: 'Gianina Marie Soriano',
          initials: 'GS',
          avatarColor: const Color(0xFF8B5CF6),
          rating: 5.0,
          date: '5 days ago',
          variantName: 'Warm Oatmeal Heather • Size M (Boxy)',
          comment:
              'Material is super thick and structured! Doesn\'t flop around like cheap polyester hoodies. The hood stands up nicely.',
          helpfulCount: 39,
        ),
      ],
    ),

    // 5. APPAREL: Tailored Linen Blend Shirt P-01
    ProductModel(
      id: 'P-01',
      title: 'Nexora Tailored Linen Blend Shirt P-01',
      imageUrl:
          'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?auto=format&fit=crop&w=600&q=80',
      category: 'Apparel & Fashion',
      location: 'Metro Manila',
      isMall: true,
      price: '₱199.00',
      originalPrice: '₱299.00',
      rating: 4.9,
      soldCount: '2.5K',
      shippingTag: 'Standard Delivery',
      hasPayLater: false,
      hasVoucher: true,
      shopId: 'aura_studios',
      shopName: 'Aura Streetwear Official',
      shopBadge: 'OFFICIAL STORE',
      stockQuantity: 25,
      galleryImages: const [
        'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1583743814966-8936f5b7be1a?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1503342217505-b0a15ec3261c?auto=format&fit=crop&w=600&q=80',
      ],
      description:
          'Lightweight resort shirt tailored from 65% French linen and 35% natural organic cotton. Breathable slub texture keeps you cool under the Philippine tropical sun while maintaining a crisp, polished drape.',
      specs: const [
        {
          'icon': Icons.eco,
          'title': 'Natural Linen Blend',
          'subtitle': '65% French flax linen combined with 35% soft breathable organic cotton.',
        },
        {
          'icon': Icons.air,
          'title': 'Airflow Open Weave',
          'subtitle': 'Naturally wicks moisture and dries quickly in high humidity.',
        },
        {
          'icon': Icons.lens,
          'title': 'Pearl Shell Buttons',
          'subtitle': 'Polished genuine mother-of-pearl cross-stitched button closures.',
        },
        {
          'icon': Icons.wb_sunny,
          'title': 'Camp Resort Collar',
          'subtitle': 'Relaxed open notch collar perfect for weekend getaways and beach trips.',
        },
      ],
      variantGroups: const [
        ProductVariantGroup(
          groupName: 'Color',
          options: [
            ProductVariantOption(
              id: 'col_nat',
              name: 'Natural',
              colorHex: Color(0xFFD4C5B9),
              stock: 15,
            ),
            ProductVariantOption(
              id: 'col_blk',
              name: 'Black',
              colorHex: Color(0xFF1E293B),
              stock: 10,
            ),
          ],
        ),
        ProductVariantGroup(
          groupName: 'Size',
          options: [
            ProductVariantOption(id: 'sz_s', name: 'S', stock: 10),
            ProductVariantOption(id: 'sz_m', name: 'M', stock: 15),
            ProductVariantOption(id: 'sz_l', name: 'L', priceOffset: 100.0, stock: 5),
          ],
        ),
      ],
      combinationStock: const {
        'Natural-S': 10,
        'Natural-M': 15,
        'Natural-L': 5,
        'Black-S': 10,
        'Black-M': 0,
        'Black-L': 5,
      },
    ),

    // 6. GAMING: Custom 75% Mechanical Keyboard RGB
    ProductModel(
      id: 'GAME-KB-01',
      title: 'Nexora Apex 75% Custom Mechanical Keyboard RGB',
      imageUrl:
          'https://images.unsplash.com/photo-1587829741301-dc798b83add3?auto=format&fit=crop&w=600&q=80',
      galleryImages: const [
        'https://images.unsplash.com/photo-1587829741301-dc798b83add3?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1618384887929-16ec33fab9ef?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1595225476474-87563907a212?auto=format&fit=crop&w=600&q=80',
      ],
      category: 'Gaming',
      isMall: true,
      discountTag: '-28%',
      price: '₱3,890.00',
      originalPrice: '₱5,400',
      rating: 4.9,
      soldCount: '620',
      shippingTag: '2-3 Days | Metro Manila',
      hasPayLater: false,
      hasVoucher: true,
      shopId: 'apex_gaming',
      shopName: 'Apex Esports Gear Labs',
      shopBadge: 'OFFICIAL STORE',
      stockQuantity: 58,
      description:
          'Gasket-mounted hot-swappable 75% mechanical keyboard engineered with CNC aluminum chassis, 5 layers of acoustic Poron sound-dampening foam, factory-lubed switches, and tri-mode 2.4GHz wireless.',
      specs: const [
        {
          'icon': Icons.graphic_eq,
          'title': 'Poron Gasket Mount',
          'subtitle': '5 layers of sound-dampening foam for pure, deep acoustics.',
        },
        {
          'icon': Icons.wifi,
          'title': 'Tri-Mode Wireless',
          'subtitle': 'Bluetooth 5.3, 2.4GHz ultra-low latency & Type-C wired.',
        },
        {
          'icon': Icons.battery_charging_full,
          'title': '4000mAh Battery',
          'subtitle': 'Up to 240 hours continuous playtime without RGB backlight.',
        },
        {
          'icon': Icons.tune,
          'title': 'Rotary Encoder',
          'subtitle': 'CNC Violet knob mapped to volume, zoom, or media playback.',
        },
      ],
      ratingBreakdown: const {5: 0.92, 4: 0.07, 3: 0.01, 2: 0.0, 1: 0.0},
      variantGroups: const [
        ProductVariantGroup(
          groupName: 'Keycap & Case Theme',
          options: [
            ProductVariantOption(
              id: 'kb_violet',
              name: 'Chalk White & Violet',
              colorHex: Color(0xFFC4B5FD),
              subtitle: 'Sublimated PBT cherry profile keycaps',
              stock: 28,
            ),
            ProductVariantOption(
              id: 'kb_navy',
              name: 'Midnight Navy',
              colorHex: Color(0xFF0F172A),
              subtitle: 'Dark mode deep indigo aesthetic',
              stock: 18,
            ),
            ProductVariantOption(
              id: 'kb_blk',
              name: 'Phantom Black',
              colorHex: Color(0xFF18181B),
              subtitle: 'Smoked translucent polycarbonate body',
              stock: 12,
            ),
          ],
        ),
        ProductVariantGroup(
          groupName: 'Factory-Lubed Switches',
          options: [
            ProductVariantOption(
              id: 'sw_yellow',
              name: 'Gateron Pro Yellow (Linear)',
              subtitle: 'Smooth 50g linear feel with creamy sound profile',
              stock: 25,
            ),
            ProductVariantOption(
              id: 'sw_white',
              name: 'Kailh Box White (Clicky)',
              subtitle: 'Crisp acoustic clickbar with 45g actuation',
              stock: 18,
            ),
            ProductVariantOption(
              id: 'sw_red',
              name: 'Silent Red (Damped Linear)',
              subtitle: 'Silenced silicone dampeners for quiet offices',
              stock: 15,
            ),
          ],
        ),
      ],
      reviews: [
        ProductReviewModel(
          id: 'rev_kb1',
          userName: 'Kiko Valenzuela',
          initials: 'KV',
          avatarColor: const Color(0xFF5038ED),
          rating: 5.0,
          date: '2d ago',
          variantName: 'Chalk White & Violet • Gateron Pro Yellow (Linear)',
          comment:
              'The CNC aluminum weight gives this keyboard such a heavy, ultra-premium feel on the desk. The sound profile right out of the box has zero hollow ping.',
          helpfulCount: 38,
        ),
      ],
    ),

    // 7. GAMING: LogiTech Superlight Esports Gaming Mouse
    ProductModel(
      id: 'GAME-MOUSE-02',
      title: 'LogiTech Superlight Wireless Esports Gaming Mouse',
      imageUrl:
          'https://images.unsplash.com/photo-1615663245857-ac93bb7c39e7?auto=format&fit=crop&w=600&q=80',
      galleryImages: const [
        'https://images.unsplash.com/photo-1615663245857-ac93bb7c39e7?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1541140590914-579f21e6b72d?auto=format&fit=crop&w=600&q=80',
      ],
      category: 'Gaming',
      isMall: true,
      discountTag: '-22%',
      price: '₱4,790.00',
      originalPrice: '₱6,200',
      rating: 4.9,
      soldCount: '9.8K+',
      shippingTag: 'Free Shipping',
      hasPayLater: false,
      hasVoucher: true,
      shopId: 'apex_gaming',
      shopName: 'Apex Esports Gear Labs',
      shopBadge: 'OFFICIAL STORE',
      stockQuantity: 60,
      description:
          'Weighing under 60 grams with HERO 25K optical sensor and LIGHTSPEED 1ms wireless technology. Engineered with top competitive CS2 and Valorant professionals.',
      specs: const [
        {
          'icon': Icons.speed,
          'title': 'Sub-60g Weight',
          'subtitle': 'Featherlight aerodynamic shell with hyper-responsive flick control.',
        },
        {
          'icon': Icons.gps_fixed,
          'title': 'HERO 25K Sensor',
          'subtitle': 'Pixel-precise tracking up to 25,600 DPI with zero smoothing.',
        },
        {
          'icon': Icons.bolt,
          'title': 'LIGHTSPEED 1ms',
          'subtitle': 'Tournament-grade 1000Hz polling rate wireless connectivity.',
        },
        {
          'icon': Icons.swipe,
          'title': 'Pure PTFE Skates',
          'subtitle': 'Virgin-grade oversized glide feet for frictionless motion on cloth.',
        },
      ],
      variantGroups: const [
        ProductVariantGroup(
          groupName: 'Esports Shell Color',
          options: [
            ProductVariantOption(
              id: 'mouse_wht',
              name: 'Ghost White',
              colorHex: Color(0xFFF8FAFC),
              stock: 25,
            ),
            ProductVariantOption(
              id: 'mouse_blk',
              name: 'Matte Stealth Black',
              colorHex: Color(0xFF0F172A),
              stock: 20,
            ),
            ProductVariantOption(
              id: 'mouse_magenta',
              name: 'Neon Magenta',
              colorHex: Color(0xFFF43F5E),
              stock: 15,
            ),
          ],
        ),
      ],
      reviews: [
        ProductReviewModel(
          id: 'rev_lt1',
          userName: 'Derrick Tan (Valo Coach)',
          initials: 'DT',
          avatarColor: const Color(0xFF0284C7),
          rating: 5.0,
          date: '2 days ago',
          variantName: 'Ghost White',
          comment:
              'Tracking and flicking feel effortless at under 60 grams. Battery lasts well over a month with daily ranked games.',
          helpfulCount: 52,
        ),
      ],
    ),

    // 8. HOME & LIVING: Handwoven Rattan Fruit Basket P-02
    ProductModel(
      id: 'P-02',
      title: 'Rattan Fruit Basket Handwoven Organizer P-02',
      imageUrl:
          'https://images.unsplash.com/photo-1544816155-12df9643f363?auto=format&fit=crop&w=600&q=80',
      galleryImages: const [
        'https://images.unsplash.com/photo-1544816155-12df9643f363?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1513519245088-0e12902e5a38?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1530595467537-0b5996c41f2d?auto=format&fit=crop&w=600&q=80',
      ],
      category: 'Home & Living',
      location: 'Luzon',
      isMall: true,
      discountTag: '-33%',
      price: '₱299.00',
      originalPrice: '₱450.00',
      rating: 4.8,
      soldCount: '1.2K',
      shippingTag: 'Standard Delivery | Luzon',
      hasPayLater: false,
      hasVoucher: true,
      isFlashSale: true,
      flashSalePrice: '₱299.00',
      flashSaleStockRemaining: 8,
      flashSaleTotalStock: 20,
      flashSaleTimeRemaining: const Duration(hours: 4, minutes: 23),
      shopId: 'nexora_home_living',
      shopName: 'Nexora Living & Essentials',
      shopBadge: 'OFFICIAL STORE',
      stockQuantity: 20,
      description:
          'Eco-friendly handwoven natural rattan fruit and bread serving basket. Artisanal quality crafted by heritage weavers in Luzon with smooth natural beeswax sealant.',
      specs: const [
        {
          'icon': Icons.park,
          'title': '100% Wild Rattan',
          'subtitle': 'Sustainably harvested natural wild rattan fibers from local forests.',
        },
        {
          'icon': Icons.handyman,
          'title': 'Artisan Handwoven',
          'subtitle': 'Meticulously crafted tight spiral weave with reinforced outer rim.',
        },
        {
          'icon': Icons.soup_kitchen,
          'title': 'Food-Grade Sealant',
          'subtitle': 'Treated with organic beeswax coating safe for fruits and bread.',
        },
        {
          'icon': Icons.cleaning_services,
          'title': 'Easy Maintenance',
          'subtitle': 'Wipes clean effortlessly with a soft damp cloth in seconds.',
        },
      ],
      claimableVouchers: const [
        ShopVoucherModel(
          id: 'MCH50',
          discountTitle: '₱50 OFF',
          tag: 'VOUCHER',
          minSpend: 'Min. spend ₱200',
          expiry: 'Exp: Today',
          buttonColor: Color(0xFF0066FF),
          discountAmount: 50,
        ),
      ],
      reviews: [
        ProductReviewModel(
          id: 'rev_rattan1',
          userName: 'Maria Theresa Santos',
          initials: 'MS',
          avatarColor: const Color(0xFFD97706),
          rating: 5.0,
          date: '4 days ago',
          variantName: 'Medium (24cm Round)',
          comment:
              'Looks so aesthetic on our kitchen island! Very smooth finish with no splintering. Packed carefully with bubble wrap.',
          helpfulCount: 21,
        ),
      ],
    ),

    // 9. HOME & LIVING: Eco Thermos Bottle P-07
    ProductModel(
      id: 'P-07',
      title: 'Limited Edition Eco Thermos Bottle P-07',
      imageUrl:
          'https://images.unsplash.com/photo-1602143407151-7111542de6e8?auto=format&fit=crop&w=600&q=80',
      galleryImages: const [
        'https://images.unsplash.com/photo-1602143407151-7111542de6e8?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1544816155-12df9643f363?auto=format&fit=crop&w=600&q=80',
      ],
      category: 'Home & Living',
      price: '₱599.00',
      originalPrice: '₱899.00',
      rating: 4.9,
      soldCount: '150',
      shippingTag: 'Standard Delivery',
      hasPayLater: false,
      hasVoucher: true,
      isFlashSale: true,
      flashSalePrice: '₱299.00',
      flashSaleStockRemaining: 8,
      flashSaleTotalStock: 20,
      flashSaleTimeRemaining: const Duration(hours: 4, minutes: 23),
      shopId: 'nexora_home_living',
      shopName: 'Nexora Living & Essentials',
      shopBadge: 'OFFICIAL STORE',
      stockQuantity: 50,
      perBuyerLimit: 2,
      description:
          'Double-wall vacuum insulated 18/8 food-grade stainless steel thermal flask. Keeps iced coffee ice-cold for 24 hours or herbal tea steaming hot for 12 hours with zero sweat condensation.',
      specs: const [
        {
          'icon': Icons.shield,
          'title': '18/8 Pro Stainless',
          'subtitle': 'Food-grade stainless steel with BPA-free powder coat exterior.',
        },
        {
          'icon': Icons.thermostat,
          'title': '24h Cold / 12h Hot',
          'subtitle': 'Advanced copper vacuum chamber eliminates temperature transfer.',
        },
        {
          'icon': Icons.lock,
          'title': '100% Leak-Proof',
          'subtitle': 'Silicone gasket magnetic flip lid with integrated comfort carry loop.',
        },
        {
          'icon': Icons.opacity,
          'title': 'Zero Condensation',
          'subtitle': 'Sweat-free outer wall keeps bags, desks, and car cup holders dry.',
        },
      ],
    ),

    // 10. HOME & LIVING: Handwoven Plant Basket
    ProductModel(
      id: 'P-PLANT-08',
      title: 'Green Tropics Handwoven Plant Basket',
      imageUrl:
          'https://images.unsplash.com/photo-1513519245088-0e12902e5a38?auto=format&fit=crop&w=600&q=80',
      galleryImages: const [
        'https://images.unsplash.com/photo-1513519245088-0e12902e5a38?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1544816155-12df9643f363?auto=format&fit=crop&w=600&q=80',
      ],
      category: 'Home & Living',
      price: '₱520.00',
      originalPrice: '₱750.00',
      rating: 4.7,
      soldCount: '580',
      shippingTag: 'Standard Delivery',
      hasPayLater: false,
      hasVoucher: true,
      isFlashSale: true,
      flashSalePrice: '₱299.00',
      flashSaleStockRemaining: 8,
      flashSaleTotalStock: 20,
      flashSaleTimeRemaining: const Duration(hours: 4, minutes: 23),
      shopId: 'nexora_home_living',
      shopName: 'Nexora Living & Essentials',
      shopBadge: 'OFFICIAL STORE',
      stockQuantity: 40,
      description:
          'Bespoke handwoven seagrass plant pot basket fitted with an inner waterproof protective membrane and sturdy folded rope handles to display indoor monsteras and snake plants.',
      specs: const [
        {
          'icon': Icons.eco,
          'title': 'Natural Seagrass',
          'subtitle': 'Eco-friendly harvested dried seagrass tightly braided for durability.',
        },
        {
          'icon': Icons.water_drop,
          'title': 'Waterproof Liner',
          'subtitle': 'Interior heat-sealed vinyl liner prevents soil and water leaking.',
        },
        {
          'icon': Icons.pan_tool,
          'title': 'Braided Handles',
          'subtitle': 'Stout side handles make moving heavy potted indoor plants simple.',
        },
        {
          'icon': Icons.home,
          'title': 'Boho Aesthetic',
          'subtitle': 'Adds warm organic texture to Scandinavian and minimalist rooms.',
        },
      ],
      variantGroups: const [
        ProductVariantGroup(
          groupName: 'Diameter Size',
          options: [
            ProductVariantOption(
              id: 'plt_8in',
              name: '8-Inch Diameter Pot',
              stock: 25,
            ),
            ProductVariantOption(
              id: 'plt_10in',
              name: '10-Inch Diameter Pot',
              priceOffset: 80,
              stock: 15,
            ),
          ],
        ),
      ],
    ),

    // 11. AUDIO: Studio Pro Wireless ANC Headphone System
    ProductModel(
      id: 'AUD-HEAD-03',
      title: 'Nexora Studio Pro Wireless ANC Headphone System',
      imageUrl:
          'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=600&q=80',
      galleryImages: const [
        'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1545454675-3531b543be5d?auto=format&fit=crop&w=600&q=80',
      ],
      category: 'Tech & Gadgets',
      isMall: true,
      discountTag: '-30%',
      price: '₱2,450.00',
      originalPrice: '₱3,500',
      rating: 4.9,
      soldCount: '1.8k',
      shippingTag: '2-3 Days | Metro Manila',
      hasPayLater: false,
      hasVoucher: false,
      shopId: 'nexora_audio',
      shopName: 'Nexora Studio Audio Official',
      shopBadge: 'OFFICIAL STORE',
      stockQuantity: 92,
      description:
          'Flagship hybrid active noise cancelling over-ear headphones with custom 40mm beryllium diaphragm drivers, 60-hour playtime, low-latency gaming mode, and cooling memory foam ear cushions.',
      specs: const [
        {
          'icon': Icons.headset,
          'title': '40mm Beryllium Drivers',
          'subtitle': 'Delivers rich deep sub-bass and ultra-detailed acoustic resolution.',
        },
        {
          'icon': Icons.hearing,
          'title': '42dB Hybrid ANC',
          'subtitle': 'Feed-forward and feedback mics cancel MRT and airplane cabin noise.',
        },
        {
          'icon': Icons.battery_charging_full,
          'title': '60h Battery Life',
          'subtitle': 'Fast-charge provides 5 hours of playback from just a 10-minute USB-C plug.',
        },
        {
          'icon': Icons.phone_android,
          'title': 'Multipoint Connect',
          'subtitle': 'Seamlessly transition audio between your laptop and smartphone.',
        },
      ],
      variantGroups: const [
        ProductVariantGroup(
          groupName: 'Color Palette',
          options: [
            ProductVariantOption(
              id: 'hp_grey',
              name: 'Matte Space Grey',
              colorHex: Color(0xFF475569),
              stock: 50,
            ),
            ProductVariantOption(
              id: 'hp_white',
              name: 'Lunar White',
              colorHex: Color(0xFFF1F5F9),
              stock: 42,
            ),
          ],
        ),
      ],
    ),

    // 12. JEWELRY: Mikana Sakura Pendant
    ProductModel(
      id: 'JWL-MIK-01',
      title: 'Mikana 18k Gold Plated Sakura Pendant Necklace',
      imageUrl:
          'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?auto=format&fit=crop&w=600&q=80',
      galleryImages: const [
        'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1605100804763-247f67b3557e?auto=format&fit=crop&w=600&q=80',
      ],
      category: 'Jewelry',
      isMall: true,
      discountTag: '-35%',
      price: '₱1,299.00',
      originalPrice: '₱1,999',
      rating: 4.8,
      soldCount: '8.3K+',
      shippingTag: 'Free Shipping',
      hasPayLater: false,
      hasVoucher: true,
      shopId: 'mikana_official',
      shopName: 'Mikana Jewelry & Co.',
      shopBadge: 'OFFICIAL STORE',
      stockQuantity: 120,
      description:
          'Hand-finished Japanese cherry blossom pendant dipped in 18k thick vacuum gold plating over medical-grade titanium steel. 100% hypoallergenic, non-tarnish, and waterproof for daily elegance.',
      specs: const [
        {
          'icon': Icons.diamond,
          'title': '18k Gold PVD Dip',
          'subtitle': 'Vacuum ionized gold plating that will not flake or discolor over time.',
        },
        {
          'icon': Icons.health_and_safety,
          'title': '100% Hypoallergenic',
          'subtitle': 'Nickel-free and lead-free medical-grade titanium base safe for sensitive skin.',
        },
        {
          'icon': Icons.shower,
          'title': 'Shower & Water Safe',
          'subtitle': 'Wear in the gym or shower without worrying about tarnishing.',
        },
        {
          'icon': Icons.card_giftcard,
          'title': 'Velvet Gift Box',
          'subtitle': 'Includes signature Mikana embossed satin pouch and authentication certificate.',
        },
      ],
      variantGroups: const [
        ProductVariantGroup(
          groupName: 'Gold Finish',
          options: [
            ProductVariantOption(
              id: 'gold_yellow',
              name: '18k Classic Yellow Gold',
              colorHex: Color(0xFFEAB308),
              stock: 65,
            ),
            ProductVariantOption(
              id: 'gold_rose',
              name: 'Blushing Rose Gold',
              colorHex: Color(0xFFFB7185),
              stock: 55,
            ),
          ],
        ),
      ],
    ),
    // 11. P-05: Essential Desk Mat
    const ProductModel(
      id: 'P-05',
      title: 'Nexora Essential Desk Mat P-05',
      imageUrl:
          'https://images.unsplash.com/photo-1527864550417-7fd91fc51a46?auto=format&fit=crop&w=600&q=80',
      category: 'Accessories',
      price: '₱490.00',
      originalPrice: '₱490.00',
      rating: 4.8,
      soldCount: '800',
      shippingTag: 'Standard Delivery',
      shopId: 'nexora_tech',
      shopName: 'Accessories Hub',
      shopBadge: 'PREFERRED',
      stockQuantity: 40,
    ),
    // 12. P-VACATION: Vacation Mode Product
    const ProductModel(
      id: 'P-VACATION',
      title: 'Nexora Vacation Store Special Item',
      imageUrl:
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=600&q=80',
      category: 'Lifestyle',
      price: '₱350.00',
      rating: 4.7,
      soldCount: '500',
      shippingTag: 'Standard Delivery',
      isOnVacation: true,
    ),
  ];
}
