import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/nexora_theme.dart';
import '../../../../core/services/shop_service.dart';

class CategorySection extends StatelessWidget {
  const CategorySection({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;

  static IconData _iconForSlug(String slugOrName) {
    final s = slugOrName.toLowerCase();
    if (s.contains('elect') || s.contains('tech') || s.contains('gadget')) {
      return Icons.devices_rounded;
    }
    if (s.contains('fashion') || s.contains('apparel') || s.contains('cloth')) {
      return Icons.checkroom_rounded;
    }
    if (s.contains('home') || s.contains('living')) {
      return Icons.chair_rounded;
    }
    if (s.contains('gam')) {
      return Icons.sports_esports_rounded;
    }
    if (s.contains('watch') || s.contains('access')) {
      return Icons.watch_rounded;
    }
    if (s.contains('sport') || s.contains('active')) {
      return Icons.sports_basketball_rounded;
    }
    if (s.contains('beauty') || s.contains('care')) {
      return Icons.auto_awesome_rounded;
    }
    if (s.contains('auto') || s.contains('motor')) {
      return Icons.directions_car_rounded;
    }
    if (s.contains('food') || s.contains('groc')) {
      return Icons.restaurant_rounded;
    }
    return Icons.category_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final pillHeight = (92 + ((textScale - 1).clamp(0.0, 1.0) * 32)).toDouble();

    return AnimatedBuilder(
      animation: ShopService.instance,
      builder: (context, _) {
        final dbCategories = ShopService.instance.categories;
        if (dbCategories.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Categories',
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
                            'Shop by collection',
                            style: TextStyle(
                              fontFamily: NexoraTheme.fontFamily,
                              fontSize: 11.5,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      key: const ValueKey('browse-all-categories'),
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.categoryProducts,
                          arguments: {
                            'category': 'All',
                            'title': 'All Categories',
                          },
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: const Size(48, 40),
                        foregroundColor: isDark
                            ? const Color(0xFF38BDF8)
                            : NexoraTheme.accent,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Browse all',
                            style: TextStyle(
                              fontFamily: NexoraTheme.fontFamily,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(Icons.arrow_outward_rounded, size: 15),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: pillHeight,
                child: ListView.separated(
                  key: const ValueKey('editorial-category-rail'),
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: dbCategories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final cat = dbCategories[index];
                    final isSelected =
                        selectedCategory?.toLowerCase() ==
                            cat.slug.toLowerCase() ||
                        selectedCategory?.toLowerCase() ==
                            cat.name.toLowerCase() ||
                        selectedCategory == cat.id.toString();

                    return Material(
                      key: ValueKey('category-${cat.slug}'),
                      color: isSelected
                          ? NexoraTheme.primary
                          : theme.colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () =>
                            onCategorySelected(isSelected ? null : cat.slug),
                        child: Container(
                          width: 112,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? NexoraTheme.primary
                                  : theme.colorScheme.outlineVariant,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _iconForSlug('${cat.slug} ${cat.name}'),
                                size: 22,
                                color: isSelected
                                    ? Colors.white
                                    : NexoraTheme.accent,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                cat.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: NexoraTheme.fontFamily,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  height: 1.15,
                                  color: isSelected
                                      ? Colors.white
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
