import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/delivery_order.dart';
import '../../../core/services/delivery_service.dart';
import '../../../core/services/rider_service.dart';
import '../../chat/presentation/rider_chat_screen.dart';
import '../../earnings/presentation/earnings_screen.dart';
import 'widgets/route_progress_widget.dart';

class ActiveDeliveryScreen extends StatefulWidget {
  final DeliveryOrder order;

  const ActiveDeliveryScreen({
    super.key,
    required this.order,
  });

  @override
  State<ActiveDeliveryScreen> createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends State<ActiveDeliveryScreen> {
  // 0: To Store, 1: At Store, 2: Pickup Verified, 3: In Transit, 4: Delivered
  int _currentStage = 0;

  // Stage 2 state
  bool _pkg1Scanned = false;
  bool _pkg2Scanned = false;
  bool _tamperSealChecked = true;
  bool _fragileSecuredChecked = true;

  @override
  void initState() {
    super.initState();
    // Initialize stage based on delivery status if needed
    final status = widget.order.status;
    if (status == DeliveryStatus.atMerchant) {
      _currentStage = 1;
    } else if (status == DeliveryStatus.pickedUp) {
      _currentStage = 3;
    } else if (status == DeliveryStatus.delivered) {
      _currentStage = 4;
    } else {
      _currentStage = 0;
    }
  }

  void _nextStage() {
    if (_currentStage < 4) {
      setState(() {
        if (_currentStage == 1) {
          // When leaving At Store, ensure both parcels are scanned
          _pkg1Scanned = true;
          _pkg2Scanned = true;
        }

        _currentStage++;

        if (_currentStage == 4) {
          DeliveryService.instance.completeCurrentDelivery(
            notes: 'Package handed directly to customer at destination pin.',
          );
        }
      });
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ $label copied to clipboard!'),
        backgroundColor: const Color(0xFF0284C7),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showQrCodeModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Dispatch Handover QR',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Present to merchant counter staff desk 02',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(
                Icons.qr_code_2_rounded,
                size: 160,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'PIN: NX-8942-S',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: Color(0xFF0284C7),
              ),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  void _openChat(String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => RiderChatScreen(
          customerName: name,
          orderId: widget.order.id,
        ),
      ),
    );
  }

  void _callPhone(String phone, String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📞 Calling $name at $phone (VoIP Masked)...'),
        backgroundColor: const Color(0xFF0284C7),
      ),
    );
  }

  void _reportDelay() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⏱️ Merchant queue delay reported to dispatch.'),
        backgroundColor: Color(0xFFD97706),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Active Order Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Order Milestone Card
            _buildTopOrderCard(order),
            const SizedBox(height: 14),

            if (_currentStage == 4) ...[
              // In Stage 5, progress stepper sits above the completion hero card
              RouteProgressWidget(
                currentStageIndex: _currentStage,
                onStepTapped: (index) {
                  setState(() => _currentStage = index);
                },
              ),
              const SizedBox(height: 14),
              _buildDarkHeroCard(order),
            ] else ...[
              // 2. Dark Hero Card (Status-dependent)
              _buildDarkHeroCard(order),
              const SizedBox(height: 14),

              // 3. 5-Stage Stepper Progress Widget
              RouteProgressWidget(
                currentStageIndex: _currentStage,
                onStepTapped: (index) {
                  setState(() => _currentStage = index);
                },
              ),
            ],
            const SizedBox(height: 14),

            // 4. Middle Dynamic Content Cards
            ..._buildStageMiddleContent(order),
            const SizedBox(height: 18),

            // 5. Bottom Action Buttons
            _buildBottomActionButtons(order),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // --- 1. Top Order Card ---
  Widget _buildTopOrderCard(DeliveryOrder order) {
    if (_currentStage == 4) {
      // Stage 5 Milestone Header
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ORDER MILESTONE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '#${order.id}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('• BGC Hub',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B))),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'ALL 5 COMPLETE',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0284C7),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_currentStage == 1) {
      // Stage 2 Header
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ORDER #${order.id} • ${order.distanceKm} KM • ~${order.estimatedMinutes} MINS',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Delivery Trip Payout',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            Text(
              '₱${order.riderEarnings.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0284C7),
              ),
            ),
          ],
        ),
      );
    }

    if (_currentStage >= 2) {
      // Stage 3 & 4 Header
      final isTransit = _currentStage == 3;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ORDER #${order.id}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isTransit ? '1.8 km • ~8 mins' : '${order.distanceKm} km • ~${order.estimatedMinutes} mins',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'DELIVERY TRIP PAYOUT',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₱${order.riderEarnings.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF00C4FF),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Stage 1 Header
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'ORDER #${order.id}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'STANDARD COURIER',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0284C7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${order.distanceKm} km • ~${order.estimatedMinutes} mins',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),
          const Text(
            'DELIVERY TRIP PAYOUT',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₱${order.riderEarnings.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF00C4FF),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_outlined, size: 14, color: Color(0xFF0284C7)),
                    SizedBox(width: 4),
                    Text(
                      'Guaranteed',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 2. Dark Hero Card ---
  Widget _buildDarkHeroCard(DeliveryOrder order) {
    if (_currentStage == 0) {
      // Stage 1: En Route to Store Navigation Bar
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0B192C),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF00C4FF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.turn_slight_right_rounded,
                color: Color(0xFF00C4FF),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'In 350m, arrive at ${order.merchantName}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 12, color: Color(0xFF38BDF8)),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Pickup Point: Main Mall Ground Entrance',
                          style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.navigation_rounded, color: Color(0xFF38BDF8), size: 18),
            ),
          ],
        ),
      );
    }

    if (_currentStage == 1) {
      // Stage 2: GPS Arrival Confirmed & Handover PIN Card
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF0B192C),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C4FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.storefront_rounded, color: Color(0xFF00C4FF), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'GPS ARRIVAL CONFIRMED • Loading Bay #2',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF38BDF8),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Arrived at ${order.merchantName}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Handover PIN Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DISPATCH HANDOVER PIN',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 0.6,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'NX-8942-S',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF00C4FF),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _copyToClipboard('NX-8942-S', 'Handover PIN'),
                        icon: const Icon(Icons.copy_rounded, size: 14),
                        label: const Text('Copy'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF00C4FF)),
                        onPressed: _showQrCodeModal,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _callPhone(order.merchantPhone, order.merchantName),
                    icon: const Icon(Icons.call_rounded, size: 15),
                    label: const Text('Call Merchant'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _reportDelay,
                    icon: const Icon(Icons.access_time_rounded, size: 15),
                    label: const Text('Report Delay'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (_currentStage == 2) {
      // Stage 3: Handoff Complete & Verified Card
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF0B192C),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HANDOFF COMPLETE • LOADING BAY #2',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF38BDF8),
                        letterSpacing: 0.6,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Handoff Verified & Inspected',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C4FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.archive_outlined, color: Color(0xFF00C4FF), size: 18),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MERCHANT HANDOVER CODE',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'NX-8942-S',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF00C4FF)),
                      SizedBox(width: 4),
                      Text(
                        'ACCEPTED BY MERCHANT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF00C4FF),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.badge_outlined, size: 14, color: Color(0xFF00C4FF)),
                    SizedBox(width: 4),
                    Text(
                      'Authorized Staff: Marco R.',
                      style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Text(
                  'Counter Desk 02',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (_currentStage == 3) {
      // Stage 4: GPS Live Feed Navigation Card
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF0B192C),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00C4FF),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'GPS LIVE FEED',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF00C4FF),
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.speed_rounded, size: 12, color: Color(0xFF38BDF8)),
                      SizedBox(width: 4),
                      Text(
                        'Speed 32 km/h',
                        style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Maneuver Info Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C4FF).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.turn_right_rounded, color: Color(0xFF00C4FF), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next Maneuver in 1.8 km',
                          style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Turn right onto 26th Street',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.navigation_rounded, size: 13, color: Color(0xFF00C4FF)),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'EN ROUTE TO DROPOFF',
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Color(0xFF00C4FF)),
                      ),
                      Text(
                        order.customerAddress,
                        style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Launching Google Maps navigation route...')),
                      );
                    },
                    icon: const Icon(Icons.near_me_rounded, size: 15),
                    label: const Text('Open Maps'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Road hazard logged for Metro Manila cluster 4B.')),
                      );
                    },
                    icon: const Icon(Icons.warning_amber_rounded, size: 15),
                    label: const Text('Road Hazard'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFBBF24),
                      side: BorderSide(color: const Color(0xFFFBBF24).withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Stage 5: Delivery Completed! Card
    final balance = RiderService.instance.profile.walletBalance;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0B192C),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF00C4FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF00C4FF), size: 22),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle, size: 6, color: Color(0xFF00C4FF)),
                    SizedBox(width: 5),
                    Text(
                      'PAYOUT SETTLED',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF00C4FF)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          const Text(
            'Delivery Completed!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.3),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF94A3B8)),
              const SizedBox(width: 5),
              Text(
                '14:38 PM • Handed to ${order.customerName}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Payout Balance Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CREDITED TO EARNINGS',
                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '+₱${order.riderEarnings.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF00C4FF)),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'NEW WALLET BALANCE',
                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '₱${balance.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. Stage Middle Content Cards ---
  List<Widget> _buildStageMiddleContent(DeliveryOrder order) {
    switch (_currentStage) {
      case 0:
        return _buildStage1Content(order);
      case 1:
        return _buildStage2Content(order);
      case 2:
        return _buildStage3Content(order);
      case 3:
        return _buildStage4Content(order);
      case 4:
      default:
        return _buildStage5Content(order);
    }
  }

  // Stage 1 Content (Headed to Store)
  List<Widget> _buildStage1Content(DeliveryOrder order) {
    return [
      // Store Pickup Details Card
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('STORE PICKUP',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF0284C7))),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('● Prepaid',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF047857))),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              order.merchantName,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.merchantAddress,
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _callPhone(order.merchantPhone, order.merchantName),
                    icon: const Icon(Icons.call_rounded, size: 15),
                    label: const Text('Call Store'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      foregroundColor: const Color(0xFF0F172A),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openChat(order.merchantName),
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15),
                    label: const Text('Chat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      foregroundColor: const Color(0xFF0F172A),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),

      // Package Manifest Card
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 16, color: Color(0xFF0284C7)),
                    SizedBox(width: 6),
                    Text(
                      'PACKAGE MANIFEST',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('2 Parcels',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildManifestItem(
              checked: true,
              title: 'Parcel #NX8942-A',
              desc: 'Medium Sealed Box • Verified Security Seal',
              tag: 'SEALED',
              tagColor: const Color(0xFFFEE2E2),
              tagTextColor: const Color(0xFFDC2626),
            ),
            const SizedBox(height: 10),
            _buildManifestItem(
              checked: true,
              title: 'Parcel #NX8942-B',
              desc: 'Express Courier Pouch • Fragile Handle with Care',
              tag: 'EXPRESS',
              tagColor: const Color(0xFFDCFCE7),
              tagTextColor: const Color(0xFF047857),
            ),
          ],
        ),
      ),
    ];
  }

  // Stage 2 Content (At Store - Scanning)
  List<Widget> _buildStage2Content(DeliveryOrder order) {
    final scannedCount = (_pkg1Scanned ? 1 : 0) + (_pkg2Scanned ? 1 : 0);

    return [
      // Store Location & Staff Info Card
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.location_on_rounded, color: Color(0xFF0284C7), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.merchantName,
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                      Text(order.merchantAddress,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 10),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Staff Counter Desk 02',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                Text('Attendant: Marco R.',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF0284C7))),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),

      // Packages for Pickup (2 Total)
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Packages for Pickup (2 Total)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: scannedCount == 2 ? const Color(0xFFDCFCE7) : const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$scannedCount/2 verified',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: scannedCount == 2 ? const Color(0xFF047857) : const Color(0xFF0284C7),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _pkg1Scanned = true;
                          _pkg2Scanned = true;
                        });
                      },
                      child: const Text('Verify All',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF0284C7))),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Scan Barcode CTA
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _pkg1Scanned = true;
                    _pkg2Scanned = true;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✓ Store dispatch barcode matched! All 2 parcels verified.')),
                  );
                },
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                label: const Text('Scan Store Dispatch Barcode',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF0F9FF),
                  foregroundColor: const Color(0xFF0284C7),
                  elevation: 0,
                  side: const BorderSide(color: Color(0xFFBAE6FD)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Package 1
            _buildPickupScanTile(
              pkgId: 'NX-PKG-8942-01',
              badge: 'FRAGILE',
              desc: 'Sealed Box • 0.65 kg',
              isScanned: _pkg1Scanned,
              onScanTap: () => setState(() => _pkg1Scanned = !_pkg1Scanned),
            ),
            const SizedBox(height: 10),

            // Package 2
            _buildPickupScanTile(
              pkgId: 'NX-PKG-8942-02',
              badge: 'STANDARD',
              desc: 'Standard Pouch • 0.40 kg',
              isScanned: _pkg2Scanned,
              onScanTap: () => setState(() => _pkg2Scanned = !_pkg2Scanned),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),

      // Inspection & Protocol Card
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.shield_outlined, size: 16, color: Color(0xFF0284C7)),
                SizedBox(width: 6),
                Text(
                  'Inspection & Protocol',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildProtocolCheckbox(
              value: _tamperSealChecked,
              text: 'Tamper-evident seals intact & undamaged',
              onChanged: (v) => setState(() => _tamperSealChecked = v ?? true),
            ),
            const SizedBox(height: 8),
            _buildProtocolCheckbox(
              value: _fragileSecuredChecked,
              text: 'Fragile parcel placed securely in padded top box',
              onChanged: (v) => setState(() => _fragileSecuredChecked = v ?? true),
            ),
          ],
        ),
      ),
    ];
  }

  // Stage 3 Content (Pickup Verified)
  List<Widget> _buildStage3Content(DeliveryOrder order) {
    return [
      // Confidential Manifest Card
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Confidential Manifest',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                Row(
                  children: [
                    Text('2/2 Verified',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0284C7))),
                    SizedBox(width: 8),
                    Icon(Icons.qr_code_scanner_rounded, size: 14, color: Color(0xFF00C4FF)),
                    SizedBox(width: 4),
                    Text('All Scanned',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF00C4FF))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Item 1
            _buildVerifiedStowTile(
              icon: Icons.shield_outlined,
              iconColor: const Color(0xFF0284C7),
              pkgId: 'NX-PKG-8942-01',
              tag: 'FRAGILE',
              desc: 'Sealed Box • 0.65 kg',
              stowLocation: 'Stowed in Top Box',
              bayText: 'BAY #2B',
            ),
            const SizedBox(height: 10),

            // Item 2
            _buildVerifiedStowTile(
              icon: Icons.inventory_2_outlined,
              iconColor: const Color(0xFF00C4FF),
              pkgId: 'NX-PKG-8942-02',
              tag: 'STANDARD',
              desc: 'Express Pouch • 0.40 kg',
              stowLocation: 'Stowed in Motorcycle Carrier',
              bayText: 'TOP BOX',
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),

      // Security & Dispatch Checklist
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SECURITY & DISPATCH CHECKLIST',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 0.6),
                ),
                Row(
                  children: [
                    Icon(Icons.check_rounded, size: 14, color: Color(0xFF00C4FF)),
                    SizedBox(width: 4),
                    Text('All Cleared',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF00C4FF))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStaticCheckRow('Tamper-evident seal intact and scanned'),
            const SizedBox(height: 8),
            _buildStaticCheckRow('Fragile cargo safely secured in insulated top-box'),
            const SizedBox(height: 8),
            _buildStaticCheckRow('Merchant digital signature logged'),
          ],
        ),
      ),
      const SizedBox(height: 14),

      // Next Destination Preview Card
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.navigation_rounded, color: Color(0xFF0284C7), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('NEXT DESTINATION',
                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8))),
                  Text(
                    order.customerAddress,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
      const SizedBox(height: 10),

      // Guaranteed Payout Row
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Trip Guaranteed Payout',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          RichText(
            text: TextSpan(
              text: '₱${order.riderEarnings.toStringAsFixed(2)} ',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              children: const [
                TextSpan(
                  text: '+₱25 Bonus applied',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF00C4FF)),
                ),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  // Stage 4 Content (In Transit)
  List<Widget> _buildStage4Content(DeliveryOrder order) {
    return [
      // 2 Secured Parcels Stowed Card
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.archive_outlined, size: 16, color: Color(0xFF0284C7)),
                    SizedBox(width: 6),
                    Text(
                      '2 Secured Parcels Stowed',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock_rounded, size: 12, color: Color(0xFF0284C7)),
                      SizedBox(width: 4),
                      Text('Secured',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF0284C7))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildTransitParcelTile(
              icon: Icons.inventory_2_outlined,
              pkgId: 'NX-PKG-8942-01',
              subtitle: '! FRAGILE Sealed Box',
              vault: 'Vault A',
            ),
            const SizedBox(height: 8),
            _buildTransitParcelTile(
              icon: Icons.mail_outline_rounded,
              pkgId: 'NX-PKG-8942-02',
              subtitle: 'STANDARD Express Pouch',
              vault: 'Vault B',
            ),
            const SizedBox(height: 8),
            const Text(
              '🛡️ Client confidentiality protocol active • Tamper seals intact',
              style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),

      // Recipient Details Card
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFE0F2FE),
                  child: const Text('JD',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0284C7))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('RECIPIENT',
                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8))),
                      Text(order.customerName,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    ],
                  ),
                ),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('ESTIMATED ARRIVAL',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8))),
                    Text('8 mins',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF00C4FF))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('📞 ${order.customerPhone}',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                  const Text('1.8 km remaining',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0284C7))),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Customer Note
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes_rounded, size: 14, color: Color(0xFF0284C7)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Customer Note: "Drop at Guard House / Lobby Reception if unavailable. Contact upon arrival."',
                      style: TextStyle(fontSize: 11, color: Color(0xFF0369A1), height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _callPhone(order.customerPhone, order.customerName),
                    icon: const Icon(Icons.call_rounded, size: 15),
                    label: const Text('Call Customer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openChat(order.customerName),
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15),
                    label: const Text('Chat Customer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      foregroundColor: const Color(0xFF0F172A),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),

      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Trip Payout upon confirmation',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          Text(
            '₱${order.riderEarnings.toStringAsFixed(2)} Total',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
          ),
        ],
      ),
    ];
  }

  // Stage 5 Content (Delivered / Completed)
  List<Widget> _buildStage5Content(DeliveryOrder order) {
    return [
      // Delivery Manifest Card
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 16, color: Color(0xFF0284C7)),
                    SizedBox(width: 6),
                    Text(
                      'Delivery Manifest',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                Text('2 / 2 Packages',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF0284C7)),
                        SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('NX-PKG-8942-01', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                            Text('Sealed • 1.2 kg', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF0284C7)),
                        SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('NX-PKG-8942-02', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                            Text('Fragile • 0.8 kg', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),

      // Digital Sign-off & POD Card
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.draw_rounded, size: 16, color: Color(0xFF0284C7)),
                    SizedBox(width: 6),
                    Text(
                      'Digital Sign-off & POD',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('Verified',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF047857))),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/images/pod_concierge.jpg',
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 52,
                        height: 52,
                        color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                        child: const Icon(Icons.photo_camera_rounded, color: Color(0xFF0284C7), size: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('BGC Tower 2 Concierge Desk',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        SizedBox(height: 2),
                        Text('Signature on file: J. Dela Cruz',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        Text('GPS: 14.5492° N, 121.0479° E',
                            style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DISTANCE', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Color(0xFF0284C7))),
                        SizedBox(height: 2),
                        Text('3.8 km total', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DURATION', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Color(0xFF0284C7))),
                        SizedBox(height: 2),
                        Text('28 mins (On-Time)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),

      // Customer Rating & Review Card
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFFE0F2FE),
                  child: Icon(Icons.person, color: Color(0xFF0284C7), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(order.customerName,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                          const SizedBox(width: 6),
                          const Text('★★★★★',
                              style: TextStyle(fontSize: 12, color: Color(0xFFFBBF24))),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text('"Fast & careful handling, highly recommended!"',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('5.0',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lightbulb_outline_rounded, size: 14, color: Color(0xFF059669)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'You achieved a 100% on-time score for this fulfillment cycle.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF047857), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ];
  }

  // --- 4. Bottom Action Buttons ---
  Widget _buildBottomActionButtons(DeliveryOrder order) {
    if (_currentStage == 4) {
      // Stage 5 Dual Actions
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                if (DeliveryService.instance.activeOrder != null) {
                  DeliveryService.instance.completeCurrentDelivery();
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C4FF),
                foregroundColor: const Color(0xFF0F172A),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'FIND NEXT DELIVERY TASK',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, letterSpacing: 0.3),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => const EarningsScreen()),
                );
              },
              icon: const Icon(Icons.account_balance_wallet_outlined, size: 16),
              label: const Text(
                'VIEW EARNINGS & WALLET',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0284C7),
                side: const BorderSide(color: Color(0xFF00C4FF), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      );
    }

    String btnText;
    IconData? prefixIcon;
    IconData? suffixIcon;
    String subLinkText;

    if (_currentStage == 0) {
      btnText = 'I HAVE ARRIVED AT STORE';
      prefixIcon = Icons.storefront_rounded;
      suffixIcon = null;
      subLinkText = 'Cannot find store or parking? Contact Dispatch';
    } else if (_currentStage == 1) {
      btnText = 'START SCANNING PARCELS';
      prefixIcon = Icons.qr_code_scanner_rounded;
      suffixIcon = null;
      subLinkText = 'Cannot verify packages? Contact Dispatch';
    } else if (_currentStage == 2) {
      btnText = 'CONFIRM PICKUP & PROCEED';
      prefixIcon = null;
      suffixIcon = Icons.arrow_forward_rounded;
      subLinkText = '⚠️ Report Dispatch Discrepancy';
    } else {
      btnText = 'I HAVE ARRIVED AT DROPOFF';
      prefixIcon = null;
      suffixIcon = Icons.arrow_forward_rounded;
      subLinkText = '🎧 Need assistance? Contact Dispatch';
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _nextStage,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C4FF),
              foregroundColor: const Color(0xFF0F172A),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (prefixIcon != null) ...[
                  Icon(prefixIcon, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(
                  btnText,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, letterSpacing: 0.3),
                ),
                if (suffixIcon != null) ...[
                  const SizedBox(width: 8),
                  Icon(suffixIcon, size: 18),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pasig Hub Dispatch hotline connected: (02) 8888-RIDE')),
              );
            },
            child: Text(
              subLinkText,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Sub-widgets for manifests and scans ---
  Widget _buildManifestItem({
    required bool checked,
    required String title,
    required String desc,
    required String tag,
    required Color tagColor,
    required Color tagTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Color(0xFF0284C7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: tagColor, borderRadius: BorderRadius.circular(6)),
                      child: Text(tag,
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: tagTextColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupScanTile({
    required String pkgId,
    required String badge,
    required String desc,
    required bool isScanned,
    required VoidCallback onScanTap,
  }) {
    final isFragile = badge == 'FRAGILE';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isScanned ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isScanned ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onScanTap,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isScanned ? const Color(0xFF059669) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: isScanned ? const Color(0xFF059669) : const Color(0xFFCBD5E1)),
              ),
              child: isScanned
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(pkgId, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isFragile ? const Color(0xFFFEE2E2) : const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: isFragile ? const Color(0xFFDC2626) : const Color(0xFF0284C7),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: onScanTap,
            icon: Icon(isScanned ? Icons.check : Icons.qr_code_scanner_rounded, size: 13),
            label: Text(isScanned ? 'Verified' : 'Scan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isScanned ? const Color(0xFFDCFCE7) : Colors.white,
              foregroundColor: isScanned ? const Color(0xFF047857) : const Color(0xFF0284C7),
              elevation: 0,
              side: BorderSide(color: isScanned ? const Color(0xFFA7F3D0) : const Color(0xFFCBD5E1)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolCheckbox({
    required bool value,
    required String text,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Checkbox(
            value: value,
            activeColor: const Color(0xFF0284C7),
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedStowTile({
    required IconData icon,
    required Color iconColor,
    required String pkgId,
    required String tag,
    required String desc,
    required String stowLocation,
    required String bayText,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(pkgId, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(tag,
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFFDC2626))),
                        ),
                      ],
                    ),
                    Text(desc, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              const Icon(Icons.check_circle_rounded, color: Color(0xFF00C4FF), size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.archive_outlined, size: 13, color: Color(0xFF0284C7)),
                    const SizedBox(width: 5),
                    Text(stowLocation,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0284C7))),
                  ],
                ),
                Text(bayText,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaticCheckRow(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_box_rounded, size: 18, color: Color(0xFF00C4FF)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
          ),
        ],
      ),
    );
  }

  Widget _buildTransitParcelTile({
    required IconData icon,
    required String pkgId,
    required String subtitle,
    required String vault,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF0284C7)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pkgId, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900)),
                Text(subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: subtitle.contains('FRAGILE') ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                    )),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Text(vault,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          ),
        ],
      ),
    );
  }
}
