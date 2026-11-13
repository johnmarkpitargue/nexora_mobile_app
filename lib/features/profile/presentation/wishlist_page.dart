import 'package:flutter/material.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/nexora_theme.dart';
import '../../../core/services/cart_service.dart';
import '../../../core/services/wishlist_service.dart';
import '../../../core/widgets/added_to_cart_hud.dart';
import '../../../core/widgets/nexora_widgets.dart';
import '../../home/presentation/widgets/product_card.dart';
import '../../home/presentation/widgets/shopping_components.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: WishlistService.instance,
      builder: (context, _) {
        final items = WishlistService.instance.items;
        final categories = [
          'All',
          ...items.map((item) => item.category).toSet(),
        ];
        if (!categories.contains(_selectedCategory)) {
          _selectedCategory = 'All';
        }
        final filteredItems = _selectedCategory == 'All'
            ? items
            : items
                  .where(
                    (item) =>
                        item.category.toLowerCase() ==
                        _selectedCategory.toLowerCase(),
                  )
                  .toList();

        return Scaffold(
          appBar: NexoraAppBar(
            titleText: items.isNotEmpty
                ? 'Wishlist (${items.length})'
                : 'Wishlist',
            actions: [
              IconButton(
                tooltip: 'Open cart',
                onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
                icon: const Icon(Icons.shopping_bag_outlined),
              ),
            ],
          ),
          body: items.isEmpty
              ? ShoppingEmptyState(
                  icon: Icons.favorite_border_rounded,
                  title: 'Save products for later',
                  message: 'Tap the heart on any product to keep it here and compare it when you’re ready.',
                  actionLabel: 'Discover products',
                  onAction: () =>
                      Navigator.pushReplacementNamed(context, AppRoutes.search),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        NexoraSpacing.md,
                        NexoraSpacing.md,
                        NexoraSpacing.md,
                        NexoraSpacing.sm,
                      ),
                      child: Text(
                        '${items.length} ${items.length == 1 ? 'product' : 'products'} saved',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (categories.length > 2)
                      SizedBox(
                        height: 52,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: NexoraSpacing.md,
                            vertical: NexoraSpacing.xs,
                          ),
                          itemCount: categories.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: NexoraSpacing.xs),
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            return ChoiceChip(
                              label: Text(category),
                              selected: category == _selectedCategory,
                              onSelected: (_) =>
                                  setState(() => _selectedCategory = category),
                            );
                          },
                        ),
                      ),
                    const Divider(),
                    Expanded(
                      child: filteredItems.isEmpty
                          ? ShoppingEmptyState(
                              icon: Icons.category_outlined,
                              title: 'Nothing saved in this category',
                              message: 'Choose another category to see your saved products.',
                              actionLabel: 'Show all',
                              onAction: () =>
                                  setState(() => _selectedCategory = 'All'),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(NexoraSpacing.md),
                              itemCount: filteredItems.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: NexoraSpacing.sm),
                              itemBuilder: (context, index) => Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 720,
                                  ),
                                  child: _WishlistProductTile(
                                    product: filteredItems[index],
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _WishlistProductTile extends StatelessWidget {
  const _WishlistProductTile({required this.product});

  final ProductModel product;

  void _addToCart(BuildContext context) {
    final price =
        double.tryParse(product.price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    final originalPrice = product.originalPrice == null
        ? null
        : double.tryParse(
            product.originalPrice!.replaceAll(RegExp(r'[^0-9.]'), ''),
          );
    CartService.instance.addItem(
      title: product.title,
      variant: 'Standard Edition',
      price: price,
      originalPrice: originalPrice,
      imageUrl: product.imageUrl,
      storeName: product.shopName,
      storeBadge: product.shopBadge,
    );
    AddedToCartHUD.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(NexoraRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.productDetails,
          arguments: product,
        ),
        child: Padding(
          padding: const EdgeInsets.all(NexoraSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(NexoraRadius.small),
                child: SizedBox(
                  width: 104,
                  height: 120,
                  child: ColoredBox(
                    color: theme.colorScheme.surfaceContainer,
                    child: Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: NexoraSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            product.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove ${product.title} from wishlist',
                          onPressed: () {
                            WishlistService.instance.removeFromWishlist(
                              product.title,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Removed from wishlist'),
                              ),
                            );
                          },
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(
                            Icons.favorite_rounded,
                            color: NexoraTheme.tertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: NexoraSpacing.xs),
                    Wrap(
                      spacing: NexoraSpacing.sm,
                      runSpacing: NexoraSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          product.category,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 3),
                            Text('${product.rating}'),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: NexoraSpacing.sm),
                    Wrap(
                      spacing: NexoraSpacing.sm,
                      runSpacing: NexoraSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          product.price,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: NexoraTheme.price,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (product.originalPrice != null)
                          Text(
                            product.originalPrice!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        FilledButton.tonalIcon(
                          onPressed: () => _addToCart(context),
                          icon: const Icon(
                            Icons.shopping_bag_outlined,
                            size: 18,
                          ),
                          label: const Text('Add to cart'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
