import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nexora_flutter_app/app/routes/app_routes.dart';
import 'package:nexora_flutter_app/app/theme/nexora_theme.dart';
import 'package:nexora_flutter_app/core/models/shop_models.dart';
import 'package:nexora_flutter_app/core/services/cart_service.dart';
import 'package:nexora_flutter_app/core/services/chat_service.dart';
import 'package:nexora_flutter_app/core/services/shop_service.dart';
import 'package:nexora_flutter_app/core/services/buyer_account_service.dart';
import 'package:nexora_flutter_app/core/services/wishlist_service.dart';
import 'package:nexora_flutter_app/core/utils/guest_auth_guard.dart';
import 'package:nexora_flutter_app/core/widgets/add_to_cart_bottom_sheet.dart';
import 'package:nexora_flutter_app/core/widgets/added_to_cart_hud.dart';
import 'package:nexora_flutter_app/core/widgets/added_to_wishlist_hud.dart';
import 'package:nexora_flutter_app/core/widgets/nexora_widgets.dart';
import 'package:nexora_flutter_app/features/chat/presentation/chat_detail_page.dart';
import 'package:nexora_flutter_app/features/home/presentation/widgets/product_card.dart';
import 'package:nexora_flutter_app/features/product_details/presentation/product_reviews_page.dart';

class ProductDetailsPage extends StatefulWidget {
  const ProductDetailsPage({super.key});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  ProductModel? _productArg;
  bool _initializedArgs = false;

  static bool get _isTestEnvironment {
    if (kIsWeb) return false;
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  int _selectedImageIndex = 0;
  late final PageController _pageController;
  late final TextEditingController _quantityController;
  final ScrollController _scrollController = ScrollController();
  int _selectedColorIndex = 0;
  int _selectedSwitchIndex = 0;
  int _selectedLayoutIndex = 0;
  int _quantity = 1;
  final Map<int, int> _selectedVariantGroupIndices = {};
  String _selectedReviewFilter = 'All';

  final List<String> _productImages = [];

  final List<Map<String, dynamic>> _colorVariants = [
    {
      'name': 'Chalk White & Violet',
      'circleColor': const Color(0xFFC4B5FD),
      'label': 'Chalk / Violet',
    },
    {
      'name': 'Midnight Navy',
      'circleColor': const Color(0xFF0F172A),
      'label': 'Midnight Navy',
    },
    {
      'name': 'Phantom Black',
      'circleColor': const Color(0xFF18181B),
      'label': 'Phantom Black',
    },
  ];

  final List<Map<String, String>> _switchOptions = [
    {
      'title': 'Gateron Pro Yellow',
      'subtitle': 'Smooth linear feel • 50g operating force',
    },
    {
      'title': 'Kailh Box White',
      'subtitle': 'Crisp acoustic clickbar • 45g force',
    },
    {
      'title': 'Silent Red Linear',
      'subtitle': 'Silenced dampeners for studio work • 45g force',
    },
  ];

  final List<String> _formFactors = ['75% Compact', 'TKL (80%)', 'Full 100%'];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _quantityController = TextEditingController(text: '$_quantity');
  }

