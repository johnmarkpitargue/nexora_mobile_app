import 'package:flutter/material.dart';
import 'package:nexora_flutter_app/app/routes/app_routes.dart';
import 'package:nexora_flutter_app/app/theme/nexora_theme.dart';
import 'package:nexora_flutter_app/core/models/shop_models.dart';
import 'package:nexora_flutter_app/core/services/wishlist_service.dart';
import 'package:nexora_flutter_app/core/widgets/added_to_wishlist_hud.dart';
import 'package:nexora_flutter_app/core/widgets/fly_to_wishlist_animation.dart';
import 'package:nexora_flutter_app/core/widgets/nexora_widgets.dart';

class ProductModel {
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
}

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});

  final ProductModel product;

  void _openProduct(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.productDetails, arguments: product);
  }

  void _toggleWishlist(BuildContext context, bool isFavorite) {
    WishlistService.instance.toggleWishlist(product);
    if (!isFavorite) {
      final box = context.findRenderObject() as RenderBox?;
      Offset? startPos;
      if (box != null && box.hasSize) {
        startPos = box.localToGlobal(
          Offset(box.size.width / 2, box.size.height / 2),
        );
      }
      FlyToWishlistAnimation.fly(
        context: context,
        startPosition: startPos,
      );
      AddedToWishlistHUD.show(
        context,
        message: 'Saved to Wishlist',
        count: WishlistService.instance.itemCount,
      );
    } else {
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Removed "${product.title}" from Wishlist (${WishlistService.instance.itemCount} items remaining)',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final showOriginalPrice =
        product.originalPrice != null && product.originalPrice != product.price;
    final wishlistKey = product.id.isEmpty ? product.title : product.id;
    return NexoraCard(
      padding: EdgeInsets.zero,
      onTap: () => _openProduct(context),
      semanticLabel:
          '${product.title}, ${product.price}, ${product.rating} stars, ${_soldLabel(product.soldCount)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 11,
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(
                      color: isDark
                          ? theme.colorScheme.surfaceContainerLow
                          : NexoraTheme.surfaceContainer,
                      child: Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        excludeFromSemantics: true,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 30,
                            ),
                          );
                        },
                      ),
                    ),
                    if (product.isOnVacation || product.discountTag != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: product.isOnVacation
                                ? const Color(0xFFC2410C)
                                : (isDark
                                    ? const Color(0xFF0F1738)
                                    : NexoraTheme.darkNavy),
                            borderRadius: BorderRadius.circular(100),
                            border: isDark
                                ? Border.all(
                                    color: Colors.white.withValues(alpha: 0.15),
                                  )
                                : null,
                          ),
                          child: Text(
                            product.isOnVacation
                                ? 'ON VACATION'
                                : product.discountTag!,
                            style: const TextStyle(
                              fontFamily: NexoraTheme.fontFamily,
                              color: Colors.white,
                              fontSize: 9.5,
                              height: 1,
                              letterSpacing: 0.2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: AnimatedBuilder(
                        animation: WishlistService.instance,
                        builder: (context, _) {
                          final isFavorite = WishlistService.instance
                              .isInWishlist(product.title);
                          return Builder(
                            builder: (btnContext) {
                              return IconButton(
                                key: ValueKey('product-wishlist-$wishlistKey'),
                                onPressed: () =>
                                    _toggleWishlist(btnContext, isFavorite),
                                tooltip: isFavorite
                                    ? 'Remove from wishlist'
                                    : 'Save to wishlist',
                                style: IconButton.styleFrom(
                                  foregroundColor: isFavorite
                                      ? NexoraTheme.tertiary
                                      : (isDark
                                          ? Colors.white
                                          : NexoraTheme.onSurface),
                                  backgroundColor: isDark
                                      ? const Color(0xFF0F1738)
                                          .withValues(alpha: 0.88)
                                      : Colors.white.withValues(alpha: 0.92),
                                  side: isDark
                                      ? BorderSide(
                                          color: Colors.white
                                              .withValues(alpha: 0.15),
                                        )
                                      : null,
                                  minimumSize: const Size(48, 48),
                                  maximumSize: const Size(48, 48),
                                  shape: const CircleBorder(),
                                ),
                                icon: Icon(
                                  isFavorite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  size: 20,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 9,
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProductTrustLine(product: product),
                      const SizedBox(height: 4),
                      Text(
                        product.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: NexoraTheme.fontFamily,
                          color: theme.colorScheme.onSurface,
                          fontSize: 12.5,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Flexible(
                            child: Text(
                              product.price,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: NexoraTheme.fontFamily,
                                color: NexoraTheme.priceColor(context),
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          if (showOriginalPrice) ...[
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                product.originalPrice!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: NexoraTheme.fontFamily,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  decoration: TextDecoration.lineThrough,
                                  fontSize: 10.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${product.rating}',
                            style: TextStyle(
                              fontFamily: NexoraTheme.fontFamily,
                              color: theme.colorScheme.onSurface,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              _soldLabel(product.soldCount),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: NexoraTheme.fontFamily,
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.local_shipping_outlined,
                            size: 13,
                            color: NexoraTheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              product.shippingTag,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: NexoraTheme.fontFamily,
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 10.5,
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
    );
  }

  static String _soldLabel(String soldCount) {
    return soldCount.toLowerCase().contains('sold')
        ? soldCount
        : '$soldCount sold';
  }
}

class _ProductTrustLine extends StatelessWidget {
  const _ProductTrustLine({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final trustLabel = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (product.isMall) ...[
          const Icon(
            Icons.verified_rounded,
            size: 13,
            color: NexoraTheme.primary,
          ),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            product.isMall ? 'Nexora Mall' : product.category,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: NexoraTheme.fontFamily,
              color: product.isMall
                  ? (isDark ? const Color(0xFF60A5FA) : NexoraTheme.primary)
                  : theme.colorScheme.onSurfaceVariant,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );

    if (!product.hasVoucher) return trustLabel;

    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final voucherText = Text(
      'Voucher',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: NexoraTheme.fontFamily,
        color: theme.colorScheme.onSurfaceVariant,
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
      ),
    );
    final voucherDot = DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.outlineVariant,
        shape: BoxShape.circle,
      ),
      child: const SizedBox(width: 3, height: 3),
    );

    if (textScale > 1.3) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          trustLabel,
          const SizedBox(height: 2),
          Row(
            children: [
              voucherDot,
              const SizedBox(width: 7),
              Expanded(child: voucherText),
            ],
          ),
        ],
      );
    }

    final voucherLabel = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        voucherDot,
        const SizedBox(width: 7),
        voucherText,
      ],
    );

    return Row(
      children: [
        Expanded(child: trustLabel),
        const SizedBox(width: 7),
        voucherLabel,
      ],
    );
  }
}
