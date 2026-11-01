import 'package:flutter/material.dart';
import '../../../core/theme/rider_theme.dart';
import '../../../core/models/delivery_order.dart';
import '../../../core/services/rider_service.dart';
import '../../../core/services/delivery_service.dart';
import '../../delivery/presentation/active_delivery_screen.dart';
import 'widgets/online_status_card.dart';
import 'widgets/earnings_summary_card.dart';
import 'widgets/available_order_card.dart';
import '../../delivery/presentation/rider_live_orders_screen.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/services/in_app_notification_service.dart';
import '../../../core/services/external_notification_service.dart';
import '../../../core/services/rider_location_service.dart';
import '../../chat/presentation/rider_chat_screen.dart';
import '../../courier/services/shift_duty_coordinator.dart';

class RiderHomeScreen extends StatefulWidget {
  final Function(int tabIndex) onNavigateTab;

  const RiderHomeScreen({
    super.key,
    required this.onNavigateTab,
  });

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  @override
  void initState() {
    super.initState();
    _subscribeChat();
    // Request system notification permission directly without showing an in-app banner
    ExternalNotificationService.requestPermissionAsync();
    // Initialize accurate rider phone GPS fix immediately
    RiderLocationService.instance.getCurrentLocation();
    // Ensure latest orders from Buyer App are synced
    DeliveryService.instance.refreshAvailableOrders();
  }

  void _subscribeChat() {
    final activeOrder = DeliveryService.instance.activeOrder;
    final orderId = activeOrder?.id ??
        (DeliveryService.instance.availableOrders.isNotEmpty
            ? DeliveryService.instance.availableOrders.first.id
            : 'NX-8942-ORD');
    RiderChatService.instance.subscribeToOrder(orderId);
    RiderChatService.instance.onNewMessageReceived = _handleNewMessage;
  }

