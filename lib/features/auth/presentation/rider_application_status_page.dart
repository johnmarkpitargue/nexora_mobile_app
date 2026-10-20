import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/rider_theme.dart';
import 'rider_application_approved_page.dart';

class RiderApplicationStatusPage extends StatefulWidget {
  final String refNumber;
  final String applicantName;
  final String vehicleModel;
  final String phone;

  const RiderApplicationStatusPage({
    super.key,
    this.refNumber = 'NX-RIDER-2026-98124',
    this.applicantName = 'Juan Carlos Del Rosario',
    this.vehicleModel = 'Honda Click 150i',
    this.phone = '+63 917 123 4567',
  });

  @override
  State<RiderApplicationStatusPage> createState() =>
      _RiderApplicationStatusPageState();
}

class _RiderApplicationStatusPageState
    extends State<RiderApplicationStatusPage>
    with TickerProviderStateMixin {
  bool _isRefreshing = false;
  late AnimationController _rotationController;
  late AnimationController _clearanceRollController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _clearanceRollController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _clearanceRollController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Reference #$text copied!'),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleRefreshStatus() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);
    _rotationController.repeat();

    // Simulated cloud verification check
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;
    _rotationController.stop();
    setState(() => _isRefreshing = false);

    // Navigate to Approved Screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => RiderApplicationApprovedPage(
          riderName: widget.applicantName.split(' ').first,
          fleetId: '#NX-PH-88421',
          voucherCode: 'PASIG-KIT-88421',
          assignedHub: 'Pasig-Ortigas Central Logistics Hub',
        ),
      ),
    );
  }

  void _showOrientationVideoDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.ondemand_video_rounded,
                        color: Color(0xFF00D2FF), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Rider Safety & Delivery Tips',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontFamily: RiderTheme.fontFamily,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00D2FF).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Color(0xFF00D2FF),
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Watch Module: 3 Mins',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Module Highlights:\n• Handling fragile consumer packages safely\n• Utilizing the optical Waybill barcode scanner\n• Immediate safety protocol in heavy rain or road hazards',
              style: TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Orientation module completed!'),
                      backgroundColor: Color(0xFF059669),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D2FF),
                  foregroundColor: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Mark Module as Finished',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontFamily: RiderTheme.fontFamily,
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Application Status',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
            fontSize: 17,
            letterSpacing: -0.3,
            fontFamily: RiderTheme.fontFamily,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.help_outline_rounded,
              color: Color(0xFF64748B),
              size: 22,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text(
                    'Application Assistance',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontFamily: RiderTheme.fontFamily,
                    ),
                  ),
                  content: const Text(
                    'Our verification team verifies submissions in real time. If your documents are clear and legible, approval completes within 1-2 hours.',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Status Hero Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Hourglass Circular Icon
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00D2FF), Color(0xFF0284C7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF0284C7).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.hourglass_top_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Pill: Application Received
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          color: Color(0xFF0284C7),
                          size: 7,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Application Received',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0284C7),
                            fontFamily: RiderTheme.fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Heading
                  const Text(
                    'Application Under Review',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      fontFamily: RiderTheme.fontFamily,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Subtitle
                  const Text(
                    'We are reviewing your details and documents.\nYou will get an SMS update once approved.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      height: 1.4,
                      fontFamily: RiderTheme.fontFamily,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // REF # Box with COPY
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.badge_outlined,
                          color: Color(0xFF475569),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'REF #${widget.refNumber}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: 0.5,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => _copyToClipboard(widget.refNumber),
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            child: Text(
                              'COPY',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0284C7),
                                letterSpacing: 0.5,
                                fontFamily: RiderTheme.fontFamily,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Estimated Approval Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF5FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Color(0xFFDBEAFE),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.bolt_rounded,
                            color: Color(0xFF0284C7),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Estimated Approval: 1 to 2 Hours',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                  fontFamily: RiderTheme.fontFamily,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'SMS notification will dispatch automatically to ${widget.phone}.',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF475569),
                                  fontFamily: RiderTheme.fontFamily,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Application Checklist Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  // Checklist Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            color: Color(0xFF0284C7),
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Application Checklist',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              fontFamily: RiderTheme.fontFamily,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '3 of 5 Completed',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF4338CA),
                            fontFamily: RiderTheme.fontFamily,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Item 1: Personal & Vehicle Info (Verified)
                  _checklistRow(
                    status: _ItemStatus.verified,
                    title: 'Personal & Vehicle Info',
                    subtitle:
                        '${widget.applicantName} • ${widget.vehicleModel}',
                    isFirst: true,
                  ),

                  // Item 2: Driver's License & OR/CR (Verified)
                  _checklistRow(
                    status: _ItemStatus.verified,
                    title: 'Driver\'s License & OR/CR',
                    subtitle:
                        'Professional Driver\'s License & Vehicle Registr...',
                  ),

                  // Item 3: Security Clearance (In Progress)
                  _checklistRow(
                    status: _ItemStatus.inProgress,
                    title: 'Security Clearance',
                    subtitle: 'Checking background clearance',
                    showProgressBar: true,
                  ),

                  // Item 4: Payout & Wallet Setup (Verified)
                  _checklistRow(
                    status: _ItemStatus.verified,
                    title: 'Payout & Wallet Setup',
                    subtitle: 'GCash 0917-***-4567 successfully paired',
                  ),

                  // Item 5: Fleet ID Activation (Queued)
                  _checklistRow(
                    status: _ItemStatus.queued,
                    title: 'Fleet ID Activation',
                    subtitle: 'Starter kit pickup ready after approval',
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // NEXT ONBOARDING PHASE: Collect Your Fleet Gear
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NEXT ONBOARDING PHASE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0284C7),
                        letterSpacing: 0.6,
                        fontFamily: RiderTheme.fontFamily,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Collect Your Fleet Gear',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        fontFamily: RiderTheme.fontFamily,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: Color(0xFF0284C7),
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 3 Gear Preview Cards
            Row(
              children: [
                Expanded(
                  child: _gearPreviewCard(
                    title: 'Pro Jacket',
                    subtitle: 'Size L',
                    icon: Icons.checkroom_rounded,
                    accentColor: const Color(0xFF0066FF),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _gearPreviewCard(
                    title: 'Visor Helmet',
                    subtitle: 'DOT Cert',
                    icon: Icons.sports_motorsports_rounded,
                    accentColor: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _gearPreviewCard(
                    title: 'Thermal Bag',
                    subtitle: '50L Proof',
                    icon: Icons.backpack_rounded,
                    accentColor: const Color(0xFF0284C7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Pasig Logistics Hub Location & Map Preview Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.location_on_outlined,
                            color: Color(0xFF0284C7),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pasig Central Logistics Hub',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                  fontFamily: RiderTheme.fontFamily,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Bldg 4, C-5 Commercial Compound, Pasig City',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                  fontFamily: RiderTheme.fontFamily,
                                ),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 13,
                                    color: Color(0xFF64748B),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Mon – Sat • 7:00 AM – 8:00 PM',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                      fontFamily: RiderTheme.fontFamily,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Mini Map Graphic
                  Container(
                    height: 105,
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        // Stylized Map Background
                        CustomPaint(
                          size: const Size(double.infinity, 105),
                          painter: _MiniMapPainter(),
                        ),

                        // Bottom Overlaid Bar
                        Positioned(
                          left: 10,
                          right: 10,
                          bottom: 10,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A)
                                      .withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.storefront_rounded,
                                      color: Color(0xFF00D2FF),
                                      size: 13,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      'Bay 3 Dispatch Counter',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        fontFamily: RiderTheme.fontFamily,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Opening navigation directions to Pasig Hub...',
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.near_me_rounded,
                                    size: 13, color: Colors.white),
                                label: const Text(
                                  'Directions',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    fontFamily: RiderTheme.fontFamily,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00D2FF),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // QUICK RIDER ORIENTATION Video Banner
            InkWell(
              onTap: _showOrientationVideoDialog,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.play_circle_outline_rounded,
                                color: Color(0xFF00D2FF),
                                size: 14,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'QUICK RIDER ORIENTATION',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF00D2FF),
                                  letterSpacing: 0.5,
                                  fontFamily: RiderTheme.fontFamily,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Rider Safety & Delivery Tips',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              fontFamily: RiderTheme.fontFamily,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Watch a short 3–minute guide while you wait to learn delivery tips and start earning faster.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                              height: 1.35,
                              fontFamily: RiderTheme.fontFamily,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00D2FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Color(0xFF0F172A),
                        size: 26,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // CHECK STATUS REFRESH Button
            Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00D2FF), Color(0xFF0284C7)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _handleRefreshStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RotationTransition(
                      turns: _rotationController,
                      child: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isRefreshing
                          ? 'VERIFYING STATUS...'
                          : 'CHECK STATUS REFRESH',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                        fontFamily: RiderTheme.fontFamily,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Fleet Dispatch Hotline Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.headset_mic_outlined,
                      color: Color(0xFF0284C7),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fleet Dispatch Hotline',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            fontFamily: RiderTheme.fontFamily,
                          ),
                        ),
                        Text(
                          '(02) 8888–RIDE',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontFamily: RiderTheme.fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Calling Fleet Hotline: (02) 8888-RIDE...'),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.call_rounded,
                            size: 12, color: Color(0xFF0284C7)),
                        SizedBox(width: 4),
                        Text(
                          'Call Now',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0284C7),
                            fontFamily: RiderTheme.fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Footer
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded,
                    size: 12, color: Color(0xFF10B981)),
                SizedBox(width: 5),
                Text(
                  'Nexora Logistics Philippines • Need help? Call (02) 8888–RIDE',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                    fontFamily: RiderTheme.fontFamily,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _gearPreviewCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              fontFamily: RiderTheme.fontFamily,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
              fontFamily: RiderTheme.fontFamily,
            ),
          ),
        ],
      ),
    );
  }

  Widget _checklistRow({
    required _ItemStatus status,
    required String title,
    required String subtitle,
    bool showProgressBar = false,
    bool isFirst = false,
    bool isLast = false,
  }) {
    Widget iconWidget;
    Widget badgeWidget;

    switch (status) {
      case _ItemStatus.verified:
        iconWidget = Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Color(0xFF059669),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
        );
        badgeWidget = Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFD1FAE5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'Verified',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF059669),
              fontFamily: RiderTheme.fontFamily,
            ),
          ),
        );
        break;

      case _ItemStatus.inProgress:
        iconWidget = Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Color(0xFF0284C7),
            shape: BoxShape.circle,
          ),
          child: RotationTransition(
            turns: _clearanceRollController,
            child: const Icon(Icons.sync_rounded, color: Colors.white, size: 14),
          ),
        );
        badgeWidget = Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2FE),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RotationTransition(
                turns: _clearanceRollController,
                child: const Icon(Icons.autorenew_rounded,
                    size: 11, color: Color(0xFF0284C7)),
              ),
              const SizedBox(width: 4),
              const Text(
                'In Progress',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0284C7),
                  fontFamily: RiderTheme.fontFamily,
                ),
              ),
            ],
          ),
        );
        break;

      case _ItemStatus.queued:
        iconWidget = Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Color(0xFFE2E8F0),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.remove_rounded,
              color: Color(0xFF64748B), size: 14),
        );
        badgeWidget = Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'Queued',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
              fontFamily: RiderTheme.fontFamily,
            ),
          ),
        );
        break;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Column
          Column(
            children: [
              iconWidget,
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: status == _ItemStatus.verified
                        ? const Color(0xFF059669)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: status == _ItemStatus.queued
                                ? const Color(0xFF64748B)
                                : const Color(0xFF0F172A),
                            fontFamily: RiderTheme.fontFamily,
                          ),
                        ),
                      ),
                      badgeWidget,
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      fontFamily: RiderTheme.fontFamily,
                    ),
                  ),
                  if (showProgressBar) ...[
                    const SizedBox(height: 6),
                    AnimatedBuilder(
                      animation: _clearanceRollController,
                      builder: (context, child) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Stack(
                                children: [
                                  Container(
                                    height: 5,
                                    width: double.infinity,
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                  FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: 0.65,
                                    child: Container(
                                      height: 5,
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFF00D2FF),
                                            Color(0xFF0284C7),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Rolling shimmer beam
                                  Positioned.fill(
                                    child: LayoutBuilder(
                                      builder: (ctx, constraints) {
                                        final maxW = constraints.maxWidth * 0.65;
                                        final offset = (_clearanceRollController.value * (maxW + 40)) - 40;
                                        return Stack(
                                          children: [
                                            Positioned(
                                              left: offset,
                                              top: 0,
                                              bottom: 0,
                                              width: 32,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.white.withValues(alpha: 0.0),
                                                      Colors.white.withValues(alpha: 0.8),
                                                      Colors.white.withValues(alpha: 0.0),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Rolling police & NBI records cross-check...',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0284C7),
                                    fontFamily: RiderTheme.fontFamily,
                                  ),
                                ),
                                Text(
                                  '65%',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0284C7),
                                    fontFamily: RiderTheme.fontFamily,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _ItemStatus { verified, inProgress, queued }

class _MiniMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFE6EEF8);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    final primaryRoadPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke;

    // Roads
    canvas.drawLine(
        Offset(0, size.height * 0.4), Offset(size.width, size.height * 0.5), roadPaint);
    canvas.drawLine(Offset(size.width * 0.3, 0),
        Offset(size.width * 0.4, size.height), primaryRoadPaint);
    canvas.drawLine(Offset(size.width * 0.7, 0),
        Offset(size.width * 0.6, size.height), roadPaint);
    canvas.drawLine(
        Offset(0, size.height * 0.75), Offset(size.width, size.height * 0.7), primaryRoadPaint);

    // Text labels for cities on map
    _drawText(canvas, 'Manila', Offset(size.width * 0.08, size.height * 0.22));
    _drawText(canvas, 'Pasig City', Offset(size.width * 0.42, size.height * 0.18));
    _drawText(canvas, 'Cainta', Offset(size.width * 0.72, size.height * 0.2));
    _drawText(canvas, 'Antipolo', Offset(size.width * 0.82, size.height * 0.35));

    // Hub Location Pin
    final pinCenter = Offset(size.width * 0.48, size.height * 0.45);
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(pinCenter.translate(0, 4), 6, shadowPaint);

    final hubPinPaint = Paint()..color = const Color(0xFF00D2FF);
    canvas.drawCircle(pinCenter, 8, hubPinPaint);

    final hubPinInnerPaint = Paint()..color = const Color(0xFF0284C7);
    canvas.drawCircle(pinCenter, 4, hubPinInnerPaint);
  }

  void _drawText(Canvas canvas, String text, Offset offset) {
    final textSpan = TextSpan(
      text: text,
      style: const TextStyle(
        color: Color(0xFF64748B),
        fontSize: 9,
        fontWeight: FontWeight.w700,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
