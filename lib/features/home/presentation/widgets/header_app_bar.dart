import 'package:flutter/material.dart';
import 'package:nexora_flutter_app/app/routes/app_routes.dart';
import 'package:nexora_flutter_app/core/services/notification_feed_service.dart';
import 'package:nexora_flutter_app/core/services/wishlist_service.dart';
import 'package:nexora_flutter_app/core/widgets/fly_to_wishlist_animation.dart';

class HeaderAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HeaderAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    void openSearch() {
      Navigator.pushNamed(context, AppRoutes.search);
    }

    void openWishlist() {
      Navigator.pushNamed(context, AppRoutes.wishlist);
    }

    void openNotifications() {
      Navigator.pushNamed(context, AppRoutes.notifications);
    }

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: theme.scaffoldBackgroundColor,
      toolbarHeight: preferredSize.height,
      titleSpacing: 16,
      title: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: 'Search products and brands',
              onTap: openSearch,
              child: ExcludeSemantics(
                child: Material(
                  color: theme.colorScheme.surfaceContainerLowest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: const ValueKey('home-search-action'),
                    onTap: openSearch,
                    child: SizedBox(
                      height: 44,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              color: theme.colorScheme.primary,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Search products and brands',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            button: true,
            label: 'Wishlist',
            onTap: openWishlist,
            child: ExcludeSemantics(
              child: _HeaderWishlistButton(onTap: openWishlist),
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            button: true,
            label: 'Notifications',
            onTap: openNotifications,
            child: ExcludeSemantics(
              child: AnimatedBuilder(
                animation: NotificationFeedService.instance,
                builder: (context, _) {
                  final unread = NotificationFeedService.instance.unreadCount;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        key: const ValueKey('home-notifications-action'),
                        onPressed: openNotifications,
                        tooltip: 'Notifications ($unread)',
                        style: IconButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurface,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerLowest,
                          minimumSize: const Size(44, 44),
                          maximumSize: const Size(44, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                        ),
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          size: 22,
                        ),
                      ),
                      if (unread > 0)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: IgnorePointer(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1.5,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: theme.scaffoldBackgroundColor,
                                  width: 1.8,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  unread > 99 ? '99+' : '$unread',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderWishlistButton extends StatefulWidget {
  final VoidCallback onTap;
  const _HeaderWishlistButton({required this.onTap});

  @override
  State<_HeaderWishlistButton> createState() => _HeaderWishlistButtonState();
}

class _HeaderWishlistButtonState extends State<_HeaderWishlistButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.32)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.32, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 50,
      ),
    ]).animate(_bounceController);

    WishlistAnimationService.bounceNotifier.addListener(_onBounce);
  }

  void _onBounce() {
    if (mounted) {
      _bounceController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    WishlistAnimationService.bounceNotifier.removeListener(_onBounce);
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([
        WishlistService.instance,
        _bounceController,
      ]),
      builder: (context, _) {
        final count = WishlistService.instance.itemCount;
        return ScaleTransition(
          scale: _scaleAnim,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                key: WishlistAnimationService.targetWishlistKey,
                onPressed: widget.onTap,
                tooltip: 'Wishlist ($count)',
                style: IconButton.styleFrom(
                  foregroundColor: count > 0
                      ? const Color(0xFFEF4444)
                      : theme.colorScheme.onSurface,
                  backgroundColor: theme.colorScheme.surfaceContainerLowest,
                  minimumSize: const Size(44, 44),
                  maximumSize: const Size(44, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: count > 0
                          ? const Color(0xFFEF4444).withValues(alpha: 0.35)
                          : theme.colorScheme.outlineVariant,
                    ),
                  ),
                ),
                icon: Icon(
                  count > 0
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 22,
                ),
              ),
              if (count > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: theme.scaffoldBackgroundColor,
                          width: 1.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFEF4444).withValues(alpha: 0.45),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
