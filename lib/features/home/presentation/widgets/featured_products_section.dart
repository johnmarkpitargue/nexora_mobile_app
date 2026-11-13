import 'package:flutter/material.dart';
import 'package:nexora_flutter_app/app/theme/nexora_theme.dart';
import 'package:nexora_flutter_app/core/services/shop_service.dart';

import 'product_card.dart';

class DailyDiscoverSection extends StatelessWidget {
  const DailyDiscoverSection({super.key, this.selectedCategory});

  final String? selectedCategory;

  static List<ProductModel> get allProducts => ShopService.allAppProducts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final products = selectedCategory == null
        ? allProducts
        : allProducts
              .where((product) => product.category == selectedCategory)
              .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selectedCategory ?? 'Recommended for you',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: NexoraTheme.fontFamily,
              color: theme.colorScheme.onSurface,
              fontSize: 20,
              height: 1.2,
              letterSpacing: -0.3,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${products.length} ${products.length == 1 ? 'product' : 'products'}',
            style: TextStyle(
              fontFamily: NexoraTheme.fontFamily,
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          if (products.isEmpty)
            _EmptyCategory(category: selectedCategory)
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = switch (constraints.maxWidth) {
                  >= 1080 => 5,
                  >= 820 => 4,
                  >= 560 => 3,
                  _ => 2,
                };
                const spacing = 12.0;
                final cardWidth =
                    (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                    crossAxisCount;
                final textScale = MediaQuery.textScalerOf(context).scale(1);
                final accessibilityGrowth =
                    ((textScale - 1).clamp(0.0, 1.0) * 116);
                final cardHeight =
                    cardWidth + 148.0 + accessibilityGrowth;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: products.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    mainAxisExtent: cardHeight,
                  ),
                  itemBuilder: (context, index) {
                    return ProductCard(product: products[index]);
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

class _EmptyCategory extends StatelessWidget {
  const _EmptyCategory({required this.category});

  final String? category;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 36,
              color: NexoraTheme.onSurfaceVariant,
            ),
            const SizedBox(height: 10),
            Text(
              'No products in ${category ?? 'this category'} yet',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: NexoraTheme.fontFamily,
                color: NexoraTheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Choose another category to keep browsing.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: NexoraTheme.fontFamily,
                color: NexoraTheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
