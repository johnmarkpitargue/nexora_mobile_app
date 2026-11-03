import 'package:flutter/material.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/nexora_theme.dart';
import '../../../../core/services/wishlist_service.dart';
import '../../../../core/models/shop_models.dart';

class ProductModel {
  final String id;
  final String title;
  final String imageUrl;
  final String category;
  final bool isMall;
  final String? discountTag;
  final String price;
  final String? originalPrice;
  final double rating;
  final String soldCount;
  final String shippingTag;
  final bool hasPayLater;
  final bool hasVoucher;
  final String shopId;
  final String shopName;
  final String shopBadge;
  final int stockQuantity;
  final List<ProductVariantGroup>? variantGroups;
  final List<ProductReviewModel>? reviews;
  final Map<int, double>? ratingBreakdown;
  final List<String>? galleryImages;
  final List<Map<String, dynamic>>? specs;
  final String? description;
  final bool isActive;
  final bool isOnVacation;
  final String location;
  final int? perBuyerLimit;
  final bool isFlashSale;
  final String? flashSalePrice;
  final int flashSaleStockRemaining;
  final int flashSaleTotalStock;
  final Duration? flashSaleTimeRemaining;
  final List<ShopVoucherModel>? claimableVouchers;
  final Map<String, int>? combinationStock;
  final bool isDeleted;

  const ProductModel({
    this.id = '',
    required this.title,
    required this.imageUrl,
    required this.category,
    this.isMall = true,
    this.discountTag,
    required this.price,
    this.originalPrice,
    required this.rating,
    required this.soldCount,
    required this.shippingTag,
    this.hasPayLater = true,
    this.hasVoucher = false,
    this.shopId = 'nexora_official',
    this.shopName = 'Nexora Official Store',
    this.shopBadge = 'NEXORA MALL',
    this.stockQuantity = 150,
    this.variantGroups,
    this.reviews,
    this.ratingBreakdown,
    this.galleryImages,
    this.specs,
    this.description,
    this.isActive = true,
    this.isOnVacation = false,
    this.location = 'Metro Manila',
    this.perBuyerLimit,
    this.isFlashSale = false,
    this.flashSalePrice,
    this.flashSaleStockRemaining = 0,
    this.flashSaleTotalStock = 0,
    this.flashSaleTimeRemaining,
    this.claimableVouchers,
    this.combinationStock,
    this.isDeleted = false,
  });

