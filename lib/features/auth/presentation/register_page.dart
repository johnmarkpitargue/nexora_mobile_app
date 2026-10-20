import 'package:flutter/material.dart';
import '../../../app/routes/app_routes.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController =
      TextEditingController();
  final TextEditingController _emailController =
      TextEditingController();
  final TextEditingController _phoneController =
      TextEditingController();
  final TextEditingController _passwordController =
      TextEditingController();
  final TextEditingController _referralController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _agreeTerms = true;
  bool _notifyPromos = true;
  bool _showReferral = false;
  bool _isLoading = false;
  String _selectedCountryCode = '+63';

  @override
  void initState() {
    super.initState();
    // Real-time listener for live password strength status updating as user types
    _passwordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  // Dynamic Password Strength Calculator
  int get _passwordScore {
    final pass = _passwordController.text;
    if (pass.isEmpty) return 0;
    int score = 0;
    if (pass.length >= 8) score++;
    if (RegExp(r'[0-9]').hasMatch(pass)) score++;
    if (RegExp(r'[A-Z]').hasMatch(pass)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(pass) || pass.length >= 10) score++;
    return score;
  }

  bool get _hasMinChars => _passwordController.text.length >= 8;
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(_passwordController.text);
  bool get _hasUppercase => RegExp(r'[A-Z]').hasMatch(_passwordController.text);

  String get _strengthLabel {
    final score = _passwordScore;
    if (_passwordController.text.isEmpty) return 'Enter password';
    switch (score) {
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return 'Too Short';
    }
  }

  Color get _strengthColor {
    final score = _passwordScore;
    if (_passwordController.text.isEmpty) return Colors.grey;
    switch (score) {
      case 1:
        return const Color(0xFFEF4444); // Red
      case 2:
        return const Color(0xFFF59E0B); // Amber
      case 3:
        return const Color(0xFF0066FF); // Electric Blue
      case 4:
        return const Color(0xFF00D2FF); // Electric Cyan
      default:
        return Colors.grey;
    }
  }

  void _handleRegister() {
    if (_formKey.currentState!.validate()) {
      if (!_agreeTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please agree to Terms & Privacy Policy.')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Account created! ₱150 voucher claimed!'),
            backgroundColor: Color(0xFF0066FF),
          ),
        );
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      });
    }
  }

  void _handleSocialSignUp(String provider) async {
    setState(() {
      _isLoading = true;
    });
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Signed up with $provider successfully!'),
        backgroundColor: const Color(0xFF0066FF),
      ),
    );
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F8FC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, AppRoutes.landing);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Application Logo
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0066FF).withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 76,
                      height: 76,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.shopping_bag_rounded,
                        size: 38,
                        color: Color(0xFF0066FF),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header Title & Subtitle
                const Text(
                  'Create Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Unlock VIP perks, lightning-fast checkout,\nand live courier tracking.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),

                // Voucher Promo Banner Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F7FA),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFB2EBF2)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🎁 ', style: TextStyle(fontSize: 14)),
                      Text(
                        'Get ₱150 voucher + free shipping on 1st order!',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00838F),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Auth Switcher Segmented Control
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEECFF),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushReplacementNamed(context, AppRoutes.login);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: const Text(
                              'Sign In',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Text(
                            'Create Account',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0066FF),
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Form Container Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Full Name
                      const Text(
                        'Full Name',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        decoration: _buildInputDecoration(
                          hint: 'Alex Rivera',
                          prefixIcon: Icons.person_outline_rounded,
                        ),
                        validator: (val) => val == null || val.isEmpty
                            ? 'Please enter your full name'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // Email Address
                      const Text(
                        'Email Address',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _buildInputDecoration(
                          hint: 'alex@lumina.com',
                          prefixIcon: Icons.email_outlined,
                        ),
                        validator: (val) =>
                            val == null || val.isEmpty || !val.contains('@')
                                ? 'Please enter a valid email'
                                : null,
                      ),
                      const SizedBox(height: 14),

                      // Mobile Number
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Mobile Number',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const Row(
                            children: [
                              Icon(Icons.flash_on_rounded,
                                  size: 13, color: Color(0xFF0066FF)),
                              SizedBox(width: 2),
                              Text(
                                'Instant SMS OTP',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0066FF),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          // Country Code Dropdown
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCountryCode,
                                isDense: true,
                                items: const [
                                  DropdownMenuItem(
                                    value: '+63',
                                    child: Text(
                                      'PH +63',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: '+1',
                                    child: Text('US +1'),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedCountryCode = val;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: _buildInputDecoration(
                                hint: '917 123 4567',
                                prefixIcon: Icons.phone_android_outlined,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Used for live rider arrival alerts and instant verification.',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Create Password
                      const Text(
                        'Create Password',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: _buildInputDecoration(
                          hint: '••••••••••••',
                          prefixIcon: Icons.lock_outline_rounded,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.grey.shade600,
                              size: 18,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Password Strength Indicator Row (Updates Live as user types!)
                      Row(
                        children: [
                          const Text(
                            'Password Strength',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 13,
                                color: _strengthColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _strengthLabel,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: _strengthColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // 4-Segment Strength Progress Bar
                      Row(
                        children: List.generate(4, (index) {
                          final isFilled = index < _passwordScore;
                          return Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 4,
                              margin: EdgeInsets.only(right: index < 3 ? 4 : 0),
                              decoration: BoxDecoration(
                                color: isFilled ? _strengthColor : const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 10),

                      // Strength Checklist Chips
                      Row(
                        children: [
                          _buildChecklistChip('8+ chars', _hasMinChars),
                          const SizedBox(width: 8),
                          _buildChecklistChip('Number', _hasNumber),
                          const SizedBox(width: 8),
                          _buildChecklistChip('Uppercase', _hasUppercase),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Referral Code Accordion
                      InkWell(
                        onTap: () {
                          setState(() {
                            _showReferral = !_showReferral;
                          });
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.local_offer_outlined,
                                size: 16, color: Color(0xFF0066FF)),
                            const SizedBox(width: 6),
                            const Text(
                              'Have a referral code? (Optional)',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0066FF),
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              _showReferral
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: const Color(0xFF0066FF),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                      if (_showReferral) ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _referralController,
                          decoration: _buildInputDecoration(
                            hint: 'Enter referral code',
                            prefixIcon: Icons.card_giftcard_outlined,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),

                      // Checkboxes
                      InkWell(
                        onTap: () {
                          setState(() {
                            _agreeTerms = !_agreeTerms;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _agreeTerms,
                                  onChanged: (val) {
                                    setState(() {
                                      _agreeTerms = val ?? true;
                                    });
                                  },
                                  activeColor: const Color(0xFF0066FF),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: RichText(
                                  text: const TextSpan(
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF1E293B),
                                      height: 1.3,
                                    ),
                                    children: [
                                      TextSpan(text: "I agree to Nexora's "),
                                      TextSpan(
                                        text: "Terms of Service",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                          color: Color(0xFF0066FF),
                                        ),
                                      ),
                                      TextSpan(text: " & "),
                                      TextSpan(
                                        text: "Privacy Policy",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                          color: Color(0xFF0066FF),
                                        ),
                                      ),
                                      TextSpan(text: "."),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _notifyPromos = !_notifyPromos;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _notifyPromos,
                                  onChanged: (val) {
                                    setState(() {
                                      _notifyPromos = val ?? true;
                                    });
                                  },
                                  activeColor: const Color(0xFF0066FF),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Notify me about secret flash drops and real-time parcel dispatch via SMS/Email.',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF64748B),
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Gradient Submit Button
                      Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00D2FF), Color(0xFF0066FF)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0066FF).withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Create Account & Claim Voucher',
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward_rounded,
                                        size: 18, color: Colors.white),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Divider Or sign up with
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Or sign up with',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),
                const SizedBox(height: 16),

                // Social Sign In Buttons (Google & Apple)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => _handleSocialSignUp('Google'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.white,
                          side: BorderSide(color: Colors.grey.shade200),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'G',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => _handleSocialSignUp('Apple'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.white,
                          side: BorderSide(color: Colors.grey.shade200),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.apple, color: Colors.black, size: 22),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Already have an account? Sign In
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(context, AppRoutes.login);
                      },
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: Color(0xFF0066FF),
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Security Footer Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F7FA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_user_outlined,
                          size: 14, color: Color(0xFF00838F)),
                      SizedBox(width: 6),
                      Text(
                        '256-Bit SSL Encrypted • Data Privacy Compliant',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF00838F),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistChip(String label, bool isSatisfied) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSatisfied ? const Color(0xFFE0F7FA) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            size: 12,
            color: isSatisfied ? const Color(0xFF00838F) : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: isSatisfied ? const Color(0xFF00838F) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF64748B), size: 18),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}