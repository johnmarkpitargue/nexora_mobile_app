import 'package:flutter/material.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/services/wishlist_service.dart';
import '../../../../core/models/shop_models.dart';

class ProductModel {
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

  const ProductModel({
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
  });
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
                              color: const Color(0xFFDC2626), // Vivid red Mall tag
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
                              color: const Color(0xFF06B6D4), // Teal discount tag
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
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tags Row: Sulit Deal & PayLater / Voucher
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Sulit Deal',
                                  style: TextStyle(
                                    color: Color(0xFF0284C7),
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              if (product.hasPayLater)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE0F2FE),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    '0% PayLater',
                                    style: TextStyle(
                                      color: Color(0xFF0284C7),
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              if (product.hasVoucher)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFE4E6),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Voucher',
                                    style: TextStyle(
                                      color: Color(0xFFE11D48),
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 4),

                        // Title with [Mall] Prefix
                        RichText(
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            children: [
                              if (product.isMall)
                                const TextSpan(
                                  text: '[Mall] ',
                                  style: TextStyle(
                                    color: Color(0xFF0284C7),
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

                        const SizedBox(height: 6),

                        // Price Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              product.price,
                              style: const TextStyle(
                                color: Color(0xFFB91C1C), // Rich Shopee style dark red
                                fontWeight: FontWeight.w900,
                                fontSize: 14.5,
                              ),
                            ),
                            if (product.originalPrice != null) ...[
                              const SizedBox(width: 4),
                              Text(
                                product.originalPrice!,
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  decoration: TextDecoration.lineThrough,
                                  fontSize: 9.5,
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 3),

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
                            Text(
                              '${product.soldCount} sold',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 9.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Shipping Tag Footer
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.local_shipping_outlined,
                            size: 11,
                            color: Color(0xFF0284C7),
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
