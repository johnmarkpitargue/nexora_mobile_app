import 'package:flutter/material.dart';
import '../../../../core/services/laguna_places_service.dart';
import '../../../chat/presentation/rider_chat_screen.dart';
import '../../../delivery/presentation/widgets/rider_live_navigation_map.dart';
import '../../models/courier_models.dart';
import '../../services/courier_service.dart';

class FleetTabView extends StatelessWidget {
  const FleetTabView({super.key});

  void _showRiderLiveMapModal(BuildContext context, CourierRider rider) {
    final service = CourierService.instance;
    final assignedParcels = service.parcels
        .where((p) => p.assignedRiderId == rider.id && p.status == CourierParcelStatus.inTransit)
        .toList();
    final activeParcel = assignedParcels.isNotEmpty
        ? assignedParcels.first
        : (service.parcels.isNotEmpty ? service.parcels.first : null);
    final destAddr = activeParcel?.customerAddress ?? rider.assignedZone;
    final resolved = LagunaPlacesService.instance.resolveCoordinates(destAddr);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.my_location_rounded, color: Color(0xFF0066FF), size: 20),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Live GPS Telemetry • ${rider.name}',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                          ),
                          Text(
                            '${rider.vehicleModel} (${rider.plateNumber}) • ${rider.assignedZone}',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              RiderLiveNavigationMap(
                destinationLat: activeParcel?.customerLat ?? resolved.latitude,
                destinationLng: activeParcel?.customerLng ?? resolved.longitude,
                destinationAddress: destAddr,
                customerName: activeParcel?.customerName ?? rider.name,
                orderId: activeParcel?.id ?? rider.id,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = CourierService.instance;
    final riders = service.riders;

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: riders.length,
      itemBuilder: (ctx, i) {
        final rider = riders[i];
        final activeTrip = service.getActiveTripForCourier(rider.id);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFE0F2FE),
                    child: Icon(
                      rider.vehicleType.contains('Van')
                          ? Icons.airport_shuttle_rounded
                          : Icons.two_wheeler_rounded,
                      color: const Color(0xFF0066FF),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rider.name,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${rider.vehicleModel} • Plate ${rider.plateNumber}',
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: rider.isOnline
                          ? const Color(0xFFDCFCE7)
                          : (rider.isLocationUnknown
                              ? const Color(0xFFFEF3C7)
                              : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      rider.isOnline
                          ? 'ON DUTY'
                          : (rider.isLocationUnknown
                              ? 'OFFLINE (Location Unknown)'
                              : 'OFFLINE'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: rider.isOnline
                            ? const Color(0xFF16A34A)
                            : (rider.isLocationUnknown
                                ? const Color(0xFFD97706)
                                : const Color(0xFF64748B)),
                      ),
                    ),
                  ),
                ],
              ),
              if (rider.isOnline) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF16A34A)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Location: ${rider.currentLocation} • Checklist: ${rider.checklistCompletedAt != null ? "${rider.checklistCompletedAt!.hour.toString().padLeft(2, '0')}:${rider.checklistCompletedAt!.minute.toString().padLeft(2, '0')}" : "Verified OK"}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (rider.preTripIssue != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFEF4444)),
                          const SizedBox(width: 6),
                          Text(
                            'Safety Hold: ${rider.preTripIssue} Not OK',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFB91C1C),
                            ),
                          ),
                        ],
                      ),
                      if (rider.preTripNote != null && rider.preTripNote!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Padding(
                          padding: const EdgeInsets.only(left: 20),
                          child: Text(
                            '"${rider.preTripNote}"',
                            style: const TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF7F1D1D),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              if (activeTrip != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.alt_route_rounded, size: 14, color: Color(0xFF0066FF)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Active Trip: ${activeTrip.id} (${activeTrip.originHubId} → ${activeTrip.destinationHubId}) • In Progress',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Assigned Zone', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(
                          rider.assignedZone,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Delivery Load', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(rider.workloadSummary, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF0066FF))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final assignedParcel = service.parcels.cast<CourierParcel?>().firstWhere(
                          (p) => p?.assignedRiderId == rider.id,
                          orElse: () => service.parcels.isNotEmpty ? service.parcels.first : null,
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RiderChatScreen(
                              orderId: assignedParcel?.id ?? 'NX-8942-ORD',
                              customerName: assignedParcel?.customerName ?? rider.name,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15),
                      label: const Text('Order Chat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0066FF),
                        side: const BorderSide(color: Color(0xFFBAE6FD)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showRiderLiveMapModal(context, rider),
                      icon: const Icon(Icons.my_location_rounded, size: 15),
                      label: const Text('Track Rider Live', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0066FF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
