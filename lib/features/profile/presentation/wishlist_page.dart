import 'package:flutter/material.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/services/cart_service.dart';
import '../../../core/services/wishlist_service.dart';
import '../../../core/widgets/added_to_cart_hud.dart';
import '../../home/presentation/widgets/product_card.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    WishlistService.instance.refreshWishlistRemote();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: WishlistService.instance,
      builder: (context, _) {
        final allItems = WishlistService.instance.items;
        final filteredItems = _selectedCategory == 'All'
            ? allItems
            : allItems.where((p) => p.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();

        final categories = ['All', ...{...allItems.map((p) => p.category)}];

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Wishlist',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${allItems.length} ${allItems.length == 1 ? "item" : "items"} saved',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF0F172A), size: 22),
                onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: allItems.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // Category Filter Pills
                    if (categories.length > 2)
                      Container(
                        height: 48,
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: categories.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final cat = categories[index];
                            final isSelected = cat == _selectedCategory;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedCategory = cat;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF0066FF) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  cat,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : const Color(0xFF475569),
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    const Divider(height: 1, color: Color(0xFFE2E8F0)),

                    // Product List / Grid
                    Expanded(
                      child: filteredItems.isEmpty
                          ? Center(
                              child: Text(
                                'No items found in "$_selectedCategory"',
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () => WishlistService.instance.refreshWishlistRemote(),
                              child: ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                padding: const EdgeInsets.all(16),
                                itemCount: filteredItems.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 14),
                                itemBuilder: (context, index) {
                                  final product = filteredItems[index];
                                  return _buildWishlistItemCard(context, product);
                                },
                              ),
                            ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFFFFECEF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 44,
                color: Color(0xFFE11D48),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your Wishlist is Empty',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Explore products and tap the heart icon on items you love to save them here for later!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066FF),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              ),
              child: const Text('Discover Products', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistItemCard(BuildContext context, ProductModel product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.productDetails, arguments: product);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      Image.network(
                        product.imageUrl,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 90,
                          height: 90,
                          color: const Color(0xFFF1F5F9),
                          child: const Icon(Icons.image_not_supported, color: Color(0xFF94A3B8)),
                        ),
                      ),
                      if (product.isMall)
                        Positioned(
                          top: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0066FF),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'MALL',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Details & Actions
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
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                                height: 1.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              WishlistService.instance.removeFromWishlist(product.title);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Removed from Wishlist'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(2),
                              child: Icon(
                                Icons.favorite,
                                color: Color(0xFFE11D48),
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Category & Rating
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              product.category,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 2),
                          Text(
                            product.rating.toString(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '• ${product.soldCount} sold',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Price & Add to Cart button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.price,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              if (product.originalPrice != null)
                                Text(
                                  product.originalPrice!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    decoration: TextDecoration.lineThrough,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              final cleanPrice = double.tryParse(
                                product.price.replaceAll(RegExp(r'[^0-9.]'), ''),
                              ) ?? 1500.0;
                              final cleanOriginalPrice = product.originalPrice != null
                                  ? double.tryParse(
                                      product.originalPrice!.replaceAll(RegExp(r'[^0-9.]'), ''),
                                    )
                                  : null;

                              CartService.instance.addItem(
                                title: product.title,
                                variant: 'Standard Edition',
                                price: cleanPrice,
                                originalPrice: cleanOriginalPrice,
                                imageUrl: product.imageUrl,
                                storeName: product.isMall ? 'Nexora Official Flagship' : 'Nexora Store',
                                storeBadge: product.isMall ? 'MALL' : '',
                              );

                              AddedToCartHUD.show(context);
                            },
                            icon: const Icon(Icons.shopping_bag_outlined, size: 14),
                            label: const Text('Add to Cart', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
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
      ),
    );
  }
}
