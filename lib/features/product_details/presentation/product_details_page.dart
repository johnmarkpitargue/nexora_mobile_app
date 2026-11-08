import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nexora_flutter_app/app/routes/app_routes.dart';
import 'package:nexora_flutter_app/core/constants/api_constants.dart';
import 'package:nexora_flutter_app/core/models/shop_models.dart';
import 'package:nexora_flutter_app/core/network/api_client.dart';
import 'package:nexora_flutter_app/core/services/buyer_account_service.dart';
import 'package:nexora_flutter_app/core/services/cart_service.dart';
import 'package:nexora_flutter_app/core/services/chat_service.dart';
import 'package:nexora_flutter_app/core/services/shop_service.dart';
import 'package:nexora_flutter_app/core/services/wishlist_service.dart';
import 'package:nexora_flutter_app/core/utils/guest_auth_guard.dart';
import 'package:nexora_flutter_app/core/utils/variant_helper.dart';
import 'package:nexora_flutter_app/core/widgets/added_to_cart_hud.dart';
import 'package:nexora_flutter_app/features/chat/presentation/chat_detail_page.dart';
import 'package:nexora_flutter_app/features/home/presentation/widgets/product_card.dart';

class ProductDetailsPage extends StatefulWidget {
  const ProductDetailsPage({super.key});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  ProductModel? _productArg;
  String? _requestedProductId;
  bool _initializedArgs = false;
  bool _isLoadingProduct = false;
  bool _productNotFound = false;
  String? _productError;
  bool _isAddingToCart = false;

  int _selectedImageIndex = 0;
  late final PageController _pageController;
  late final TextEditingController _quantityController;
  int _quantity = 1;
  final Map<int, int> _selectedVariantGroupIndices = {};
  String _selectedReviewFilter = 'All';

