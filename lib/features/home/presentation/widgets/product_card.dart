import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/nexora_theme.dart';
import '../../../../core/services/wishlist_service.dart';
import '../../../../core/models/shop_models.dart';
import '../../../../core/utils/image_url_helper.dart';
import '../../../../core/utils/variant_helper.dart';
import '../../../../core/widgets/added_to_wishlist_hud.dart';
import '../../../../core/widgets/fly_to_wishlist_animation.dart';
import '../../../../core/widgets/nexora_widgets.dart';

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
  final String? shopAvatarUrl;
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
    this.isMall = false,
    this.discountTag,
    required this.price,
    this.originalPrice,
    required this.rating,
    required this.soldCount,
    required this.shippingTag,
    this.hasPayLater = false,
    this.hasVoucher = false,
    this.shopId = '',
    this.shopName = '',
    this.shopBadge = '',
    this.shopAvatarUrl,
    this.stockQuantity = 0,
    this.variantGroups,
    this.reviews,
    this.ratingBreakdown,
    this.galleryImages,
    this.specs,
    this.description,
    this.isActive = true,
    this.isOnVacation = false,
    this.location = '',
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
    final json =
        inputJson.containsKey('product') &&
            inputJson['product'] is Map<String, dynamic>
        ? inputJson['product'] as Map<String, dynamic>
        : inputJson;
    final seller = json['seller'] as Map<String, dynamic>?;
    final primaryImg = ImageUrlHelper.resolve(
      json['image'] as String? ?? json['primary_image'] as String?,
    );
    final gallery =
        (json['gallery'] as List?)
            ?.map((e) => ImageUrlHelper.resolve(e))
            .where((e) => e.isNotEmpty)
            .toList() ??
        [];
    final imagesList =
        (json['images'] as List?)
            ?.map((e) => ImageUrlHelper.resolve(e))
            .where((e) => e.isNotEmpty)
            .toList() ??
        [];
    final allImages = <String>[];
    for (final img in [...gallery, ...imagesList]) {
      if (!allImages.contains(img)) allImages.add(img);
    }
    final imgUrl = primaryImg.isNotEmpty
        ? primaryImg
        : (allImages.isNotEmpty ? allImages.first : '');

    final priceNum = (json['price'] as num?)?.toDouble();
    final compareNum =
        (json['compare_price'] as num?)?.toDouble() ??
        (json['regular_price'] as num?)?.toDouble();
    final formattedPrice =
        json['formatted_price'] as String? ??
        (priceNum != null
            ? '₱${priceNum % 1 == 0 ? priceNum.toInt().toString() : priceNum.toStringAsFixed(2)}'
            : '₱0.00');
    final formattedOriginal =
        (compareNum != null && priceNum != null && compareNum > priceNum)
        ? '₱${compareNum % 1 == 0 ? compareNum.toInt().toString() : compareNum.toStringAsFixed(2)}'
        : null;
    String? discountTag = json['discount_tag'] as String?;
    if (discountTag == null &&
        compareNum != null &&
        priceNum != null &&
        compareNum > priceNum &&
        compareNum > 0) {
      final pct = (((compareNum - priceNum) / compareNum) * 100).round();
      if (pct > 0) discountTag = '-$pct%';
    }

    final sellerId =
        seller?['id']?.toString() ?? json['seller_id']?.toString() ?? '';
    final sellerName =
        (seller?['store_name'] as String?)?.trim().isNotEmpty == true
        ? seller!['store_name'].toString().trim()
        : ((seller?['business_name'] as String?)?.trim().isNotEmpty == true
              ? seller!['business_name'].toString().trim()
              : ((seller?['name'] as String?)?.trim().isNotEmpty == true
                    ? seller!['name'].toString().trim()
                    : (json['seller_name'] as String?)?.trim() ?? ''));
    final sellerCity = (seller?['city'] as String?)?.trim() ?? '';
    final sellerAvatar = ImageUrlHelper.resolve(seller?['avatar_url']);
    final shopBadge =
        (seller?['badge'] as String?)?.trim() ??
        (json['shop_badge'] as String?)?.trim() ??
        '';
    final isMall = seller?['is_mall'] == true || json['is_mall'] == true;

    final categoryName =
        json['category_name'] as String? ??
        json['category'] as String? ??
        (json['category_slug'] != null ? json['category_slug'].toString() : '');

    final isVacation =
        seller?['is_vacation_mode'] == true || json['is_vacation_mode'] == true;
    final parsedStock = (json['stock'] as num?)?.toInt() ?? 0;

    final variantGroups = VariantHelper.buildVariantGroups(
      variantsData: json['variants_data'],
      colors: json['colors'],
      sizes: json['sizes'],
      defaultStock: parsedStock,
    );

    // Reviews if provided
    List<ProductReviewModel>? reviews;
    if (json['reviews'] is List && (json['reviews'] as List).isNotEmpty) {
      reviews = (json['reviews'] as List).map((r) {
        final reviewer = r['buyer_name'] as String? ?? 'Shopper';
        final initial = reviewer.isNotEmpty ? reviewer[0].toUpperCase() : 'S';
        final photos =
            (r['photos'] as List?)
                ?.map((p) => ImageUrlHelper.resolve(p))
                .where((p) => p.isNotEmpty)
                .toList() ??
            [];
        return ProductReviewModel(
          id: r['id']?.toString() ?? 'rev-1',
          userName: reviewer,
          initials: initial,
          avatarColor: const Color(0xFF0066FF),
          rating: (r['rating'] as num?)?.toDouble() ?? 5.0,
          date: r['created_at'] as String? ?? 'Recently',
          variantName: VariantHelper.formatVariantDisplay(r['variant']),
          comment: r['comment'] as String? ?? '',
          reviewImages: photos,
        );
      }).toList();
    }

    final int flashSeconds =
        (json['flash_sale_remaining_seconds'] as num?)?.toInt() ?? 0;

    final rawSoldCount =
        json['sold_count'] ?? json['sales_count'] ?? json['reviews_count'] ?? 0;
    final int soldNum = (rawSoldCount is num)
        ? rawSoldCount.toInt()
        : (int.tryParse(
                rawSoldCount.toString().replaceAll(RegExp(r'[^0-9]'), ''),
              ) ??
              0);
    final soldStr = '$soldNum sold';

    return ProductModel(
      id: json['id'].toString(),
      title: json['name'] as String? ?? json['title'] as String? ?? '',
      imageUrl: imgUrl,
      category: categoryName,
      isMall: isMall,
      discountTag: discountTag,
      price: formattedPrice,
      originalPrice: formattedOriginal,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      soldCount: soldStr,
      shippingTag: (json['shipping_tag'] as String?)?.trim() ?? sellerCity,
      shopId: sellerId,
      shopName: sellerName,
      shopBadge: shopBadge,
      shopAvatarUrl: sellerAvatar.isNotEmpty ? sellerAvatar : null,
      stockQuantity: parsedStock,
      description: json['description'] as String? ?? '',
      galleryImages: allImages.isNotEmpty
          ? allImages
          : (imgUrl.isNotEmpty ? [imgUrl] : []),
      location: sellerCity,
      isActive: json['is_active'] != false && json['status'] != 'inactive',
      isOnVacation: isVacation,
      isFlashSale: json['is_flash_sale'] == true,
      flashSalePrice: json['flash_sale_price'] != null
          ? '₱${json['flash_sale_price']}'
          : null,
      flashSaleTimeRemaining: flashSeconds > 0
          ? Duration(seconds: flashSeconds)
          : null,
      perBuyerLimit: (json['max_purchase_limit'] as num?)?.toInt(),
      variantGroups: variantGroups,
      reviews: reviews,
    );
  }
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
                    child: product.imageUrl.isNotEmpty
                        ? Image.network(
                            product.imageUrl,
                            fit: BoxFit.cover,
                            excludeFromSemantics: true,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: isDark
                                    ? const Color(0xFF131D38)
                                    : const Color(0xFFF1F5F9),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.shopping_bag_outlined,
                                        color: isDark
                                            ? const Color(0xFF475569)
                                            : const Color(0xFF94A3B8),
                                        size: 32,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Nexora',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                          color: isDark
                                              ? const Color(0xFF475569)
                                              : const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            color: isDark
                                ? const Color(0xFF131D38)
                                : const Color(0xFFF1F5F9),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.shopping_bag_outlined,
                                    color: isDark
                                        ? const Color(0xFF475569)
                                        : const Color(0xFF94A3B8),
                                    size: 32,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Nexora',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                      color: isDark
                                          ? const Color(0xFF475569)
                                          : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
            flex: 10,
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
            product.isMall ? 'Nexora Mall' : (product.shopName.isNotEmpty ? product.shopName : product.category),
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
