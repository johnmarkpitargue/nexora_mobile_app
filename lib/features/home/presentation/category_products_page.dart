import 'package:flutter/material.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/nexora_theme.dart';
import '../../../core/services/cart_service.dart';
import '../../../core/services/shop_service.dart';
import 'widgets/product_card.dart';

class CategoryProductsPage extends StatefulWidget {
  const CategoryProductsPage({
    super.key,
    required this.category,
    this.categoryTitle,
  });

  final String category;
  final String? categoryTitle;

  @override
  State<CategoryProductsPage> createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  String _selectedSort = 'relevance';
  String _searchQuery = '';
  bool _isSearchOpen = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    ShopService.instance.addListener(_onServiceUpdate);
    ShopService.instance
        .loadCatalogRemote(
          category: widget.category == 'All' ? null : widget.category,
        )
        .catchError((_) => <ProductModel>[]);
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    ShopService.instance.removeListener(_onServiceUpdate);
    _searchController.dispose();
    super.dispose();
  }

  String get _displayTitle {
    if (widget.categoryTitle != null && widget.categoryTitle!.isNotEmpty) {
      return widget.categoryTitle!;
    }
    return widget.category;
  }

  List<ProductModel> get _filteredProducts {
    final all = ShopService.instance.products.where((p) => p.isActive).toList();
    final catLower = widget.category.toLowerCase().trim();

    List<ProductModel> matching;
    if (catLower == 'all' || catLower.isEmpty) {
      matching = all;
    } else {
      matching = all.where((p) {
        final pCat = p.category.toLowerCase();
        final pTitle = p.title.toLowerCase();
        final pDesc = p.description?.toLowerCase() ?? '';

        if (pCat == catLower) {
          return true;
        }

        // Tech & Gadgets (includes Audio, Gaming, Tech accessories)
        final isTechTarget = catLower.contains('tech') ||
            catLower.contains('gadget') ||
            catLower.contains('electronic');
        if (isTechTarget) {
          if (pCat.contains('tech') ||
              pCat.contains('gadget') ||
              pCat.contains('audio') ||
              pCat.contains('gaming') ||
              pCat.contains('accessories') ||
              pTitle.contains('keyboard') ||
              pTitle.contains('mouse') ||
              pTitle.contains('mic') ||
              pTitle.contains('headphone')) {
            return true;
          }
        }

        // Apparel & Fashion
        final isFashionTarget = catLower.contains('fashion') ||
            catLower.contains('apparel') ||
            catLower.contains('clothing') ||
            catLower.contains('style') ||
            catLower.contains('wear');
        if (isFashionTarget) {
          if (pCat.contains('fashion') ||
              pCat.contains('apparel') ||
              pTitle.contains('tee') ||
              pTitle.contains('hoodie') ||
              pTitle.contains('shirt')) {
            return true;
          }
        }

        // Home & Living
        final isHomeTarget = catLower.contains('home') ||
            catLower.contains('living') ||
            catLower.contains('decor');
        if (isHomeTarget) {
          if (pCat.contains('home') ||
              pCat.contains('living') ||
              pTitle.contains('rattan') ||
              pTitle.contains('thermos') ||
              pTitle.contains('plant')) {
            return true;
          }
        }

        // Gaming Gear
        final isGamingTarget = catLower.contains('gaming') ||
            catLower.contains('game') ||
            catLower.contains('esport');
        if (isGamingTarget) {
          if (pCat.contains('gaming') ||
              pTitle.contains('keyboard') ||
              pTitle.contains('mouse')) {
            return true;
          }
        }

        // Audio & Sound
        final isAudioTarget = catLower.contains('audio') ||
            catLower.contains('sound') ||
            catLower.contains('music');
        if (isAudioTarget) {
          if (pCat.contains('audio') ||
              pTitle.contains('headphone') ||
              pTitle.contains('mic') ||
              pTitle.contains('boom arm')) {
            return true;
          }
        }

        // Jewelry & Watches
        final isJewelryTarget = catLower.contains('jewelry') ||
            catLower.contains('watch') ||
            catLower.contains('pendant') ||
            catLower.contains('gold');
        if (isJewelryTarget) {
          if (pCat.contains('jewelry') ||
              pTitle.contains('necklace') ||
              pTitle.contains('pendant') ||
              pTitle.contains('watch') ||
              pTitle.contains('sakura')) {
            return true;
          }
        }

        // Accessories
        final isAccessoriesTarget = catLower.contains('accessories') ||
            catLower.contains('accessory');
        if (isAccessoriesTarget) {
          if (pCat.contains('accessories') ||
              pTitle.contains('desk mat') ||
              pTitle.contains('watch')) {
            return true;
          }
        }

        // Lifestyle
        final isLifestyleTarget = catLower.contains('lifestyle');
        if (isLifestyleTarget) {
          if (pCat.contains('lifestyle') ||
              pCat.contains('home') ||
              pCat.contains('living')) {
            return true;
          }
        }

        // Direct containment checks
        if (pCat.contains(catLower) || catLower.contains(pCat)) {
          return true;
        }

        // Keyword word-level overlap
        final searchWords = catLower
            .split(RegExp(r'[^a-z0-9]+'))
            .where((w) => w.length > 2 && w != 'and');
        for (final word in searchWords) {
          if (pCat.contains(word) || pTitle.contains(word) || pDesc.contains(word)) {
            return true;
          }
        }

        return false;
      }).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      matching = matching.where((p) {
        return p.title.toLowerCase().contains(q) ||
            (p.description?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    // Sort
    switch (_selectedSort) {
      case 'rating':
        matching.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'price_asc':
        matching.sort((a, b) => _parsePrice(a.price).compareTo(_parsePrice(b.price)));
        break;
      case 'price_desc':
        matching.sort((a, b) => _parsePrice(b.price).compareTo(_parsePrice(a.price)));
        break;
      case 'best_selling':
        matching.sort((a, b) => _parseSold(b.soldCount).compareTo(_parseSold(a.soldCount)));
        break;
      default:
        break;
    }

    return matching;
  }

  double _parsePrice(String priceStr) {
    final clean = priceStr.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(clean) ?? 0.0;
  }

  int _parseSold(String soldStr) {
    final clean = soldStr.replaceAll(RegExp(r'[^0-9kK.+]'), '').toLowerCase();
    if (clean.contains('k')) {
      final numPart = double.tryParse(clean.replaceAll('k', '').replaceAll('+', '')) ?? 1.0;
      return (numPart * 1000).toInt();
    }
    return int.tryParse(clean.replaceAll('+', '')) ?? 0;
  }

  IconData get _categoryIcon {
    final cat = widget.category.toLowerCase();
    if (cat.contains('tech') || cat.contains('gadget')) return Icons.devices_outlined;
    if (cat.contains('fashion') || cat.contains('apparel')) return Icons.checkroom_outlined;
    if (cat.contains('home') || cat.contains('living')) return Icons.chair_outlined;
    if (cat.contains('gaming')) return Icons.sports_esports_outlined;
    if (cat.contains('audio')) return Icons.headphones_outlined;
    if (cat.contains('jewelry')) return Icons.diamond_outlined;
    if (cat.contains('accessories')) return Icons.watch_outlined;
    return Icons.category_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final products = _filteredProducts;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: _isSearchOpen
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Search in $_displayTitle...',
                  isDense: true,
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '${products.length} product${products.length == 1 ? '' : 's'} available',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
        actions: [
          IconButton(
            tooltip: _isSearchOpen ? 'Close search' : 'Search in category',
            icon: Icon(_isSearchOpen ? Icons.close_rounded : Icons.search_rounded),
            onPressed: () {
              setState(() {
                _isSearchOpen = !_isSearchOpen;
                if (!_isSearchOpen) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
          ListenableBuilder(
            listenable: CartService.instance,
            builder: (context, _) {
              final count = CartService.instance.itemCount;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    tooltip: 'Shopping Cart',
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF38BDF8) : NexoraTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$count',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: isDark ? NexoraTheme.darkNavy : Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header Banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.2)
                          : const Color(0xFF0F172A).withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_categoryIcon, color: theme.colorScheme.primary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _displayTitle,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'All items curated for ${_displayTitle.toLowerCase()}',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Quick Filter Strip
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _buildSortChip('relevance', 'All Items'),
                  const SizedBox(width: 8),
                  _buildSortChip('best_selling', 'Best Selling'),
                  const SizedBox(width: 8),
                  _buildSortChip('rating', 'Top Rated (4.8+)'),
                  const SizedBox(width: 8),
                  _buildSortChip('price_asc', 'Price: Low to High'),
                  const SizedBox(width: 8),
                  _buildSortChip('price_desc', 'Price: High to Low'),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // Product Grid or Empty State
          if (products.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 56,
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No products found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'No products matched "$_searchQuery" in this category.'
                            : 'Check back soon for new arrivals in this collection.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverLayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = switch (constraints.crossAxisExtent) {
                  >= 1080 => 5,
                  >= 820 => 4,
                  >= 560 => 3,
                  _ => 2,
                };
                const spacing = 12.0;
                final cardWidth =
                    (constraints.crossAxisExtent - 32 - spacing * (crossAxisCount - 1)) /
                    crossAxisCount;
                final textScale = MediaQuery.textScalerOf(context).scale(1);
                final accessibilityGrowth =
                    ((textScale - 1).clamp(0.0, 1.0) * 116);
                final cardHeight = cardWidth + 168.0 + accessibilityGrowth;

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: 14,
                      mainAxisExtent: cardHeight,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return ProductCard(product: products[index]);
                      },
                      childCount: products.length,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String sortKey, String label) {
    final theme = Theme.of(context);
    final isSelected = _selectedSort == sortKey;
    final isDark = theme.brightness == Brightness.dark;

    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        color: isSelected
            ? (isDark ? NexoraTheme.darkNavy : Colors.white)
            : theme.colorScheme.onSurface,
      ),
      selectedColor: isDark ? const Color(0xFF38BDF8) : NexoraTheme.primary,
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      side: BorderSide(
        color: isSelected
            ? Colors.transparent
            : theme.colorScheme.outlineVariant,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (_) => setState(() => _selectedSort = sortKey),
    );
  }
}
