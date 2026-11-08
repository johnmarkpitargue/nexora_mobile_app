import '../../features/home/presentation/widgets/product_card.dart';
import '../models/shop_models.dart';
import 'image_url_helper.dart';

class VariantSelectionResult {
  final Map<String, dynamic>? payload;
  final String displaySummary;

  const VariantSelectionResult({
    this.payload,
    this.displaySummary = 'Standard',
  });
}

class VariantHelper {
  VariantHelper._();

  static bool isSizeGroup(ProductVariantGroup group) {
    final name = group.groupName.trim().toLowerCase();
    return name == 'size' || name == 'sizes';
  }

  /// Builds independent Variation and Size groups matching the web PDP:
  /// - Variation group comes from `variants_data` if non-empty, else from `colors`.
  /// - Size group is built independently whenever `sizes` is non-empty.
  static List<ProductVariantGroup>? buildVariantGroups({
    required dynamic variantsData,
    required dynamic colors,
    required dynamic sizes,
    required int defaultStock,
  }) {
    final groups = <ProductVariantGroup>[];

    if (variantsData is List && variantsData.isNotEmpty) {
      final options = variantsData.map((v) {
        if (v is! Map) {
          final optStr = v.toString();
          return ProductVariantOption(
            id: optStr,
            name: optStr,
            stock: defaultStock,
          );
        }
        final optName = v['name']?.toString().trim().isNotEmpty == true
            ? v['name'].toString().trim()
            : (v['sku']?.toString().trim().isNotEmpty == true
                ? v['sku'].toString().trim()
                : (v['color']?.toString().trim().isNotEmpty == true
                    ? v['color'].toString().trim()
                    : 'Option'));
        final optStock = (v['stock'] as num?)?.toInt() ?? defaultStock;
        final optPrice = (v['price'] as num?)?.toDouble();
        final optImg = ImageUrlHelper.resolve(v['image']);
        final optColor = v['color']?.toString().trim();
        final optSize = v['size']?.toString().trim();
        final optSku = v['sku']?.toString().trim();

        return ProductVariantOption(
          id: optSku != null && optSku.isNotEmpty ? optSku : optName,
          name: optName,
          price: optPrice,
          stock: optStock,
          imageUrl: optImg.isNotEmpty ? optImg : null,
          color: optColor?.isNotEmpty == true ? optColor : null,
          size: optSize?.isNotEmpty == true ? optSize : null,
          sku: optSku?.isNotEmpty == true ? optSku : null,
        );
      }).toList();

      if (options.isNotEmpty) {
        groups.add(
          ProductVariantGroup(
            groupName: 'Variation',
            options: options,
          ),
        );
      }
    } else {
      final colorsList = (colors as List?)
              ?.map((c) => c.toString().trim())
              .where((c) => c.isNotEmpty)
              .toList() ??
          const <String>[];
      if (colorsList.isNotEmpty) {
        groups.add(
          ProductVariantGroup(
            groupName: 'Variation',
            options: colorsList
                .map(
                  (c) => ProductVariantOption(
                    id: c,
                    name: c,
                    stock: defaultStock,
                    color: c,
                  ),
                )
                .toList(),
          ),
        );
      }
    }

    final sizesList = (sizes as List?)
            ?.map((s) => s.toString().trim())
            .where((s) => s.isNotEmpty)
            .toList() ??
        const <String>[];
    if (sizesList.isNotEmpty) {
      groups.add(
        ProductVariantGroup(
          groupName: 'Size',
          options: sizesList
              .map(
                (s) => ProductVariantOption(
                  id: s,
                  name: s,
                  stock: defaultStock,
                  size: s,
                ),
              )
              .toList(),
        ),
      );
    }

    return groups.isEmpty ? null : groups;
  }

