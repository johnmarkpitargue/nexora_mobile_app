import 'package:flutter/material.dart';
import 'package:nexora_flutter_app/app/theme/nexora_theme.dart';

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
      label: 'Tech & Gadgets',
      value: 'Tech & Gadgets',
      icon: Icons.devices_rounded,
      description: 'Smart tools for work, play & daily flow.',
      imageUrl:
          'https://images.unsplash.com/photo-1498049794561-7780e7231661?auto=format&fit=crop&w=400&q=80',
    ),
    CategoryItemData(
      label: 'Fashion & Style',
      value: 'Apparel & Fashion',
      icon: Icons.checkroom_rounded,
      description: 'Everyday pieces made for your rhythm.',
      imageUrl:
          'https://images.unsplash.com/photo-1483985988355-763728e1935b?auto=format&fit=crop&w=400&q=80',
    ),
    CategoryItemData(
      label: 'Home & Living',
      value: 'Home & Living',
      icon: Icons.chair_rounded,
      description: 'Finds for a calmer, personal space.',
      imageUrl:
          'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?auto=format&fit=crop&w=400&q=80',
    ),
    CategoryItemData(
      label: 'Gaming Gear',
      value: 'Gaming',
      icon: Icons.sports_esports_rounded,
      description: 'Responsive gear built for next level.',
      imageUrl:
          'https://images.unsplash.com/photo-1542751371-adc38448a05e?auto=format&fit=crop&w=400&q=80',
    ),
    CategoryItemData(
      label: 'Audio & Sound',
      value: 'Audio',
      icon: Icons.headphones_rounded,
      description: 'Headphones tuned for daily listening.',
      imageUrl:
          'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=400&q=80',
    ),
    CategoryItemData(
      label: 'Accessories',
      value: 'Accessories',
      icon: Icons.watch_rounded,
      description: 'Finishing touches with clear purpose.',
      imageUrl:
          'https://images.unsplash.com/photo-1523779917675-b6ed3a42a561?auto=format&fit=crop&w=400&q=80',
    ),
    CategoryItemData(
      label: 'Jewelry & Watches',
      value: 'Jewelry',
      icon: Icons.diamond_rounded,
      description: 'Considered accents for every day.',
      imageUrl:
          'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?auto=format&fit=crop&w=400&q=80',
    ),
    CategoryItemData(
      label: 'Lifestyle',
      value: 'Lifestyle',
      icon: Icons.local_cafe_rounded,
      description: 'Useful comforts for curated living.',
      imageUrl:
          'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?auto=format&fit=crop&w=400&q=80',
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
                        fontSize: 11.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  key: const ValueKey('browse-all-categories'),
                  onPressed: () => onCategorySelected(null),
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

          // Minimized Horizontal Card Rail (Height 148dp vs previous 366dp)
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
                final isSelected = selectedCategory == cat.value;

                return _MinimizedCategoryCard(
                  key: ValueKey(_keyFor(cat.value)),
                  category: cat,
                  isSelected: isSelected,
                  onTap: () => onCategorySelected(cat.value),
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 168,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    isDark
                        ? Colors.black.withValues(alpha: 0.3)
                        : const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Thumbnail with "Made for you" capsule
              SizedBox(
                height: 88,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      category.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => Container(
                            color:
                                isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFE2E8F0),
                            child: Icon(
                              category.icon,
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 28,
                            ),
                          ),
                    ),
                    Positioned(
                      top: 7,
                      left: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 0.5,
                          ),
                        ),
                        child: const Text(
                          'Made for you',
                          style: TextStyle(
                            fontFamily: NexoraTheme.fontFamily,
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Title, Arrow & Subtitle info block
              Expanded(
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
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_outward_rounded,
                            size: 13,
                            color:
                                isSelected
                                    ? (isDark
                                        ? const Color(0xFF38BDF8)
                                        : NexoraTheme.primary)
                                    : (isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B)),
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
                          fontSize: 10,
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.2,
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
    );
  }
}
