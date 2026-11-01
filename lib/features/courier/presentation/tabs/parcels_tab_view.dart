import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/rider_theme.dart';
import '../../../../core/services/chat_service.dart';
import '../../../../core/services/delivery_service.dart';
import '../../../chat/presentation/rider_chat_screen.dart';
import '../../../delivery/presentation/active_delivery_screen.dart';
import '../../models/courier_models.dart';
import '../../services/courier_service.dart';

class ParcelsTabView extends StatefulWidget {
  final void Function(CourierParcel parcel) onAssignRider;
  final void Function(CourierParcel parcel) onShowParcelDetails;
  final void Function(CourierTrip trip)? onShowTripDetails;

  const ParcelsTabView({
    super.key,
    required this.onAssignRider,
    required this.onShowParcelDetails,
    this.onShowTripDetails,
  });

  @override
  State<ParcelsTabView> createState() => _ParcelsTabViewState();
}

class _ParcelsTabViewState extends State<ParcelsTabView> {
  final CourierService _service = CourierService.instance;
  CourierParcelStatus? _selectedStatusFilter;
  String _searchQuery = '';
  bool _showTripsSection = true;

  @override
  void initState() {
    super.initState();
    RiderChatService.instance.addListener(_onChatUpdated);
  }

  @override
  void dispose() {
    RiderChatService.instance.removeListener(_onChatUpdated);
    super.dispose();
  }

  void _onChatUpdated() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final filteredParcels = _service.parcels.where((p) {
      if (_selectedStatusFilter != null && p.status != _selectedStatusFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchId = p.id.toLowerCase().contains(q);
        final matchCust = p.customerName.toLowerCase().contains(q);
        final matchAddr = p.customerAddress.toLowerCase().contains(q);
        final matchRider = (p.assignedRiderName ?? '').toLowerCase().contains(q);
        return matchId || matchCust || matchAddr || matchRider;
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Search & Filter Row
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search by Tracking #, customer, or rider...',
                  hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All (${_service.totalParcelsCount})', null),
                    _buildFilterChip('In Hub (${_service.inHubSortingCount})', CourierParcelStatus.sorting),
                    _buildFilterChip('Out for Delivery (${_service.outForDeliveryCount})', CourierParcelStatus.inTransit),
                    _buildFilterChip('Delivered (${_service.deliveredTodayCount})', CourierParcelStatus.delivered),
                    _buildFilterChip('Assigned (${_service.assignedCount})', CourierParcelStatus.assigned),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Optional Inter-Hub Trips Section Header
        if (_service.trips.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFF1F5F9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.alt_route_rounded, size: 16, color: Color(0xFF0066FF)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Inter-Hub Scheduled Transfers (${_service.trips.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => setState(() => _showTripsSection = !_showTripsSection),
                  child: Text(
                    _showTripsSection ? 'Collapse' : 'Show',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0066FF)),
                  ),
                ),
              ],
            ),
          ),

        // Scheduled Trips List
        if (_showTripsSection && _service.trips.isNotEmpty)
          Container(
            color: const Color(0xFFF8FAFC),
            child: Column(
              children: _service.trips.map((trip) => _buildTripCard(trip)).toList(),
            ),
          ),

        // Parcels List
        Expanded(
          child: filteredParcels.isEmpty
              ? _buildEmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'No Parcels Found',
                  subtitle: 'No shipments match your current search or filter criteria.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredParcels.length,
                  itemBuilder: (ctx, i) => _buildParcelCard(filteredParcels[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, CourierParcelStatus? status) {
    final isSelected = _selectedStatusFilter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedStatusFilter = status),
        selectedColor: RiderTheme.primary,
        labelStyle: TextStyle(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: isSelected ? Colors.white : const Color(0xFF475569),
        ),
        backgroundColor: const Color(0xFFF1F5F9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      ),
    );
  }

