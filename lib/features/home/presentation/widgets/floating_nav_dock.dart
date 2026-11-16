import 'package:flutter/material.dart';
import 'package:nexora_flutter_app/app/theme/nexora_theme.dart';

class FloatingNavDock extends StatelessWidget {
  const FloatingNavDock({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.cartCount = 0,
    this.chatUnreadCount = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final int cartCount;
  final int chatUnreadCount;

  static const List<_NavItemData> _items = [
    _NavItemData(
      icon: Icons.storefront_outlined,
      selectedIcon: Icons.storefront_rounded,
      label: 'Home',
    ),
    _NavItemData(
      icon: Icons.shopping_cart_outlined,
      selectedIcon: Icons.shopping_cart_rounded,
      label: 'Cart',
    ),
    _NavItemData(
      icon: Icons.local_shipping_outlined,
      selectedIcon: Icons.local_shipping_rounded,
      label: 'Orders',
    ),
    _NavItemData(
      icon: Icons.chat_bubble_outline_rounded,
      selectedIcon: Icons.chat_bubble_rounded,
      label: 'Messages',
    ),
    _NavItemData(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final motionDuration = NexoraMotion.resolve(context);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1.0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
              boxShadow: [
                BoxShadow(
                  color: theme.brightness == Brightness.dark
                      ? Colors.black.withValues(alpha: 0.5)
                      : NexoraTheme.darkNavy.withValues(alpha: 0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(26),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                height: 70,
                child: Row(
                  children: List.generate(_items.length, (index) {
                    final item = _items[index];
                    final isSelected = currentIndex == index;
                    final badgeCount = switch (index) {
                      1 => cartCount,
                      3 => chatUnreadCount,
                      _ => 0,
                    };

                    return Expanded(
                      child: _DockItem(
                        key: ValueKey('nav-item-$index'),
                        item: item,
                        isSelected: isSelected,
                        badgeCount: badgeCount,
                        badgeKey: switch (index) {
                          1 => const ValueKey('cart-nav-badge'),
                          3 => const ValueKey('messages-nav-badge'),
                          _ => null,
                        },
                        badgeColor: index == 3
                            ? theme.colorScheme.tertiary
                            : theme.colorScheme.secondary,
                        badgeForegroundColor: index == 3
                            ? Colors.white
                            : NexoraTheme.darkNavy,
                        motionDuration: motionDuration,
                        onTap: () => onTap(index),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    super.key,
    required this.item,
    required this.isSelected,
    required this.badgeCount,
    required this.badgeColor,
    required this.badgeForegroundColor,
    required this.motionDuration,
    required this.onTap,
    this.badgeKey,
  });

  final _NavItemData item;
  final bool isSelected;
  final int badgeCount;
  final Color badgeColor;
  final Color badgeForegroundColor;
  final Duration motionDuration;
  final VoidCallback onTap;
  final Key? badgeKey;

  String get _semanticLabel {
    if (badgeCount <= 0) return item.label;
    final noun = item.label == 'Cart'
        ? badgeCount == 1
              ? 'item'
              : 'items'
        : badgeCount == 1
        ? 'unread message'
        : 'unread messages';
    return '${item.label}, $badgeCount $noun';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: isSelected,
      label: _semanticLabel,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        excludeFromSemantics: true,
        child: ExcludeSemantics(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: motionDuration,
                curve: NexoraMotion.standardCurve,
                width: 40,
                height: 30,
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        isSelected ? item.selectedIcon : item.icon,
                        size: 22,
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      if (badgeCount > 0)
                        Positioned(
                          key: badgeKey,
                          top: -7,
                          right: -11,
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              badgeCount > 99 ? '99+' : '$badgeCount',
                              style: TextStyle(
                                color: badgeForegroundColor,
                                fontSize: 9,
                                height: 1,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: motionDuration,
                curve: NexoraMotion.standardCurve,
                style: TextStyle(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                  height: 1.2,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
