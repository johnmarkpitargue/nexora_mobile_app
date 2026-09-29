import 'package:flutter/material.dart';

class SearchAndTrendSection extends StatelessWidget {
  const SearchAndTrendSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 4),
      child: SizedBox(
        height: 38,
        child: ListView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          children: [
            // Summer Drop Gradient Pill
            _TrendChip(
              label: '🔥 Summer Drop',
              isGradient: true,
              onTap: () {},
            ),
            const SizedBox(width: 8),
            _TrendChip(
              label: 'Audio',
              icon: Icons.headphones_outlined,
              iconColor: const Color(0xFF0891B2),
              isGradient: false,
              onTap: () {},
            ),
            const SizedBox(width: 8),
            _TrendChip(
              label: 'Minimalist',
              isGradient: false,
              onTap: () {},
            ),
            const SizedBox(width: 8),
            _TrendChip(
              label: 'Urban',
              isGradient: false,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? iconColor;
  final bool isGradient;
  final VoidCallback onTap;

  const _TrendChip({
    required this.label,
    this.icon,
    this.iconColor,
    required this.isGradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: isGradient
              ? const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF0066FF)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: isGradient ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isGradient
              ? null
              : Border.all(color: const Color(0xFFE2E8F0), width: 1),
          boxShadow: [
            BoxShadow(
              color: isGradient
                  ? const Color(0xFF0066FF).withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: iconColor ?? const Color(0xFF475569),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isGradient ? Colors.white : const Color(0xFF334155),
                fontWeight: isGradient ? FontWeight.w800 : FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
