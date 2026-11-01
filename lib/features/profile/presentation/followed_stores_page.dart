import 'package:flutter/material.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/models/shop_models.dart';
import '../../../../core/services/shop_service.dart';

class FollowedStoresPage extends StatefulWidget {
  const FollowedStoresPage({super.key});

  @override
  State<FollowedStoresPage> createState() => _FollowedStoresPageState();
}

class _FollowedStoresPageState extends State<FollowedStoresPage> {
  final TextEditingController _searchController = TextEditingController();
  String _filterText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final shopService = ShopService.instance;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101216) : const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'Following',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0.5,
        backgroundColor: isDark ? const Color(0xFF181B20) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1E2024),
      ),
      body: ListenableBuilder(
        listenable: shopService,
        builder: (context, _) {
          final followedIds = shopService.followedShopIds;
          final allShops = shopService.allShops;
          final followedShops = allShops
              .where((s) => followedIds.contains(s.id))
              .where((s) => _filterText.isEmpty || s.name.toLowerCase().contains(_filterText.toLowerCase()))
              .toList();
          final suggestedShops = allShops
              .where((s) => !followedIds.contains(s.id))
              .toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Search Header if user follows shops
              if (followedIds.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF22262E) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _filterText = val),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search followed stores...',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                          suffixIcon: _filterText.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _filterText = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                ),

              // Followed stores count banner
              if (followedIds.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Followed Stores (${followedShops.length})',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white70 : Colors.black54,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          '${shopService.followedShopCount} Total',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Empty State if no shops are followed
              if (followedIds.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF0066FF).withValues(alpha: 0.08),
                          ),
                          child: const Icon(
                            Icons.storefront_rounded,
                            size: 40,
                            color: Color(0xFF0066FF),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Followed Stores Yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF1E2024),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Follow your favorite official brands to get updates on flash sales, new product drops, and exclusive vouchers.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // List of Followed Stores
              if (followedShops.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final shop = followedShops[index];
                        return _buildShopCard(context, shop, isDark, isFollowed: true);
                      },
                      childCount: followedShops.length,
                    ),
                  ),
                ),

              // Section: Suggested Official Stores to Follow
              if (suggestedShops.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          size: 18,
                          color: Color(0xFF0066FF),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          followedIds.isEmpty ? 'Recommended Official Stores' : 'Discover More Stores',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF1E2024),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final shop = suggestedShops[index];
                        return _buildShopCard(context, shop, isDark, isFollowed: false);
                      },
                      childCount: suggestedShops.length,
                    ),
                  ),
                ),
              ],

              const SliverToBoxAdapter(
                child: SizedBox(height: 40),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildShopCard(BuildContext context, ShopModel shop, bool isDark, {required bool isFollowed}) {
    final shopService = ShopService.instance;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E222A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.shop, arguments: shop.id);
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Store Avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: shop.avatarBg,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: shop.avatarBg.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      shop.initials,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Store Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0066FF).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              shop.badge,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0066FF),
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: Color(0xFFFFB300),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            shop.rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        shop.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1E2024),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${shop.followers} Followers • ${shop.categoryGroupTitle}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Action Buttons
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Follow / Unfollow Button
                    SizedBox(
                      height: 32,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          backgroundColor: isFollowed
                              ? (isDark ? Colors.white10 : const Color(0xFFF1F3F5))
                              : const Color(0xFF0066FF),
                          foregroundColor: isFollowed
                              ? (isDark ? Colors.white70 : const Color(0xFF495057))
                              : Colors.white,
                          side: BorderSide(
                            color: isFollowed
                                ? (isDark ? Colors.white24 : Colors.black12)
                                : const Color(0xFF0066FF),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          shopService.toggleFollow(shop.id);
                        },
                        child: Text(
                          isFollowed ? 'Following' : '+ Follow',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isFollowed
                                ? (isDark ? Colors.white70 : const Color(0xFF495057))
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Visit Store link
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.shop, arguments: shop.id);
                      },
                      child: const Text(
                        'View Store',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0066FF),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
