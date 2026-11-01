import 'package:flutter/material.dart';
import '../../../core/theme/rider_theme.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/delivery_service.dart';
import '../../auth/presentation/rider_login_page.dart';
import '../../chat/presentation/rider_chat_screen.dart';
import '../../delivery/presentation/active_delivery_screen.dart';
import '../models/courier_models.dart';
import '../services/courier_service.dart';
import 'courier_profile_screen.dart';
import 'trip_details_screen.dart';
import 'tabs/parcels_tab_view.dart';
import 'tabs/fleet_tab_view.dart';
import 'tabs/scanner_tab_view.dart';
import 'tabs/analytics_tab_view.dart';

class CourierDashboardPage extends StatefulWidget {
  const CourierDashboardPage({super.key});

  @override
  State<CourierDashboardPage> createState() => _CourierDashboardPageState();
}

class _CourierDashboardPageState extends State<CourierDashboardPage>
    with SingleTickerProviderStateMixin {
  final CourierService _service = CourierService.instance;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _service.addListener(_onServiceUpdate);
    RiderChatService.instance.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    RiderChatService.instance.removeListener(_onServiceUpdate);
    _tabController.dispose();
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('Sign Out of Courier Hub', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
        content: const Text(
          'Are you sure you want to end your courier dispatch session and return to the login screen?',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (ctx) => const RiderLoginPage()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeroHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  ParcelsTabView(
                    onAssignRider: _showAssignRiderModal,
                    onShowParcelDetails: _showParcelDetailsModal,
                    onShowTripDetails: (trip) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TripDetailsScreen(tripId: trip.id),
                        ),
                      );
                    },
                  ),
                  const FleetTabView(),
                  const ScannerTabView(),
                  const AnalyticsTabView(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewParcelModal,
        backgroundColor: RiderTheme.primary,
        icon: const Icon(Icons.add_box_rounded, color: Colors.white),
        label: const Text(
          'New Parcel',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
        ),
      ),
    );
  }

  // 1. Hero Hub Header with Metrics
  Widget _buildHeroHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF050B28), Color(0xFF0E1738)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00D2FF), Color(0xFF0066FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0066FF).withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Flexible(
                          child: Text(
                            'Nexora Courier Hub',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF10B981)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 3,
                                backgroundColor: Color(0xFF10B981),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'ONLINE',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _service.currentHub.name,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: () {
                      final activeOrder = DeliveryService.instance.activeOrder;
                      final targetParcel = _service.parcels.isNotEmpty ? _service.parcels.first : null;
                      final orderId = activeOrder?.id ?? targetParcel?.id ?? 'NX-8942-ORD';
                      final customerName = activeOrder?.customerName ?? targetParcel?.customerName ?? 'Alex Rivera';
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RiderChatScreen(
                            orderId: orderId,
                            customerName: customerName,
                          ),
                        ),
                      );
                    },
                    tooltip: 'Customer Chat',
                    icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 21),
                  ),
                  if (RiderChatService.instance.getTotalUnreadCount() > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${RiderChatService.instance.getTotalUnreadCount()}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: _showDispatchNotificationsModal,
                    tooltip: 'Dispatch Feed',
                    icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
                  ),
                  if (_service.dispatchNotifications.isNotEmpty)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${_service.dispatchNotifications.length}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => const CourierProfileScreen(),
                    ),
                  );
                },
                tooltip: 'My Profile',
                icon: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 22),
              ),
              IconButton(
                onPressed: _logout,
                tooltip: 'Sign Out',
                icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4 KPI Stat Badges Row
          Row(
            children: [
              _buildKpiCard(
                label: 'Total Shipments',
                value: '${_service.totalParcelsCount}',
                icon: Icons.inventory_2_outlined,
                color: const Color(0xFF00D2FF),
              ),
              const SizedBox(width: 8),
              _buildKpiCard(
                label: 'Out for Delivery',
                value: '${_service.outForDeliveryCount}',
                icon: Icons.two_wheeler_rounded,
                color: const Color(0xFF38BDF8),
              ),
              const SizedBox(width: 8),
              _buildKpiCard(
                label: 'Delivered',
                value: '${_service.deliveredTodayCount}',
                icon: Icons.check_circle_outline_rounded,
                color: const Color(0xFF10B981),
              ),
              const SizedBox(width: 8),
              _buildKpiCard(
                label: 'In Hub Sorting',
                value: '${_service.inHubSortingCount}',
                icon: Icons.hourglass_top_rounded,
                color: const Color(0xFFF59E0B),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    size: 13,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. Tab Bar
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: false,
        labelColor: RiderTheme.primary,
        unselectedLabelColor: const Color(0xFF64748B),
        indicatorColor: RiderTheme.primary,
        indicatorWeight: 3,
        labelStyle: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(icon: Icon(Icons.local_shipping_outlined, size: 18), text: 'Parcels'),
          Tab(icon: Icon(Icons.groups_outlined, size: 18), text: 'Fleet'),
          Tab(icon: Icon(Icons.qr_code_scanner_rounded, size: 18), text: 'Scanner'),
          Tab(icon: Icon(Icons.analytics_outlined, size: 18), text: 'Hub Stats'),
        ],
      ),
    );
  }

  // Modals: Assign Rider Modal
  void _showAssignRiderModal(CourierParcel parcel) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final onlineRiders = _service.riders.where((r) => r.isOnline).toList();
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Assign Rider to ${parcel.id}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text('Deliver to: ${parcel.customerName} • ${parcel.city}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 16),
              if (onlineRiders.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_off_rounded, color: Color(0xFF64748B), size: 30),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No Couriers Currently On Duty',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Couriers must complete pre-trip inspection and switch On Duty to appear for new trip assignments.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                )
              else
                ...onlineRiders.map((r) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFE0F2FE),
                      child: Icon(
                        r.vehicleType.contains('Van') ? Icons.airport_shuttle : Icons.two_wheeler,
                        color: const Color(0xFF0066FF),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('ON DUTY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                        ),
                      ],
                    ),
                    subtitle: Text('${r.vehicleModel} • ${r.currentLocation} (${r.workloadSummary})', style: const TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () {
                      Navigator.pop(ctx);
                      final success = _service.assignParcelToRider(parcelId: parcel.id, riderId: r.id);
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Dispatched ${parcel.id} to ${r.name}!'),
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Cannot assign: ${r.name} is offline or unavailable.'),
                            backgroundColor: const Color(0xFFEF4444),
                          ),
                        );
                      }
                    },
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  void _showDispatchNotificationsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final notifications = _service.dispatchNotifications;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF0066FF), size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dispatch & Incident Feed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                          Text('Real-time logistics telemetry & safety alerts', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),
                    ],
                  ),
                  if (notifications.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _service.clearDispatchNotifications();
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text('Clear All', style: TextStyle(fontSize: 12, color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (notifications.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(Icons.mark_chat_read_outlined, size: 40, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      const Text('No dispatch notifications', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                      const SizedBox(height: 4),
                      const Text('Courier pre-trip checks and shift telemetry updates will appear here.', style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8))),
                    ],
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: notifications.length,
                    separatorBuilder: (_, index) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final note = notifications[i];
                      final isSafety = note.contains('[Safety Incident]');
                      final isPassed = note.contains('[Pre-Trip Passed]');
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isSafety
                                    ? const Color(0xFFFEE2E2)
                                    : (isPassed ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9)),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isSafety
                                    ? Icons.warning_amber_rounded
                                    : (isPassed ? Icons.verified_rounded : Icons.info_outline_rounded),
                                size: 16,
                                color: isSafety
                                    ? const Color(0xFFEF4444)
                                    : (isPassed ? const Color(0xFF16A34A) : const Color(0xFF64748B)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                note,
                                style: const TextStyle(fontSize: 12.5, height: 1.35, color: Color(0xFF1E293B)),
                              ),
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

  // Modals: New Inbound Parcel Modal
  void _showNewParcelModal() {
    final merchantCtrl = TextEditingController(text: 'Nexora Laguna Store');
    final custNameCtrl = TextEditingController();
    final custPhoneCtrl = TextEditingController(text: '09170001122');
    final custAddrCtrl = TextEditingController();
    final itemsCtrl = TextEditingController();
    final amountCtrl = TextEditingController(text: '1200.00');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.add_box_rounded, color: Color(0xFF0066FF)),
                    SizedBox(width: 8),
                    Text('Create Inbound Parcel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: merchantCtrl,
                  decoration: const InputDecoration(labelText: 'Merchant / Sender Name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: custNameCtrl,
                  decoration: const InputDecoration(labelText: 'Customer Full Name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: custPhoneCtrl,
                  decoration: const InputDecoration(labelText: 'Customer Contact Phone'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: custAddrCtrl,
                  decoration: const InputDecoration(labelText: 'Delivery Address & City'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: itemsCtrl,
                  decoration: const InputDecoration(labelText: 'Items Description'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'COD Amount (PHP)'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      if (custNameCtrl.text.isEmpty || custAddrCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill in customer name and address')),
                        );
                        return;
                      }
                      Navigator.pop(ctx);
                      final p = _service.addInboundParcel(
                        merchantName: merchantCtrl.text,
                        customerName: custNameCtrl.text,
                        customerPhone: custPhoneCtrl.text,
                        customerAddress: custAddrCtrl.text,
                        city: custAddrCtrl.text.split(',').last.trim(),
                        itemsDescription: itemsCtrl.text.isEmpty ? 'Assorted Merchandise' : itemsCtrl.text,
                        weightKg: 1.2,
                        amountCod: double.tryParse(amountCtrl.text) ?? 0.0,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Inbound parcel ${p.id} registered into hub!'),
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066FF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Register & Save to Hub', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Modals: Parcel Details Modal
  void _showParcelDetailsModal(CourierParcel parcel) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(parcel.id, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: parcel.status.backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      parcel.status.label,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: parcel.status.color),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Merchant: ${parcel.merchantName}', style: const TextStyle(fontSize: 12.5)),
              const SizedBox(height: 4),
              Text('Recipient: ${parcel.customerName} (${parcel.customerPhone})', style: const TextStyle(fontSize: 12.5)),
              const SizedBox(height: 4),
              Text('Address: ${parcel.customerAddress}', style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
              const SizedBox(height: 4),
              Text('Items: ${parcel.itemsDescription}', style: const TextStyle(fontSize: 12.5)),
              const SizedBox(height: 4),
              Text('COD Collection: ₱${parcel.amountCod.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0066FF))),
              if (parcel.notes != null) ...[
                const SizedBox(height: 6),
                Text('Notes: ${parcel.notes}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFFD97706))),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RiderChatScreen(
                              orderId: parcel.id,
                              customerName: parcel.customerName,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                      label: const Text('Chat Buyer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0066FF),
                        side: const BorderSide(color: Color(0xFF0066FF)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        DeliveryService.instance.activateCourierParcel(parcel);
                        final order = CourierService.instance.toDeliveryOrder(parcel);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ActiveDeliveryScreen(order: order),
                          ),
                        );
                      },
                      icon: const Icon(Icons.navigation_rounded, size: 16),
                      label: const Text('Live Track / Deliver', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0066FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
