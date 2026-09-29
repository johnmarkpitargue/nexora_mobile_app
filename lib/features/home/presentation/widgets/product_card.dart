import 'package:flutter/material.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/services/cart_service.dart';

class ProductModel {
  final String title;
  final String imageUrl;
  final String tag;
  final Color tagBgColor;
  final Color tagTextColor;
  final double rating;
  final String reviewsCount;
  final String price;
  final String? originalPrice;
  final String? discountTag;

  const ProductModel({
    required this.title,
    required this.imageUrl,
    required this.tag,
    required this.tagBgColor,
    required this.tagTextColor,
    required this.rating,
    required this.reviewsCount,
    required this.price,
    this.originalPrice,
    this.discountTag,
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
    final theme = Theme.of(context);
    final product = widget.product;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.productDetails);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1:1 Aspect Ratio Image Container with Badges & Wishlist Glass Button
          AspectRatio(
            aspectRatio: 1.0,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    color: const Color(0xFFF1F5F9),
                    child: Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFFE2E8F0),
                          child: const Icon(
                            Icons.headphones,
                            size: 44,
                            color: Color(0xFF94A3B8),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Top Left Badge
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: product.tagBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      product.tag,
                      style: TextStyle(
                        color: product.tagTextColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                // Top Right Wishlist Glass Button
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isFavorite = !isFavorite;
                      });
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: isFavorite ? const Color(0xFFE11D48) : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content Details Area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Rating row
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 14,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${product.rating}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '(${product.reviewsCount})',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF94A3B8),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 2),

                  // Title
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      fontSize: 12.5,
                      color: const Color(0xFF0F172A),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Price & Quick Add Button Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (product.originalPrice != null)
                              Row(
                                children: [
                                  Text(
                                    product.originalPrice!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: const Color(0xFF94A3B8),
                                      decoration: TextDecoration.lineThrough,
                                      fontSize: 10,
                                    ),
                                  ),
                                  if (product.discountTag != null) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFE4E6),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        product.discountTag!,
                                        style: const TextStyle(
                                          color: Color(0xFFE11D48),
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            Text(
                              product.price,
                              style: const TextStyle(
                                color: Color(0xFF0066FF),
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Plus Add Button directly right of price
                      GestureDetector(
                        onTap: () {
                          final parsedPrice = double.tryParse(
                                  product.price.replaceAll(RegExp(r'[^\d.]'), '')) ??
                              1000.0;
                          CartService.instance.addItem(
                            title: product.title,
                            variant: 'Standard Edition',
                            price: parsedPrice,
                            imageUrl: product.imageUrl,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added "${product.title}" to Shopping Cart!'),
                              backgroundColor: const Color(0xFF050B28),
                              action: SnackBarAction(
                                label: 'VIEW CART',
                                textColor: const Color(0xFF00D2FF),
                                onPressed: () {
                                  Navigator.pushNamed(context, AppRoutes.cart);
                                },
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D2FF),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00D2FF).withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 20,
                            color: Color(0xFF050B28),
                          ),
                        ),
                      ),
                    ],
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