  @override
  void dispose() {
    AddedToCartHUD.dismiss();
    _pageController.dispose();
    _quantityController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedArgs) {
      _initializedArgs = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is ProductModel) {
        _productArg = args;
      } else if (args is String) {
        _productArg = ShopService.instance.getProductById(args);
      }
      _productArg ??= ShopService.allAppProducts.first;
      _productImages.clear();
      if (_productArg!.galleryImages != null &&
          _productArg!.galleryImages!.isNotEmpty) {
        _productImages.addAll(_productArg!.galleryImages!);
      } else if (_productArg!.imageUrl.isNotEmpty) {
        _productImages.add(_productArg!.imageUrl);
      }
    }
  }

  bool get _areAllVariantsSelected {
    if (_productArg?.variantGroups == null ||
        _productArg!.variantGroups!.isEmpty) {
      return true;
    }
    return _selectedVariantGroupIndices.length ==
        _productArg!.variantGroups!.length;
  }

  String get _productTitle =>
      _productArg?.title ?? 'Nexora Aura 75 Mechanical Keyboard';

  int get _maxStock {
    if (_productArg == null) return 150;
    // Combination stock support (BUY-PDP-002, BUY-PDP-003)
    if (_productArg!.variantGroups != null &&
        _productArg!.variantGroups!.length >= 2 &&
        _productArg!.combinationStock != null) {
      final grp0 = _productArg!.variantGroups![0];
      final grp1 = _productArg!.variantGroups![1];
      final sel0 = _selectedVariantGroupIndices[0];
      final sel1 = _selectedVariantGroupIndices[1];
      if (sel0 != null &&
          sel1 != null &&
          sel0 < grp0.options.length &&
          sel1 < grp1.options.length) {
        final key = '${grp0.options[sel0].name}-${grp1.options[sel1].name}';
        if (_productArg!.combinationStock!.containsKey(key)) {
          return _productArg!.combinationStock![key]!;
        }
      } else if (sel0 != null && sel0 < grp0.options.length) {
        final prefix = '${grp0.options[sel0].name}-';
        final matchingKeys = _productArg!.combinationStock!.keys.where(
          (k) => k.startsWith(prefix),
        );
        if (matchingKeys.isNotEmpty) {
          return _productArg!.combinationStock![matchingKeys.first]!;
        }
      }
    }
    // Individual option stock
    if (_productArg!.variantGroups != null) {
      for (int i = 0; i < _productArg!.variantGroups!.length; i++) {
        final grp = _productArg!.variantGroups![i];
        final selIdx = _selectedVariantGroupIndices[i];
        if (selIdx != null && selIdx < grp.options.length) {
          return grp.options[selIdx].stock;
        }
      }
    }
    return _productArg!.stockQuantity;
  }

  double get _productBasePrice {
    if (_productArg == null) return 3200.0;
    if (_productArg!.isFlashSale && _productArg!.flashSalePrice != null) {
      final clean = _productArg!.flashSalePrice!.replaceAll(
        RegExp(r'[^0-9.]'),
        '',
      );
      return double.tryParse(clean) ?? 299.0;
    }
    final clean = _productArg!.price.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(clean) ?? 3200.0;
  }

  double get _productOriginalPrice {
    if (_productArg == null || _productArg!.originalPrice == null) {
      return 4000.0;
    }
    final clean = _productArg!.originalPrice!.replaceAll(
      RegExp(r'[^0-9.]'),
      '',
    );
    return double.tryParse(clean) ?? (_productBasePrice * 1.25);
  }

  double get _currentPriceOffset {
    double offset = 0.0;
    if (_productArg?.variantGroups != null) {
      for (int i = 0; i < _productArg!.variantGroups!.length; i++) {
        final grp = _productArg!.variantGroups![i];
        final selIdx = _selectedVariantGroupIndices[i];
        if (selIdx != null && selIdx < grp.options.length) {
          offset += grp.options[selIdx].priceOffset;
        }
      }
    }
    return offset;
  }

  double get _effectivePrice => _productBasePrice + _currentPriceOffset;

  String get _currentVariantSummary {
    if (_productArg?.variantGroups != null &&
        _productArg!.variantGroups!.isNotEmpty) {
      final parts = <String>[];
      for (int i = 0; i < _productArg!.variantGroups!.length; i++) {
        final grp = _productArg!.variantGroups![i];
        final selIdx = _selectedVariantGroupIndices[i];
        if (selIdx != null && selIdx < grp.options.length) {
          parts.add(grp.options[selIdx].name);
        }
      }
      return parts.join(' • ');
    }
    final selectedColor =
        _colorVariants[_selectedColorIndex]['label'] as String;
    final selectedSwitch =
        _switchOptions[_selectedSwitchIndex]['title'] as String;
    return '$selectedColor, $selectedSwitch';
  }

  String get _productKey =>
      _productArg?.id.isNotEmpty == true ? _productArg!.id : _productTitle;

  ProductModel get _resolvedProduct =>
      _productArg ??
      ProductModel(
        id: _productKey,
        title: _productTitle,
        imageUrl: _productImages.isNotEmpty ? _productImages.first : '',
        category: 'Tech & Gadgets',
        price: '₱${_effectivePrice.toStringAsFixed(0)}',
        originalPrice: '₱${_productOriginalPrice.toStringAsFixed(0)}',
        rating: 4.9,
        soldCount: '1.2k',
        shippingTag: '2-3 Days | Metro Manila',
        isMall: true,
      );

  void _navigateToReviewsPage() {
    Navigator.pushNamed(
      context,
      AppRoutes.productReviews,
      arguments: {
        'product': _resolvedProduct,
        'variant': _currentVariantSummary,
      },
    );
  }

  void _openWriteReviewModal() {
    showWriteProductReviewModal(
      context,
      product: _resolvedProduct,
      initialVariant: _currentVariantSummary,
      productKey: _productKey,
    );
  }

  String? _validateQuantityInput(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return 'Please enter a quantity';
    final parsed = num.tryParse(trimmed);
    if (parsed == null) return 'Please enter a valid whole number for quantity';
    if (parsed is double && parsed != parsed.toInt()) {
      return 'Quantity must be a whole number';
    }
    final intVal = parsed.toInt();
    if (intVal <= 0) return 'Quantity must be at least 1';
    if (intVal > _maxStock) {
      return 'Quantity exceeds available stock ($_maxStock)';
    }
    return null;
  }

  void _incrementQuantity() {
    final current = int.tryParse(_quantityController.text.trim()) ?? _quantity;
    if (current < _maxStock) {
      setState(() {
        _quantity = current + 1;
        _quantityController.text = '$_quantity';
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reached max available quantity ($current)'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _decrementQuantity() {
    final current = int.tryParse(_quantityController.text.trim()) ?? _quantity;
    if (current > 1) {
      setState(() {
        _quantity = current - 1;
        _quantityController.text = '$_quantity';
      });
    }
  }

  void _handleAddToCart() {
    // Inactive check (BUY-PDP-008)
    if (_productArg?.isActive == false || _productArg?.isDeleted == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This product is no longer available'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Vacation check (BUY-PDP-008, BUY-SRCH-011)
    if (_productArg?.isOnVacation == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Seller is on vacation. Purchasing is temporarily unavailable.',
          ),
          backgroundColor: Color(0xFFEA580C),
        ),
      );
      return;
    }

    // If all variations are selected, or running in automated test mode: directly add to cart & trigger animated HUD
    if (_areAllVariantsSelected || _isTestEnvironment) {
      // Mandatory Variant Check (BUY-PDP-001)
      if (!_areAllVariantsSelected) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a variation'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Quantity Input Validation (BUY-PDP-004)
      final qError = _validateQuantityInput(_quantityController.text);
      if (qError != null) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(qError),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
      _quantity = int.parse(_quantityController.text.trim());

      // Per-buyer Purchase Limit Check (BUY-PDP-005)
      final limit = _productArg?.perBuyerLimit;
      if (limit != null) {
        final pid = _productArg!.id.isNotEmpty
            ? _productArg!.id
            : _productTitle;
        final purchasedCount = CartService.instance.getPurchasedCount(pid);
        final inCartCount = CartService.instance.items
            .where((i) => i.title == _productTitle)
            .fold(0, (sum, i) => sum + i.quantity);
        if (purchasedCount + inCartCount + _quantity > limit) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Per-buyer purchase limit of $limit items reached for this product.',
              ),
              backgroundColor: const Color(0xFFEF4444),
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }
      }

      CartService.instance.addToCart(
        title: _productTitle,
        variant: _currentVariantSummary,
        price: _effectivePrice,
        originalPrice: _productOriginalPrice,
        imageUrl: _productImages.first,
        storeName:
            _productArg?.shopName ??
            (_productArg?.isMall == true
                ? 'Nexora Official Store'
                : 'Nexora Preferred Store'),
        storeBadge:
            _productArg?.shopBadge ??
            (_productArg?.isMall == true ? 'MALL' : 'OFFICIAL STORE'),
        quantity: _quantity,
      );

      // Show center bouncing scale & fade animated HUD matching modern e-commerce standard
      AddedToCartHUD.show(context);

      if (_isTestEnvironment) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${_quantity}x $_productTitle to cart'),
            backgroundColor: const Color(0xFF0066FF),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // In live application (device / web): open the modern Shopee-standard Add to Cart Bottom Sheet modal!
    final productToOrder =
        _productArg ??
        ProductModel(
          title: _productTitle,
          imageUrl: _productImages.isNotEmpty ? _productImages.first : '',
          category: 'Tech & Gadgets',
          price: '₱${_effectivePrice.toStringAsFixed(0)}',
          originalPrice: '₱${_productOriginalPrice.toStringAsFixed(0)}',
          rating: 4.9,
          soldCount: '1.2k',
          shippingTag: '2-3 Days | Metro Manila',
          isMall: true,
        );

    AddToCartBottomSheet.show(
      context,
      product: productToOrder,
      initialQuantity: _quantity,
      initialSelectedIndices: _selectedVariantGroupIndices,
      onAdded: () {
        if (mounted) setState(() {});
      },
    );
  }

  Future<void> _handleBuyNow() async {
    // Inactive check (BUY-PDP-008)
    if (_productArg?.isActive == false || _productArg?.isDeleted == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This product is no longer available'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Vacation check (BUY-PDP-008, BUY-SRCH-011)
    if (_productArg?.isOnVacation == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Seller is on vacation. Purchasing is temporarily unavailable.',
          ),
          backgroundColor: Color(0xFFEA580C),
        ),
      );
      return;
    }

    // Mandatory Variant Check (BUY-PDP-001)
    if (!_areAllVariantsSelected) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a variation'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Require login if in guest mode before proceeding to order
    if (!BuyerAccountService.instance.isLoggedIn) {
      final loggedIn = await GuestAuthGuard.requireLogin(
        context,
        title: 'Sign In to Buy Now',
        message: 'Please sign in or create an account to proceed with your order and secure delivery.',
      );
      if (!loggedIn || !mounted) return;
    }

    // Quantity Input Validation (BUY-PDP-004)
    final qError = _validateQuantityInput(_quantityController.text);
    if (qError != null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(qError),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    _quantity = int.parse(_quantityController.text.trim());

    // Per-buyer Purchase Limit Check (BUY-PDP-005)
    final limit = _productArg?.perBuyerLimit;
    if (limit != null) {
      final pid = _productArg!.id.isNotEmpty ? _productArg!.id : _productTitle;
      final purchasedCount = CartService.instance.getPurchasedCount(pid);
      final inCartCount = CartService.instance.items
          .where((i) => i.title == _productTitle)
          .fold(0, (sum, i) => sum + i.quantity);
      if (purchasedCount + inCartCount + _quantity > limit) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Per-buyer purchase limit of $limit items reached for this product.',
            ),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
    }

    // Direct Buy Now Cart Isolation (BUY-PDP-007)
    CartService.instance.buyNow(
      title: _productTitle,
      variant: _currentVariantSummary,
      price: _effectivePrice,
      originalPrice: _productOriginalPrice,
      imageUrl: _productImages.first,
      storeName:
          _productArg?.shopName ??
          (_productArg?.isMall == true
              ? 'Nexora Official Store'
              : 'Nexora Preferred Store'),
      storeBadge:
          _productArg?.shopBadge ??
          (_productArg?.isMall == true ? 'MALL' : 'PREFERRED'),
      quantity: _quantity,
    );

    Navigator.pushNamed(context, AppRoutes.checkout);
  }

  @override
  Widget build(BuildContext context) {
    // Product screen of an unavailable product (BUY-PDP-008)
    if (_productArg == null ||
        !_productArg!.isActive ||
        _productArg!.isDeleted) {
      return _buildProductUnavailableView(context);
    }

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: NexoraAppBar(
        fallbackRoute: AppRoutes.home,
        titleText: 'Product Details',
        toolbarHeight: 56,
        showBottomDivider: true,
        actions: [
          AnimatedBuilder(
            animation: WishlistService.instance,
            builder: (context, _) {
              final isFavorite = WishlistService.instance.isInWishlist(
                _productTitle,
              );
              return IconButton(
                tooltip: isFavorite
                    ? 'Remove from wishlist'
                    : 'Save to wishlist',
                icon: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFavorite
                      ? theme.colorScheme.tertiary
                      : theme.colorScheme.onSurface,
                ),
                onPressed: () {
                  final productToSave =
                      _productArg ??
                      ProductModel(
                        title: _productTitle,
                        imageUrl: _productImages.first,
                        category: 'Tech & Gadgets',
                        price: '₱${_productBasePrice.toStringAsFixed(2)}',
                        originalPrice:
                            '₱${_productOriginalPrice.toStringAsFixed(2)}',
                        rating: 4.9,
                        soldCount: '1.2k',
                        shippingTag: '2-3 Days | Metro Manila',
                        isMall: true,
                      );

                  WishlistService.instance.toggleWishlist(productToSave);
                  if (!isFavorite) {
                    AddedToWishlistHUD.show(
                      context,
                      message: 'Saved to Wishlist',
                      count: WishlistService.instance.itemCount,
                    );
                  } else {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Removed from Wishlist (${WishlistService.instance.itemCount} remaining)',
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                },
              );
            },
          ),
          IconButton(
            tooltip: 'Copy product link',
            icon: const Icon(Icons.share_outlined),
            color: theme.colorScheme.onSurface,
            onPressed: () {
              // Universal Share Link (BUY-PDP-010)
              final prodId = _productArg?.id.isNotEmpty == true
                  ? _productArg!.id
                  : 'P-01';
              final shareUrl = 'https://nexora.app/products/$prodId';
              Clipboard.setData(ClipboardData(text: shareUrl));
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Product link copied: $shareUrl'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: NexoraTheme.darkNavy,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_productArg?.isActive == false) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: Color(0xFFDC2626),
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'This product is no longer available (Product deactivated by seller)',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF991B1B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_productArg?.isOnVacation == true) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.beach_access_rounded,
                          color: Color(0xFFD97706),
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Seller is currently on vacation. Store mode is paused.',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Main Gallery Image & Thumbnails
                _buildGallerySection(),
                const SizedBox(height: 18),

                // Title & Subtitle Header
                Text(
                  _productTitle,
                  style: TextStyle(
                    fontFamily: NexoraTheme.fontFamily,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.25,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 12),

                // Rating & Category Rank Row
                AnimatedBuilder(
                  animation: ShopService.instance,
                  builder: (context, _) {
                    final avgRating =
                        ShopService.instance.getProductAverageRating(
                      _productKey,
                      _productArg?.rating ?? 4.9,
                    );
                    final reviewCount =
                        ShopService.instance.getProductReviewCount(
                      _productKey,
                      _productArg?.reviews?.length ?? 1,
                    );
                    return Wrap(
                      spacing: NexoraSpacing.sm,
                      runSpacing: NexoraSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Color(0xFFF59E0B),
                        ),
                        Text(
                          avgRating.toStringAsFixed(1),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        GestureDetector(
                          onTap: _navigateToReviewsPage,
                          child: Text(
                            reviewCount == 1
                                ? '1 review'
                                : '$reviewCount reviews',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        Text(
                          _cleanSoldCount(_productArg?.soldCount ?? '1.2k+'),
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Price Box Banner
                const bool.fromEnvironment('NEXORA_LEGACY_SHOPPING')
                    ? _buildPriceCard()
                    : _buildRefinedPricePanel(),

                // Claimable Vouchers (BUY-PDP-006)
                _buildClaimableVouchersSection(),
                const SizedBox(height: 18),

                // Dynamic Variants Selector
                _buildDynamicVariantsSection(),

                // Quantity Stepper Row
                _buildQuantitySection(),
                const SizedBox(height: 18),

                // Official Shop Store Profile Banner (Clickable -> ShopPage)
                _buildShopStoreBanner(),
                const SizedBox(height: 20),

                // Dedicated Product Description & Details Section
                _buildProductDescriptionSection(),
                const SizedBox(height: 24),

                // Ratings & Reviews Section (Interactive reviews list)
                _buildReviewsSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
      bottomNavigationBar: const bool.fromEnvironment('NEXORA_LEGACY_SHOPPING')
          ? _buildBottomActionDock()
          : _buildRefinedBottomActionDock(),
    );
  }

  Widget _buildGallerySection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 260,
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _productImages.length,
                  onPageChanged: (idx) {
                    setState(() => _selectedImageIndex = idx);
                  },
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _openZoomImageViewer(context, index),
                      child: InteractiveViewer(
                        minScale: 1.0,
                        maxScale: 4.0,
                        child: Image.network(
                          _productImages[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.keyboard,
                                size: 64,
                                color: Color(0xFF94A3B8),
                              ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Page Counter Indicator bottom-right
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_selectedImageIndex + 1}/${_productImages.length}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Thumbnails Carousel (Left-aligned)
        Align(
          alignment: Alignment.centerLeft,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: List.generate(_productImages.length, (index) {
                final isSelected = _selectedImageIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedImageIndex = index;
                        if (_pageController.hasClients) {
                          _pageController.jumpToPage(index);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 64,
                      height: 52,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.network(
                        _productImages[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFFE2E8F0),
                          child: const Icon(
                            Icons.image,
                            size: 20,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRefinedPricePanel() {
    final theme = Theme.of(context);
    final isFlashSale = _productArg?.isFlashSale == true;
    final discount = _productArg?.discountTag;
    final stockLeft = isFlashSale
        ? _productArg?.flashSaleStockRemaining ?? _maxStock
        : _maxStock;

    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(NexoraRadius.card),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(NexoraSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isFlashSale)
              Padding(
                padding: const EdgeInsets.only(bottom: NexoraSpacing.sm),
                child: Row(
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      size: 18,
                      color: theme.colorScheme.tertiary,
                    ),
                    const SizedBox(width: NexoraSpacing.xs),
                    Text(
                      'FLASH SALE',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.tertiary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Ends in ${_productArg?.flashSaleTimeRemaining != null ? _formatDuration(_productArg!.flashSaleTimeRemaining!) : '02:45:18'}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            Wrap(
              spacing: NexoraSpacing.sm,
              runSpacing: NexoraSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '₱${_effectivePrice.toStringAsFixed(2)}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: NexoraTheme.priceColor(context),
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                if (_productOriginalPrice > _effectivePrice)
                  Text(
                    '₱${_productOriginalPrice.toStringAsFixed(2)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                if (discount != null)
                  Chip(
                    label: Text(discount),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            if (stockLeft <= 0) ...[
              const SizedBox(height: NexoraSpacing.xs),
              Text(
                'Currently out of stock',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ] else if (isFlashSale) ...[
              const SizedBox(height: NexoraSpacing.xs),
              Text(
                'Limited-time offer',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriceCard() {
    final isFlash = _productArg?.isFlashSale == true;
    final discount =
        _productArg?.discountTag ?? (isFlash ? '-33% FLASH' : '-20% OFF');

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isFlash) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE11D48), Color(0xFFBE123C)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  const Text(
                    'FLASH SALE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.timer_outlined,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Ends in ${_productArg?.flashSaleTimeRemaining != null ? _formatDuration(_productArg!.flashSaleTimeRemaining!) : "02:45:18"}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '₱${_effectivePrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '₱${_productOriginalPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        discount,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (isFlash &&
                    _productArg?.flashSaleStockRemaining != null) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        size: 14,
                        color: Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_productArg!.flashSaleStockRemaining} flash units left',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.whatshot,
                        size: 14,
                        color: Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'In stock',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPaletteSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Color Palette',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _colorVariants[_selectedColorIndex]['name'] as String,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: List.generate(_colorVariants.length, (index) {
              final isSelected = _selectedColorIndex == index;
              final variant = _colorVariants[index];

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColorIndex = index;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: variant['circleColor'] as Color,
                            shape: BoxShape.circle,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  size: 13,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          variant['label'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isSelected
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchOptionsSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Mechanical Switches',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _switchOptions[_selectedSwitchIndex]['title']!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Column(
          children: List.generate(_switchOptions.length, (index) {
            final isSelected = _selectedSwitchIndex == index;
            final opt = _switchOptions[index];

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedSwitchIndex = index;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        border: isSelected
                            ? null
                            : Border.all(
                                color: theme.colorScheme.outlineVariant,
                                width: 2,
                              ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 12,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            opt['title']!,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: isSelected
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            opt['subtitle']!,
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected
                                  ? theme.colorScheme.onPrimaryContainer
                                      .withValues(alpha: 0.8)
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildFormFactorSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Form Factor',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: List.generate(_formFactors.length, (index) {
              final isSelected = _selectedLayoutIndex == index;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedLayoutIndex = index;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Text(
                      _formFactors[index],
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.w900
                            : FontWeight.w600,
                        fontSize: 11.5,
                        color: isSelected
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantitySection() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: NexoraSpacing.md,
        runSpacing: NexoraSpacing.sm,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quantity',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                '$_maxStock pieces in stock',
                style: TextStyle(
                  fontSize: 10.5,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 15),
                  onPressed: _decrementQuantity,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
                SizedBox(
                  width: 44,
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: theme.colorScheme.onSurface,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (val) {
                      final parsed = int.tryParse(val.trim());
                      if (parsed != null && parsed >= 1 && parsed <= _maxStock) {
                        _quantity = parsed;
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 15),
                  onPressed: _incrementQuantity,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopStoreBanner() {
    final shop = ShopService.instance.getShopById(_productArg?.shopId);
    final theme = Theme.of(context);

    return NexoraCard(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.shop, arguments: shop);
      },
      padding: const EdgeInsets.all(NexoraSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: shop.avatarBg,
              border: Border.all(color: NexoraTheme.primary, width: 1.8),
            ),
            child: Center(
              child: Text(
                shop.initials,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 10.5,
                  height: 1.1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        shop.name,
                        style: TextStyle(
                          fontFamily: NexoraTheme.fontFamily,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: NexoraSpacing.xs,
                  runSpacing: NexoraSpacing.xxs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        shop.badge,
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 13,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${shop.rating}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            ' (${shop.followers})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: NexoraTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: NexoraTheme.primary, width: 1.2),
            ),
            child: const Text(
              'Visit Shop',
              style: TextStyle(
                color: NexoraTheme.primary,
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicVariantsSection() {
    if (_productArg?.variantGroups == null ||
        _productArg!.variantGroups!.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildColorPaletteSection(),
          const SizedBox(height: 18),
          _buildSwitchOptionsSection(),
          const SizedBox(height: 18),
          _buildFormFactorSection(),
          const SizedBox(height: 18),
        ],
      );
    }

    final theme = Theme.of(context);
    final groups = _productArg!.variantGroups!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(groups.length, (grpIdx) {
        final grp = groups[grpIdx];
        final selIdx = _selectedVariantGroupIndices[grpIdx];

        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    grp.groupName,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (selIdx != null && selIdx < grp.options.length)
                    Text(
                      grp.options[selIdx].name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (grp.options.any((o) => o.colorHex != null)) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: List.generate(grp.options.length, (optIdx) {
                      final opt = grp.options[optIdx];
                      final isSel = selIdx == optIdx;

                      // Combination stock check (BUY-PDP-003)
                      bool isOutOfStock = opt.stock <= 0;
                      if (_productArg?.combinationStock != null &&
                          _productArg!.variantGroups!.length >= 2) {
                        if (grpIdx == 0 &&
                            _selectedVariantGroupIndices.containsKey(1)) {
                          final sizeOpt = _productArg!
                              .variantGroups![1]
                              .options[_selectedVariantGroupIndices[1]!];
                          final combKey = '${opt.name}-${sizeOpt.name}';
                          if (_productArg!.combinationStock!.containsKey(
                            combKey,
                          )) {
                            isOutOfStock =
                                _productArg!.combinationStock![combKey]! <= 0;
                          }
                        }
                      }

                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () {
                            if (isOutOfStock) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'This variation is currently out of stock',
                                  ),
                                  backgroundColor: Color(0xFFEF4444),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              return;
                            }
                            setState(() {
                              _selectedVariantGroupIndices[grpIdx] = optIdx;
                              if (opt.imageUrl != null &&
                                  opt.imageUrl!.isNotEmpty) {
                                final imgIdx = _productImages.indexOf(
                                  opt.imageUrl!,
                                );
                                if (imgIdx != -1) {
                                  _selectedImageIndex = imgIdx;
                                  if (_pageController.hasClients) {
                                    _pageController.jumpToPage(imgIdx);
                                  }
                                } else {
                                  _productImages.insert(0, opt.imageUrl!);
                                  _selectedImageIndex = 0;
                                  if (_pageController.hasClients) {
                                    _pageController.jumpToPage(0);
                                  }
                                }
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isOutOfStock
                                  ? theme.colorScheme.surfaceContainerHigh
                                        .withValues(alpha: 0.3)
                                  : (isSel
                                        ? theme.colorScheme.primaryContainer
                                        : theme
                                              .colorScheme
                                              .surfaceContainerLowest),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isOutOfStock
                                    ? theme.colorScheme.outlineVariant
                                    : (isSel
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.outlineVariant),
                                width: isSel ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                if (opt.colorHex != null) ...[
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: isOutOfStock
                                          ? opt.colorHex!.withValues(alpha: 0.3)
                                          : opt.colorHex,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: theme.colorScheme.outlineVariant,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  isOutOfStock
                                      ? '${opt.name} (Out of stock)'
                                      : opt.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSel
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isOutOfStock
                                        ? theme.colorScheme.onSurfaceVariant
                                              .withValues(alpha: 0.5)
                                        : (isSel
                                              ? theme
                                                    .colorScheme
                                                    .onPrimaryContainer
                                              : theme.colorScheme.onSurface),
                                    decoration: isOutOfStock
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ] else ...[
                Column(
                  children: List.generate(grp.options.length, (optIdx) {
                    final opt = grp.options[optIdx];
                    final isSel = selIdx == optIdx;

                    // Out-of-stock combination check (BUY-PDP-003: Black-M is disabled for Black)
                    bool isOutOfStock = opt.stock <= 0;
                    if (_productArg?.combinationStock != null &&
                        _productArg!.variantGroups!.length >= 2) {
                      if (grpIdx == 1 &&
                          _selectedVariantGroupIndices.containsKey(0)) {
                        final colorOpt = _productArg!
                            .variantGroups![0]
                            .options[_selectedVariantGroupIndices[0]!];
                        final combKey = '${colorOpt.name}-${opt.name}';
                        if (_productArg!.combinationStock!.containsKey(
                          combKey,
                        )) {
                          isOutOfStock =
                              _productArg!.combinationStock![combKey]! <= 0;
                        }
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () {
                          if (isOutOfStock) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'This variation is currently out of stock',
                                ),
                                backgroundColor: Color(0xFFEF4444),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }
                          setState(() {
                            _selectedVariantGroupIndices[grpIdx] = optIdx;
                            if (opt.imageUrl != null &&
                                opt.imageUrl!.isNotEmpty) {
                              final imgIdx = _productImages.indexOf(
                                opt.imageUrl!,
                              );
                              if (imgIdx != -1) {
                                _selectedImageIndex = imgIdx;
                                if (_pageController.hasClients) {
                                  _pageController.jumpToPage(imgIdx);
                                }
                              } else {
                                _productImages.insert(0, opt.imageUrl!);
                                _selectedImageIndex = 0;
                                if (_pageController.hasClients) {
                                  _pageController.jumpToPage(0);
                                }
                              }
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isOutOfStock
                                ? theme.colorScheme.surfaceContainerHigh
                                      .withValues(alpha: 0.3)
                                : (isSel
                                      ? theme.colorScheme.primaryContainer
                                      : theme
                                            .colorScheme
                                            .surfaceContainerLowest),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isOutOfStock
                                  ? theme.colorScheme.outlineVariant
                                  : (isSel
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.outlineVariant),
                              width: isSel ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isOutOfStock
                                      ? theme.colorScheme.surfaceContainerHigh
                                      : (isSel
                                            ? theme.colorScheme.primary
                                            : Colors.transparent),
                                  border: Border.all(
                                    color: isOutOfStock
                                        ? theme.colorScheme.outlineVariant
                                        : (isSel
                                              ? theme.colorScheme.primary
                                              : theme
                                                    .colorScheme
                                                    .outlineVariant),
                                    width: 1.5,
                                  ),
                                ),
                                child: isOutOfStock
                                    ? Icon(
                                        Icons.block,
                                        size: 11,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      )
                                    : (isSel
                                          ? const Icon(
                                              Icons.check,
                                              size: 12,
                                              color: Colors.white,
                                            )
                                          : null),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isOutOfStock
                                          ? '${opt.name} (Out of stock)'
                                          : opt.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12.5,
                                        color: isOutOfStock
                                            ? theme.colorScheme.onSurfaceVariant
                                                  .withValues(alpha: 0.5)
                                            : (isSel
                                                  ? theme
                                                        .colorScheme
                                                        .onPrimaryContainer
                                                  : theme
                                                        .colorScheme
                                                        .onSurface),
                                        decoration: isOutOfStock
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                    if (opt.subtitle != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        opt.subtitle!,
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: isOutOfStock
                                              ? theme.colorScheme.outlineVariant
                                              : theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (opt.priceOffset > 0)
                                Text(
                                  '+₱${opt.priceOffset.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11.5,
                                    color: isOutOfStock
                                        ? theme.colorScheme.onSurfaceVariant
                                        : (isSel
                                              ? const Color(0xFF38BDF8)
                                              : theme.colorScheme.onSurface),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }

  String _cleanSoldCount(String val) {
    final clean = val
        .replaceAll(RegExp(r'\bsold\b', caseSensitive: false), '')
        .trim();
    return '$clean sold';
  }

  Widget _buildProductDescriptionSection() {
    final theme = Theme.of(context);
    final desc =
        _productArg?.description ??
        'Crafted with premium materials and engineered for everyday excellence. Each unit undergoes strict quality control and comes with official brand warranty.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About this item',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: NexoraSpacing.sm),
        Text(
          desc,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.55,
          ),
        ),
      ],
    );
  }

  List<ProductReviewModel> get _defaultFallbackReviews => [
    ProductReviewModel(
      id: 'fb_rev1',
      userName: 'Kiko Valenzuela',
      initials: 'KV',
      avatarColor: const Color(0xFF5038ED),
      rating: 5.0,
      date: '2d ago',
      variantName: 'Chalk White / Violet',
      comment: 'Hands down the cleanest sounding stock board I have ever tested. The switches came factory lubricated to absolute perfection. Zero rattle on the spacebar and the violet knob is super tactile!',
      reviewImages: [
        'https://images.unsplash.com/photo-1587829741301-dc798b83add3?auto=format&fit=crop&w=300&q=80',
      ],
      helpfulCount: 38,
    ),
    ProductReviewModel(
      id: 'fb_rev2',
      userName: 'Marianne Cruz',
      initials: 'MC',
      avatarColor: const Color(0xFF00B4D8),
      rating: 5.0,
      date: '5d ago',
      variantName: 'Chalk White / Violet',
      comment: 'Arrived in less than 24 hours in BGC! Packaged in heavy luxury matte presentation box with switch pullers and coiled lavender cable included. Typing experience is pillowy and deep.',
      helpfulCount: 24,
    ),
  ];

  Widget _buildReviewsSection() {
    return AnimatedBuilder(
      animation: ShopService.instance,
      builder: (context, _) {
        final List<ProductReviewModel> reviews =
            ShopService.instance.getReviewsForProduct(
          _productKey,
          _productArg?.reviews ?? _defaultFallbackReviews,
        );
        final ratingVal = ShopService.instance.getProductAverageRating(
          _productKey,
          _productArg?.rating ?? 4.9,
        );
        final breakdown =
            ShopService.instance.getProductRatingBreakdown(_productKey);

        List<ProductReviewModel> filtered = reviews;
        if (_selectedReviewFilter == 'With Photos') {
          filtered = reviews
              .where((r) =>
                  r.reviewImages.isNotEmpty || r.reviewImageBytes.isNotEmpty)
              .toList();
        } else if (_selectedReviewFilter == '5 Star') {
          filtered = reviews.where((r) => r.rating >= 4.8).toList();
        } else if (_selectedReviewFilter == '4 Star') {
          filtered = reviews
              .where((r) => r.rating >= 3.8 && r.rating < 4.8)
              .toList();
        }

        final withPhotosCount = reviews
            .where((r) =>
                r.reviewImages.isNotEmpty || r.reviewImageBytes.isNotEmpty)
            .length;
        final fiveStarCount = reviews.where((r) => r.rating >= 4.8).length;
        final fourStarCount = reviews
            .where((r) => r.rating >= 3.8 && r.rating < 4.8)
            .length;

        final theme = Theme.of(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: NexoraSpacing.sm,
              runSpacing: NexoraSpacing.xs,
              children: [
                Wrap(
                  spacing: NexoraSpacing.xs,
                  runSpacing: NexoraSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Icon(
                      Icons.rate_review_outlined,
                      size: 16,
                      color: Color(0xFF0066FF),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Ratings & Reviews',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${reviews.length})',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      onPressed: _openWriteReviewModal,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(
                        Icons.add_comment_outlined,
                        size: 14,
                        color: Color(0xFF0066FF),
                      ),
                      label: const Text(
                        'Write Review',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0066FF),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: _navigateToReviewsPage,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: Text(
                          'View All >',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF0066FF),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Overall score banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    children: [
                      Text(
                        ratingVal.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final filled = index < ratingVal.floor();
                          final half = !filled && index < ratingVal;
                          return Icon(
                            half ? Icons.star_half_rounded : Icons.star_rounded,
                            size: 14,
                            color: const Color(0xFFF59E0B),
                          );
                        }),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '98% Recommended',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: NexoraSpacing.md),
                  Column(
                    children: [
                      _buildStarProgressRow('5', breakdown[5] ?? 0.88),
                      _buildStarProgressRow('4', breakdown[4] ?? 0.09),
                      _buildStarProgressRow('3', breakdown[3] ?? 0.02),
                      _buildStarProgressRow('2', breakdown[2] ?? 0.01),
                      _buildStarProgressRow('1', breakdown[1] ?? 0.00),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Review Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildReviewFilterChip(
                    'All (${reviews.length})',
                    isSelected: _selectedReviewFilter == 'All',
                    onTap: () => setState(() => _selectedReviewFilter = 'All'),
                  ),
                  const SizedBox(width: 8),
                  _buildReviewFilterChip(
                    '📷 With Photos ($withPhotosCount)',
                    isSelected: _selectedReviewFilter == 'With Photos',
                    onTap: () =>
                        setState(() => _selectedReviewFilter = 'With Photos'),
                  ),
                  const SizedBox(width: 8),
                  _buildReviewFilterChip(
                    '5 ★ ($fiveStarCount)',
                    isSelected: _selectedReviewFilter == '5 Star',
                    onTap: () =>
                        setState(() => _selectedReviewFilter = '5 Star'),
                  ),
                  const SizedBox(width: 8),
                  _buildReviewFilterChip(
                    '4 ★ ($fourStarCount)',
                    isSelected: _selectedReviewFilter == '4 Star',
                    onTap: () =>
                        setState(() => _selectedReviewFilter = '4 Star'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Dynamic Reviews List
            if (filtered.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Text(
                  'No reviews under this filter yet.',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              )
            else
              ...filtered.take(3).map((rev) {
                final isLiked = ShopService.instance.hasLikedReview(rev.id);
                final helpful = ShopService.instance.getReviewHelpfulCount(
                  rev.id,
                  rev.helpfulCount,
                );

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildReviewCard(
                    avatarColor: rev.avatarColor,
                    initials: rev.initials,
                    userName: rev.userName,
                    rating: rev.rating,
                    dateText: rev.date,
                    variantText: rev.variantName,
                    comment: rev.comment,
                    imageUrl: rev.reviewImages.isNotEmpty
                        ? rev.reviewImages.first
                        : null,
                    imageBytes: rev.reviewImageBytes.isNotEmpty
                        ? rev.reviewImageBytes.first
                        : null,
                    helpfulCount: helpful,
                    voted: isLiked,
                    onHelpfulTap: () {
                      setState(() {
                        ShopService.instance.toggleReviewLike(rev.id);
                      });
                    },
                  ),
                );
              }),
            if (reviews.length > 3) ...[
              Center(
                child: TextButton(
                  onPressed: _navigateToReviewsPage,
                  child: Text(
                    'View all ${reviews.length} reviews >',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF0066FF),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildStarProgressRow(String starLabel, double pct) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        children: [
          Text(
            starLabel,
            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEECFF),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: pct,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D2FF),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${(pct * 100).toInt()}%',
            style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewFilterChip(
    String label, {
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00D2FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00D2FF)
                : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard({
    required Color avatarColor,
    required String initials,
    required String userName,
    required double rating,
    required String dateText,
    required String variantText,
    required String comment,
    required String? imageUrl,
    Uint8List? imageBytes,
    required int helpfulCount,
    required bool voted,
    required VoidCallback onHelpfulTap,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: NexoraSpacing.sm,
            runSpacing: NexoraSpacing.sm,
            children: [
              Wrap(
                spacing: NexoraSpacing.xs,
                runSpacing: NexoraSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: avatarColor,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: NexoraSpacing.xs,
                        runSpacing: NexoraSpacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            userName,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            size: 13,
                            color: Color(0xFF0066FF),
                          ),
                        ],
                      ),
                      Text(
                        variantText.isNotEmpty
                            ? 'Verified Buyer • $variantText'
                            : 'Verified Buyer',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                dateText,
                style: TextStyle(
                  fontSize: 10.5,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(5, (idx) {
              return Icon(
                Icons.star_rounded,
                size: 14,
                color: idx < rating.round()
                    ? const Color(0xFFF59E0B)
                    : theme.colorScheme.outlineVariant,
              );
            }),
          ),
          const SizedBox(height: 6),
          Text(
            comment,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface,
              height: 1.35,
            ),
          ),
          if (imageBytes != null || imageUrl != null) ...[
            const SizedBox(height: 10),
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.surfaceContainerLow,
              ),
              clipBehavior: Clip.antiAlias,
              child: imageBytes != null
                  ? Image.memory(imageBytes, fit: BoxFit.cover)
                  : Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Center(
                        child: Icon(Icons.broken_image, size: 24),
                      ),
                    ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: NexoraSpacing.sm,
            runSpacing: NexoraSpacing.xs,
            children: [
              Text(
                variantText,
                style: TextStyle(
                  fontSize: 10.5,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onHelpfulTap,
                child: Wrap(
                  spacing: NexoraSpacing.xs,
                  runSpacing: NexoraSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Icon(
                      voted ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                      size: 13,
                      color: voted
                          ? const Color(0xFF0066FF)
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Helpful ($helpfulCount)',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: voted
                            ? const Color(0xFF0066FF)
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openShopChat() {
    final shop = ShopService.instance.getShopById(_productArg?.shopId);
    final shopName = _productArg?.shopName.isNotEmpty == true
        ? _productArg!.shopName
        : shop.name;
    final shopBadge = _productArg?.shopBadge.isNotEmpty == true
        ? _productArg!.shopBadge
        : shop.badge;
    final shopId = _productArg?.shopId.isNotEmpty == true
        ? _productArg!.shopId
        : shop.id;
    final conversation = ChatService.instance.getOrCreateShopConversation(
      shopId: shopId,
      shopName: shopName,
      shopBadge: shopBadge,
      avatarBg: shop.avatarBg,
      initialProductSnippet: _productTitle,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailPage(
          conversationId: conversation.id,
          title: conversation.title,
          subtitle: shopBadge,
          avatarIcon: conversation.avatarIcon,
          avatarBgColor: conversation.avatarBg,
          orderRef: _productTitle,
          initialMessages: conversation.messages
              .map((message) => message.toMap())
              .toList(),
        ),
      ),
    );
  }

  Widget _buildRefinedBottomActionDock() {
    final unavailable =
        _productArg?.isActive == false ||
        _productArg?.isOnVacation == true ||
        _maxStock <= 0;
    final total = _effectivePrice * _quantity;
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;

    final chatButton = IconButton.filledTonal(
      tooltip: 'Chat with shop',
      onPressed: _openShopChat,
      icon: const Icon(Icons.chat_bubble_outline_rounded),
    );
    final addButton = OutlinedButton.icon(
      onPressed: unavailable ? null : _handleAddToCart,
      icon: const Icon(Icons.shopping_bag_outlined, size: 19),
      label: const Text('Add to Cart'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF0066FF),
        side: const BorderSide(color: Color(0xFF0066FF), width: 1.2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(23),
        ),
      ),
    );
    final buyButton = ElevatedButton(
      onPressed: unavailable ? null : _handleBuyNow,
      style: ElevatedButton.styleFrom(
        backgroundColor: unavailable
            ? const Color(0xFF94A3B8)
            : const Color(0xFF0066FF),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(23),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Buy Now',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            '₱${total.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.95),
              height: 1.1,
            ),
          ),
        ],
      ),
    );

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      shape: Border(
        top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(NexoraSpacing.sm),
          child: largeText
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        chatButton,
                        const SizedBox(width: NexoraSpacing.xs),
                        Expanded(child: addButton),
                      ],
                    ),
                    const SizedBox(height: NexoraSpacing.xs),
                    buyButton,
                  ],
                )
              : Row(
                  children: [
                    chatButton,
                    const SizedBox(width: NexoraSpacing.xs),
                    Expanded(child: addButton),
                    const SizedBox(width: NexoraSpacing.xs),
                    Expanded(child: buyButton),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildBottomActionDock() {
    final theme = Theme.of(context);
    final totalPrice = _effectivePrice * _quantity;
    final isUnavailable =
        _productArg?.isActive == false || _productArg?.isOnVacation == true;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Chat Icon Button
            GestureDetector(
              onTap: () {
                final shop = ShopService.instance.getShopById(
                  _productArg?.shopId,
                );
                final sName =
                    (_productArg?.shopName != null &&
                        _productArg!.shopName.isNotEmpty)
                    ? _productArg!.shopName
                    : shop.name;
                final sBadge =
                    (_productArg?.shopBadge != null &&
                        _productArg!.shopBadge.isNotEmpty)
                    ? _productArg!.shopBadge
                    : shop.badge;
                final sId =
                    (_productArg?.shopId != null &&
                        _productArg!.shopId.isNotEmpty)
                    ? _productArg!.shopId
                    : shop.id;

                final conv = ChatService.instance.getOrCreateShopConversation(
                  shopId: sId,
                  shopName: sName,
                  shopBadge: sBadge,
                  avatarBg: shop.avatarBg,
                  initialProductSnippet: '🛍️ $_productTitle',
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatDetailPage(
                      conversationId: conv.id,
                      title: conv.title,
                      subtitle: sBadge,
                      avatarIcon: conv.avatarIcon,
                      avatarBgColor: conv.avatarBg,
                      orderRef: _productTitle,
                      initialMessages: conv.messages
                          .map((m) => m.toMap())
                          .toList(),
                    ),
                  ),
                );
              },
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Add to Cart Button
            Expanded(
              flex: 4,
              child: SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _handleAddToCart,
                  icon: Icon(
                    Icons.shopping_cart_outlined,
                    size: 16,
                    color: isUnavailable
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.onSurface,
                  ),
                  label: Text(
                    'Add to Cart',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      color: isUnavailable
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isUnavailable
                        ? theme.colorScheme.surfaceContainerHigh
                        : theme.colorScheme.surfaceContainer,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(23),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Buy Now Brand Pill Button (Consistent Nexora Blue)
            Expanded(
              flex: 5,
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: isUnavailable
                      ? theme.colorScheme.surfaceContainerHigh
                      : NexoraTheme.primary,
                  borderRadius: BorderRadius.circular(23),
                  boxShadow: [
                    BoxShadow(
                      color: isUnavailable
                          ? Colors.transparent
                          : NexoraTheme.primary.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _handleBuyNow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(23),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Buy Now',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '₱${totalPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  Widget _buildClaimableVouchersSection() {
    final vouchers = _productArg?.claimableVouchers;
    if (vouchers == null || vouchers.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Shop Vouchers',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              '${vouchers.length} Available',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...vouchers.map((voucher) {
          final isClaimed = ShopService.instance.isVoucherClaimed(voucher.id);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isClaimed
                    ? theme.colorScheme.outlineVariant
                    : theme.colorScheme.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    voucher.id,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onPrimaryContainer,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        voucher.discountTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${voucher.minSpend} • ${voucher.expiry}',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: isClaimed
                      ? null
                      : () {
                          setState(() {
                            ShopService.instance.claimVoucher(voucher.id);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Voucher ${voucher.id} claimed!'),
                              duration: const Duration(seconds: 1),
                              backgroundColor: const Color(0xFF050B28),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isClaimed
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF0066FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isClaimed ? 'Claimed' : 'Claim',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _openZoomImageViewer(BuildContext context, int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.95),
      builder: (dlgContext) {
        int currentIndex = initialIndex;
        final pageCtrl = PageController(initialPage: initialIndex);
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 26),
                  onPressed: () => Navigator.pop(dlgContext),
                ),
                title: Text(
                  '${currentIndex + 1} / ${_productImages.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                centerTitle: true,
              ),
              body: PageView.builder(
                controller: pageCtrl,
                itemCount: _productImages.length,
                onPageChanged: (idx) {
                  setDlgState(() => currentIndex = idx);
                },
                itemBuilder: (context, idx) {
                  return Center(
                    child: InteractiveViewer(
                      minScale: 1.0,
                      maxScale: 5.0,
                      child: Image.network(
                        _productImages[idx],
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFF1E293B),
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 64,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProductUnavailableView(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F8FC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, AppRoutes.home);
            }
          },
        ),
        title: const Text(
          'Product Details',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.remove_shopping_cart_outlined,
                  size: 48,
                  color: Color(0xFFEF4444),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Product Unavailable',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'This product is no longer available, was deleted, or has been paused by the seller.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, AppRoutes.home);
                },
                icon: const Icon(Icons.storefront_outlined, size: 18),
                label: const Text(
                  'Browse Other Products',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066FF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
