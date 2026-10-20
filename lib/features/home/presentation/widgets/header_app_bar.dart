import 'package:flutter/material.dart';
import 'package:nexora_flutter_app/app/routes/app_routes.dart';
import 'package:nexora_flutter_app/core/services/cart_service.dart';
import 'package:nexora_flutter_app/core/services/chat_service.dart';

class HeaderAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HeaderAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF050B28),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 4,
        left: 14,
        right: 14,
        bottom: 8,
      ),
      child: Row(
        children: [
          // White Capsule Search Field Bar
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.search,
                    color: Color(0xFF0066FF),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search products, bra...',
                        hintStyle: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12.5,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.qr_code_scanner,
                    color: Color(0xFF64748B),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.camera_alt_outlined,
                    color: Color(0xFF64748B),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Shopping Cart Icon with dynamic badge
          AnimatedBuilder(
            animation: CartService.instance,
            builder: (context, _) {
              final count = CartService.instance.itemCount;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.cart);
                    },
                    icon: const Icon(
                      Icons.shopping_cart_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  if (count > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF00D2FF),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Color(0xFF050B28),
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 12),

          // Chat Icon with dynamic unread badge
          AnimatedBuilder(
            animation: ChatService.instance,
            builder: (context, _) {
              final unread = ChatService.instance.totalUnreadCount;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.chat);
                    },
                    icon: const Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.white,
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  if (unread > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE11D48),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