  /// Returns the web-aligned CTA label for missing required selection,
  /// or null when every required group has a valid option selected.
  static String? missingRequiredGroupLabel(
    List<ProductVariantGroup> groups,
    Map<int, int> selectedIndices,
  ) {
    for (int i = 0; i < groups.length; i++) {
      final grp = groups[i];
      if (grp.options.isEmpty) continue;
      final sel = selectedIndices[i];
      if (sel == null || sel < 0 || sel >= grp.options.length) {
        return isSizeGroup(grp) ? 'Select a Size' : 'Select a Variation';
      }
    }
    return null;
  }

  static bool areAllSelected(
    List<ProductVariantGroup> groups,
    Map<int, int> selectedIndices,
  ) {
    return missingRequiredGroupLabel(groups, selectedIndices) == null;
  }

  /// Checks whether a given option is out of stock (considering `combinationStock` when present).
  static bool isOptionOutOfStock({
    required ProductModel? product,
    required List<ProductVariantGroup> groups,
    required Map<int, int> selectedIndices,
    required int groupIndex,
    required int optionIndex,
  }) {
    if (groupIndex < 0 || groupIndex >= groups.length) return true;
    final grp = groups[groupIndex];
    if (optionIndex < 0 || optionIndex >= grp.options.length) return true;
    final opt = grp.options[optionIndex];
    bool isOut = opt.stock <= 0;

    final combStock = product?.combinationStock;
    if (combStock != null && groups.length >= 2) {
      if (groupIndex == 0 && selectedIndices.containsKey(1)) {
        final sel1 = selectedIndices[1]!;
        if (sel1 >= 0 && sel1 < groups[1].options.length) {
          final combKey = '${opt.name}-${groups[1].options[sel1].name}';
          if (combStock.containsKey(combKey)) {
            isOut = combStock[combKey]! <= 0;
          }
        }
      } else if (groupIndex == 1 && selectedIndices.containsKey(0)) {
        final sel0 = selectedIndices[0]!;
        if (sel0 >= 0 && sel0 < groups[0].options.length) {
          final combKey = '${groups[0].options[sel0].name}-${opt.name}';
          if (combStock.containsKey(combKey)) {
            isOut = combStock[combKey]! <= 0;
          }
        }
      }
    }
    return isOut;
  }

  /// Resolves available stock as the minimum across all selected options
  /// (or matching combinationStock entry if present).
  static int resolveStock({
    required ProductModel? product,
    required List<ProductVariantGroup> groups,
    required Map<int, int> selectedIndices,
  }) {
    if (groups.length >= 2 && product?.combinationStock != null) {
      final grp0 = groups[0];
      final grp1 = groups[1];
      final sel0 = selectedIndices[0];
      final sel1 = selectedIndices[1];
      if (sel0 != null &&
          sel1 != null &&
          sel0 >= 0 &&
          sel1 >= 0 &&
          sel0 < grp0.options.length &&
          sel1 < grp1.options.length) {
        final key = '${grp0.options[sel0].name}-${grp1.options[sel1].name}';
        if (product!.combinationStock!.containsKey(key)) {
          return product.combinationStock![key]!;
        }
      } else if (sel0 != null && sel0 >= 0 && sel0 < grp0.options.length) {
        final prefix = '${grp0.options[sel0].name}-';
        final matchingKeys =
            product!.combinationStock!.keys.where((k) => k.startsWith(prefix));
        if (matchingKeys.isNotEmpty) {
          return product.combinationStock![matchingKeys.first]!;
        }
      }
    }

    int? minStock;
    for (int i = 0; i < groups.length; i++) {
      final sel = selectedIndices[i];
      if (sel != null && sel >= 0 && sel < groups[i].options.length) {
        final s = groups[i].options[sel].stock;
        if (minStock == null || s < minStock) {
          minStock = s;
        }
      }
    }
    if (minStock != null) return minStock;
    return product?.stockQuantity ?? 0;
  }

