import 'package:flutter/material.dart';
import '../../../../core/services/shop_service.dart';

class CategorySection extends StatefulWidget {
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;

  const CategorySection({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  State<CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<CategorySection> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await ShopService.instance.fetchCategoriesRemote();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load categories';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  static IconData _getIconForCategory(String slug, String name) {
    final s = '${slug.toLowerCase()} ${name.toLowerCase()}';
    if (s.contains('tech') || s.contains('electron') || s.contains('device')) {
      return Icons.devices_outlined;
    }
    if (s.contains('fashion') || s.contains('cloth') || s.contains('apparel')) {
      return Icons.checkroom_outlined;
    }
    if (s.contains('home') || s.contains('living') || s.contains('chair')) {
      return Icons.chair_outlined;
    }
    if (s.contains('beauty') || s.contains('cosmetic')) {
      return Icons.auto_awesome_outlined;
    }
    if (s.contains('sport') || s.contains('fitness')) {
      return Icons.sports_basketball_outlined;
    }
    if (s.contains('gaming') || s.contains('game')) {
      return Icons.headphones_outlined;
    }
    if (s.contains('book') || s.contains('stationery')) {
      return Icons.menu_book_outlined;
    }
    if (s.contains('pet')) {
      return Icons.pets_outlined;
    }
    if (s.contains('auto') || s.contains('motor')) {
      return Icons.directions_car_outlined;
    }
    if (s.contains('grocer') || s.contains('food')) {
      return Icons.local_grocery_store_outlined;
    }
    if (s.contains('health')) {
      return Icons.health_and_safety_outlined;
    }
    if (s.contains('access') || s.contains('jewel')) {
      return Icons.watch_outlined;
    }
    if (s.contains('kid') || s.contains('baby')) {
      return Icons.child_care_outlined;
    }
    return Icons.category_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final categories = ShopService.instance.categories;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Categories',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Color(0xFF0F172A),
                ),
              ),
              InkWell(
                onTap: () {
                  widget.onCategorySelected(null);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        widget.selectedCategory == null ? 'See All' : 'Show All',
                        style: const TextStyle(
                          color: Color(0xFF0284C7),
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: Color(0xFF0284C7),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (_isLoading && categories.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            )
          else if (_errorMessage != null && categories.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 12, color: Colors.redAccent),
                    ),
                    const SizedBox(height: 6),
                    TextButton.icon(
                      onPressed: _loadCategories,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Retry', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = widget.selectedCategory == cat.slug ||
                      widget.selectedCategory == cat.id.toString();
                  final iconData = _getIconForCategory(cat.slug, cat.name);

                  return GestureDetector(
                    onTap: () {
                      if (isSelected) {
                        widget.onCategorySelected(null);
                      } else {
                        widget.onCategorySelected(cat.slug);
                      }
                    },
                    child: SizedBox(
                      width: 68,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF0066FF) : const Color(0xFFEFF6FF),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? const Color(0xFF0066FF) : const Color(0xFFDBEAFE),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF0066FF).withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Icon(
                              iconData,
                              size: 22,
                              color: isSelected ? Colors.white : const Color(0xFF0066FF),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            cat.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 11,
                              color: isSelected ? const Color(0xFF0066FF) : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