  void _handleNewMessage(RiderChatMessage msg) {
    if (!mounted) return;
    InAppNotificationService.instance.showNotification(
      senderName: msg.senderName.isNotEmpty ? msg.senderName : 'Customer',
      message: msg.text,
      orderId: msg.orderId,
      icon: Icons.person_pin_circle_rounded,
      accentColor: const Color(0xFF0066FF),
      onReply: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RiderChatScreen(
              orderId: msg.orderId,
              customerName: msg.senderName,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    if (RiderChatService.instance.onNewMessageReceived == _handleNewMessage) {
      RiderChatService.instance.onNewMessageReceived = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RiderTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/logo.png',
                width: 30,
                height: 30,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: RiderTheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text('N',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w900)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Nexora',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: RiderTheme.textDark,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'RIDER',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        color: RiderTheme.primary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Central Logistics Hub #4',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: RiderTheme.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          AnimatedBuilder(
            animation: RiderChatService.instance,
            builder: (context, _) {
              final activeOrder = DeliveryService.instance.activeOrder;
              final orderId = activeOrder?.id ?? 'NX-8942-ORD';
              final unread = RiderChatService.instance.getUnreadCount(orderId);
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF0066FF)),
                    tooltip: 'In-App Messages',
                    onPressed: () {
                      final targetOrder = activeOrder ??
                          (DeliveryService.instance.availableOrders.isNotEmpty
                              ? DeliveryService.instance.availableOrders.first
                              : null);
                      final name = targetOrder?.customerName ?? 'Alex Rivera';
                      final id = targetOrder?.id ?? 'NX-8942-ORD';
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RiderChatScreen(
                            orderId: id,
                            customerName: name,
                          ),
                        ),
                      );
                    },
                  ),
                  if (unread > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            '$unread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // Nexora Notification Bell & Center
          ValueListenableBuilder<int>(
            valueListenable: InAppNotificationService.instance.unreadCountNotifier,
            builder: (context, unread, _) {
              return Tooltip(
                message: 'Dispatch & Order Alerts',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () {
                      InAppNotificationService.instance.showNotificationHistory(context);
                    },
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(
                            Icons.notifications_none_rounded,
                            color: Color(0xFF0F172A),
                            size: 24,
                          ),
                          if (unread > 0)
                            Positioned(
                              top: 5,
                              right: 5,
                              child: IgnorePointer(
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF0066FF),
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                  child: Text(
                                    '$unread',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.radar_rounded, color: Color(0xFF0066FF)),
            tooltip: 'Live Incoming Orders',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RiderLiveOrdersScreen()),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          RiderService.instance,
          DeliveryService.instance,
        ]),
        builder: (context, _) {
          final isOnline = RiderService.instance.profile.isOnline;
          final activeOrder = DeliveryService.instance.activeOrder;
          final availableOrders = DeliveryService.instance.availableOrders;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Shift Toggle Card
                const OnlineStatusCard(),
                const SizedBox(height: 14),

                // 2. Active Trip Floating Banner (if ongoing delivery)
                if (activeOrder != null) ...[
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) =>
                              ActiveDeliveryScreen(order: activeOrder),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0052CC), RiderTheme.primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: RiderTheme.primary.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.directions_bike_rounded,
                                        size: 13, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text(
                                      'TRIP IN PROGRESS',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                DeliveryService.instance.activeOrderStage == 1
                                    ? 'At Store / Picking Up'
                                    : DeliveryService.instance.activeOrderStage == 2
                                        ? 'Pickup Verified'
                                        : DeliveryService.instance.activeOrderStage == 3
                                            ? 'In Transit to Customer'
                                            : activeOrder.status.label,
                                style: const TextStyle(
                                  color: RiderTheme.secondary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            activeOrder.customerName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            activeOrder.customerAddress,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Payout: ₱${activeOrder.riderEarnings.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                              Row(
                                children: [
                                  const Text(
                                    'Open Trip Dashboard',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_rounded,
                                      size: 16, color: Colors.white.withValues(alpha: 0.9)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // 3. Earnings Summary Card
                EarningsSummaryCard(
                  onSeeWallet: () => widget.onNavigateTab(2), // Switch to wallet tab
                ),
                const SizedBox(height: 14),

                // 4. Spacing before available requests
                const SizedBox(height: 6),

                // 5. Available Orders Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Available Dispatch Requests',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: RiderTheme.textDark,
                          ),
                        ),
                        if (availableOrders.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: RiderTheme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${availableOrders.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 6. Available Orders List or Offline Notice
                if (!isOnline)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: RiderTheme.cardBorder),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.power_settings_new_rounded,
                            size: 44, color: Colors.grey.shade400),
                        const SizedBox(height: 10),
                        const Text(
                          'You are currently Offline',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: RiderTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Switch your duty toggle to Online to begin receiving delivery dispatches in your assigned hub.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: RiderTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ShiftDutyCoordinator.handleRiderToggleDuty(context);
                          },
                          child: const Text('Go Online Now'),
                        ),
                      ],
                    ),
                  )
                else if (availableOrders.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: RiderTheme.cardBorder),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.two_wheeler_rounded,
                            size: 44, color: RiderTheme.primary),
                        const SizedBox(height: 10),
                        const Text(
                          'Searching for Nearby Orders...',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: RiderTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'You are on priority dispatch. New orders will appear here automatically.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: RiderTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...availableOrders.map((order) {
                    return AvailableOrderCard(
                      key: ValueKey('order_${order.id}'),
                      order: order,
                      onAccept: () {
                        final currentActive = DeliveryService.instance.activeOrder;
                        if (currentActive != null) {
                          InAppNotificationService.instance.showNotification(
                            senderName: 'Active Delivery in Progress',
                            message: 'You already have an active trip for ${currentActive.customerName}. Tap the banner above to continue it.',
                            orderId: currentActive.id,
                            icon: Icons.two_wheeler_rounded,
                            accentColor: const Color(0xFF0066FF),
                          );
                          return;
                        }

                        DeliveryService.instance.acceptOrder(order.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Accepted Order ${order.id}! Heading to store.'),
                            backgroundColor: RiderTheme.onlineGreen,
                          ),
                        );
                        // Open Active Delivery Screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) => ActiveDeliveryScreen(
                              order: order.copyWith(status: DeliveryStatus.accepted),
                            ),
                          ),
                        );
                      },
                      onDecline: () {
                        DeliveryService.instance.declineOrder(order.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Order ${order.id} declined.'),
                          ),
                        );
                      },
                    );
                  }),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
