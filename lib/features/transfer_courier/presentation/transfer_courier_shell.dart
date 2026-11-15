import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/rider_account_service.dart';
import '../../../core/theme/rider_theme.dart';
import '../../auth/presentation/rider_login_page.dart';
import '../models/transfer_manifest_models.dart';
import '../services/transfer_courier_service.dart';
import 'manifest_detail_screen.dart';

class TransferCourierShell extends StatefulWidget {
  const TransferCourierShell({super.key});

  @override
  State<TransferCourierShell> createState() => _TransferCourierShellState();
}

class _TransferCourierShellState extends State<TransferCourierShell> {
  int _currentIndex = 0;
  String _tripFilter = 'active';
  final TextEditingController _inventorySearchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    TransferCourierService.instance.addListener(_onUpdate);
    TransferCourierService.instance.fetchDashboard();
    TransferCourierService.instance.fetchManifests(filter: _tripFilter);
    TransferCourierService.instance.fetchInventory();
    TransferCourierService.instance.fetchProfile();
  }

  @override
  void dispose() {
    TransferCourierService.instance.removeListener(_onUpdate);
    _inventorySearchController.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _logout() async {
    try {
      await ApiClient.instance.post('/api/mobile/v1/auth/logout');
    } catch (_) {}
    await ApiClient.instance.clearToken();
    RiderAccountService.instance.logout();
    TransferCourierService.instance.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RiderLoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RiderTheme.background,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildHomeTab(),
            _buildTripsTab(),
            _buildInventoryTab(),
            _buildProfileTab(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (idx) => setState(() => _currentIndex = idx),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: RiderTheme.primary,
        unselectedItemColor: RiderTheme.textMuted,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping_rounded),
            label: 'My Trips',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_rounded),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    final service = TransferCourierService.instance;
    final dash = service.dashboard;

    return RefreshIndicator(
      onRefresh: () => service.fetchDashboard(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [RiderTheme.primary, RiderTheme.primaryDark],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${dash?.courierName ?? 'Transfer Courier'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  dash?.companyName ?? 'Logistics Partner',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                if (dash?.assignedHub != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Assigned Hub: ${dash!.assignedHub!.name} (${dash.assignedHub!.code})',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (dash?.activeManifest != null)
            _buildManifestCard(dash!.activeManifest!)
          else
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: RiderTheme.cardBorder),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    size: 40,
                    color: RiderTheme.textMuted,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'No active hub transfer assigned.',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: RiderTheme.textDark,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'You will see your assigned transfer manifest here once dispatched by your logistics operator.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: RiderTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _statCard('Assigned Parcels', '${dash?.totalAssignedParcels ?? 0}',
                  Icons.inventory_2_outlined, RiderTheme.primary),
              _statCard('Loaded Parcels', '${dash?.totalLoadedParcels ?? 0}',
                  Icons.check_circle_outline, RiderTheme.onlineGreen),
              _statCard('Completed Transfers', '${dash?.completedTransfers ?? 0}',
                  Icons.done_all_rounded, RiderTheme.primary),
              _statCard('Reported Exceptions', '${dash?.reportedExceptions ?? 0}',
                  Icons.warning_amber_rounded, RiderTheme.warningOrange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RiderTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: RiderTheme.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTripsTab() {
    final service = TransferCourierService.instance;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Text(
                'My Transfer Trips',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              ChoiceChip(
                label: const Text('Active'),
                selected: _tripFilter == 'active',
                onSelected: (_) {
                  setState(() => _tripFilter = 'active');
                  service.fetchManifests(filter: 'active');
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('History'),
                selected: _tripFilter == 'history',
                onSelected: (_) {
                  setState(() => _tripFilter = 'history');
                  service.fetchManifests(filter: 'history');
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => service.fetchManifests(filter: _tripFilter),
            child: service.manifests.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 80),
                      Center(
                        child: Text(
                          'No transfer manifests found.',
                          style: TextStyle(color: RiderTheme.textMuted),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: service.manifests.length,
                    itemBuilder: (_, idx) =>
                        _buildManifestCard(service.manifests[idx]),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildManifestCard(TransferManifestModel manifest) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ManifestDetailScreen(manifestId: manifest.id),
          ),
        );
        TransferCourierService.instance.fetchDashboard();
        TransferCourierService.instance.fetchManifests(filter: _tripFilter);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: RiderTheme.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  manifest.manifestNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: RiderTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    manifest.status.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: RiderTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${manifest.originHub?.name ?? 'Origin'} → ${manifest.destinationHub?.name ?? 'Destination'}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  '${manifest.totalParcels} parcels',
                  style: const TextStyle(
                    fontSize: 12,
                    color: RiderTheme.textMuted,
                  ),
                ),
                if (manifest.vehiclePlateNumber != null &&
                    manifest.vehiclePlateNumber!.isNotEmpty) ...[
                  const Text('  •  ',
                      style: TextStyle(color: RiderTheme.textMuted)),
                  Text(
                    'Plate: ${manifest.vehiclePlateNumber}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: RiderTheme.textMuted,
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

  Widget _buildInventoryTab() {
    final service = TransferCourierService.instance;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _inventorySearchController,
            onChanged: (q) => service.fetchInventory(query: q),
            decoration: const InputDecoration(
              hintText: 'Search assigned parcel tracking #...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => service.fetchInventory(
              query: _inventorySearchController.text,
            ),
            child: service.inventory.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 80),
                      Center(
                        child: Text(
                          'No assigned parcels in your inventory.',
                          style: TextStyle(color: RiderTheme.textMuted),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: service.inventory.length,
                    itemBuilder: (_, idx) {
                      final item = service.inventory[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: RiderTheme.cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item.trackingNumber,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  item.manifestNumber ?? '',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: RiderTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.originHubName ?? 'Origin'} → ${item.destinationHubName ?? 'Destination'}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Loading: ${item.loadingStatus.toUpperCase()}  •  Receiving: ${item.receivingStatus.toUpperCase()}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: RiderTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileTab() {
    final profile = TransferCourierService.instance.profileData;
    final user = profile?['user'] as Map<String, dynamic>?;
    final session = RiderAccountService.instance.activeRiderSession;

    final fullName = user?['full_name']?.toString() ??
        session?.fullName ??
        'Transfer Courier';
    final email = user?['email']?.toString() ?? session?.email ?? '';
    final phone =
        user?['contact_number']?.toString() ?? session?.mobileNumber ?? '';
    final company = profile?['company_name']?.toString() ??
        session?.companyName ??
        'Logistics Partner';
    final licenseStatus = profile?['license_status']?.toString() ?? 'Valid';
    final accountStatus =
        profile?['account_status']?.toString() ?? session?.accountStatus ?? 'active';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Transfer Courier Profile',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: RiderTheme.cardBorder),
          ),
          child: Column(
            children: [
              _profileRow('Name', fullName),
              _profileRow('Email', email),
              _profileRow('Contact Number', phone),
              _profileRow('Logistics Company', company),
              _profileRow('Driver\'s License Status', licenseStatus),
              _profileRow('Account Status', accountStatus.toUpperCase()),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _logout,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Log Out'),
          style: ElevatedButton.styleFrom(
            backgroundColor: RiderTheme.errorRed,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _profileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: RiderTheme.textMuted,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
