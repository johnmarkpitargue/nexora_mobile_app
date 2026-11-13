import 'package:flutter/material.dart';

import '../../app/theme/nexora_theme.dart';
import '../models/shop_models.dart';
import '../network/api_client.dart';
import '../services/cart_service.dart';
import '../utils/variant_helper.dart';
import 'added_to_cart_hud.dart';
import '../../features/home/presentation/widgets/product_card.dart';

/// Interactive Add to Cart Bottom Sheet modal.
/// Displays product thumbnail, dynamic price, stock, variant selectors (Variation, Size),
/// quantity stepper, and mandatory variant validation matching the website.
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
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity > 0 ? widget.initialQuantity : 1;
    _selectedIndices = {};

    if (widget.initialSelectedIndices != null &&
        widget.initialSelectedIndices!.isNotEmpty) {
      _selectedIndices.addAll(widget.initialSelectedIndices!);
    } else {
      // Auto-select first available option for each variant group so user can immediately add or tap to switch
      final groups = _effectiveVariantGroups;
      for (int i = 0; i < groups.length; i++) {
        if (groups[i].options.isNotEmpty) {
          final firstInStock =
              groups[i].options.indexWhere((o) => o.stock > 0);
          _selectedIndices[i] = firstInStock >= 0 ? firstInStock : 0;
        }
      }
    }
  }

  List<ProductVariantGroup> get _effectiveVariantGroups {
    if (widget.product.variantGroups != null &&
        widget.product.variantGroups!.isNotEmpty) {
      return widget.product.variantGroups!;
    }

    // Dynamic fallback variant groups based on category ensuring variants always appear
    final cat = widget.product.category.toLowerCase();
    if (cat.contains('apparel') || cat.contains('fashion')) {
      return const [
        ProductVariantGroup(
          groupName: 'Color',
          options: [
            ProductVariantOption(
              id: 'col_blk',
              name: 'Midnight Black',
              colorHex: Color(0xFF1E293B),
              stock: 35,
            ),
            ProductVariantOption(
              id: 'col_wht',
              name: 'Pure White',
              colorHex: Color(0xFFF8FAFC),
              stock: 40,
            ),
            ProductVariantOption(
              id: 'col_gry',
              name: 'Heather Grey',
              colorHex: Color(0xFF94A3B8),
              stock: 25,
            ),
          ],
        ),
        ProductVariantGroup(
          groupName: 'Size',
          options: [
            ProductVariantOption(id: 'sz_s', name: 'S', stock: 20),
            ProductVariantOption(id: 'sz_m', name: 'M', stock: 35),
            ProductVariantOption(id: 'sz_l', name: 'L', stock: 30),
            ProductVariantOption(id: 'sz_xl', name: 'XL', stock: 15),
          ],
        ),
      ];
    } else if (cat.contains('gaming')) {
      return const [
        ProductVariantGroup(
          groupName: 'Edition',
          options: [
            ProductVariantOption(
              id: 'ed_std',
              name: 'Standard Edition',
              stock: 40,
            ),
            ProductVariantOption(
              id: 'ed_rgb',
              name: 'RGB Pro Edition',
              priceOffset: 250,
              stock: 25,
            ),
          ],
        ),
      ];
    } else if (cat.contains('home')) {
      return const [
        ProductVariantGroup(
          groupName: 'Variant',
          options: [
            ProductVariantOption(
              id: 'hm_std',
              name: 'Standard Artisan Size',
              stock: 30,
            ),
            ProductVariantOption(
              id: 'hm_lrg',
              name: 'Large Family Size',
              priceOffset: 120,
              stock: 20,
            ),
          ],
        ),
      ];
    }

    return const [
      ProductVariantGroup(
        groupName: 'Option',
        options: [
          ProductVariantOption(
            id: 'opt_std',
            name: 'Standard Package',
            stock: 50,
          ),
        ],
      ),
    ];
  }

  double get _basePrice {
    final clean = widget.product.price.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(clean) ?? 0.0;
  }

  double? get _originalPriceVal {
    if (widget.product.originalPrice == null) return null;
    final clean = widget.product.originalPrice!.replaceAll(
      RegExp(r'[^0-9.]'),
      '',
    );
    return double.tryParse(clean);
  }

  double get _effectivePrice => VariantHelper.resolvePrice(
        basePrice: _basePrice,
        groups: _effectiveVariantGroups,
        selectedIndices: _selectedIndices,
      );

  int get _currentStock => VariantHelper.resolveStock(
        product: widget.product,
        groups: _effectiveVariantGroups,
        selectedIndices: _selectedIndices,
      );

  String? get _missingSelectionLabel =>
      VariantHelper.missingRequiredGroupLabel(
        _effectiveVariantGroups,
        _selectedIndices,
      );

  bool get _hasAnyAvailableOption {
    final groups = _effectiveVariantGroups;
    if (groups.isEmpty) return widget.product.stockQuantity > 0;
    for (final grp in groups) {
      if (grp.options.isNotEmpty && grp.options.every((o) => o.stock <= 0)) {
        return false;
      }
    }
    return true;
  }

  String get _currentVariantSummary => VariantHelper.buildSelection(
        groups: _effectiveVariantGroups,
        selectedIndices: _selectedIndices,
      ).displaySummary;

  String get _currentThumbnailUrl {
    final variantImg = VariantHelper.resolveSelectedImage(
      groups: _effectiveVariantGroups,
      selectedIndices: _selectedIndices,
    );
    if (variantImg != null && variantImg.isNotEmpty) return variantImg;
    if (widget.product.galleryImages != null &&
        widget.product.galleryImages!.isNotEmpty) {
      return widget.product.galleryImages!.first;
    }
    return widget.product.imageUrl;
  }

  Future<void> _onAddToCartPressed() async {
    if (_isSubmitting) return;

    final groups = _effectiveVariantGroups;
    final selection = VariantHelper.buildSelection(
      groups: groups,
      selectedIndices: _selectedIndices,
    );

    final pId = int.tryParse(widget.product.id) ?? 0;
    if (pId > 0 && ApiClient.instance.hasToken) {
      setState(() => _isSubmitting = true);
      try {
        await CartService.instance.addToCart(
          productId: pId,
          variantPayload: selection.payload,
          quantity: _quantity,
        );
        if (!mounted) return;
        widget.onAdded?.call();
        Navigator.pop(context, true);
      } on ApiException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    } else {
      CartService.instance.addLocalItem(
        title: widget.product.title,
        variant: _currentVariantSummary,
        price: _effectivePrice,
        originalPrice: _originalPriceVal,
        imageUrl: _currentThumbnailUrl,
        productId: widget.product.id,
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final groups = _effectiveVariantGroups;
    final missingLabel = _missingSelectionLabel;
    final bool allOutOfStock = !_hasAnyAvailableOption;
    final bool canPurchaseNow =
        !allOutOfStock && missingLabel == null && _currentStock > 0;
    final String buttonLabel = allOutOfStock
        ? 'Out of Stock'
        : (missingLabel ??
            (_currentStock <= 0 ? 'Out of Stock' : 'Add to Cart'));

    final limit = widget.product.perBuyerLimit;
    final maxAllowed = (limit != null && limit > 0)
        ? (limit < _currentStock ? limit : _currentStock)
        : (_currentStock > 0 ? _currentStock : 1);

    final shippingInfo = widget.product.shippingTag.trim().isNotEmpty
        ? widget.product.shippingTag.trim()
        : widget.product.location.trim();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                  color: theme.colorScheme.outlineVariant,
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
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _currentThumbnailUrl.isNotEmpty
                        ? Image.network(
                            _currentThumbnailUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, error, stackTrace) => Icon(
                              Icons.shopping_bag_outlined,
                              size: 36,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          )
                        : Icon(
                            Icons.shopping_bag_outlined,
                            size: 36,
                            color: theme.colorScheme.onSurfaceVariant,
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
                              '₱${_effectivePrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: NexoraTheme.priceColor(context),
                                letterSpacing: -0.5,
                              ),
                            ),
                            if (_originalPriceVal != null &&
                                _originalPriceVal! > _effectivePrice) ...[
                              const SizedBox(width: 6),
                              Text(
                                '₱${_originalPriceVal!.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
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
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          missingLabel != null
                              ? 'Please $missingLabel'
                              : 'Selected: $_currentVariantSummary',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: missingLabel != null
                                ? const Color(0xFFDC2626)
                                : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Close button
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            if (shippingInfo.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F1738)
                        : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFDBEAFE),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_shipping_rounded,
                        size: 16,
                        color: isDark
                            ? const Color(0xFF38BDF8)
                            : NexoraTheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ships from $shippingInfo',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? const Color(0xFF38BDF8)
                                : NexoraTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Divider(height: 1, color: theme.colorScheme.outlineVariant),
            ],

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
                    ...List.generate(groups.length, (grpIdx) {
                      final grp = groups[grpIdx];
                      final selectedOptIdx = _selectedIndices[grpIdx];
                      final isApparelSize =
                          grp.groupName.toLowerCase().contains('size');

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                grp.groupName,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.onSurface,
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
                                  child: Text(
                                    'Size Guide',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                )
                              else if (selectedOptIdx != null &&
                                  selectedOptIdx < grp.options.length)
                                Text(
                                  grp.options[selectedOptIdx].name,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? const Color(0xFF38BDF8)
                                        : NexoraTheme.primary,
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
                              final isOutOfStock =
                                  VariantHelper.isOptionOutOfStock(
                                product: widget.product,
                                groups: groups,
                                selectedIndices: _selectedIndices,
                                groupIndex: grpIdx,
                                optionIndex: optIdx,
                              );

                              return InkWell(
                                onTap: isOutOfStock
                                    ? null
                                    : () {
                                        setState(() {
                                          _selectedIndices[grpIdx] = optIdx;
                                          final nextStock = _currentStock;
                                          if (nextStock > 0 &&
                                              _quantity > nextStock) {
                                            _quantity = nextStock;
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
                                        ? (isDark
                                            ? const Color(0xFF0C2454)
                                            : const Color(0xFFEEF2FF))
                                        : theme.colorScheme.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isSelected
                                          ? (isDark
                                              ? const Color(0xFF38BDF8)
                                              : NexoraTheme.primary)
                                          : theme.colorScheme.outlineVariant,
                                      width: isSelected ? 1.5 : 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (opt.imageUrl != null &&
                                          opt.imageUrl!.isNotEmpty) ...[
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: Image.network(
                                            opt.imageUrl!,
                                            width: 18,
                                            height: 18,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) =>
                                                const SizedBox.shrink(),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                      ] else if (opt.colorHex != null) ...[
                                        Container(
                                          width: 12,
                                          height: 12,
                                          margin:
                                              const EdgeInsets.only(right: 6),
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
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: isOutOfStock
                                              ? theme.colorScheme.outlineVariant
                                              : (isSelected
                                                  ? (isDark
                                                      ? const Color(
                                                          0xFF38BDF8)
                                                      : NexoraTheme.primary)
                                                  : theme.colorScheme
                                                      .onSurface),
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

                    Divider(
                        height: 1, color: theme.colorScheme.outlineVariant),
                    const SizedBox(height: 12),

                    // Quantity Stepper Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Quantity',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: theme.colorScheme.outlineVariant),
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
                                  color:
                                      theme.colorScheme.surfaceContainerLow,
                                  child: Icon(
                                    Icons.remove,
                                    size: 14,
                                    color: _quantity > 1
                                        ? theme.colorScheme.onSurface
                                        : theme.colorScheme.outlineVariant,
                                  ),
                                ),
                              ),
                              Container(
                                width: 44,
                                height: 30,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  border: Border.symmetric(
                                    vertical: BorderSide(
                                      color:
                                          theme.colorScheme.outlineVariant,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  '$_quantity',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurface,
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
                                  color:
                                      theme.colorScheme.surfaceContainerLow,
                                  child: Icon(
                                    Icons.add,
                                    size: 14,
                                    color: _quantity < maxAllowed
                                        ? theme.colorScheme.onSurface
                                        : theme.colorScheme.outlineVariant,
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
                  onPressed: (!canPurchaseNow || _isSubmitting)
                      ? null
                      : _onAddToCartPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        theme.colorScheme.outlineVariant,
                    disabledForegroundColor:
                        theme.colorScheme.onSurfaceVariant,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          buttonLabel,
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