  Widget _buildTripCard(CourierTrip trip) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: trip.status.backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.local_shipping_rounded, size: 16, color: trip.status.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${trip.id} • ${trip.originHubId} → ${trip.destinationHubId}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF0F172A)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      trip.status.label.toUpperCase(),
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: trip.status.color),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${trip.parcelsCount} parcels (${trip.weightKg} kg) • Pay ₱${trip.payAmount.toStringAsFixed(2)} • Assigned: ${trip.assignedCourierName ?? 'Unassigned'}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                if (trip.declinedReason != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Declined: "${trip.declinedReason}" (Payout: ₱0.00)',
                    style: const TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: Color(0xFFDC2626)),
                  ),
                ],
              ],
            ),
          ),
          if (widget.onShowTripDetails != null) ...[
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF94A3B8)),
              onPressed: () => widget.onShowTripDetails!(trip),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildParcelCard(CourierParcel parcel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Tracking ID + Copy + Status Chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.qr_code, size: 16, color: Color(0xFF0066FF)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        parcel.id,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: Color(0xFF0F172A),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: parcel.id));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tracking # copied to clipboard'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      child: const Icon(Icons.copy, size: 14, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: parcel.status.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(parcel.status.icon, size: 12, color: parcel.status.color),
                    const SizedBox(width: 4),
                    Text(
                      parcel.status.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: parcel.status.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: Customer Name & Destination
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parcel.customerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      parcel.customerAddress,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              // COD Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  parcel.isCod ? 'COD ₱${parcel.amountCod.toStringAsFixed(2)}' : 'PREPAID',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0066FF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Row 3: Items Description
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.shopping_bag_outlined, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    parcel.itemsDescription,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155)),
                  ),
                ),
                Text(
                  '${parcel.weightKg} kg',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Row 4: Assigned Rider & Actions
          Row(
            children: [
              // Rider assignment badge
              Expanded(
                child: InkWell(
                  onTap: () => widget.onAssignRider(parcel),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: parcel.isAssigned ? const Color(0xFFF0FDF4) : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: parcel.isAssigned ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          parcel.isAssigned ? Icons.two_wheeler_rounded : Icons.person_add_outlined,
                          size: 14,
                          color: parcel.isAssigned ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            parcel.isAssigned
                                ? '${parcel.assignedRiderName}'
                                : 'Unassigned • Tap to Assign Rider',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: parcel.isAssigned ? const Color(0xFF16A34A) : const Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Quick Chat Buyer Button with Unread Badge
              Builder(
                builder: (ctx) {
                  final unread = RiderChatService.instance.getUnreadCount(parcel.id);
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      InkWell(
                        onTap: () {
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
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFBAE6FD)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat_bubble_outline_rounded, size: 13, color: Color(0xFF0066FF)),
                              SizedBox(width: 4),
                              Text('Chat', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0066FF))),
                            ],
                          ),
                        ),
                      ),
                      if (unread > 0)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                            child: Text(
                              '$unread',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 6),

              // Quick Live Track / Deliver Button
              InkWell(
                onTap: () {
                  DeliveryService.instance.activateCourierParcel(parcel);
                  final order = _service.toDeliveryOrder(parcel);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ActiveDeliveryScreen(order: order),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFC7D2FE)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.navigation_rounded, size: 13, color: Color(0xFF0066FF)),
                      SizedBox(width: 4),
                      Text('Track', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0066FF))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Action Popup Button
              PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'assign') {
                    widget.onAssignRider(parcel);
                  } else if (val == 'chat') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RiderChatScreen(
                          orderId: parcel.id,
                          customerName: parcel.customerName,
                        ),
                      ),
                    );
                  } else if (val == 'track') {
                    DeliveryService.instance.activateCourierParcel(parcel);
                    final order = _service.toDeliveryOrder(parcel);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ActiveDeliveryScreen(order: order),
                      ),
                    );
                  } else if (val == 'out_for_delivery') {
                    _service.updateParcelStatus(
                      parcelId: parcel.id,
                      newStatus: CourierParcelStatus.inTransit,
                    );
                  } else if (val == 'delivered') {
                    _service.updateParcelStatus(
                      parcelId: parcel.id,
                      newStatus: CourierParcelStatus.delivered,
                    );
                  } else if (val == 'details') {
                    widget.onShowParcelDetails(parcel);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'track',
                    child: Row(
                      children: [
                        Icon(Icons.navigation_rounded, size: 16, color: Color(0xFF0066FF)),
                        SizedBox(width: 8),
                        Text('Live Navigation & Delivery'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'chat',
                    child: Row(
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Color(0xFF0066FF)),
                        SizedBox(width: 8),
                        Text('Chat Customer'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'assign',
                    child: Row(
                      children: [
                        Icon(Icons.two_wheeler_rounded, size: 16, color: Color(0xFF0066FF)),
                        SizedBox(width: 8),
                        Text('Assign / Change Rider'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'out_for_delivery',
                    child: Row(
                      children: [
                        Icon(Icons.local_shipping_outlined, size: 16, color: Color(0xFF0066FF)),
                        SizedBox(width: 8),
                        Text('Mark Out for Delivery'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delivered',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF10B981)),
                        SizedBox(width: 8),
                        Text('Mark as Delivered'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'details',
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Color(0xFF64748B)),
                        SizedBox(width: 8),
                        Text('View Full Waybill'),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Actions', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFF64748B)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: const Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
            const SizedBox(height: 4),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }
}
