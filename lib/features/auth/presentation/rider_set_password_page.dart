import 'package:flutter/material.dart';
import '../../../core/services/rider_account_service.dart';
import 'rider_login_page.dart';

class RiderSetPasswordPage extends StatefulWidget {
  final String activationToken;
  final DateTime? simulatedCurrentTime; // For testing expired link (TC-RID-023)

  const RiderSetPasswordPage({
    super.key,
    required this.activationToken,
    this.simulatedCurrentTime,
  });

  @override
  State<RiderSetPasswordPage> createState() => _RiderSetPasswordPageState();
}

class _RiderSetPasswordPageState extends State<RiderSetPasswordPage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;

  String? _passwordError;
  String? _confirmError;
  String? _globalError;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    setState(() {
      _passwordError = null;
      _globalError = null;
    });
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Live password checklist rules (A5)
  bool get _hasMin8 => _passwordController.text.length >= 8;
  bool get _hasUpper => RegExp(r'[A-Z]').hasMatch(_passwordController.text);
  bool get _hasLower => RegExp(r'[a-z]').hasMatch(_passwordController.text);
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(_passwordController.text);
  bool get _hasSpecial => RegExp(r'[!@#\$%^&*(),.?":{}|<>\-_]').hasMatch(_passwordController.text);

  void _handleActivate() async {
    if (_isSubmitting) return;

    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    setState(() {
      _passwordError = null;
      _confirmError = null;
      _globalError = null;
    });

    // Check link validity first (TC-RID-023, TC-RID-025)
    final rider = RiderAccountService.instance.findRiderByToken(widget.activationToken);
    if (rider == null) {
      setState(() {
        _globalError = 'This activation link is invalid or has already been used.';
      });
      return;
    }

    if (rider.isTokenUsed || rider.accountStatus == 'Active') {
      setState(() {
        _globalError = 'This activation link is invalid or has already been used.';
      });
      return;
    }

    final now = widget.simulatedCurrentTime ?? DateTime.now();
    if (rider.tokenExpiresAt != null && now.isAfter(rider.tokenExpiresAt!)) {
      setState(() {
        _globalError = 'This activation link has expired. Please ask your logistics provider to resend the activation email.';
      });
      return;
    }

    // Validate password rules (A5, TC-RID-021)
    if (!RiderValidationRules.isValidPassword(password)) {
      setState(() {
        _passwordError =
            'Password must be at least 8 characters with at least one uppercase letter, one lowercase letter, one number, and one special character.';
      });
      return;
    }

    // Validate confirm password match (A5, TC-RID-022)
    if (password != confirm) {
      setState(() {
        _confirmError = 'Confirm Password does not match.';
      });
      return;
    }

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 600));

    final result = RiderAccountService.instance.activateAccount(
      token: widget.activationToken,
      password: password,
      confirmPassword: confirm,
      testCurrentTime: widget.simulatedCurrentTime,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text('Account activated successfully! You may now log in with your password.'),
              ),
            ],
          ),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 4),
        ),
      );

      // Navigate to Rider Login (TC-RID-020)
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => RiderLoginPage(
            initialEmail: rider.email,
            activationSuccessMessage:
                'Welcome, ${rider.fullName}! Your account has been activated under ${rider.companyName}.',
          ),
        ),
        (route) => false,
      );
    } else {
      setState(() {
        _globalError = result.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check initial token status for view rendering
    final rider = RiderAccountService.instance.findRiderByToken(widget.activationToken);
    final now = widget.simulatedCurrentTime ?? DateTime.now();
    final isExpired = rider != null && rider.tokenExpiresAt != null && now.isAfter(rider.tokenExpiresAt!);
    final isUsedOrInvalid = rider == null || rider.isTokenUsed || rider.accountStatus == 'Active';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Activate Rider Account',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_reset_rounded, size: 14, color: Color(0xFF0284C7)),
                    SizedBox(width: 4),
                    Text(
                      'STEP 2: SET PASSWORD',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0284C7),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              const Text(
                'Set Your Account Password',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                rider != null
                    ? 'Welcome, ${rider.fullName}! Create your secure password to complete activation for ${rider.companyName}.'
                    : 'Activate your new Nexora delivery rider fleet account.',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
              ),
              const SizedBox(height: 20),

              // Expired Link Banner (TC-RID-023)
              if (isExpired || (_globalError != null && _globalError!.contains('expired'))) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.timer_off_outlined, color: Color(0xFFDC2626), size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Activation Link Expired',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF991B1B),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Text(
                        'This activation link has expired. Activation links are valid for 24 hours. Please ask your logistics provider to resend the activation email.',
                        style: TextStyle(fontSize: 12.5, height: 1.4, color: Color(0xFF7F1D1D)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ] else if (isUsedOrInvalid || (_globalError != null && _globalError!.contains('invalid'))) ...[
                // Invalid or already used link banner (TC-RID-025)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFCD34D)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.link_off_rounded, color: Color(0xFFD97706), size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Invalid or Already Used Link',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Text(
                        'This activation link is invalid or has already been used. If your account is already active, please proceed to log in.',
                        style: TextStyle(fontSize: 12.5, height: 1.4, color: Color(0xFF78350F)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Main Password Form Container
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Password Field (M2, TC-RID-033: no autocorrect or suggestions)
                    const Text(
                      'New Password *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      autocorrect: false, // TC-RID-033
                      enableSuggestions: false, // TC-RID-033
                      decoration: InputDecoration(
                        hintText: 'e.g. Rider@2026',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 18,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        errorText: _passwordError,
                        errorMaxLines: 3,
                        errorStyle: const TextStyle(fontSize: 11, color: Color(0xFFEF4444)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: _passwordError != null
                              ? const BorderSide(color: Color(0xFFEF4444), width: 1.5)
                              : BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Confirm Password Field
                    const Text(
                      'Confirm Password *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      autocorrect: false, // TC-RID-033
                      enableSuggestions: false, // TC-RID-033
                      decoration: InputDecoration(
                        hintText: 'Re-enter your password',
                        prefixIcon: const Icon(Icons.lock_clock_outlined, size: 18),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 18,
                          ),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        errorText: _confirmError,
                        errorStyle: const TextStyle(fontSize: 11, color: Color(0xFFEF4444)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: _confirmError != null
                              ? const BorderSide(color: Color(0xFFEF4444), width: 1.5)
                              : BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onChanged: (_) {
                        if (_confirmError != null) {
                          setState(() => _confirmError = null);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Rules Checklist Display (A5)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Password Requirement Checklist (A5):',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                          ),
                          const SizedBox(height: 6),
                          _buildRuleCheckItem('At least 8 characters long', _hasMin8),
                          _buildRuleCheckItem('At least 1 uppercase letter (A-Z)', _hasUpper),
                          _buildRuleCheckItem('At least 1 lowercase letter (a-z)', _hasLower),
                          _buildRuleCheckItem('At least 1 numeric digit (0-9)', _hasNumber),
                          _buildRuleCheckItem('At least 1 special character (!@#\$%^&*)', _hasSpecial),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Activate Button
                    ElevatedButton(
                      onPressed: (isExpired || isUsedOrInvalid || _isSubmitting) ? null : _handleActivate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFBAE6FD),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                      child: _isSubmitting
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Activating Account...'),
                              ],
                            )
                          : const Text(
                              'Activate Account',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                            ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              // Support footer
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const RiderLoginPage()),
                    );
                  },
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Back to Rider Log In', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRuleCheckItem(String label, bool passed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 14,
            color: passed ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: passed ? FontWeight.bold : FontWeight.normal,
              color: passed ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
