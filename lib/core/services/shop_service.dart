import 'package:flutter/material.dart';
import '../models/shop_models.dart';
import '../../features/home/presentation/widgets/product_card.dart';

class ShopService extends ChangeNotifier {
  static final ShopService instance = ShopService._internal();
  ShopService._internal();

  final Set<String> _followedShopIds = {};
  final Set<String> _claimedVoucherIds = {};
  final Map<String, int> _helpfulVotes = {};
  final Set<String> _userUpvotedReviews = {};

  bool isFollowing(String shopId) => _followedShopIds.contains(shopId);

  void toggleFollow(String shopId) {
    if (_followedShopIds.contains(shopId)) {
      _followedShopIds.remove(shopId);
    } else {
      _followedShopIds.add(shopId);
    }
    notifyListeners();
  }

  bool isVoucherClaimed(String voucherId) => _claimedVoucherIds.contains(voucherId);

  void claimVoucher(String voucherId) {
    _claimedVoucherIds.add(voucherId);
    notifyListeners();
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

  // List of all shops
  List<ShopModel> get allShops => [
        nexoraOfficialStore,
        soundMaxAudioStore,
        mikanaJewelryStore,
        logitechHubStore,
        auraStudiosStore,
      ];

  ShopModel getShopById(String? shopId) {
    if (shopId == null) return nexoraOfficialStore;
    return allShops.firstWhere(
      (s) => s.id.toLowerCase() == shopId.toLowerCase(),
      orElse: () => nexoraOfficialStore,
    );
  }

  ShopModel getShopForProduct(ProductModel product) {
    return getShopById(product.shopId);
  }

  // -------------------------------------------------------------
  // 1. NEXORA OFFICIAL STORE (Matching screenshots)
  // -------------------------------------------------------------
  static final ShopModel nexoraOfficialStore = ShopModel(
    id: 'nexora_official',
    name: 'Nexora Official Store',
    badge: 'NEXORA MALL',
    rating: 4.9,
    followers: '129.4K',
    initials: 'N\nMALL',
    avatarBg: const Color(0xFF001233),
    categoryGroupTitle: 'AUDIO & STUDIO GEAR',
    categories: [
      const ShopCategoryModel(
        id: 'mic',
        title: 'Microphone',
        itemCount: 32,
        imageUrl:
            'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?auto=format&fit=crop&w=400&q=80',
      ),
      const ShopCategoryModel(
        id: 'soundcard',
        title: 'Sound Card',
        itemCount: 17,
        imageUrl:
            'https://images.unsplash.com/photo-1545454675-3531b543be5d?auto=format&fit=crop&w=400&q=80',
      ),
      const ShopCategoryModel(
        id: 'gaming_mic',
        title: 'Gaming Microphone',
        itemCount: 18,
        imageUrl:
            'https://images.unsplash.com/photo-1583743814966-8936f5b7be1a?auto=format&fit=crop&w=400&q=80',
      ),
      const ShopCategoryModel(
        id: 'studio_rec',
        title: 'Podcast & Studio Recording',
        itemCount: 13,
        imageUrl:
            'https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?auto=format&fit=crop&w=400&q=80',
      ),
      const ShopCategoryModel(
        id: 'lavalier',
        title: 'Wireless Lavalier & Lapel Kits',
        itemCount: 9,
        imageUrl:
            'https://images.unsplash.com/photo-1618384887929-16ec33fab9ef?auto=format&fit=crop&w=400&q=80',
      ),
      const ShopCategoryModel(
        id: 'mixers',
        title: 'Audio Interfaces & Mixers',
        itemCount: 14,
        imageUrl:
            'https://images.unsplash.com/photo-1545454675-3531b543be5d?auto=format&fit=crop&w=400&q=80',
      ),
      const ShopCategoryModel(
        id: 'boom_arms',
        title: 'Boom Arms & Stands',
        itemCount: 21,
        imageUrl:
            'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=400&q=80',
      ),
      const ShopCategoryModel(
        id: 'monitors',
        title: 'Headphones & Studio Monitors',
        itemCount: 15,
        imageUrl:
            'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?auto=format&fit=crop&w=400&q=80',
      ),
    ],
    vouchers: [
      const ShopVoucherModel(
        id: 'nexora_v1',
        discountTitle: '5% OFF',
        tag: 'Store',
        minSpend: 'Min. spend ₱2,000',
        expiry: 'Exp: 31.12.2026',
        buttonColor: Color(0xFF00C2FF),
        discountAmount: 0.05,
        isPercentage: true,
      ),
      const ShopVoucherModel(
        id: 'nexora_v2',
        discountTitle: '₱100 OFF',
        tag: 'Welcome',
        minSpend: 'Min. spend ₱0',
        expiry: 'Exp: 31.12.2026',
        buttonColor: Color(0xFF050B28),
        discountAmount: 100,
        isPercentage: false,
      ),
      const ShopVoucherModel(
        id: 'nexora_v3',
        discountTitle: '10% OFF',
        tag: 'Mall VIP',
        minSpend: 'Min. spend ₱4,500',
        expiry: 'Exp: 31.12.2026',
        buttonColor: Color(0xFF0066FF),
        discountAmount: 0.10,
        isPercentage: true,
      ),
    ],
  );

  // -------------------------------------------------------------
  // 2. SOUNDMAX AUDIO STORE
  // -------------------------------------------------------------
  static final ShopModel soundMaxAudioStore = ShopModel(
    id: 'soundmax_audio',
    name: 'SoundMax Pro Audio',
    badge: 'NEXORA MALL',
    rating: 4.9,
    followers: '84.2K',
    initials: 'SM\nPRO',
    avatarBg: const Color(0xFF1E1B4B),
    categoryGroupTitle: 'PRO HI-FI AUDIO & SOUND SYSTEMS',
    categories: [
      const ShopCategoryModel(
        id: 'sm_headphones',
        title: 'Studio Over-Ear Headphones',
        itemCount: 22,
        imageUrl:
            'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=400&q=80',
      ),
      const ShopCategoryModel(
        id: 'sm_speakers',
        title: 'Spatial Audio Speakers',
        itemCount: 16,
        imageUrl:
            'https://images.unsplash.com/photo-1545454675-3531b543be5d?auto=format&fit=crop&w=400&q=80',
      ),
      const ShopCategoryModel(
        id: 'sm_wireless',
        title: 'True Wireless ANC Earbuds',
        itemCount: 19,
        imageUrl:
            'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?auto=format&fit=crop&w=400&q=80',
      ),
      const ShopCategoryModel(
        id: 'sm_amps',
        title: 'High-Res DAC & Headphone Amps',
        itemCount: 12,
        imageUrl:
            'https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?auto=format&fit=crop&w=400&q=80',
      ),
    ],
    vouchers: [
      const ShopVoucherModel(
        id: 'sm_v1',
        discountTitle: '₱150 OFF',
        tag: 'Store',
        minSpend: 'Min. spend ₱2,500',
        expiry: 'Exp: 31.12.2026',
        buttonColor: Color(0xFF00C2FF),
        discountAmount: 150,
      ),
      const ShopVoucherModel(
        id: 'sm_v2',
        discountTitle: '8% OFF',
        tag: 'Welcome',
        minSpend: 'Min. spend ₱1,500',
        expiry: 'Exp: 31.12.2026',
        buttonColor: Color(0xFF1E1B4B),
        discountAmount: 0.08,
        isPercentage: true,
      ),
    ],
  );

  // -------------------------------------------------------------
  // 3. MIKANA JEWELRY STORE
  // -------------------------------------------------------------
  static final ShopModel mikanaJewelryStore = ShopModel(
    id: 'mikana_official',
    name: 'Mikana Jewelry & Co.',
    badge: 'NEXORA MALL',
    rating: 4.8,
    followers: '96.5K',
    initials: 'MK\nJEWEL',
    avatarBg: const Color(0xFF701A75),
    categoryGroupTitle: 'JAPANESE 18K GOLD & LUXURY PIECES',
    categories: [
      const ShopCategoryModel(
        id: 'mk_necklaces',
        title: 'Pendant Necklaces',
        itemCount: 48,
        imageUrl:
            'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?auto=format&fit=crop&w=400&q=80',
      ),
      const ShopCategoryModel(
        id: 'mk_rings',
        title: 'Eternity & Solitaire Rings',
        itemCount: 36,
        imageUrl:
            'https://images.unsplash.com/photo-1605100804763-247f67b3557e?auto=format&fit=crop&w=400&q=80',
      ),
      const ShopCategoryModel(
        id: 'mk_bracelets',
        title: 'Charm Bangles & Tennis',
        itemCount: 24,
        imageUrl:
            'https://images.unsplash.com/photo-1611591475870-745a7d65b701?auto=format&fit=crop&w=400&q=80',
      ),
      const ShopCategoryModel(
        id: 'mk_gift',
        title: 'Velvet Jewelry Gift Sets',
        itemCount: 14,
        imageUrl:
            'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?auto=format&fit=crop&w=400&q=80',
      ),
    ],
    vouchers: [
      const ShopVoucherModel(
        id: 'mk_v1',
        discountTitle: '₱120 OFF',
        tag: 'Store',
        minSpend: 'Min. spend ₱1,800',
        expiry: 'Exp: 31.12.2026',
        buttonColor: Color(0xFF00C2FF),
        discountAmount: 120,
      ),
      const ShopVoucherModel(
        id: 'mk_v2',
        discountTitle: '12% OFF',
        tag: 'Gold Club',
        minSpend: 'Min. spend ₱3,000',
        expiry: 'Exp: 31.12.2026',
        buttonColor: Color(0xFF4A044E),
        discountAmount: 0.12,
        isPercentage: true,
      ),
    ],
  );

  // -------------------------------------------------------------
  // 4. LOGITECH GEAR HUB
  // -------------------------------------------------------------
  static final ShopModel logitechHubStore = ShopModel(
    id: 'logitech_hub',
    name: 'LogiTech Gear Hub',
    badge: 'OFFICIAL STORE',
    rating: 4.9,
    followers: '215.8K',
    initials: 'LT\nGEAR',
    avatarBg: const Color(0xFF0369A1),
    categoryGroupTitle: 'ESPORTS GAMING PERIPHERALS & STREAMING',
    categories: [
      const ShopCategoryModel(
        id: 'lt_mice',
        title: 'Ultra-Lightweight Mice',
        itemCount: 16,
        imageUrl:
            'https://images.unsplash.com/photo-1615663245857-ac93bb7c39e7?auto=format&fit=crop&w=400&q=80',
      ),
      const ShopCategoryModel(
        id: 'lt_keyboards',
        title: 'Wireless Mechanical Keyboards',
        itemCount: 20,
        imageUrl:
            'https://images.unsplash.com/photo-1587829741301-dc798b83add3?auto=format&fit=crop&w=400&q=80',
      ),
      const ShopCategoryModel(
        id: 'lt_webcams',
        title: '4K Pro HDR Webcams',
        itemCount: 9,
        imageUrl:
            'https://images.unsplash.com/photo-1587829741301-dc798b83add3?auto=format&fit=crop&w=400&q=80',
      ),
      const ShopCategoryModel(
        id: 'lt_pads',
        title: 'Speed Edition Desk Mats',
        itemCount: 18,
        imageUrl:
            'https://images.unsplash.com/photo-1541140590914-579f21e6b72d?auto=format&fit=crop&w=400&q=80',
      ),
    ],
    vouchers: [
      const ShopVoucherModel(
        id: 'lt_v1',
        discountTitle: '₱200 OFF',
        tag: 'Gamer Pass',
        minSpend: 'Min. spend ₱3,500',
        expiry: 'Exp: 31.12.2026',
        buttonColor: Color(0xFF00C2FF),
        discountAmount: 200,
      ),
      const ShopVoucherModel(
        id: 'lt_v2',
        discountTitle: '10% OFF',
        tag: 'Flagship',
        minSpend: 'Min. spend ₱4,000',
        expiry: 'Exp: 31.12.2026',
        buttonColor: Color(0xFF0C4A6E),
        discountAmount: 0.10,
        isPercentage: true,
      ),
    ],
  );

  // -------------------------------------------------------------
  // 5. AURA STUDIOS APPAREL
  // -------------------------------------------------------------
  static final ShopModel auraStudiosStore = ShopModel(
    id: 'aura_studios',
    name: 'Aura Studios Official',
    badge: 'TOP SELLER',
    rating: 4.8,
    followers: '45.1K',
    initials: 'AS\nURBAN',
    avatarBg: const Color(0xFF334155),
    categoryGroupTitle: 'URBAN STREETWEAR & HEAVYWEIGHT BASICS',
    categories: [
      const ShopCategoryModel(
        id: 'as_hoodies',
        title: '450GSM Heavy Fleece Hoodies',
        itemCount: 14,
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDzlfM9UI-vGVUMAkUKI4WCoDpA4njq2i2bH5FsGflhVF28xwuR4599HpCZ5j6YtJKmVEHwfR2hVgWxghw8H2THFwFCT27W7Fk_z0wKe4q_kg8uwhxD9uXh8zSSoZ67ltyCehtwjAQfkdZzcDRantW9HcQz8VT_3vLB_3girMZ7tKvzHlokhxLLe-oKWduwhOBz7fV1Jgul-8KVjTL7YA5C12MOUbZqrBtVidhRBHOauvw8mO5Sfus',
      ),
      const ShopCategoryModel(
        id: 'as_tees',
        title: 'Boxy Drop-Shoulder Tees',
        itemCount: 26,
        imageUrl:
            'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?auto=format&fit=crop&w=400&q=80',
      ),
      const ShopCategoryModel(
        id: 'as_cargos',
        title: 'Tactical Multi-Pocket Cargos',
        itemCount: 16,
        imageUrl:
            'https://images.unsplash.com/photo-1552902865-b72c031ac5ea?auto=format&fit=crop&w=400&q=80',
      ),
      const ShopCategoryModel(
        id: 'as_bags',
        title: 'Waterproof Crossbody Slings',
        itemCount: 10,
        imageUrl:
            'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?auto=format&fit=crop&w=400&q=80',
      ),
    ],
    vouchers: [
      const ShopVoucherModel(
        id: 'as_v1',
        discountTitle: '₱80 OFF',
        tag: 'First Order',
        minSpend: 'Min. spend ₱999',
        expiry: 'Exp: 31.12.2026',
        buttonColor: Color(0xFF00C2FF),
        discountAmount: 80,
      ),
      const ShopVoucherModel(
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

  // All products in application with full custom variants, reviews, ratings, stock
  static final List<ProductModel> allAppProducts = [
    // -------------------------------------------------------------
    // NEXORA OFFICIAL STORE PRODUCTS (From Screenshot 1, 2, 3)
    // -------------------------------------------------------------
    ProductModel(
      title: 'Nexora PD100X Dynamic RGB Studio Mic',
      imageUrl:
          'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?auto=format&fit=crop&w=600&q=80',
      category: 'Audio',
      isMall: true,
      discountTag: '-37%',
      price: '₱2,540',
      originalPrice: '₱3,000',
      rating: 4.9,
      soldCount: '6K+ sold',
      shippingTag: 'Free Shipping',
      hasPayLater: true,
      hasVoucher: true,
      shopId: 'nexora_official',
      shopName: 'Nexora Official Store',
      shopBadge: 'NEXORA MALL',
      stockQuantity: 84,
      description:
          'Broadcast-grade cardioid dynamic microphone with customizable RGB lighting, dual USB & XLR outputs, and built-in noise gate suppression.',
      ratingBreakdown: {5: 0.89, 4: 0.08, 3: 0.02, 2: 0.01, 1: 0.0},
      variantGroups: [
        ProductVariantGroup(
          groupName: 'Body Finish',
          options: [
            ProductVariantOption(
              id: 'pd_blk',
              name: 'Matte Obsidian Black',
              colorHex: Color(0xFF18181B),
              subtitle: 'Stealth matte coating with RGB ring',
              stock: 45,
            ),
            ProductVariantOption(
              id: 'pd_wht',
              name: 'Blizzard White Edition',
              colorHex: Color(0xFFF8FAFC),
              subtitle: 'Ceramic matte coat with frosted diffuser',
              stock: 39,
            ),
          ],
        ),
        ProductVariantGroup(
          groupName: 'Mounting Bundle',
          options: [
            ProductVariantOption(
              id: 'bundle_desk',
              name: 'Heavy Desk Stand',
              subtitle: 'Weighted anti-vibration circular base',
              stock: 50,
            ),
            ProductVariantOption(
              id: 'bundle_boom',
              name: 'Full Studio Boom Arm Kit',
              subtitle: 'Heavy duty arm + integrated XLR cable (+₱650)',
              priceOffset: 650,
              stock: 34,
            ),
          ],
        ),
      ],
      reviews: [
        ProductReviewModel(
          id: 'rev_pd1',
          userName: 'Mark Anthony Santos',
          initials: 'MS',
          avatarColor: const Color(0xFF2563EB),
          rating: 5.0,
          date: '1 day ago',
          variantName: 'Matte Obsidian Black • Full Studio Boom Arm Kit',
          comment:
              'The audio clarity on Discord and OBS is insane for this price point! XLR preamp handles loud vocals effortlessly and the RGB looks so clean in my stream.',
          reviewImages: [
            'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?auto=format&fit=crop&w=300&q=80',
          ],
          helpfulCount: 42,
        ),
        ProductReviewModel(
          id: 'rev_pd2',
          userName: 'Bea Nicole Reyes',
          initials: 'BR',
          avatarColor: const Color(0xFF9333EA),
          rating: 5.0,
          date: '3 days ago',
          variantName: 'Blizzard White Edition • Heavy Desk Stand',
          comment:
              'Super aesthetically pleasing mic! Plug-and-play USB works immediately on Mac. Tap-to-mute button on top is very tactile and responsive.',
          helpfulCount: 28,
        ),
        ProductReviewModel(
          id: 'rev_pd3',
          userName: 'Rico J. Fernandez',
          initials: 'RF',
          avatarColor: const Color(0xFF059669),
          rating: 4.8,
          date: '1 week ago',
          variantName: 'Matte Obsidian Black • Heavy Desk Stand',
          comment:
              'Great background noise rejection. Typing on blue switch keyboard doesn\'t get picked up on cardioid mode.',
          helpfulCount: 15,
        ),
      ],
    ),

    ProductModel(
      title: 'Nexora DGM20S USB Condenser Mic with Boom Arm',
      imageUrl:
          'https://images.unsplash.com/photo-1583743814966-8936f5b7be1a?auto=format&fit=crop&w=600&q=80',
      category: 'Audio',
      isMall: true,
      discountTag: '-48%',
      price: '₱1,549',
      originalPrice: '₱2,000',
      rating: 4.9,
      soldCount: '10K+ sold',
      shippingTag: 'Free Shipping',
      hasPayLater: true,
      hasVoucher: true,
      shopId: 'nexora_official',
      shopName: 'Nexora Official Store',
      shopBadge: 'NEXORA MALL',
      stockQuantity: 140,
      description:
          'All-in-one streaming microphone featuring one-touch noise cancellation, headphone monitoring jack, and dynamic gradient RGB.',
      ratingBreakdown: {5: 0.91, 4: 0.07, 3: 0.02, 2: 0.0, 1: 0.0},
      variantGroups: [
        ProductVariantGroup(
          groupName: 'Color Edition',
          options: [
            ProductVariantOption(
              id: 'dgm_blk',
              name: 'Midnight Black',
              colorHex: Color(0xFF09090B),
              subtitle: 'Signature matte black with shockmount',
              stock: 75,
            ),
            ProductVariantOption(
              id: 'dgm_wht',
              name: 'Pure Arctic White',
              colorHex: Color(0xFFFFFFFF),
              subtitle: 'Clean white arm and shockmount',
              stock: 65,
            ),
          ],
        ),
        ProductVariantGroup(
          groupName: 'Filter Package',
          options: [
            ProductVariantOption(
              id: 'filter_pop',
              name: 'Metal Mesh Pop Filter',
              subtitle: 'Acoustic curved metal shield included',
              stock: 80,
            ),
            ProductVariantOption(
              id: 'filter_foam',
              name: 'High-Density Foam Windscreen',
              subtitle: 'Tightly fitted for outdoor/fan noise',
              stock: 60,
            ),
          ],
        ),
      ],
      reviews: [
        ProductReviewModel(
          id: 'rev_dgm1',
          userName: 'Carlos Mendoza',
          initials: 'CM',
          avatarColor: const Color(0xFFEA580C),
          rating: 5.0,
          date: '2 days ago',
          variantName: 'Midnight Black • Metal Mesh Pop Filter',
          comment:
              'Best budget condenser microphone in the Philippines! 10k sold for a reason. Boom arm is sturdy and holds position easily.',
          reviewImages: [
            'https://images.unsplash.com/photo-1583743814966-8936f5b7be1a?auto=format&fit=crop&w=300&q=80',
          ],
          helpfulCount: 56,
        ),
        ProductReviewModel(
          id: 'rev_dgm2',
          userName: 'Janice Tan',
          initials: 'JT',
          avatarColor: const Color(0xFF0284C7),
          rating: 4.9,
          date: '5 days ago',
          variantName: 'Pure Arctic White • Metal Mesh Pop Filter',
          comment:
              'Noise cancellation button on the bottom actually works. Removes aircon humming completely.',
          helpfulCount: 31,
        ),
      ],
    ),

    ProductModel(
      title: 'Nexora Pro Heavy Duty Suspension Boom Arm',
      imageUrl:
          'https://images.unsplash.com/photo-1541140590914-579f21e6b72d?auto=format&fit=crop&w=600&q=80',
      category: 'Audio',
      isMall: true,
      discountTag: '-35%',
      price: '₱899',
      originalPrice: '₱1,400',
      rating: 4.8,
      soldCount: '3.2K sold',
      shippingTag: 'Free Shipping',
      hasPayLater: false,
      hasVoucher: true,
      shopId: 'nexora_official',
      shopName: 'Nexora Official Store',
      shopBadge: 'NEXORA MALL',
      stockQuantity: 210,
      description:
          'Heavy-duty alloy internal spring boom arm with concealed cable channel management. Supports up to 2.2kg payload.',
      ratingBreakdown: {5: 0.85, 4: 0.12, 3: 0.03, 2: 0.0, 1: 0.0},
      variantGroups: [
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

    ProductModel(
      title: 'Nexora Duo Wireless Lavalier Microphone Kit',
      imageUrl:
          'https://images.unsplash.com/photo-1618384887929-16ec33fab9ef?auto=format&fit=crop&w=600&q=80',
      category: 'Audio',
      isMall: true,
      discountTag: '-34%',
      price: '₱1,890',
      originalPrice: '₱2,890',
      rating: 5.0,
      soldCount: '1.4K sold',
      shippingTag: '2-3 Days | Metro Manila',
      hasPayLater: true,
      hasVoucher: true,
      shopId: 'nexora_official',
      shopName: 'Nexora Official Store',
      shopBadge: 'NEXORA MALL',
      stockQuantity: 65,
      description:
          '2.4GHz dual-channel wireless lavalier with OLED smart charging case, 48kHz lossless recording, and 200m line-of-sight range.',
      ratingBreakdown: {5: 0.95, 4: 0.05, 3: 0.0, 2: 0.0, 1: 0.0},
      variantGroups: [
        ProductVariantGroup(
          groupName: 'Device Compatibility',
          options: [
            ProductVariantOption(
              id: 'lav_typec',
              name: 'Type-C for Android / iPhone 15 & 16',
              subtitle: 'Direct digital OTG lossless audio',
              stock: 35,
            ),
            ProductVariantOption(
              id: 'lav_lightning',
              name: 'Lightning for iPhone 14 & Below',
              subtitle: 'Apple MFi certified chip',
              stock: 30,
            ),
          ],
        ),
      ],
      reviews: [
        ProductReviewModel(
          id: 'rev_lav1',
          userName: 'Patricia Joyce Cruz',
          initials: 'PC',
          avatarColor: const Color(0xFFD97706),
          rating: 5.0,
          date: '4 days ago',
          variantName: 'Type-C for Android / iPhone 15 & 16',
          comment:
              'Vlogging outdoors along BGC with heavy wind was no problem with the furry deadcats. Sounded like I was inside a studio!',
          helpfulCount: 22,
        ),
      ],
    ),

    // Flash Deals for Nexora
    ProductModel(
      title: 'Nexora StreamMic D20',
      imageUrl:
          'https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?auto=format&fit=crop&w=600&q=80',
      category: 'Audio',
      isMall: true,
      discountTag: '-48%',
      price: '₱1,549',
      originalPrice: '₱3,000',
      rating: 4.9,
      soldCount: '2.5K sold',
      shippingTag: 'Free Shipping',
      hasPayLater: true,
      hasVoucher: true,
      shopId: 'nexora_official',
      shopName: 'Nexora Official Store',
      shopBadge: 'NEXORA MALL',
      stockQuantity: 45,
      description:
          'Compact streaming condenser microphone with built-in DSP limiter, 24-bit/96kHz sampling, and quick mute button.',
      ratingBreakdown: {5: 0.88, 4: 0.10, 3: 0.02, 2: 0.0, 1: 0.0},
      variantGroups: [
        ProductVariantGroup(
          groupName: 'Acoustic Capsule',
          options: [
            ProductVariantOption(
              id: 'capsule_cardioid',
              name: 'Tight Cardioid Solo',
              subtitle: 'Focused on single front voice',
              stock: 25,
            ),
            ProductVariantOption(
              id: 'capsule_stereo',
              name: 'Dual Capsule Stereo Mode',
              subtitle: 'Ideal for instruments & ASMR',
              stock: 20,
            ),
          ],
        ),
      ],
      reviews: [
        ProductReviewModel(
          id: 'rev_d20',
          userName: 'Joshua David Ramos',
          initials: 'JR',
          avatarColor: const Color(0xFF6366F1),
          rating: 5.0,
          date: '1 week ago',
          variantName: 'Tight Cardioid Solo',
          comment: 'Flash deal price is an absolute steal! The DSP limiter stops voice clipping instantly.',
          helpfulCount: 19,
        ),
      ],
    ),

    ProductModel(
      title: 'Nexora Voice Master Amp',
      imageUrl:
          'https://images.unsplash.com/photo-1545454675-3531b543be5d?auto=format&fit=crop&w=600&q=80',
      category: 'Audio',
      isMall: true,
      discountTag: '-54%',
      price: '₱1,149',
      originalPrice: '₱2,500',
      rating: 4.8,
      soldCount: '1.1K sold',
      shippingTag: 'Free Shipping',
      hasPayLater: true,
      hasVoucher: true,
      shopId: 'nexora_official',
      shopName: 'Nexora Official Store',
      shopBadge: 'NEXORA MALL',
      stockQuantity: 30,
      description:
          'Multi-channel desktop audio interface with dual low-noise mic preamps and real-time hardware voice effects.',
      ratingBreakdown: {5: 0.86, 4: 0.11, 3: 0.03, 2: 0.0, 1: 0.0},
      variantGroups: [
        ProductVariantGroup(
          groupName: 'Input Configuration',
          options: [
            ProductVariantOption(
              id: 'amp_single',
              name: 'Single XLR + 1/4" Line In',
              subtitle: 'Compact for solo podcasts',
              stock: 18,
            ),
            ProductVariantOption(
              id: 'amp_dual',
              name: 'Dual Combo XLR + 48V Phantom',
              subtitle: 'Dual mic & guitar input (+₱400)',
              priceOffset: 400,
              stock: 12,
            ),
          ],
        ),
      ],
      reviews: [
        ProductReviewModel(
          id: 'rev_vma',
          userName: 'Jerome Castillo',
          initials: 'JC',
          avatarColor: const Color(0xFF0D9488),
          rating: 4.8,
          date: '5 days ago',
          variantName: 'Dual Combo XLR + 48V Phantom',
          comment: 'Powers my dynamic mic cleanly with plenty of gain headroom. Zero ground loop hiss.',
          helpfulCount: 14,
        ),
      ],
    ),

    ProductModel(
      title: 'Nexora Studio Pro Wireless ANC Headphone System',
      imageUrl:
          'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=600&q=80',
      category: 'Tech & Gadgets',
      isMall: true,
      discountTag: '-30%',
      price: '₱2,450.00',
      originalPrice: '₱3,500',
      rating: 4.9,
      soldCount: '1.8k sold',
      shippingTag: '2-3 Days | Metro Manila',
      hasPayLater: true,
      hasVoucher: false,
      shopId: 'nexora_official',
      shopName: 'Nexora Official Store',
      shopBadge: 'NEXORA MALL',
      stockQuantity: 92,
      description:
          'Flagship hybrid active noise cancelling headphone with 40mm beryllium diaphragm drivers, 60h battery life, and spatial audio.',
      ratingBreakdown: {5: 0.90, 4: 0.08, 3: 0.02, 2: 0.0, 1: 0.0},
      variantGroups: [
        ProductVariantGroup(
          groupName: 'Color Palette',
          options: [
            ProductVariantOption(
              id: 'hp_grey',
              name: 'Matte Space Grey',
              colorHex: Color(0xFF475569),
              subtitle: 'Anodized aluminum outer cups',
              stock: 50,
            ),
            ProductVariantOption(
              id: 'hp_white',
              name: 'Lunar White',
              colorHex: Color(0xFFF1F5F9),
              subtitle: 'Stain-resistant silicone headband',
              stock: 42,
            ),
          ],
        ),
        ProductVariantGroup(
          groupName: 'Cushion Material',
          options: [
            ProductVariantOption(
              id: 'pad_foam',
              name: 'High-Density Memory Foam',
              subtitle: 'Warm acoustic seal',
              stock: 52,
            ),
            ProductVariantOption(
              id: 'pad_gel',
              name: 'Cooling Gel Infused Leatherette',
              subtitle: 'All-day breathable comfort',
              stock: 40,
            ),
          ],
        ),
      ],
      reviews: [
        ProductReviewModel(
          id: 'rev_hp1',
          userName: 'Kristine Mae Bautista',
          initials: 'KB',
          avatarColor: const Color(0xFFEC4899),
          rating: 5.0,
          date: '3 days ago',
          variantName: 'Matte Space Grey • Cooling Gel Infused Leatherette',
          comment:
              'The noise cancellation on the MRT-3 is magic. Drowns out engine rumbling completely. Battery lasts almost two weeks on daily commutes!',
          helpfulCount: 47,
        ),
      ],
    ),

    ProductModel(
      title: 'Nexora Apex 75% Custom Mechanical Keyboard RGB',
      imageUrl:
          'https://images.unsplash.com/photo-1587829741301-dc798b83add3?auto=format&fit=crop&w=600&q=80',
      category: 'Gaming',
      isMall: true,
      discountTag: '-28%',
      price: '₱3,890.00',
      originalPrice: '₱5,400',
      rating: 4.9,
      soldCount: '620 sold',
      shippingTag: '2-3 Days | Metro Manila',
      hasPayLater: true,
      hasVoucher: false,
      shopId: 'nexora_official',
      shopName: 'Nexora Official Store',
      shopBadge: 'NEXORA MALL',
      stockQuantity: 58,
      description:
          'Gasket-mounted hot-swappable 75% mechanical keyboard with CNC aluminum body, sound-dampening poron foam layers, and multi-device tri-mode wireless.',
      ratingBreakdown: {5: 0.92, 4: 0.07, 3: 0.01, 2: 0.0, 1: 0.0},
      variantGroups: [
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
          reviewImages: [
            'https://images.unsplash.com/photo-1587829741301-dc798b83add3?auto=format&fit=crop&w=300&q=80',
          ],
          helpfulCount: 38,
        ),
        ProductReviewModel(
          id: 'rev_kb2',
          userName: 'Alyssa Chen',
          initials: 'AC',
          avatarColor: const Color(0xFF00B4D8),
          rating: 5.0,
          date: '4d ago',
          variantName: 'Midnight Navy • Silent Red (Damped Linear)',
          comment:
              'Seamlessly connects between my MacBook M3 Pro and my Windows desktop using the 2.4GHz dongle and Bluetooth. Rotary dial is so smooth!',
          helpfulCount: 24,
        ),
      ],
    ),

    // -------------------------------------------------------------
    // SOUNDMAX AUDIO STORE PRODUCTS
    // -------------------------------------------------------------
    ProductModel(
      title: 'SoundMax Pro Active Noise Cancelling Studio Headset',
      imageUrl:
          'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=600&q=80',
      category: 'Tech & Gadgets',
      isMall: true,
      discountTag: '-26%',
      price: '₱3,299.00',
      originalPrice: '₱4,500',
      rating: 4.9,
      soldCount: '2.4K+ sold',
      shippingTag: 'Free Shipping',
      hasPayLater: true,
      hasVoucher: true,
      shopId: 'soundmax_audio',
      shopName: 'SoundMax Pro Audio',
      shopBadge: 'NEXORA MALL',
      stockQuantity: 72,
      description:
          'Hi-Res Audio Certified wireless headphones with LDAC codec support, 45dB hybrid ANC, and custom-tuned 45mm dynamic drivers.',
      ratingBreakdown: {5: 0.90, 4: 0.08, 3: 0.02, 2: 0.0, 1: 0.0},
      variantGroups: [
        ProductVariantGroup(
          groupName: 'Color Edition',
          options: [
            ProductVariantOption(
              id: 'sm_blk',
              name: 'Matte Jet Black',
              colorHex: Color(0xFF111827),
              stock: 42,
            ),
            ProductVariantOption(
              id: 'sm_slv',
              name: 'Platinum Silver',
              colorHex: Color(0xFFCBD5E1),
              stock: 30,
            ),
          ],
        ),
      ],
      reviews: [
        ProductReviewModel(
          id: 'rev_sm1',
          userName: 'Angelo D. Mercado',
          initials: 'AM',
          avatarColor: const Color(0xFF3B82F6),
          rating: 5.0,
          date: '1 week ago',
          variantName: 'Matte Jet Black',
          comment: 'Soundstage is wide and punchy. LDAC streaming from my phone sounds incredibly detailed.',
          helpfulCount: 19,
        ),
      ],
    ),

    ProductModel(
      title: 'SoundMax Pulse 360 Portable Bluetooth Speaker',
      imageUrl:
          'https://images.unsplash.com/photo-1545454675-3531b543be5d?auto=format&fit=crop&w=600&q=80',
      category: 'Tech & Gadgets',
      isMall: true,
      discountTag: '-31%',
      price: '₱1,499.00',
      originalPrice: '₱2,199',
      rating: 4.8,
      soldCount: '4.1K+ sold',
      shippingTag: 'Free Shipping',
      hasPayLater: false,
      hasVoucher: true,
      shopId: 'soundmax_audio',
      shopName: 'SoundMax Pro Audio',
      shopBadge: 'NEXORA MALL',
      stockQuantity: 110,
      description:
          'IPX7 waterproof cylindrical outdoor speaker with 360-degree sound projection, deep passive bass radiators, and 24h battery.',
      ratingBreakdown: {5: 0.85, 4: 0.12, 3: 0.03, 2: 0.0, 1: 0.0},
      variantGroups: [
        ProductVariantGroup(
          groupName: 'Color Edition',
          options: [
            ProductVariantOption(
              id: 'pulse_blue',
              name: 'Ocean Cobalt Blue',
              colorHex: Color(0xFF0284C7),
              stock: 60,
            ),
            ProductVariantOption(
              id: 'pulse_blk',
              name: 'Stealth Black',
              colorHex: Color(0xFF0F172A),
              stock: 50,
            ),
          ],
        ),
      ],
      reviews: [
        ProductReviewModel(
          id: 'rev_pulse1',
          userName: 'Maria Santos',
          initials: 'MS',
          avatarColor: const Color(0xFF10B981),
          rating: 5.0,
          date: '2 weeks ago',
          variantName: 'Ocean Cobalt Blue',
          comment: 'Took it to our beach outing in Batangas. It got splashed with saltwater and worked fine!',
          helpfulCount: 26,
        ),
      ],
    ),

    // -------------------------------------------------------------
    // MIKANA JEWELRY PRODUCTS
    // -------------------------------------------------------------
    ProductModel(
      title: 'Mikana 18k Gold Plated Sakura Pendant Necklace',
      imageUrl:
          'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?auto=format&fit=crop&w=600&q=80',
      category: 'Jewelry',
      isMall: true,
      discountTag: '-35%',
      price: '₱1,299.00',
      originalPrice: '₱1,999',
      rating: 4.8,
      soldCount: '8.3K+ sold',
      shippingTag: 'Free Shipping',
      hasPayLater: true,
      hasVoucher: true,
      shopId: 'mikana_official',
      shopName: 'Mikana Jewelry & Co.',
      shopBadge: 'NEXORA MALL',
      stockQuantity: 120,
      description:
          'Inspired by Japanese cherry blossoms. 18k thick gold plating over titanium steel. Non-tarnish and hypoallergenic for sensitive skin.',
      ratingBreakdown: {5: 0.88, 4: 0.09, 3: 0.03, 2: 0.0, 1: 0.0},
      variantGroups: [
        ProductVariantGroup(
          groupName: 'Gold Plating Finish',
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
        ProductVariantGroup(
          groupName: 'Chain Length',
          options: [
            ProductVariantOption(
              id: 'len_40',
              name: '40cm + 5cm Extender (Choker Fit)',
              stock: 60,
            ),
            ProductVariantOption(
              id: 'len_45',
              name: '45cm + 5cm Extender (Princess Fit)',
              stock: 60,
            ),
          ],
        ),
      ],
      reviews: [
        ProductReviewModel(
          id: 'rev_mk1',
          userName: 'Stephanie Anne Villar',
          initials: 'SV',
          avatarColor: const Color(0xFFBE185D),
          rating: 5.0,
          date: '4 days ago',
          variantName: '18k Classic Yellow Gold • 45cm + 5cm Extender',
          comment:
              'I\'ve worn this in the shower for 3 weeks straight and it has not tarnished or faded whatsoever. Mikana packaging box is so luxe!',
          reviewImages: [
            'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?auto=format&fit=crop&w=300&q=80',
          ],
          helpfulCount: 68,
        ),
      ],
    ),

    // -------------------------------------------------------------
    // LOGITECH HUB PRODUCTS
    // -------------------------------------------------------------
    ProductModel(
      title: 'LogiTech Superlight Wireless Esports Gaming Mouse',
      imageUrl:
          'https://images.unsplash.com/photo-1615663245857-ac93bb7c39e7?auto=format&fit=crop&w=600&q=80',
      category: 'Gaming',
      isMall: true,
      discountTag: '-22%',
      price: '₱4,790.00',
      originalPrice: '₱6,200',
      rating: 4.9,
      soldCount: '9.8K+ sold',
      shippingTag: 'Free Shipping',
      hasPayLater: true,
      hasVoucher: true,
      shopId: 'logitech_hub',
      shopName: 'LogiTech Gear Hub',
      shopBadge: 'OFFICIAL STORE',
      stockQuantity: 60,
      description:
          'Weighing under 60 grams with HERO 25K optical sensor and LIGHTSPEED 1ms wireless technology. Designed with top esports pros.',
      ratingBreakdown: {5: 0.94, 4: 0.05, 3: 0.01, 2: 0.0, 1: 0.0},
      variantGroups: [
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
          comment: 'Tracking and flicking feel effortless at under 60 grams. Battery lasts well over a month with daily ranked games.',
          helpfulCount: 52,
        ),
      ],
    ),

    // -------------------------------------------------------------
    // AURA STUDIOS APPAREL PRODUCTS
    // -------------------------------------------------------------
    ProductModel(
      title: 'Aura Minimalist Heavy Fleece Hoodie Streetwear',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDzlfM9UI-vGVUMAkUKI4WCoDpA4njq2i2bH5FsGflhVF28xwuR4599HpCZ5j6YtJKmVEHwfR2hVgWxghw8H2THFwFCT27W7Fk_z0wKe4q_kg8uwhxD9uXh8zSSoZ67ltyCehtwjAQfkdZzcDRantW9HcQz8VT_3vLB_3girMZ7tKvzHlokhxLLe-oKWduwhOBz7fV1Jgul-8KVjTL7YA5C12MOUbZqrBtVidhRBHOauvw8mO5Sfus',
      category: 'Fashion',
      isMall: true,
      discountTag: '-22%',
      price: '₱1,250.00',
      originalPrice: '₱1,600',
      rating: 4.8,
      soldCount: '840 sold',
      shippingTag: '2-3 Days | Metro Manila',
      hasPayLater: false,
      hasVoucher: true,
      shopId: 'aura_studios',
      shopName: 'Aura Studios Official',
      shopBadge: 'TOP SELLER',
      stockQuantity: 150,
      description:
          '450GSM heavy brushed cotton fleece hoodie with double-layer oversized hood, drop-shoulder silhouette, and hidden phone pocket.',
      ratingBreakdown: {5: 0.87, 4: 0.10, 3: 0.03, 2: 0.0, 1: 0.0},
      variantGroups: [
        ProductVariantGroup(
          groupName: 'Streetwear Wash',
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
          groupName: 'Oversized Size',
          options: [
            ProductVariantOption(id: 'sz_s', name: 'Size S (Relaxed)', stock: 35),
            ProductVariantOption(id: 'sz_m', name: 'Size M (Boxy)', stock: 45),
            ProductVariantOption(id: 'sz_l', name: 'Size L (Oversized)', stock: 40),
            ProductVariantOption(id: 'sz_xl', name: 'Size XL (Baggy)', stock: 30),
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
  ];
}
