import 'package:flutter/material.dart';
import '../../../core/services/rider_service.dart';
import '../../shell/presentation/rider_shell.dart';

class RiderLoginPage extends StatefulWidget {
  const RiderLoginPage({super.key});

  @override
  State<RiderLoginPage> createState() => _RiderLoginPageState();
}

class _RiderLoginPageState extends State<RiderLoginPage>
    with SingleTickerProviderStateMixin {
  int _selectedTab = 1; // 0: Mobile Number, 1: Rider ID (per design)
  final TextEditingController _idController =
      TextEditingController(text: 'NX-9104-RDR');
  final TextEditingController _phoneController =
      TextEditingController(text: '+63 917 123 4567');
  final TextEditingController _pinController =
      TextEditingController(text: '123456');

  bool _obscurePin = true;
  bool _rememberDevice = true;
  bool _isLoading = false;

  late final AnimationController _shimmerController;
  late final Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _shimmerAnim = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _idController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final identifier = _selectedTab == 1
        ? _idController.text.trim()
        : _phoneController.text.trim();
    final pin = _pinController.text.trim();

    if (identifier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_selectedTab == 1
              ? 'Please enter your Rider ID or Fleet Badge'
              : 'Please enter your registered mobile number'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    if (pin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your 6-digit Security PIN'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    setState(() => _isLoading = false);

    // Switch session to Rider 1 (Pedro Jose Garcia) or matched ID
    RiderService.instance.switchRider('NX-RD-001');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Welcome back, Pedro! Daily dispatch route loaded.'),
        backgroundColor: Color(0xFF10B981),
      ),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (ctx) => const RiderShell()),
      (route) => false,
    );
  }

  void _showWhereToFindDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.badge_rounded, color: Color(0xFF0284C7), size: 24),
            SizedBox(width: 8),
            Text(
              'Rider ID / Fleet Badge',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        content: const Text(
          'Your Rider ID is provided upon verification by your Pasig Hub Dispatch supervisor.\n\nIt begins with "NX-" or "RDR-" (e.g. NX-9104-RDR or NX-RD-001) and is printed on your physical fleet ID card and digital onboarding clearance.',
          style: TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Understood',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _showForgotPinDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_reset_rounded, color: Color(0xFF0284C7), size: 24),
            SizedBox(width: 8),
            Text(
              'Reset Security PIN',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        content: const Text(
          'A 6-digit OTP reset token will be sent to your verified mobile number and GCash-linked contact.\n\nPlease ensure your device is able to receive SMS dispatch pings.',
          style: TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('OTP reset token sent to your registered mobile!'),
                  backgroundColor: Color(0xFF0284C7),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Send Reset OTP'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Center(
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              margin: const EdgeInsets.only(left: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  size: 18, color: Color(0xFF0F172A)),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Pill: NEXORA RIDER • FLEET ACCESS
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00D2FF),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'NEXORA RIDER • FLEET ACCESS',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0284C7),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 2. Title & Subtitle
              const Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Sign in to access your daily routes and delivery tasks.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),

              // 3. Dual Tab Selector (Mobile Number | Rider ID)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _tabPill(
                        index: 0,
                        icon: Icons.phone_android_rounded,
                        label: 'Mobile Number',
                      ),
                    ),
                    Expanded(
                      child: _tabPill(
                        index: 1,
                        icon: Icons.badge_outlined,
                        label: 'Rider ID',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 4. Form Field 1: Rider ID or Mobile Number
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedTab == 1 ? 'RIDER ID / FLEET BADGE' : 'REGISTERED MOBILE',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF475569),
                      letterSpacing: 0.4,
                    ),
                  ),
                  if (_selectedTab == 1)
                    GestureDetector(
                      onTap: _showWhereToFindDialog,
                      child: const Text(
                        'Where to find?',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller:
                      _selectedTab == 1 ? _idController : _phoneController,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: 0.5,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      _selectedTab == 1
                          ? Icons.badge_outlined
                          : Icons.phone_iphone_rounded,
                      color: const Color(0xFF64748B),
                      size: 20,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.cancel_rounded,
                          color: Color(0xFF94A3B8), size: 18),
                      onPressed: () {
                        if (_selectedTab == 1) {
                          _idController.clear();
                        } else {
                          _phoneController.clear();
                        }
                      },
                    ),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Assigned by your Hub Dispatch supervisor (starts with NX or RDR)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 18),

              // 5. Form Field 2: Security PIN / Password
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'SECURITY PIN / PASSWORD',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF475569),
                      letterSpacing: 0.4,
                    ),
                  ),
                  GestureDetector(
                    onTap: _showForgotPinDialog,
                    child: const Text(
                      'Forgot PIN?',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _pinController,
                  obscureText: _obscurePin,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4.0,
                    color: Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: Color(0xFF64748B),
                      size: 20,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePin
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: const Color(0xFF64748B),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() => _obscurePin = !_obscurePin);
                      },
                    ),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 6. Checkbox Row: Remember Device + Auto-login 30d
              Row(
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Checkbox(
                      value: _rememberDevice,
                      onChanged: (val) {
                        setState(() => _rememberDevice = val ?? true);
                      },
                      activeColor: const Color(0xFF0284C7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Remember device',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE0F2FE)),
                    ),
                    child: const Text(
                      'Auto-login 30d',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 7. Animated Primary Login Button
              _buildAnimatedLoginButton(),
              const SizedBox(height: 36),

              // 8. 3-Tier Dispatch Security Footer
              _buildSecurityFooter(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabPill({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedTab == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? const Color(0xFF0284C7)
                  : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                color: isSelected
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedLoginButton() {
    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: const [
                Color(0xFF00D2FF), // Cyan
                Color(0xFF0284C7), // Sky Blue
                Color(0xFF0369A1), // Deep Ocean
              ],
              begin: Alignment(-1.0 + _shimmerAnim.value, 0.0),
              end: Alignment(1.0 + _shimmerAnim.value, 0.0),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00D2FF).withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'LOG IN',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildSecurityFooter() {
    return Column(
      children: [
        Center(
          child: RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              text: 'Need help? Call Pasig Hub Dispatch ',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
              children: [
                TextSpan(
                  text: '📞 (02) 8888–RIDE',
                  style: TextStyle(
                    color: Color(0xFF0284C7),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE0F2FE)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🔒', style: TextStyle(fontSize: 12)),
                SizedBox(width: 6),
                Text(
                  'Nexora Fleet Access • 256–Bit SSL Encrypted',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0284C7),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        Center(
          child: RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              text: 'Nexora Logistics Philippines • ',
              style: TextStyle(
                fontSize: 10.5,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
              children: [
                TextSpan(
                  text: 'Terms & Privacy',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
