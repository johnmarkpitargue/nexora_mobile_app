import 'package:flutter/material.dart';

import '../models/shop_models.dart';
import '../services/cart_service.dart';
import 'added_to_cart_hud.dart';
import '../../features/home/presentation/widgets/product_card.dart';

/// Interactive Add to Cart Bottom Sheet modal matching Shopee/TikTok Shop standard.
/// Displays product thumbnail, dynamic price, stock, variant selectors (Color, Size, etc.),
/// quantity stepper, fast delivery notice, and a prominent "Add to Cart" button.
/// Strictly excludes SPayLater and Sulit Deal clutter for a clean, premium design.
class AddToCartBottomSheet extends StatefulWidget {
  final ProductModel product;
  final VoidCallback? onAdded;
  final int initialQuantity;
  final Map<int, int>? initialSelectedIndices;

  const AddToCartBottomSheet({
    super.key,
    required this.product,
    this.onAdded,
    this.initialQuantity = 1,
    this.initialSelectedIndices,
  });

  /// Convenient helper to open the Add to Cart modal bottom sheet from anywhere.
  static Future<bool?> show(
    BuildContext context, {
    required ProductModel product,
    VoidCallback? onAdded,
    int initialQuantity = 1,
    Map<int, int>? initialSelectedIndices,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddToCartBottomSheet(
        product: product,
        onAdded: onAdded,
        initialQuantity: initialQuantity,
        initialSelectedIndices: initialSelectedIndices,
      ),
    );

    if (result == true) {
      if (!context.mounted) return result;
      AddedToCartHUD.show(context);
    }
    return result;
  }

  @override
  State<AddToCartBottomSheet> createState() => _AddToCartBottomSheetState();
}

class _AddToCartBottomSheetState extends State<AddToCartBottomSheet> {
  late int _quantity;
  late final Map<int, int> _selectedIndices;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity > 0 ? widget.initialQuantity : 1;
    _selectedIndices = {};

