import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/rider_theme.dart';
import '../../../core/services/delivery_service.dart';
import '../../../core/widgets/parcel_barcode_scanner.dart';
import '../../home/presentation/rider_home_screen.dart';
import '../../delivery/presentation/delivery_history_screen.dart';
import '../../earnings/presentation/earnings_screen.dart';
import '../../profile/presentation/rider_profile_screen.dart';

class RiderShell extends StatefulWidget {
  const RiderShell({super.key});

  @override
  State<RiderShell> createState() => _RiderShellState();
}

class _RiderShellState extends State<RiderShell> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    if (index == 2) {
      // Optical Waybill Scanner Trigger
      _openWaybillScanner();
      return;
    }
    setState(() => _currentIndex = index);
  }

  Future<void> _openWaybillScanner() async {
    Map<String, dynamic>? lookedUpParcel;

    final scanned = await ParcelBarcodeScanner.open(
      context,
      mode: ParcelScanMode.parcelLookup,
      title: 'Scan Parcel Waybill',
      subtitle:
          'Point camera at parcel barcode or type tracking number to inspect parcel custody and status.',
      onBarcodeSubmitted: (code) async {
        try {
          final info = await DeliveryService.instance.lookupParcelRemote(code);
          lookedUpParcel = info;
          final tn = (info['tracking_number'] ?? code).toString();
          final st = (info['status'] ?? '').toString().toUpperCase();
          return ParcelScanSubmissionResult(
            success: true,
            message: 'Verified $tn ($st)',
          );
        } on ApiException catch (e) {
          return ParcelScanSubmissionResult(
            success: false,
            message: e.message,
          );
        } catch (_) {
          return const ParcelScanSubmissionResult(
            success: false,
            message: 'Unable to verify parcel with server right now.',
          );
        }
      },
    );

    if (scanned == true && lookedUpParcel != null && mounted) {
      await _showParcelLookupSheet(lookedUpParcel!);
    }
  }

  Future<void> _showParcelLookupSheet(Map<String, dynamic> info) async {
    final trackingNumber = (info['tracking_number'] ?? 'N/A').toString();
    final orderNumber = (info['order_number'] ?? '').toString();
    final status = (info['status'] ?? 'unknown').toString();
    final sellerName = (info['seller_name'] ?? '').toString();
    final recipientName = (info['recipient_name'] ?? '').toString();
    final deliveryAddress = (info['delivery_address'] ?? '').toString();
    final currentHub = (info['current_hub_name'] ?? '').toString();
    final destHub = (info['destination_hub_name'] ?? '').toString();
    final codAmount = (info['cod_amount'] as num?)?.toDouble() ?? 0.0;
    final paymentMethod = (info['payment_method'] ?? '').toString().toLowerCase();

    final active = DeliveryService.instance.activeOrder;
    final matchesActive = active != null &&
        (active.trackingNumber?.toUpperCase() == trackingNumber.toUpperCase() ||
            active.id.replaceAll('#', '').toUpperCase() ==
                orderNumber.replaceAll('#', '').toUpperCase());

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surfaceContainerLowest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.qr_code_2_rounded, color: Color(0xFF0066FF)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    trackingNumber,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0066FF).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0066FF),
                    ),
                  ),
                ),
              ],
            ),
            if (orderNumber.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Order: $orderNumber',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const Divider(height: 20),
            if (sellerName.isNotEmpty)
              _lookupRow(ctx, 'Seller', sellerName),
            if (recipientName.isNotEmpty)
              _lookupRow(ctx, 'Recipient', recipientName),
            if (deliveryAddress.isNotEmpty)
              _lookupRow(ctx, 'Address', deliveryAddress),
            if (currentHub.isNotEmpty)
              _lookupRow(ctx, 'Current Hub', currentHub),
            if (destHub.isNotEmpty)
              _lookupRow(ctx, 'Destination Hub', destHub),
            if (paymentMethod == 'cod' && codAmount > 0)
              _lookupRow(ctx, 'COD Collectible', '₱${codAmount.toStringAsFixed(2)}'),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close'),
                  ),
                ),
                if (matchesActive) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pushNamed(context, '/active-delivery');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RiderTheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Open Delivery'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _lookupRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final screens = [
      RiderHomeScreen(onNavigateTab: (tab) => setState(() => _currentIndex = tab)),
      const DeliveryHistoryScreen(),
      const SizedBox(), // Placeholder for Scan index
      const EarningsScreen(),
      const RiderProfileScreen(),
    ];

    return AnimatedBuilder(
      animation: DeliveryService.instance,
      builder: (context, _) {
        final hasActiveOrder = DeliveryService.instance.activeOrder != null;

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex == 2 ? 0 : _currentIndex,
            children: screens,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(
                top: BorderSide(color: RiderTheme.cardBorder, width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onTabSelected,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              elevation: 0,
              selectedItemColor: const Color(0xFF0066FF),
              unselectedItemColor: const Color(0xFF64748B),
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.grid_view_rounded),
                  activeIcon: Icon(Icons.grid_view_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Badge(
                    isLabelVisible: hasActiveOrder,
                    label: const Text('1'),
                    backgroundColor: const Color(0xFF0066FF),
                    child: const Icon(Icons.assignment_outlined),
                  ),
                  activeIcon: Badge(
                    isLabelVisible: hasActiveOrder,
                    label: const Text('1'),
                    backgroundColor: const Color(0xFF0066FF),
                    child: const Icon(Icons.assignment_rounded),
                  ),
                  label: 'Tasks',
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0066FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  label: 'Scan',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  activeIcon: Icon(Icons.account_balance_wallet_rounded),
                  label: 'Earnings',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded),
                  activeIcon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