  factory ProductModel.fromApiJson(Map<String, dynamic> inputJson) {
    final json = inputJson.containsKey('product') && inputJson['product'] is Map<String, dynamic>
        ? inputJson['product'] as Map<String, dynamic>
        : inputJson;
    final seller = json['seller'] as Map<String, dynamic>?;
    final primaryImg = json['image'] as String? ?? json['primary_image'] as String?;
    final gallery = (json['gallery'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final imagesList = (json['images'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final allImages = [...gallery, ...imagesList];
    final imgUrl = primaryImg ?? (allImages.isNotEmpty ? allImages.first : '');

    final priceVal = json['price'];
    final compareVal = json['compare_price'] ?? json['regular_price'];
    final formattedPrice = json['formatted_price'] ??
        (priceVal != null
            ? '₱${priceVal is num ? (priceVal % 1 == 0 ? priceVal.toInt().toString() : priceVal.toStringAsFixed(2)) : priceVal}'
            : '₱0.00');
    final formattedOriginal = compareVal != null && compareVal != priceVal
        ? '₱${compareVal is num ? (compareVal % 1 == 0 ? compareVal.toInt().toString() : compareVal.toStringAsFixed(2)) : compareVal}'
        : null;

    final sellerId = seller?['id']?.toString() ?? json['seller_id']?.toString() ?? '1';
    final sellerName = seller?['name'] as String? ??
        seller?['business_name'] as String? ??
        seller?['store_name'] as String? ??
        json['seller_name'] as String? ??
        'Nexora Store';

    final categoryName = json['category_name'] as String? ??
        json['category'] as String? ??
        (json['category_slug'] != null ? json['category_slug'].toString() : 'General');

    final isVacation = seller?['is_vacation_mode'] == true || json['is_vacation_mode'] == true;

    // Variants data if provided by product detail endpoint
    List<ProductVariantGroup>? variantGroups;
    if (json['variants_data'] is List && (json['variants_data'] as List).isNotEmpty) {
      final vList = json['variants_data'] as List;
      final options = vList.map((v) {
        final optName = v['name']?.toString() ??
            v['color']?.toString() ??
            v['size']?.toString() ??
            'Default';
        return ProductVariantOption(
          id: v['id']?.toString() ?? optName,
          name: optName,
          stock: (v['stock'] as num?)?.toInt() ??
              (json['stock'] as num?)?.toInt() ??
              50,
        );
      }).toList();
      variantGroups = [
        ProductVariantGroup(
          groupName: 'Variation',
          options: options,
        )
      ];
    }

    // Reviews if provided
    List<ProductReviewModel>? reviews;
    if (json['reviews'] is List && (json['reviews'] as List).isNotEmpty) {
      reviews = (json['reviews'] as List).map((r) {
        final reviewer = r['buyer_name'] as String? ?? 'Shopper';
        final initial = reviewer.isNotEmpty ? reviewer[0].toUpperCase() : 'S';
        final photos =
            (r['photos'] as List?)?.map((p) => p.toString()).toList() ?? [];
        return ProductReviewModel(
          id: r['id']?.toString() ?? 'rev-1',
          userName: reviewer,
          initials: initial,
          avatarColor: const Color(0xFF0066FF),
          rating: (r['rating'] as num?)?.toDouble() ?? 5.0,
          date: r['created_at'] as String? ?? 'Recently',
          variantName: 'Standard',
          comment: r['comment'] as String? ?? '',
          reviewImages: photos,
        );
      }).toList();
    }

    return ProductModel(
      id: json['id'].toString(),
      title: json['name'] as String? ?? json['title'] as String? ?? '',
      imageUrl: imgUrl,
      category: categoryName,
      price: formattedPrice,
      originalPrice: formattedOriginal,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      soldCount: '${json['sold_count'] ?? json['reviews_count'] ?? 0} sold',
      shippingTag: 'Fast Delivery',
      shopId: sellerId,
      shopName: sellerName,
      shopBadge: 'OFFICIAL STORE',
      stockQuantity: (json['stock'] as num?)?.toInt() ?? 50,
      description: json['description'] as String? ?? '',
      galleryImages: allImages.isNotEmpty ? allImages : (imgUrl.isNotEmpty ? [imgUrl] : []),
      location: seller?['city'] as String? ?? 'Metro Manila',
      isActive: json['is_active'] != false && json['status'] != 'inactive',
      isOnVacation: isVacation,
      isFlashSale: json['is_flash_sale'] == true,
      flashSalePrice: json['flash_sale_price'] != null ? '₱${json['flash_sale_price']}' : null,
      perBuyerLimit: (json['max_purchase_limit'] as num?)?.toInt(),
      variantGroups: variantGroups,
      reviews: reviews,
    );
  }
}

class ProductCard extends StatefulWidget {
  final ProductModel product;

  const ProductCard({
    super.key,
    required this.product,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.productDetails, arguments: product);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Container with Badges
            AspectRatio(
              aspectRatio: 1.0,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      color: const Color(0xFFE2E8F0),
                      child: Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFFCBD5E1),
                            child: const Center(
                              child: Text(
                                'img',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Top Left Badges (MALL badge & Discount badge)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.isMall)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            margin: const EdgeInsets.only(bottom: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0066FF), // Nexora Brand Theme Electric Blue
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'MALL',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        if (product.discountTag != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: product.isMall
                                  ? const Color(0xFF050B28) // Dark Navy accent when paired with Mall badge
                                  : const Color(0xFF0066FF), // Nexora Electric Blue discount tag
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              product.discountTag!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Top Right Wishlist Button
                  Positioned(
                    top: 6,
                    right: 6,
                    child: AnimatedBuilder(
                      animation: WishlistService.instance,
                      builder: (context, _) {
                        final isFavorite = WishlistService.instance.isInWishlist(product.title);
                        return GestureDetector(
                          onTap: () {
                            WishlistService.instance.toggleWishlist(product);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isFavorite
                                      ? 'Removed "${product.title}" from Wishlist'
                                      : 'Saved "${product.title}" to Wishlist!',
                                ),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.85),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              size: 16,
                              color: isFavorite
                                  ? const Color(0xFFE11D48)
                                  : const Color(0xFF475569),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Content Details Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Tags Row: Clean Voucher or Category Highlight
                          if (product.hasVoucher)
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: const Color(0xFFDBEAFE)),
                                    ),
                                    child: const Text(
                                      'Voucher Available',
                                      style: TextStyle(
                                        color: Color(0xFF0066FF),
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 3),

                          // Title with [Mall] Prefix
                          Flexible(
                            child: RichText(
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                children: [
                                  if (product.isMall)
                                    const TextSpan(
                                      text: '[Mall] ',
                                      style: TextStyle(
                                        color: Color(0xFF0066FF),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  TextSpan(
                                    text: product.title,
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11.5,
                                      height: 1.25,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 4),

                          // Price Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Flexible(
                                child: Text(
                                  product.price,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: NexoraTheme.price,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14.5,
                                  ),
                                ),
                              ),
                              if (product.originalPrice != null) ...[
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    product.originalPrice!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF94A3B8),
                                      decoration: TextDecoration.lineThrough,
                                      fontSize: 9.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 2),

                          // Rating & Sold Count
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 11,
                                color: Color(0xFFF59E0B),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${product.rating}',
                                style: const TextStyle(
                                  color: Color(0xFFD97706),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  product.soldCount.toLowerCase().contains('sold')
                                      ? product.soldCount
                                      : '${product.soldCount} sold',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 9.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Shipping Tag Footer
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.local_shipping_outlined,
                            size: 11,
                            color: Color(0xFF0066FF),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              product.shippingTag,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