    if (widget.initialSelectedIndices != null &&
        widget.initialSelectedIndices!.isNotEmpty) {
      _selectedIndices.addAll(widget.initialSelectedIndices!);
    } else {
      // Auto-select first option for each variant group so user can immediately add or tap to switch
      final groups = _effectiveVariantGroups;
      for (int i = 0; i < groups.length; i++) {
        if (groups[i].options.isNotEmpty) {
          _selectedIndices[i] = 0;
        }
      }
    }
  }

  /// Provides variant groups from the product
  List<ProductVariantGroup> get _effectiveVariantGroups {
    if (widget.product.variantGroups != null &&
        widget.product.variantGroups!.isNotEmpty) {
      return widget.product.variantGroups!;
    }
    return const [];
  }

  double get _basePrice {
    final clean = widget.product.price.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(clean) ?? 999.0;
  }

  double get _originalPriceVal {
    if (widget.product.originalPrice == null) return _basePrice * 1.25;
    final clean = widget.product.originalPrice!.replaceAll(
      RegExp(r'[^0-9.]'),
      '',
    );
    return double.tryParse(clean) ?? (_basePrice * 1.25);
  }

  double get _variantOffset {
    double offset = 0.0;
    final groups = _effectiveVariantGroups;
    for (int i = 0; i < groups.length; i++) {
      final sel = _selectedIndices[i];
      if (sel != null && sel < groups[i].options.length) {
        offset += groups[i].options[sel].priceOffset;
      }
    }
    return offset;
  }

  double get _effectivePrice {
    final groups = _effectiveVariantGroups;
    for (int i = 0; i < groups.length; i++) {
      final sel = _selectedIndices[i];
      if (sel != null && sel < groups[i].options.length) {
        final opt = groups[i].options[sel];
        if (opt.price != null && opt.price! > 0) {
          return opt.price!;
        }
      }
    }
    return _basePrice + _variantOffset;
  }

  int get _currentStock {
    final groups = _effectiveVariantGroups;
    for (int i = 0; i < groups.length; i++) {
      final sel = _selectedIndices[i];
      if (sel != null && sel < groups[i].options.length) {
        return groups[i].options[sel].stock;
      }
    }
    return widget.product.stockQuantity > 0 ? widget.product.stockQuantity : 45;
  }

  String get _currentVariantSummary {
    final parts = <String>[];
    final groups = _effectiveVariantGroups;
    for (int i = 0; i < groups.length; i++) {
      final sel = _selectedIndices[i];
      if (sel != null && sel < groups[i].options.length) {
        parts.add(groups[i].options[sel].name);
      }
    }
    return parts.isEmpty ? 'Standard' : parts.join(' • ');
  }

  String get _currentThumbnailUrl {
    final groups = _effectiveVariantGroups;
    for (int i = 0; i < groups.length; i++) {
      final sel = _selectedIndices[i];
      if (sel != null && sel < groups[i].options.length) {
        final optImg = groups[i].options[sel].imageUrl;
        if (optImg != null && optImg.isNotEmpty) return optImg;
      }
    }
    if (widget.product.galleryImages != null &&
        widget.product.galleryImages!.isNotEmpty) {
      return widget.product.galleryImages!.first;
    }
    return widget.product.imageUrl;
  }

  void _onAddToCartPressed() {
    Map<String, dynamic>? variantPayload;
    final groups = _effectiveVariantGroups;
    if (groups.isNotEmpty) {
      final parts = <String>[];
      String? optSize;
      String? optColor;
      String? optImage;
      for (int i = 0; i < groups.length; i++) {
        final sel = _selectedIndices[i];
        if (sel != null && sel < groups[i].options.length) {
          final opt = groups[i].options[sel];
          parts.add(opt.name);
          if (opt.size != null && opt.size!.isNotEmpty) optSize = opt.size;
          if (opt.color != null && opt.color!.isNotEmpty) optColor = opt.color;
          if (opt.imageUrl != null && opt.imageUrl!.isNotEmpty) optImage = opt.imageUrl;
        }
      }
      if (parts.isNotEmpty) {
        variantPayload = {
          'variation': parts.join(' • '),
          if (optSize != null) 'size': optSize,
          if (optColor != null) 'color': optColor,
          if (optImage != null) 'image': optImage,
        };
      }
    }

    final pId = int.tryParse(widget.product.id) ?? 0;
    if (pId > 0) {
      CartService.instance.addItemRemote(
        productId: pId,
        quantity: _quantity,
        variant: variantPayload,
      );
    }

    CartService.instance.addToCart(
      productId: pId > 0 ? pId : null,
      variantPayload: variantPayload,
      title: widget.product.title,
      variant: _currentVariantSummary,
      price: _effectivePrice,
      originalPrice: _originalPriceVal,
      imageUrl: _currentThumbnailUrl,
      storeName: widget.product.shopName.isNotEmpty
          ? widget.product.shopName
          : (widget.product.isMall
                ? 'Nexora Official Store'
                : 'Nexora Preferred Store'),
      storeBadge: widget.product.shopBadge.isNotEmpty
          ? widget.product.shopBadge
          : (widget.product.isMall ? 'MALL' : 'OFFICIAL STORE'),
      quantity: _quantity,
    );

    widget.onAdded?.call();
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final groups = _effectiveVariantGroups;
    final maxAllowed = _currentStock > 20
        ? 20
        : (_currentStock > 0 ? _currentStock : 1);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Drag Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Top Header: Thumbnail, Price, Stock, Close button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Preview Thumbnail Card
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      _currentThumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, stackTrace) => const Icon(
                        Icons.shopping_bag_outlined,
                        size: 36,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Price & Stock
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '₱${_effectivePrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                letterSpacing: -0.5,
                              ),
                            ),
                            if (widget.product.originalPrice != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                '₱${_originalPriceVal.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF94A3B8),
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Stock: $_currentStock',
                          style: TextStyle(
                            fontSize: 12,
                            color: _currentStock < 10
                                ? const Color(0xFFE11D48)
                                : const Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Selected: $_currentVariantSummary',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Close button
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      size: 20,
                      color: Color(0xFF64748B),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFF1F5F9)),

            // Delivery Tag Banner - Aligned to Nexora Brand Blue theme (No "Order before 2PM")
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_shipping_rounded,
                      size: 16,
                      color: Color(0xFF0066FF),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.product.shippingTag.isNotEmpty
                            ? (widget.product.shippingTag
                                      .toLowerCase()
                                      .contains('tomorrow')
                                  ? widget.product.shippingTag
                                  : '${widget.product.shippingTag} • Tomorrow')
                            : 'Tomorrow',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0066FF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1, color: Color(0xFFF1F5F9)),

            // Scrollable Variant Selection Body
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dynamic Variant Groups (e.g. Color, Size, Finish)
                    ...List.generate(groups.length, (grpIdx) {
                      final grp = groups[grpIdx];
                      final selectedOptIdx = _selectedIndices[grpIdx];
                      final isApparelSize = grp.groupName
                          .toLowerCase()
                          .contains('size');

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                grp.groupName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              if (isApparelSize)
                                InkWell(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Standard Asian/US Size Chart: S(36-38), M(38-40), L(40-42), XL(42-44)',
                                        ),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Size Guide',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Option Chips
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(grp.options.length, (
                              optIdx,
                            ) {
                              final opt = grp.options[optIdx];
                              final isSelected = selectedOptIdx == optIdx;
                              final isOutOfStock = opt.stock <= 0;

                              return InkWell(
                                onTap: isOutOfStock
                                    ? null
                                    : () {
                                        setState(() {
                                          _selectedIndices[grpIdx] = optIdx;
                                          if (_quantity > opt.stock) {
                                            _quantity = opt.stock > 0
                                                ? opt.stock
                                                : 1;
                                          }
                                        });
                                      },
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFEEF2FF)
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF0066FF)
                                          : const Color(0xFFE2E8F0),
                                      width: isSelected ? 1.5 : 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (opt.colorHex != null) ...[
                                        Container(
                                          width: 12,
                                          height: 12,
                                          margin: const EdgeInsets.only(
                                            right: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: opt.colorHex,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.black12,
                                              width: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                      Text(
                                        opt.name,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          color: isOutOfStock
                                              ? const Color(0xFF94A3B8)
                                              : (isSelected
                                                    ? const Color(0xFF0066FF)
                                                    : const Color(0xFF1E293B)),
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
                          const SizedBox(height: 14),
                        ],
                      );
                    }),

                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 12),

                    // Quantity Stepper Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Quantity',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: _quantity > 1
                                    ? () => setState(() => _quantity--)
                                    : null,
                                borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(5),
                                ),
                                child: Container(
                                  width: 32,
                                  height: 30,
                                  alignment: Alignment.center,
                                  color: _quantity > 1
                                      ? Colors.white
                                      : const Color(0xFFF8FAFC),
                                  child: Icon(
                                    Icons.remove,
                                    size: 14,
                                    color: _quantity > 1
                                        ? const Color(0xFF0F172A)
                                        : const Color(0xFFCBD5E1),
                                  ),
                                ),
                              ),
                              Container(
                                width: 44,
                                height: 30,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  border: Border.symmetric(
                                    vertical: BorderSide(
                                      color: Color(0xFFE2E8F0),
                                    ),
                                  ),
                                ),
                                child: Text(
                                  '$_quantity',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: _quantity < maxAllowed
                                    ? () => setState(() => _quantity++)
                                    : null,
                                borderRadius: const BorderRadius.horizontal(
                                  right: Radius.circular(5),
                                ),
                                child: Container(
                                  width: 32,
                                  height: 30,
                                  alignment: Alignment.center,
                                  color: _quantity < maxAllowed
                                      ? Colors.white
                                      : const Color(0xFFF8FAFC),
                                  child: Icon(
                                    Icons.add,
                                    size: 14,
                                    color: _quantity < maxAllowed
                                        ? const Color(0xFF0F172A)
                                        : const Color(0xFFCBD5E1),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Bottom Add to Cart CTA Button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _currentStock <= 0 ? null : _onAddToCartPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFCBD5E1),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _currentStock <= 0 ? 'Out of Stock' : 'Add to Cart',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
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
}