  /// Resolves effective price: uses variation option's explicit price when present (> 0),
  /// otherwise base price + sum of selected option offsets.
  static double resolvePrice({
    required double basePrice,
    required List<ProductVariantGroup> groups,
    required Map<int, int> selectedIndices,
  }) {
    for (int i = 0; i < groups.length; i++) {
      final sel = selectedIndices[i];
      if (sel != null && sel >= 0 && sel < groups[i].options.length) {
        final opt = groups[i].options[sel];
        if (!isSizeGroup(groups[i]) && opt.price != null && opt.price! > 0) {
          return opt.price!;
        }
      }
    }
    double offset = 0.0;
    for (int i = 0; i < groups.length; i++) {
      final sel = selectedIndices[i];
      if (sel != null && sel >= 0 && sel < groups[i].options.length) {
        final opt = groups[i].options[sel];
        if (opt.price != null && opt.price! > 0) {
          return opt.price!;
        }
        offset += opt.priceOffset;
      }
    }
    return basePrice + offset;
  }

  /// Resolves thumbnail image prioritizing selected variation option image.
  static String? resolveSelectedImage({
    required List<ProductVariantGroup> groups,
    required Map<int, int> selectedIndices,
  }) {
    for (int i = 0; i < groups.length; i++) {
      final sel = selectedIndices[i];
      if (sel != null && sel >= 0 && sel < groups[i].options.length) {
        final img = groups[i].options[sel].imageUrl;
        if (img != null && img.isNotEmpty) {
          return img;
        }
      }
    }
    return null;
  }

  /// Builds the web-compatible cart payload `{variation, size, image}`
  /// and human-readable display string.
  static VariantSelectionResult buildSelection({
    required List<ProductVariantGroup> groups,
    required Map<int, int> selectedIndices,
  }) {
    if (groups.isEmpty) {
      return const VariantSelectionResult();
    }

    String? variationKey;
    String? sizeValue;
    String? imageValue;
    final summaryParts = <String>[];

    for (int i = 0; i < groups.length; i++) {
      final grp = groups[i];
      final sel = selectedIndices[i];
      if (sel == null || sel < 0 || sel >= grp.options.length) continue;
      final opt = grp.options[sel];
      summaryParts.add(opt.name);

      if (isSizeGroup(grp)) {
        sizeValue = (opt.size != null && opt.size!.isNotEmpty)
            ? opt.size!
            : opt.name;
      } else {
        variationKey ??= opt.name.isNotEmpty
            ? opt.name
            : ((opt.sku != null && opt.sku!.isNotEmpty) ? opt.sku : null);
        if (opt.size != null && opt.size!.isNotEmpty && sizeValue == null) {
          sizeValue = opt.size;
        }
        if (opt.imageUrl != null && opt.imageUrl!.isNotEmpty && imageValue == null) {
          imageValue = opt.imageUrl;
        }
      }
    }

    Map<String, dynamic>? payload;
    if (variationKey != null || sizeValue != null || imageValue != null) {
      payload = <String, dynamic>{
        'variation': ?variationKey,
        'size': ?sizeValue,
        'image': ?imageValue,
      };
    }

    return VariantSelectionResult(
      payload: payload,
      displaySummary: summaryParts.isEmpty ? 'Standard' : summaryParts.join(' • '),
    );
  }

  /// Formats `cart_item.variant` JSON or String for UI display.
  static String formatVariantDisplay(dynamic rawVariant) {
    if (rawVariant is Map) {
      final variation = rawVariant['variation']?.toString().trim() ??
          rawVariant['name']?.toString().trim() ??
          rawVariant['color']?.toString().trim() ??
          '';
      final size = rawVariant['size']?.toString().trim() ?? '';
      final parts = <String>[
        if (variation.isNotEmpty) variation,
        if (size.isNotEmpty && size != variation) size,
      ];
      return parts.isEmpty ? 'Standard' : parts.join(' • ');
    }
    if (rawVariant is String && rawVariant.trim().isNotEmpty) {
      return rawVariant.trim();
    }
    return 'Standard';
  }
}