  final List<String> _productImages = [];

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
    super.dispose();
  }

  void _syncProductImages(ProductModel product) {
    _productImages.clear();
    if (product.galleryImages != null && product.galleryImages!.isNotEmpty) {
      _productImages.addAll(product.galleryImages!.where((e) => e.isNotEmpty));
    } else if (product.imageUrl.isNotEmpty) {
      _productImages.add(product.imageUrl);
    }
    if (_selectedImageIndex >= _productImages.length) {
      _selectedImageIndex = 0;
    }
    // Auto-select only when a group has a single available option (matching web show.blade.php).
    final groups = product.variantGroups ?? const <ProductVariantGroup>[];
    for (int i = 0; i < groups.length; i++) {
      if (!_selectedVariantGroupIndices.containsKey(i) &&
          groups[i].options.length == 1 &&
          groups[i].options.first.stock > 0) {
        _selectedVariantGroupIndices[i] = 0;
      }
    }
  }

  Future<void> _fetchProductDetail(String productId) async {
    if (productId.isEmpty) return;
    setState(() {
      _isLoadingProduct = true;
      _productError = null;
      _productNotFound = false;
    });
    try {
      final fresh = await ShopService.instance.fetchProductDetailOrThrow(productId);
      if (!mounted) return;
      setState(() {
        _productArg = fresh;
        _syncProductImages(fresh);
        _isLoadingProduct = false;
        _productError = null;
        _productNotFound = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingProduct = false;
        if (e.statusCode == 404) {
          _productNotFound = true;
          _productError = e.message;
        } else {
          _productError = e.message;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingProduct = false;
        _productError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedArgs) {
      _initializedArgs = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is ProductModel) {
        _productArg = args;
        _requestedProductId = args.id;
        _syncProductImages(args);
        if (int.tryParse(args.id) != null && int.parse(args.id) > 0) {
          _fetchProductDetail(args.id);
        }
      } else if (args is String) {
        _requestedProductId = args;
        final cached = ShopService.instance.getProductById(args);
        if (cached != null) {
          _productArg = cached;
          _syncProductImages(cached);
        }
        if (int.tryParse(args) != null && int.parse(args) > 0) {
          _fetchProductDetail(args);
        } else if (cached == null) {
          _productNotFound = true;
        }
      } else {
        _productNotFound = true;
      }
    }
  }

  List<ProductVariantGroup> get _variantGroups =>
      _productArg?.variantGroups ?? const <ProductVariantGroup>[];

  bool get _areAllVariantsSelected => VariantHelper.areAllSelected(
        _variantGroups,
        _selectedVariantGroupIndices,
      );

  String get _productTitle => _productArg?.title ?? '';

  int get _maxStock => VariantHelper.resolveStock(
        product: _productArg,
        groups: _variantGroups,
        selectedIndices: _selectedVariantGroupIndices,
      );

  double get _productBasePrice {
    if (_productArg == null) return 0.0;
    if (_productArg!.isFlashSale && _productArg!.flashSalePrice != null) {
      final clean =
          _productArg!.flashSalePrice!.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(clean) ?? 0.0;
    }
    final clean = _productArg!.price.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(clean) ?? 0.0;
  }

  double? get _productOriginalPrice {
    if (_productArg == null || _productArg!.originalPrice == null) return null;
    final clean =
        _productArg!.originalPrice!.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(clean);
  }

  double get _effectivePrice => VariantHelper.resolvePrice(
        basePrice: _productBasePrice,
        groups: _variantGroups,
        selectedIndices: _selectedVariantGroupIndices,
      );

  int get _orderLimit {
    final limit = _productArg?.perBuyerLimit;
    if (limit != null && limit > 0) return limit;
    return _maxStock > 0 ? _maxStock : 999;
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
    final limit = _orderLimit;
    if (intVal > limit) return 'Maximum order limit is $limit units';
    if (intVal > _maxStock) {
      return 'Quantity exceeds available stock ($_maxStock)';
    }
    return null;
  }

  void _incrementQuantity() {
    final current = int.tryParse(_quantityController.text.trim()) ?? _quantity;
    final limit = _orderLimit;
    if (current < _maxStock && current < limit) {
      setState(() {
        _quantity = current + 1;
        _quantityController.text = '$_quantity';
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            current >= limit
                ? 'Maximum order limit is $limit units'
                : 'Reached max available quantity ($current)',
          ),
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

  String _resolvedImageForSelection(VariantSelectionResult selection) {
    final vImg = selection.payload?['image']?.toString() ?? '';
    if (vImg.isNotEmpty) return vImg;
    if (_productImages.isNotEmpty) return _productImages.first;
    return _productArg?.imageUrl ?? '';
  }

  Future<void> _handleAddToCart() async {
    if (_isAddingToCart) return;

    if (_productArg == null ||
        _productArg!.isActive == false ||
        _productArg!.isDeleted == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This product is no longer available'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_productArg!.isOnVacation == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Seller is on vacation. Purchasing is temporarily unavailable.'),
          backgroundColor: Color(0xFFEA580C),
        ),
      );
      return;
    }

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

    final limit = _productArg!.perBuyerLimit;
    if (limit != null) {
      final pid =
          _productArg!.id.isNotEmpty ? _productArg!.id : _productTitle;
      final purchasedCount = CartService.instance.getPurchasedCount(pid);
      final inCartCount = CartService.instance.items
          .where((i) => i.productId == _productArg!.id || i.title == _productTitle)
          .fold(0, (sum, i) => sum + i.quantity);
      if (purchasedCount + inCartCount + _quantity > limit) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Per-buyer purchase limit of $limit items reached for this product.'),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
    }

    if (!BuyerAccountService.instance.isLoggedIn ||
        !ApiClient.instance.hasToken) {
      final loggedIn = await GuestAuthGuard.requireLogin(
        context,
        title: 'Sign In to Add to Cart',
        message: 'Please sign in or create an account to save items to your cart.',
      );
      if (!loggedIn || !mounted) return;
    }

    final pId = int.tryParse(_productArg!.id) ?? 0;
    if (pId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid product ID. Please refresh and try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final selection = VariantHelper.buildSelection(
      groups: _variantGroups,
      selectedIndices: _selectedVariantGroupIndices,
    );

    setState(() => _isAddingToCart = true);
    try {
      await CartService.instance.addToCart(
        productId: pId,
        variantPayload: selection.payload,
        quantity: _quantity,
      );
      if (!mounted) return;
      AddedToCartHUD.show(context);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${_quantity}x $_productTitle to cart'),
          backgroundColor: const Color(0xFF0066FF),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException
          ? e.message
          : e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFFDC2626),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _handleAddToCart,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isAddingToCart = false);
      }
    }
  }

  Future<void> _handleBuyNow() async {
    if (_productArg == null ||
        _productArg!.isActive == false ||
        _productArg!.isDeleted == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This product is no longer available'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_productArg!.isOnVacation == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Seller is on vacation. Purchasing is temporarily unavailable.'),
          backgroundColor: Color(0xFFEA580C),
        ),
      );
      return;
    }

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

    if (!BuyerAccountService.instance.isLoggedIn ||
        !ApiClient.instance.hasToken) {
      final loggedIn = await GuestAuthGuard.requireLogin(
        context,
        title: 'Sign In to Buy Now',
        message:
            'Please sign in or create an account to proceed with your order and secure delivery.',
      );
      if (!loggedIn || !mounted) return;
    }

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

    final limit = _productArg!.perBuyerLimit;
    if (limit != null) {
      final pid =
          _productArg!.id.isNotEmpty ? _productArg!.id : _productTitle;
      final purchasedCount = CartService.instance.getPurchasedCount(pid);
      final inCartCount = CartService.instance.items
          .where((i) => i.productId == _productArg!.id || i.title == _productTitle)
          .fold(0, (sum, i) => sum + i.quantity);
      if (purchasedCount + inCartCount + _quantity > limit) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Per-buyer purchase limit of $limit items reached for this product.'),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
    }

    final selection = VariantHelper.buildSelection(
      groups: _variantGroups,
      selectedIndices: _selectedVariantGroupIndices,
    );

    CartService.instance.buyNow(
      productId: _productArg!.id,
      sellerId: int.tryParse(_productArg!.shopId),
      variantData: selection.payload,
      title: _productTitle,
      variant: selection.displaySummary,
      price: _effectivePrice,
      originalPrice: _productOriginalPrice,
      imageUrl: _resolvedImageForSelection(selection),
      storeName: _productArg!.shopName,
      storeBadge: _productArg!.shopBadge,
      quantity: _quantity,
    );

    Navigator.pushNamed(context, AppRoutes.checkout);
  }

  @override
  Widget build(BuildContext context) {
    if (_productArg == null && _isLoadingProduct) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F8FC),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF6F8FC),
          elevation: 0,
          title: const Text(
            'Product Details',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_productArg == null && _productError != null && !_productNotFound) {
      return _buildProductErrorView(context, _productError!);
    }

    if (_productArg == null ||
        _productNotFound ||
        !_productArg!.isActive ||
        _productArg!.isDeleted) {
      return _buildProductUnavailableView(context);
    }

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
        actions: [
          AnimatedBuilder(
            animation: WishlistService.instance,
            builder: (context, _) {
              final isFavorite =
                  WishlistService.instance.isInWishlist(_productTitle);
              return IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite
                      ? const Color(0xFFE11D48)
                      : const Color(0xFF0F172A),
                ),
                onPressed: () {
                  WishlistService.instance.toggleWishlist(_productArg!);
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isFavorite
                            ? 'Removed from Wishlist'
                            : 'Saved to Wishlist!',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Color(0xFF0F172A)),
            onPressed: () {
              final prodId = _productArg?.id ?? '';
              final shareUrl = '${ApiConstants.baseUrl}/products/$prodId';
              Clipboard.setData(ClipboardData(text: shareUrl));
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Product link copied: $shareUrl'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: const Color(0xFF050B28),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                if (_productError != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            size: 18, color: Color(0xFFDC2626)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _productError!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF991B1B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _requestedProductId != null
                              ? () => _fetchProductDetail(_requestedProductId!)
                              : null,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                if (_productArg?.isActive == false) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.error_outline_rounded,
                            color: Color(0xFFDC2626), size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'This product is no longer available',
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
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.beach_access_rounded,
                            color: Color(0xFFD97706), size: 20),
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
                _buildGallerySection(),
                const SizedBox(height: 18),

                // Title
                Text(
                  _productTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    height: 1.2,
                  ),
                ),
                if (_productArg?.category.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    _productArg!.category,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
                const SizedBox(height: 8),

                // Rating & Sold Count Row
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 16, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 4),
                    Text(
                      _productArg!.rating > 0
                          ? _productArg!.rating.toStringAsFixed(1)
                          : '0.0',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '• ${_productArg?.reviews?.length == 1 ? '1 review' : '${_productArg?.reviews?.length ?? 0} reviews'}',
                      style: const TextStyle(
                        color: Color(0xFF0066FF),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• ${_cleanSoldCount(_productArg?.soldCount ?? '0')}',
                      style: const TextStyle(
                        color: Color(0xFF0891B2),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                _buildPriceCard(),
                _buildClaimableVouchersSection(),
                const SizedBox(height: 18),

                _buildDynamicVariantsSection(),
                _buildQuantitySection(),
                const SizedBox(height: 18),

                _buildShopStoreBanner(),
                const SizedBox(height: 20),

                _buildProductDescriptionSection(),
                if (_productArg?.specs != null &&
                    _productArg!.specs!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildSpecFeaturesGrid(),
                ],
                const SizedBox(height: 24),

                _buildReviewsSection(),
                const SizedBox(height: 110),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomActionDock(),
          ),
        ],
      ),
    );
  }

  Widget _buildGallerySection() {
    if (_productImages.isEmpty) {
      return Container(
        height: 260,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: Icon(Icons.image_outlined, size: 64, color: Color(0xFF94A3B8)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 260,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFEEECFF),
            borderRadius: BorderRadius.circular(24),
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
                            Icons.image_outlined,
                            size: 64,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
        if (_productImages.length > 1) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF0066FF)
                                : const Color(0xFFE2E8F0),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.network(
                          _productImages[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: const Color(0xFFE2E8F0),
                            child: const Icon(Icons.image,
                                size: 20, color: Colors.grey),
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
      ],
    );
  }

  Widget _buildPriceCard() {
    final isFlash = _productArg?.isFlashSale == true;
    final originalPrice = _productOriginalPrice;
    final hasDiscount = originalPrice != null && originalPrice > _effectivePrice;
    final discount = _productArg?.discountTag ??
        (isFlash
            ? 'FLASH SALE'
            : (hasDiscount
                ? '-${(((originalPrice - _effectivePrice) / originalPrice) * 100).round()}% OFF'
                : null));

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
                  if (_productArg?.flashSaleTimeRemaining != null) ...[
                    const Icon(Icons.timer_outlined,
                        size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'Ends in ${_formatDuration(_productArg!.flashSaleTimeRemaining!)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
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
                    if (hasDiscount) ...[
                      const SizedBox(width: 8),
                      Text(
                        '₱${originalPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                    if (discount != null && discount.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
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
                  ],
                ),
                const SizedBox(height: 4),
                if (isFlash && _productArg!.flashSaleStockRemaining > 0) ...[
                  Row(
                    children: [
                      const Icon(Icons.local_fire_department,
                          size: 14, color: Color(0xFFEF4444)),
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
                      Icon(
                        _maxStock > 0
                            ? Icons.inventory_2_outlined
                            : Icons.remove_shopping_cart_outlined,
                        size: 14,
                        color: _maxStock > 10
                            ? const Color(0xFF0066FF)
                            : const Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _maxStock > 0
                            ? (_maxStock <= 10
                                ? 'Only $_maxStock left in stock - order soon!'
                                : 'In stock ($_maxStock available)')
                            : 'Out of stock',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: _maxStock > 10
                              ? const Color(0xFF0066FF)
                              : const Color(0xFFEF4444),
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

  Widget _buildQuantitySection() {
    final limit = _productArg?.perBuyerLimit;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quantity',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                (limit != null && limit > 0)
                    ? '$_maxStock pieces in stock • Limit $limit/order'
                    : '$_maxStock pieces in stock',
                style: const TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Container(
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 15),
                  onPressed: _decrementQuantity,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                SizedBox(
                  width: 44,
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF0F172A),
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (val) {
                      final parsed = int.tryParse(val.trim());
                      if (parsed != null && parsed >= 1 && parsed <= 20) {
                        _quantity = parsed;
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 15),
                  onPressed: _incrementQuantity,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopStoreBanner() {
    final sellerId = _productArg?.shopId ?? '';
    final cachedShop =
        sellerId.isNotEmpty ? ShopService.instance.getShopById(sellerId) : null;
    final sellerName = _productArg?.shopName.isNotEmpty == true
        ? _productArg!.shopName
        : (cachedShop?.name ?? 'Seller Store');
    final avatarUrl = _productArg?.shopAvatarUrl ?? cachedShop?.avatarUrl ?? '';
    final badge = _productArg?.shopBadge.isNotEmpty == true
        ? _productArg!.shopBadge
        : (cachedShop?.badge ?? '');
    final city = _productArg?.location ?? '';
    final followers = cachedShop?.followers;
    final displayInitial =
        sellerName.isNotEmpty ? sellerName[0].toUpperCase() : 'S';

    return GestureDetector(
      onTap: sellerId.isNotEmpty
          ? () {
              Navigator.pushNamed(
                context,
                AppRoutes.shop,
                arguments: sellerId,
              );
            }
          : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0066FF),
                border:
                    Border.all(color: const Color(0xFF0066FF), width: 1.8),
              ),
              clipBehavior: Clip.antiAlias,
              child: avatarUrl.isNotEmpty
                  ? Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Center(
                        child: Text(
                          displayInitial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        displayInitial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          sellerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right,
                          size: 16, color: Color(0xFF64748B)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (badge.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                        ),
                      if (city.isNotEmpty)
                        Text(
                          city,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      if (followers != null && followers != '0')
                        Text(
                          '$followers followers',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (sellerId.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF0066FF).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: const Color(0xFF0066FF), width: 1.2),
                ),
                child: const Text(
                  'Visit Shop',
                  style: TextStyle(
                    color: Color(0xFF0066FF),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicVariantsSection() {
    if (_variantGroups.isEmpty) {
      return const SizedBox.shrink();
    }

    final groups = _variantGroups;
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (selIdx != null && selIdx < grp.options.length)
                    Text(
                      grp.options[selIdx].name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: Color(0xFF0066FF),
                      ),
                    )
                  else
                    Text(
                      VariantHelper.isSizeGroup(grp)
                          ? 'Select a Size'
                          : 'Select a Variation',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 11.5,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (grp.options.any((o) => o.colorHex != null) ||
                  grp.options.any((o) =>
                      o.imageUrl != null && o.imageUrl!.isNotEmpty) ||
                  VariantHelper.isSizeGroup(grp)) ...[
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(grp.options.length, (optIdx) {
                    final opt = grp.options[optIdx];
                    final isSel = selIdx == optIdx;
                    final isOutOfStock = VariantHelper.isOptionOutOfStock(
                      product: _productArg,
                      groups: groups,
                      selectedIndices: _selectedVariantGroupIndices,
                      groupIndex: grpIdx,
                      optionIndex: optIdx,
                    );

                    return GestureDetector(
                      onTap: () {
                        if (isOutOfStock) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'This variation is currently out of stock'),
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
                            final imgIdx =
                                _productImages.indexOf(opt.imageUrl!);
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
                          final nextMax = _maxStock;
                          if (nextMax > 0 && _quantity > nextMax) {
                            _quantity = nextMax;
                            _quantityController.text = '$_quantity';
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isOutOfStock
                              ? const Color(0xFFF1F5F9)
                              : (isSel
                                  ? const Color(0xFFEEF2FF)
                                  : Colors.white),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isOutOfStock
                                ? const Color(0xFFCBD5E1)
                                : (isSel
                                    ? const Color(0xFF0066FF)
                                    : const Color(0xFFE2E8F0)),
                            width: isSel ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (opt.imageUrl != null &&
                                opt.imageUrl!.isNotEmpty) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  opt.imageUrl!,
                                  width: 20,
                                  height: 20,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      const SizedBox.shrink(),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ] else if (opt.colorHex != null) ...[
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: isOutOfStock
                                      ? opt.colorHex!.withValues(alpha: 0.3)
                                      : opt.colorHex,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: const Color(0xFFCBD5E1),
                                      width: 1),
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
                                fontWeight:
                                    isSel ? FontWeight.w800 : FontWeight.w600,
                                color: isOutOfStock
                                    ? const Color(0xFF94A3B8)
                                    : (isSel
                                        ? const Color(0xFF0066FF)
                                        : const Color(0xFF334155)),
                                decoration: isOutOfStock
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ] else ...[
                Column(
                  children: List.generate(grp.options.length, (optIdx) {
                    final opt = grp.options[optIdx];
                    final isSel = selIdx == optIdx;

                    bool isOutOfStock = opt.stock <= 0;
                    if (_productArg?.combinationStock != null &&
                        groups.length >= 2) {
                      if (grpIdx == 1 &&
                          _selectedVariantGroupIndices.containsKey(0)) {
                        final colorOpt = groups[0]
                            .options[_selectedVariantGroupIndices[0]!];
                        final combKey = '${colorOpt.name}-${opt.name}';
                        if (_productArg!.combinationStock!
                            .containsKey(combKey)) {
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
                                    'This variation is currently out of stock'),
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
                              final imgIdx =
                                  _productImages.indexOf(opt.imageUrl!);
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
                            final nextMax = _maxStock;
                            if (nextMax > 0 && _quantity > nextMax) {
                              _quantity = nextMax;
                              _quantityController.text = '$_quantity';
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isOutOfStock
                                ? const Color(0xFFF8FAFC)
                                : (isSel
                                    ? const Color(0xFF050B28)
                                    : Colors.white),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isOutOfStock
                                  ? const Color(0xFFCBD5E1)
                                  : (isSel
                                      ? const Color(0xFF0066FF)
                                      : const Color(0xFFE2E8F0)),
                              width: isSel ? 1.5 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isOutOfStock
                                      ? const Color(0xFFF1F5F9)
                                      : (isSel
                                          ? const Color(0xFF0066FF)
                                          : Colors.transparent),
                                  border: Border.all(
                                    color: isOutOfStock
                                        ? const Color(0xFFCBD5E1)
                                        : (isSel
                                            ? const Color(0xFF0066FF)
                                            : const Color(0xFFCBD5E1)),
                                    width: 1.5,
                                  ),
                                ),
                                child: isOutOfStock
                                    ? const Icon(Icons.block,
                                        size: 11, color: Color(0xFF94A3B8))
                                    : (isSel
                                        ? const Icon(Icons.check,
                                            size: 12,
                                            color: Color(0xFF050B28))
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
                                            ? const Color(0xFF94A3B8)
                                            : (isSel
                                                ? Colors.white
                                                : const Color(0xFF0F172A)),
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
                                              ? const Color(0xFFCBD5E1)
                                              : (isSel
                                                  ? const Color(0xFF94A3B8)
                                                  : const Color(0xFF64748B)),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (opt.price != null && opt.price! > 0)
                                Text(
                                  '₱${opt.price!.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11.5,
                                    color: isOutOfStock
                                        ? const Color(0xFF94A3B8)
                                        : (isSel
                                            ? const Color(0xFF38BDF8)
                                            : const Color(0xFF0F172A)),
                                  ),
                                )
                              else if (opt.priceOffset > 0)
                                Text(
                                  '+₱${opt.priceOffset.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11.5,
                                    color: isOutOfStock
                                        ? const Color(0xFF94A3B8)
                                        : (isSel
                                            ? const Color(0xFF38BDF8)
                                            : const Color(0xFF0F172A)),
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
    if (val.toLowerCase().contains('sold')) return val;
    return '$val sold';
  }

  Widget _buildProductDescriptionSection() {
    final desc = _productArg?.description?.trim() ?? '';
    if (desc.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.description_outlined,
                  size: 18, color: Color(0xFF0066FF)),
              SizedBox(width: 8),
              Text(
                'Product Description & Details',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF334155),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecFeaturesGrid() {
    final specs = _productArg?.specs;
    if (specs == null || specs.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: specs.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.25,
      ),
      itemBuilder: (context, index) {
        final item = specs[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                item['icon'] as IconData? ?? Icons.info_outline,
                color: const Color(0xFF0066FF),
                size: 22,
              ),
              const SizedBox(height: 6),
              Text(
                item['title'] as String? ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item['subtitle'] as String? ?? '',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF64748B),
                  height: 1.25,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Map<int, double> _computeRatingBreakdown(List<ProductReviewModel> reviews) {
    if (_productArg?.ratingBreakdown != null) {
      return _productArg!.ratingBreakdown!;
    }
    if (reviews.isEmpty) {
      return {5: 0.0, 4: 0.0, 3: 0.0, 2: 0.0, 1: 0.0};
    }
    final counts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in reviews) {
      final stars = r.rating.round().clamp(1, 5);
      counts[stars] = (counts[stars] ?? 0) + 1;
    }
    return counts.map((k, v) => MapEntry(k, v / reviews.length));
  }

  Widget _buildReviewsSection() {
    final List<ProductReviewModel> reviews =
        _productArg?.reviews ?? const [];
    final ratingVal = _productArg?.rating ?? 0.0;
    final breakdown = _computeRatingBreakdown(reviews);

    List<ProductReviewModel> filtered = reviews;
    if (_selectedReviewFilter == 'With Photos') {
      filtered = reviews.where((r) => r.reviewImages.isNotEmpty).toList();
    } else if (_selectedReviewFilter == '5 Star') {
      filtered = reviews.where((r) => r.rating >= 4.8).toList();
    } else if (_selectedReviewFilter == '4 Star') {
      filtered =
          reviews.where((r) => r.rating >= 3.8 && r.rating < 4.8).toList();
    }

    final withPhotosCount =
        reviews.where((r) => r.reviewImages.isNotEmpty).length;
    final fiveStarCount = reviews.where((r) => r.rating >= 4.8).length;
    final fourStarCount =
        reviews.where((r) => r.rating >= 3.8 && r.rating < 4.8).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.rate_review_outlined,
                    size: 16, color: Color(0xFF0066FF)),
                const SizedBox(width: 6),
                const Text(
                  'Ratings & Reviews',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${reviews.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () {
                setState(() => _selectedReviewFilter = 'All');
              },
              child: const Text(
                'View All',
                style: TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF0066FF),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Overall score banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Column(
                children: [
                  Text(
                    ratingVal.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < ratingVal.round()
                            ? Icons.star
                            : Icons.star_border,
                        size: 13,
                        color: const Color(0xFFF59E0B),
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildStarProgressRow('5', breakdown[5] ?? 0.0),
                    _buildStarProgressRow('4', breakdown[4] ?? 0.0),
                    _buildStarProgressRow('3', breakdown[3] ?? 0.0),
                    _buildStarProgressRow('2', breakdown[2] ?? 0.0),
                    _buildStarProgressRow('1', breakdown[1] ?? 0.0),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

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
                'With Photos ($withPhotosCount)',
                isSelected: _selectedReviewFilter == 'With Photos',
                onTap: () =>
                    setState(() => _selectedReviewFilter = 'With Photos'),
              ),
              const SizedBox(width: 8),
              _buildReviewFilterChip(
                '5 Star ($fiveStarCount)',
                isSelected: _selectedReviewFilter == '5 Star',
                onTap: () => setState(() => _selectedReviewFilter = '5 Star'),
              ),
              const SizedBox(width: 8),
              _buildReviewFilterChip(
                '4 Star ($fourStarCount)',
                isSelected: _selectedReviewFilter == '4 Star',
                onTap: () => setState(() => _selectedReviewFilter = '4 Star'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'No reviews under this filter yet.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          )
        else
          ...filtered.map((rev) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildReviewCard(rev),
            );
          }),
      ],
    );
  }

  Widget _buildStarProgressRow(String starLabel, double pct) {
    final safePct = pct.clamp(0.0, 1.0);
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
                  widthFactor: safePct,
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
            '${(safePct * 100).round()}%',
            style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewFilterChip(String label,
      {required bool isSelected, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00D2FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF00D2FF) : const Color(0xFFE2E8F0),
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

  Widget _buildReviewCard(ProductReviewModel rev) {
    final starCount = rev.rating.round().clamp(1, 5);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: rev.avatarColor,
                    child: Text(
                      rev.initials,
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
                      Text(
                        rev.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (rev.variantName.isNotEmpty &&
                          rev.variantName != 'Standard')
                        Text(
                          rev.variantName,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              Text(
                rev.date,
                style:
                    const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(5, (i) {
              return Icon(
                i < starCount ? Icons.star : Icons.star_border,
                size: 14,
                color: const Color(0xFFF59E0B),
              );
            }),
          ),
          if (rev.comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              rev.comment,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF334155),
                height: 1.35,
              ),
            ),
          ],
          if (rev.reviewImages.isNotEmpty) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: rev.reviewImages.map((imgUrl) {
                  return Container(
                    width: 84,
                    height: 84,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFFF1F5F9),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(imgUrl, fit: BoxFit.cover),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomActionDock() {
    final totalPrice = _effectivePrice * _quantity;
    final isUnavailable =
        _productArg?.isActive == false || _productArg?.isOnVacation == true;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Chat Icon Button
            GestureDetector(
              onTap: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);

                // Require authentication before allowing chat
                if (!ApiClient.instance.hasToken || !BuyerAccountService.instance.isLoggedIn) {
                  final loggedIn = await GuestAuthGuard.requireLogin(
                    context,
                    title: 'Sign In to Chat',
                    message: 'Please sign in or create an account to chat with sellers.',
                  );
                  if (!loggedIn) return;
                }

                final sId = int.tryParse(_productArg?.shopId ?? '');
                final sName = _productArg?.shopName ?? '';

                if (ApiClient.instance.hasToken && sId != null && sId > 0) {
                  try {
                    final conv = await ChatService.instance
                        .startConversationRemote(sId);
                    if (!mounted) return;
                    if (conv != null) {
                      navigator.push(
                        MaterialPageRoute(
                          builder: (_) => ChatDetailPage(
                            conversationId: conv.id,
                            title: conv.title.isNotEmpty ? conv.title : sName,
                            subtitle: conv.subtitle,
                            avatarIcon: conv.avatarIcon,
                            avatarBgColor: conv.avatarBg,
                            orderRef: _productTitle,
                            initialMessages:
                                conv.messages.map((m) => m.toMap()).toList(),
                          ),
                        ),
                      );
                      return;
                    }
                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          e is ApiException ? e.message : e.toString(),
                        ),
                        backgroundColor: const Color(0xFFDC2626),
                      ),
                    );
                    return;
                  }
                }

                // Fallback for tests or offline shop context
                final conv = ChatService.instance.getOrCreateShopConversation(
                  shopId: _productArg?.shopId ?? '1',
                  shopName: sName.isNotEmpty ? sName : 'Seller',
                  shopBadge: _productArg?.shopBadge,
                  initialProductSnippet: _productTitle,
                );
                navigator.push(
                  MaterialPageRoute(
                    builder: (_) => ChatDetailPage(
                      conversationId: conv.id,
                      title: conv.title.isNotEmpty ? conv.title : sName,
                      subtitle: conv.subtitle,
                      avatarIcon: conv.avatarIcon,
                      avatarBgColor: conv.avatarBg,
                      orderRef: _productTitle,
                      initialMessages:
                          conv.messages.map((m) => m.toMap()).toList(),
                    ),
                  ),
                );
              },
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Color(0xFF0066FF),
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
                  onPressed: _isAddingToCart ? null : _handleAddToCart,
                  icon: _isAddingToCart
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.shopping_cart_outlined,
                          size: 16, color: Colors.white),
                  label: const Text(
                    'Add to Cart',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isUnavailable
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF0F172A),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(23),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Buy Now Button
            Expanded(
              flex: 5,
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: isUnavailable
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF0066FF),
                  borderRadius: BorderRadius.circular(23),
                  boxShadow: [
                    BoxShadow(
                      color: isUnavailable
                          ? Colors.black.withValues(alpha: 0.1)
                          : const Color(0xFF0066FF).withValues(alpha: 0.28),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Shop Vouchers',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              '${vouchers.length} Available',
              style: const TextStyle(
                color: Color(0xFF0066FF),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isClaimed
                    ? const Color(0xFFCBD5E1)
                    : const Color(0xFF0066FF).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    voucher.id,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0066FF),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '${voucher.minSpend} • ${voucher.expiry}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: isClaimed
                      ? null
                      : () async {
                          final ok = await ShopService.instance
                              .claimVoucherRemote(voucher.id);
                          if (!mounted) return;
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? 'Voucher ${voucher.id} claimed!'
                                    : 'Could not claim voucher.',
                              ),
                              duration: const Duration(seconds: 2),
                              backgroundColor: ok
                                  ? const Color(0xFF050B28)
                                  : const Color(0xFFDC2626),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isClaimed
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF0066FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isClaimed ? 'Claimed' : 'Claim',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 11.5),
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
    if (_productImages.isEmpty) return;
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
                            child: Icon(Icons.broken_image,
                                size: 64, color: Colors.grey),
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

  Widget _buildProductErrorView(BuildContext context, String message) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F8FC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Product Details',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 56, color: Color(0xFFDC2626)),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _requestedProductId != null
                    ? () => _fetchProductDetail(_requestedProductId!)
                    : null,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
