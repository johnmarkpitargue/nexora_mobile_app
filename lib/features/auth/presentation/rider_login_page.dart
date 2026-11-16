import 'package:flutter/material.dart';

import '../../../core/services/rider_account_service.dart';
import '../../shell/presentation/rider_shell.dart';
import '../../transfer_courier/presentation/transfer_courier_shell.dart';

class RiderLoginPage extends StatefulWidget {
  final String? initialEmail;
  final String? activationSuccessMessage;

  const RiderLoginPage({
    super.key,
    this.initialEmail,
    this.activationSuccessMessage,
  });

  @override
  State<RiderLoginPage> createState() => _RiderLoginPageState();
}

class _RiderLoginPageState extends State<RiderLoginPage> {
  late final TextEditingController _identifierController;
  late final TextEditingController _passwordController;

  bool _obscurePassword = true;
  bool _rememberDevice = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _identifierController = TextEditingController(
      text: widget.initialEmail ?? '',
    );
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    if (identifier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter your registered email address or mobile number',
          ),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your account password or security PIN'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Authenticate via unified Laravel backend (/api/mobile/v1/auth/rider/login)
    final accountResult = await RiderAccountService.instance.loginRemote(
      email: identifier,
      password: password,
      rememberDevice: _rememberDevice,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (accountResult.success) {
      final role = RiderAccountService.instance.currentUserRole;
      final fullName = accountResult.rider?.fullName.trim().isNotEmpty == true
          ? accountResult.rider!.fullName
          : (role == 'courier' ? 'Transfer Courier' : 'Rider');
      final company = accountResult.rider?.companyName ?? 'Logistics Partner';

      if (role == 'courier') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Welcome back, $fullName! Transfer Courier dashboard loaded for $company.',
            ),
            backgroundColor: const Color(0xFF0066FF),
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (ctx) => const TransferCourierShell()),
          (route) => false,
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Welcome back, $fullName! Daily dispatch route loaded for $company.',
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (ctx) => const RiderShell()),
        (route) => false,
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(accountResult.message),
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
  }

  void _showForgotPasswordOrPinDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_reset_rounded, color: Color(0xFF0066FF), size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Password Reset Unavailable',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        content: const Text(
          'Self-service password reset is not available in the mobile app.\n\nPlease contact your logistics company administrator or use the Nexora web portal to reset your password.',
          style: TextStyle(
            fontSize: 13,
            height: 1.45,
            color: Color(0xFF475569),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('OK'),
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
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 18,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 0. Activation Success Banner
              if (widget.activationSuccessMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF15803D),
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.activationSuccessMessage!,
                          style: const TextStyle(
                            color: Color(0xFF14532D),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // 1. Official Rider Brand Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0066FF)
                              .withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(5),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0066FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              'N',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Nexora',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                            ),
                            SizedBox(width: 5),
                            Text(
                              'RIDER',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0066FF),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 1),
                        Text(
                          'Courier & Fleet Dispatch Portal',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

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
                'Sign in with your registered email or mobile number to access your daily routes and delivery tasks.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              // 3. Form Field 1: Email or Mobile Number (Single Unified Field)
              const Text(
                'EMAIL OR MOBILE NUMBER',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF475569),
                  letterSpacing: 0.4,
                ),
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
                  controller: _identifierController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: 0.3,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter your email or mobile number',
                    hintStyle: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8),
                    ),
                    prefixIcon: const Icon(
                      Icons.person_outline_rounded,
                      color: Color(0xFF64748B),
                      size: 20,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(
                        Icons.cancel_rounded,
                        color: Color(0xFF94A3B8),
                        size: 18,
                      ),
                      onPressed: () => _identifierController.clear(),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'You can use your registered rider email (e.g. name@domain.com) or PH mobile (+63 9XX...)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),

              // 4. Form Field 2: Password or Security PIN
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Text(
                      'PASSWORD OR SECURITY PIN',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF475569),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _showForgotPasswordOrPinDialog,
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0066FF),
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
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  autocorrect: false,
                  enableSuggestions: false,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter your password or 6-digit PIN',
                    hintStyle: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0,
                      color: Color(0xFF94A3B8),
                    ),
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: Color(0xFF64748B),
                      size: 20,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: const Color(0xFF64748B),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Enter your account password or 6-digit dispatch security PIN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 18),

              // 5. Checkbox Row: Remember Device + Auto-login 30d
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
                      activeColor: const Color(0xFF0066FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Flexible(
                    child: Text(
                      'Remember device',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
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
                        color: Color(0xFF0066FF),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // 6. Clean Static Primary Login Button
              _buildLoginButton(),
              const SizedBox(height: 36),

              // 7. Security Footer
              _buildSecurityFooter(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0066FF), // Electric Cyan
            Color(0xFF0066FF), // Sky Blue
            Color(0xFF0369A1), // Deep Ocean
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0066FF).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                    color: Color(0xFF0066FF),
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
                Flexible(
                  child: Text(
                    'Nexora Fleet Access • 256–Bit SSL Encrypted',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0066FF),
                    ),
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
