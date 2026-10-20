import 'package:flutter/material.dart';
import '../../../core/theme/rider_theme.dart';
import '../../../core/services/delivery_service.dart';
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

  void _openWaybillScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 18),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF00D2FF)),
                SizedBox(width: 8),
                Text(
                  'Waybill Optical Engine',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'AI Auto-Detect Active (Continuous 60 FPS)',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
            const SizedBox(height: 24),
            // Scanner Viewport Mock
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF00D2FF), width: 1.5),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white70, width: 2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    const Positioned(
                      bottom: 24,
                      child: Text(
                        'Align barcode / waybill QR within frame',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Waybill #NX-WAY-8812 Scanned & Verified!'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                },
                icon: const Icon(Icons.flash_on_rounded),
                label: const Text('Simulate Waybill Scan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
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
              selectedItemColor: const Color(0xFF0284C7),
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
                    backgroundColor: const Color(0xFF0284C7),
                    child: const Icon(Icons.assignment_outlined),
                  ),
                  activeIcon: Badge(
                    isLabelVisible: hasActiveOrder,
                    label: const Text('1'),
                    backgroundColor: const Color(0xFF0284C7),
                    child: const Icon(Icons.assignment_rounded),
                  ),
                  label: 'Tasks',
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7),
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
