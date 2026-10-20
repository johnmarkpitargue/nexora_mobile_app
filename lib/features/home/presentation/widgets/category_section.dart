import 'package:flutter/material.dart';

class CategoryItemData {
  final String label;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;

  const CategoryItemData({
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
  });
}

class CategorySection extends StatelessWidget {
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;

  const CategorySection({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  static const List<CategoryItemData> categories = [
    CategoryItemData(
      label: 'Tech & Gadgets',
      icon: Icons.devices_outlined,
      bgColor: Color(0xFFE0F7FA),
      iconColor: Color(0xFF0891B2),
    ),
    CategoryItemData(
      label: 'Fashion',
      icon: Icons.checkroom_outlined,
      bgColor: Color(0xFFFFE4E6),
      iconColor: Color(0xFFE11D48),
    ),
    CategoryItemData(
      label: 'Home',
      icon: Icons.chair_outlined,
      bgColor: Color(0xFFEEF2FF),
      iconColor: Color(0xFF0066FF),
    ),
    CategoryItemData(
      label: 'Beauty',
      icon: Icons.auto_awesome_outlined,
      bgColor: Color(0xFFE0F2F1),
      iconColor: Color(0xFF0D9488),
    ),
    CategoryItemData(
      label: 'Sports',
      icon: Icons.sports_basketball_outlined,
      bgColor: Color(0xFFE0E7FF),
      iconColor: Color(0xFF059669),
    ),
    CategoryItemData(
      label: 'Gaming',
      icon: Icons.headphones_outlined,
      bgColor: Color(0xFFE0F2FE),
      iconColor: Color(0xFF0284C7),
    ),
    CategoryItemData(
      label: 'Mall',
      icon: Icons.verified_outlined,
      bgColor: Color(0xFFFFE4E6),
      iconColor: Color(0xFFDC2626),
    ),
    CategoryItemData(
      label: 'Vouchers',
      icon: Icons.confirmation_number_outlined,
      bgColor: Color(0xFFDCFCE7),
      iconColor: Color(0xFF16A34A),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Break 8 items into 2 rows of 4 items each
    final firstRow = categories.sublist(0, 4);
    final secondRow = categories.sublist(4, 8);

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
                  // Toggle back to All when clicking See All
                  onCategorySelected(null);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        selectedCategory == null ? 'See All' : 'Show All',
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

          // Row 1
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: firstRow.map((cat) => _buildCategoryTile(cat)).toList(),
          ),

          const SizedBox(height: 12),

          // Row 2
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: secondRow.map((cat) => _buildCategoryTile(cat)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(CategoryItemData cat) {
    final isSelected = selectedCategory == cat.label;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (isSelected) {
            // Unselect if tapped again
            onCategorySelected(null);
          } else {
            onCategorySelected(cat.label);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: cat.bgColor,
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: cat.iconColor, width: 2.5)
                    : Border.all(color: Colors.transparent, width: 1),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: cat.iconColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                cat.icon,
                size: 24,
                color: cat.iconColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              cat.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 11,
                color: isSelected ? cat.iconColor : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
