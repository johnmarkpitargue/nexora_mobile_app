import 'package:flutter/material.dart';

class CategoryData {
  final String label;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;

  const CategoryData({
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
  });
}

class CategorySection extends StatelessWidget {
  const CategorySection({super.key});

  static const List<CategoryData> categories = [
    CategoryData(
      label: 'Tech',
      icon: Icons.devices_outlined,
      bgColor: Color(0xFFE0F7FA),
      iconColor: Color(0xFF0891B2),
    ),
    CategoryData(
      label: 'Fashion',
      icon: Icons.checkroom_outlined,
      bgColor: Color(0xFFFFE4E6),
      iconColor: Color(0xFFE11D48),
    ),
    CategoryData(
      label: 'Home',
      icon: Icons.chair_outlined,
      bgColor: Color(0xFFEEF2FF),
      iconColor: Color(0xFF0066FF),
    ),
    CategoryData(
      label: 'Beauty',
      icon: Icons.auto_awesome_outlined,
      bgColor: Color(0xFFE0F2F1),
      iconColor: Color(0xFF0891B2),
    ),
    CategoryData(
      label: 'Sports',
      icon: Icons.sports_basketball_outlined,
      bgColor: Color(0xFFE0E7FF),
      iconColor: Color(0xFF475569),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                  fontSize: 18,
                  color: Color(0xFF0F172A),
                ),
              ),
              InkWell(
                onTap: () {},
                child: const Row(
                  children: [
                    Text(
                      'See All',
                      style: TextStyle(
                        color: Color(0xFF0066FF),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: Color(0xFF0066FF),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 5 Vibrant Category Cards Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: categories.map((cat) {
              return Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: cat.bgColor,
                        borderRadius: BorderRadius.circular(18),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
