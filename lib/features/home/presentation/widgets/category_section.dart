import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/nexora_theme.dart';

class CategoryItemData {
  const CategoryItemData({
    required this.label,
    required this.value,
    required this.icon,
    required this.description,
    required this.imageUrl,
  });

  final String label;
  final String value;
  final IconData icon;
  final String description;
  final String imageUrl;
}

class CategorySection extends StatelessWidget {
  const CategorySection({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;

  static const List<CategoryItemData> categories = [
    CategoryItemData(
      label: 'Electronics & Tech',
      value: 'electronics',
      icon: Icons.devices_rounded,
      description: 'Smart devices, audio & daily tech.',
      imageUrl:
          'https://images.unsplash.com/photo-1498049794561-7780e7231661?auto=format&fit=crop&w=600&q=80',
    ),
    CategoryItemData(
      label: 'Fashion & Style',
      value: 'fashion',
      icon: Icons.checkroom_rounded,
      description: 'Everyday apparel made for your rhythm.',
      imageUrl:
          'https://images.unsplash.com/photo-1483985988355-763728e1935b?auto=format&fit=crop&w=600&q=80',
    ),
    CategoryItemData(
      label: 'Home & Living',
      value: 'home-living',
      icon: Icons.chair_rounded,
      description: 'Finds for a calmer, personal space.',
      imageUrl:
          'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?auto=format&fit=crop&w=600&q=80',
    ),
    CategoryItemData(
      label: 'Gaming Gear',
      value: 'gaming',
      icon: Icons.sports_esports_rounded,
      description: 'Responsive gear built for next level.',
      imageUrl:
          'https://images.unsplash.com/photo-1542751371-adc38448a05e?auto=format&fit=crop&w=600&q=80',
    ),
    CategoryItemData(
      label: 'Accessories & Watches',
      value: 'accessories',
      icon: Icons.watch_rounded,
      description: 'Finishing touches with clear purpose.',
      imageUrl:
          'https://images.unsplash.com/photo-1523779917675-b6ed3a42a561?auto=format&fit=crop&w=600&q=80',
    ),
    CategoryItemData(
      label: 'Sports & Active',
      value: 'sports',
      icon: Icons.sports_basketball_rounded,
      description: 'High performance gear for motion.',
      imageUrl:
          'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?auto=format&fit=crop&w=600&q=80',
    ),
    CategoryItemData(
      label: 'Beauty & Self Care',
      value: 'beauty',
      icon: Icons.auto_awesome_rounded,
      description: 'Thoughtful rituals and radiance.',
      imageUrl:
          'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?auto=format&fit=crop&w=600&q=80',
    ),
    CategoryItemData(
      label: 'Automotive & Motor',
      value: 'automotive',
      icon: Icons.directions_car_rounded,
      description: 'Essentials for your ride.',
      imageUrl:
          'https://images.unsplash.com/photo-1511919884226-fd3cad34687c?auto=format&fit=crop&w=600&q=80',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Minimized Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Find your next favorite',
                      style: TextStyle(
                        fontFamily: NexoraTheme.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Curated collections to explore',
                      style: TextStyle(
                        fontFamily: NexoraTheme.fontFamily,
                        fontSize: 11.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  key: const ValueKey('browse-all-categories'),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.categoryProducts,
                      arguments: {'category': 'All', 'title': 'All Categories'},
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: const Size(48, 32),
                    foregroundColor:
                        isDark ? const Color(0xFF38BDF8) : NexoraTheme.primary,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Browse all',
                        style: TextStyle(
                          fontFamily: NexoraTheme.fontFamily,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark
                                  ? const Color(0xFF38BDF8)
                                  : NexoraTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.arrow_outward_rounded,
                        size: 15,
                        color:
                            isDark
                                ? const Color(0xFF38BDF8)
                                : NexoraTheme.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Horizontal Editorial Category Rail
          SizedBox(
            height: 148,
            child: ListView.separated(
              key: const ValueKey('editorial-category-rail'),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              itemCount: categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = selectedCategory?.toLowerCase() == cat.value.toLowerCase() ||
                    selectedCategory?.toLowerCase() == cat.label.toLowerCase();

                return _MinimizedCategoryCard(
                  key: ValueKey(_keyFor(cat.value)),
                  category: cat,
                  isSelected: isSelected,
                  onTap: () {
                    if (isSelected) {
                      onCategorySelected(null);
                    } else {
                      onCategorySelected(cat.value);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _keyFor(String value) {
    final slug = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return 'category-$slug';
  }
}

class _MinimizedCategoryCard extends StatelessWidget {
  const _MinimizedCategoryCard({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final CategoryItemData category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBg =
        isSelected
            ? (isDark
                ? const Color(0xFF0C2454)
                : NexoraTheme.primaryContainer.withValues(alpha: 0.5))
            : (isDark
                ? const Color(0xFF131D38)
                : theme.colorScheme.surfaceContainerLowest);

    final borderColor =
        isSelected
            ? (isDark ? const Color(0xFF38BDF8) : NexoraTheme.primary)
            : theme.colorScheme.outlineVariant;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${category.label} collection. Tap to browse products.',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: NexoraTheme.primary.withValues(alpha: 0.12),
          highlightColor: NexoraTheme.primary.withValues(alpha: 0.06),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 200,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: isSelected ? 1.6 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      isDark
                          ? Colors.black.withValues(alpha: 0.3)
                          : NexoraTheme.darkNavy.withValues(alpha: 0.04),
                  blurRadius: isSelected ? 12 : 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image with "Made for you" Badge
                  Expanded(
                    flex: 5,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          category.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: isDark
                                ? const Color(0xFF1A2645)
                                : const Color(0xFFE2E8F0),
                            child: Icon(
                              category.icon,
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 28,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6.5,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0F1738).withValues(alpha: 0.9)
                                  : NexoraTheme.darkNavy.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: const Text(
                              'Made for you',
                              style: TextStyle(
                                fontFamily: NexoraTheme.fontFamily,
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Text Content
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  category.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: NexoraTheme.fontFamily,
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_outward_rounded,
                                size: 12,
                                color: isDark
                                    ? const Color(0xFF38BDF8)
                                    : NexoraTheme.primary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            category.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: NexoraTheme.fontFamily,
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
