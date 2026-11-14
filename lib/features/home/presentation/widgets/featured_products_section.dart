import 'package:flutter/material.dart';

import '../../../../app/theme/nexora_theme.dart';
import '../../../../core/services/shop_service.dart';
import 'product_card.dart';

class DailyDiscoverSection extends StatefulWidget {
  const DailyDiscoverSection({
    super.key,
    this.selectedCategory,
    this.onLoadMore,
  });

  final String? selectedCategory;
  final VoidCallback? onLoadMore;

  static List<ProductModel> get allProducts => ShopService.instance.products;

  @override
  State<DailyDiscoverSection> createState() => _DailyDiscoverSectionState();
}

class _DailyDiscoverSectionState extends State<DailyDiscoverSection> {
  @override
  void initState() {
    super.initState();
    ShopService.instance.addListener(_onServiceUpdate);
    _loadCatalog();
  }

  @override
  void didUpdateWidget(covariant DailyDiscoverSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCategory != oldWidget.selectedCategory) {
      _loadCatalog();
    }
  }

  @override
  void dispose() {
    ShopService.instance.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  void _loadCatalog() {
    if (ShopService.instance.isLoadingCatalog) return;
    ShopService.instance
        .loadCatalogRemote(category: widget.selectedCategory)
        .catchError((_) => <ProductModel>[]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final products = ShopService.instance.products;
    final isLoading = ShopService.instance.isLoadingCatalog;
    final error = ShopService.instance.catalogError;
    final selectedCategory = widget.selectedCategory;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
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
                      isLoading && products.isEmpty
                          ? 'Loading products...'
                          : '${products.length} ${products.length == 1 ? 'product' : 'products'}',
                      style: TextStyle(
                        fontFamily: NexoraTheme.fontFamily,
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (selectedCategory != null)
                TextButton(
                  onPressed: () {
                    ShopService.instance
                        .loadCatalogRemote(category: null)
                        .catchError((_) => <ProductModel>[]);
                  },
                  child: Text(
                    'Clear filter',
                    style: TextStyle(
                      fontFamily: NexoraTheme.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF38BDF8) : NexoraTheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (isLoading && products.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: isDark ? const Color(0xFF38BDF8) : NexoraTheme.primary,
                  ),
                ),
              ),
            )
          else if (products.isEmpty)
            _EmptyCategory(
              category: selectedCategory,
              errorMessage: error,
              onRetry: _loadCatalog,
            )
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
                final cardHeight = cardWidth + 168.0 + accessibilityGrowth;

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
  const _EmptyCategory({
    required this.category,
    this.errorMessage,
    this.onRetry,
  });

  final String? category;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              category == null
                  ? 'No products available right now'
                  : 'No products in $category',
              style: TextStyle(
                fontFamily: NexoraTheme.fontFamily,
                color: theme.colorScheme.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              errorMessage ?? 'Check back soon for new arrivals.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: NexoraTheme.fontFamily,
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 12.5,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Try again'),
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      isDark ? const Color(0xFF38BDF8) : NexoraTheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
