import 'package:flutter/material.dart';
import '../../../core/theme/rider_theme.dart';
import '../../../core/models/delivery_order.dart';
import '../../../core/services/delivery_service.dart';
import 'active_delivery_screen.dart';

class DeliveryHistoryScreen extends StatefulWidget {
  const DeliveryHistoryScreen({super.key});

  @override
  State<DeliveryHistoryScreen> createState() => _DeliveryHistoryScreenState();
}

class _DeliveryHistoryScreenState extends State<DeliveryHistoryScreen> {
  int _selectedTab = 0; // 0: All, 1: Active, 2: Completed

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: DeliveryService.instance,
      builder: (context, _) {
        final activeOrder = DeliveryService.instance.activeOrder;
        final completedOrders = DeliveryService.instance.completedOrders;

        List<DeliveryOrder> displayedOrders = [];
        if (_selectedTab == 0) {
          if (activeOrder != null) displayedOrders.add(activeOrder);
          displayedOrders.addAll(completedOrders);
        } else if (_selectedTab == 1) {
          if (activeOrder != null) displayedOrders.add(activeOrder);
        } else {
          displayedOrders.addAll(completedOrders);
        }

        return Scaffold(
          backgroundColor: RiderTheme.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'My Deliveries',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: RiderTheme.textDark,
              ),
            ),
          ),
          body: Column(
            children: [
              // Segmented Bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _tabButton('All (${(activeOrder != null ? 1 : 0) + completedOrders.length})', 0),
                    const SizedBox(width: 8),
                    _tabButton('Active (${activeOrder != null ? 1 : 0})', 1),
                    const SizedBox(width: 8),
                    _tabButton('Completed (${completedOrders.length})', 2),
                  ],
                ),
              ),
              const Divider(height: 1, color: RiderTheme.cardBorder),

              // Orders List
              Expanded(
                child: displayedOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined,
                                size: 54, color: Colors.grey.shade400),
                            const SizedBox(height: 10),
                            Text(
                              'No ${_selectedTab == 1 ? "active" : "past"} deliveries found',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: displayedOrders.length,
                        itemBuilder: (context, index) {
                          final order = displayedOrders[index];
                          final isActive = order.status != DeliveryStatus.delivered &&
                              order.status != DeliveryStatus.cancelled;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isActive
                                    ? RiderTheme.primary.withValues(alpha: 0.4)
                                    : RiderTheme.cardBorder,
                                width: isActive ? 1.5 : 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      order.id,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: RiderTheme.textDark,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? RiderTheme.primaryContainer
                                            : RiderTheme.onlineGreenLight,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        order.status.label,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: isActive
                                              ? RiderTheme.primary
                                              : const Color(0xFF10B981),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Merchant: ${order.merchantName}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: RiderTheme.textDark,
                                  ),
                                ),
                                Text(
                                  'Destination: ${order.customerAddress}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: RiderTheme.textMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),
                                const Divider(
                                    height: 1, color: RiderTheme.cardBorder),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.paid_rounded,
                                            size: 15,
                                            color: RiderTheme.onlineGreen),
                                        const SizedBox(width: 4),
                                        Text(
                                          '₱${order.riderEarnings.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900,
                                            color: RiderTheme.textDark,
                                          ),
                                        ),
                                        if (order.tip > 0) ...[
                                          const SizedBox(width: 4),
                                          Text(
                                            '(₱${order.tip.toStringAsFixed(0)} tip)',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF10B981),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (isActive)
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (ctx) =>
                                                  ActiveDeliveryScreen(
                                                      order: order),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: RiderTheme.primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        child: const Text(
                                          'Continue Trip',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
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

  Widget _tabButton(String title, int index) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? RiderTheme.primary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : RiderTheme.textMuted,
          ),
        ),
      ),
    );
  }
}
