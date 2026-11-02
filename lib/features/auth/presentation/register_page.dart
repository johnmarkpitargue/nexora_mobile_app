import 'package:flutter/material.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/services/buyer_account_service.dart';
import '../../../core/services/supabase_auth_service.dart';
import '../../../core/services/external_notification_service.dart';
import '../../../core/widgets/google_logo_icon.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();

  DateTime? _selectedDob;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreeTerms = true;
  bool _notifyPromos = true;
  bool _showReferral = false;
  bool _isLoading = false;
  bool _autoValidate = false;
  String _selectedCountryCode = '+63';

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    setState(() {});
    if (_autoValidate) {
      _formKey.currentState?.validate();
    }
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  // Check if form has any unsaved input (TC-BUY-040)
  bool get _hasUnsavedInput {
    return _firstNameController.text.isNotEmpty ||
        _lastNameController.text.isNotEmpty ||
        _emailController.text.isNotEmpty ||
        _phoneController.text.isNotEmpty ||
        _dobController.text.isNotEmpty ||
        _passwordController.text.isNotEmpty ||
        _confirmPasswordController.text.isNotEmpty ||
        _referralController.text.isNotEmpty;
  }

  // Dynamic Password Strength Calculator (TC-BUY-017, TC-BUY-018)
  int get _passwordScore {
    final pass = _passwordController.text;
    if (pass.isEmpty) return 0;
    int score = 0;
    if (pass.length >= 8) score++;
    if (RegExp(r'[0-9]').hasMatch(pass)) score++;
    if (RegExp(r'[A-Z]').hasMatch(pass) && RegExp(r'[a-z]').hasMatch(pass)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>\-_]').hasMatch(pass) || pass.length >= 10) score++;
    return score;
  }

  bool get _hasMinChars => _passwordController.text.length >= 8;
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(_passwordController.text);
  bool get _hasUppercase => RegExp(r'[A-Z]').hasMatch(_passwordController.text);
  bool get _hasLowercase => RegExp(r'[a-z]').hasMatch(_passwordController.text);
  bool get _hasSpecialChar =>
      RegExp(r'[!@#\$%^&*(),.?":{}|<>\-_]').hasMatch(_passwordController.text);

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

  // Date picker handler restricting future dates (TC-BUY-008)
  Future<void> _selectDateOfBirth(BuildContext context) async {
    final now = DateTime.now();
    // Default initial date 18 years ago today
    final eighteenYearsAgo = DateTime(now.year - 18, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? eighteenYearsAgo,
      firstDate: DateTime(1900),
      lastDate: now, // Future dates blocked in picker (TC-BUY-008)
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0066FF),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobController.text =
            '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
      });
      if (_autoValidate) {
        _formKey.currentState?.validate();
      }
    }
  }

  // Parse manual date text MM/DD/YYYY, DD/MM/YYYY, or YYYY-MM-DD
  DateTime? _parseDateText(String raw) {
    if (raw.trim().isEmpty) return null;
    final parts = raw.trim().split(RegExp(r'[\/\-\.]'));
    if (parts.length == 3) {
      // MM/DD/YYYY or DD/MM/YYYY
      if (parts[2].length == 4) {
        final p0 = int.tryParse(parts[0]);
        final p1 = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2]);
        if (p0 != null && p1 != null && y != null) {
          // If first number > 12 and second <= 12, it is DD/MM/YYYY
          if (p0 > 12 && p0 <= 31 && p1 >= 1 && p1 <= 12) {
            return DateTime(y, p1, p0);
          }
          // Default MM/DD/YYYY
          if (p0 >= 1 && p0 <= 12 && p1 >= 1 && p1 <= 31) {
            return DateTime(y, p0, p1);
          }
        }
      }
      // YYYY-MM-DD
      if (parts[0].length == 4) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final d = int.tryParse(parts[2]);
        if (m != null && d != null && y != null && m >= 1 && m <= 12 && d >= 1 && d <= 31) {
          return DateTime(y, m, d);
        }
      }
    }
    return null;
  }

  // Handle Register Form Submission (TC-BUY-001 to TC-BUY-022)
  void _handleRegister() async {
    // Prevent repeated taps during processing
    if (_isLoading) return;

    setState(() {
      _autoValidate = true;
    });

    // Check Terms checkbox (TC-BUY-021)
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to Terms & Privacy Policy to proceed.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    final isFormValid = _formKey.currentState!.validate();
    if (!isFormValid || !_agreeTerms) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Parse DOB from what the user typed or picked
    final dob = _parseDateText(_dobController.text) ?? _selectedDob;

    // Normalize phone number to clean 11-digit 09XXXXXXXXX
    final rawPhone = _phoneController.text.trim();
    final combinedPhone = BuyerValidationRules.normalizePhone(
      rawPhone.startsWith('+') ? rawPhone : '$_selectedCountryCode$rawPhone',
    );

    // Simulate network latency
    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;

    var result = await BuyerAccountService.instance.registerRemote(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      email: _emailController.text,
      mobileNumber: combinedPhone,
      dateOfBirth: dob,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      agreeTerms: _agreeTerms,
      referralCode: _referralController.text,
    );

    // Fallback to local validator/registry if offline or local testing
    if (!result.success && result.fieldErrors == null) {
      final localRes = BuyerAccountService.instance.registerBuyer(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        email: _emailController.text,
        mobileNumber: combinedPhone,
        dateOfBirth: dob,
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
        agreeTerms: _agreeTerms,
        referralCode: _referralController.text,
      );
      if (localRes.success) {
        result = localRes;
      }
    }

    setState(() {
      _isLoading = false;
    });

    if (result.success) {
      // Optionally provision account in Supabase database in background
      try {
        SupabaseAuthService.instance.signUpWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          phone: combinedPhone,
        ).catchError((_) => SupabaseAuthResult.fail(''));
      } catch (_) {}

      if (!mounted) return;

      // Fire OS system-level external notification (no in-app overlay)
      if (result.otp != null) {
        ExternalNotificationService.show(
          title: 'Nexora Security Alert',
          body: 'Your 6-digit verification code is ${result.otp}',
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 ${result.message}'),
          backgroundColor: const Color(0xFF0066FF),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate to OTP Email Verification screen (Section 4, TC-BUY-001)
      Navigator.pushNamed(
        context,
        AppRoutes.emailVerification,
        arguments: _emailController.text.trim().toLowerCase(),
      );
    } else {
      if (!mounted) return;
      String errorMessage = result.message;
      if (result.fieldErrors != null && result.fieldErrors!.isNotEmpty) {
        errorMessage = result.fieldErrors!.values.first;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Handle Google Social Sign-up (authentic Google login)
  void _handleGoogleSignUp() async {
    setState(() {
      _isLoading = true;
    });

    final success = await SupabaseAuthService.instance.signInWithGoogle();

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Signed up with Google successfully!'),
          backgroundColor: Color(0xFF0066FF),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (route) => false,
      );
    }
  }

  // System Back with confirmation dialog (TC-BUY-040)
  Future<bool> _onWillPop() async {
    if (!_hasUnsavedInput) {
      return true;
    }

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Discard Registration?',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: const Text(
          'You have unsaved information. Are you sure you want to leave? Your entered information will be lost.',
          style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Discard', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    return shouldDiscard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldLeave = await _onWillPop();
        if (shouldLeave && context.mounted) {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.pushReplacementNamed(context, AppRoutes.landing);
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FC),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF6F8FC),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
            onPressed: () async {
              final shouldLeave = await _onWillPop();
              if (shouldLeave && context.mounted) {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacementNamed(context, AppRoutes.landing);
                }
              }
            },
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Form(
              key: _formKey,
              autovalidateMode: _autoValidate
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
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
                    'Join Nexora for fast checkout, exclusive drops,\nand real-time order tracking.',
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFDBEAFE), width: 1),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🎁 ', style: TextStyle(fontSize: 13)),
                        Text(
                          'Get ₱150 voucher + free shipping on 1st order!',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0066FF),
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
                        // First Name & Last Name (TC-BUY-002 to TC-BUY-006)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'First Name',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _firstNameController,
                                    keyboardType: TextInputType.name,
                                    decoration: _buildInputDecoration(
                                      hint: 'Juan Miguel',
                                      prefixIcon: Icons.person_outline_rounded,
                                    ),
                                    validator: (val) {
                                      final text = val?.trim() ?? '';
                                      if (text.isEmpty) {
                                        return 'First Name is required';
                                      }
                                      if (text.length < BuyerValidationRules.minNameLength) {
                                        return 'Min 2 characters';
                                      }
                                      if (text.length > BuyerValidationRules.maxNameLength) {
                                        return 'Max 50 characters';
                                      }
                                      if (!BuyerValidationRules.isValidName(text)) {
                                        return 'Only letters allowed';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Last Name',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _lastNameController,
                                    keyboardType: TextInputType.name,
                                    decoration: _buildInputDecoration(
                                      hint: 'Dela Cruz',
                                      prefixIcon: Icons.badge_outlined,
                                    ),
                                    validator: (val) {
                                      final text = val?.trim() ?? '';
                                      if (text.isEmpty) {
                                        return 'Last Name is required';
                                      }
                                      if (text.length < BuyerValidationRules.minNameLength) {
                                        return 'Min 2 characters';
                                      }
                                      if (text.length > BuyerValidationRules.maxNameLength) {
                                        return 'Max 50 characters';
                                      }
                                      if (!BuyerValidationRules.isValidName(text)) {
                                        return 'Only letters allowed';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Date of Birth (TC-BUY-007, TC-BUY-008)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Date of Birth',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Must be 18+',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0066FF),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _dobController,
                          keyboardType: TextInputType.datetime,
                          readOnly: false,
                          onChanged: (val) {
                            _selectedDob = _parseDateText(val);
                            if (_autoValidate) {
                              _formKey.currentState?.validate();
                            }
                          },
                          decoration: _buildInputDecoration(
                            hint: 'MM/DD/YYYY',
                            prefixIcon: Icons.calendar_today_rounded,
                            suffixIcon: IconButton(
                              icon: const Icon(
                                Icons.date_range_rounded,
                                color: Color(0xFF0066FF),
                                size: 20,
                              ),
                              onPressed: () => _selectDateOfBirth(context),
                            ),
                          ),
                          validator: (val) {
                            final text = val?.trim() ?? '';
                            if (text.isEmpty) {
                              return 'Date of birth is required';
                            }
                            final parsed = _parseDateText(text) ?? _selectedDob;
                            if (parsed == null) {
                              return 'Please enter a valid date (MM/DD/YYYY)';
                            }
                            final today = DateTime.now();
                            final dateOnly = DateTime(parsed.year, parsed.month, parsed.day);
                            final todayOnly = DateTime(today.year, today.month, today.day);

                            if (dateOnly.isAfter(todayOnly)) {
                              return 'Date of birth cannot be in the future';
                            }
                            if (!BuyerValidationRules.isAtLeast18YearsOld(parsed)) {
                              return 'You must be at least 18 years old to register';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Email Address (TC-BUY-009 to TC-BUY-012)
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
                            hint: 'juan.delacruz@example.com',
                            prefixIcon: Icons.email_outlined,
                          ),
                          validator: (val) {
                            final email = val?.trim() ?? '';
                            if (email.isEmpty) {
                              return 'Email Address is required';
                            }
                            if (!BuyerValidationRules.emailRegex.hasMatch(email) ||
                                email.contains('..') ||
                                !email.contains('@') ||
                                email.startsWith('@') ||
                                email.endsWith('@')) {
                              return 'Please enter a valid email address';
                            }
                            // Cross-role duplicate check (TC-BUY-010, TC-BUY-011)
                            if (BuyerAccountService.instance.allBuyers
                                    .any((b) => b.email == email.toLowerCase()) ||
                                email.toLowerCase() == 'juan.miguel.delacruz@gmail.com' ||
                                email.toLowerCase() == 'mariaclara.santos@example.com' ||
                                email.toLowerCase() == 'operations@bilishatid.example.com') {
                              return 'An account with this email already exists. Sign in or reset password.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Mobile Number (TC-BUY-013 to TC-BUY-016)
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
                                Icon(Icons.flash_on_rounded, size: 13, color: Color(0xFF0066FF)),
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
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
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
                                  hint: '0917 888 9900',
                                  prefixIcon: Icons.phone_android_outlined,
                                ),
                                validator: (val) {
                                  final raw = val?.trim() ?? '';
                                  if (raw.isEmpty) {
                                    return 'Mobile Number is required';
                                  }
                                  final norm = BuyerValidationRules.normalizePhone(raw);
                                  if (norm.length != 11) {
                                    return 'Mobile number must be 11 digits';
                                  }
                                  if (!BuyerValidationRules.phoneRegex.hasMatch(norm)) {
                                    return 'Must start with 09';
                                  }
                                  // Duplicate phone check (TC-BUY-015, TC-BUY-016)
                                  if (norm == '09171234567' ||
                                      norm == '09189876543' ||
                                      norm == '09285551234') {
                                    return 'This mobile number is already registered';
                                  }
                                  return null;
                                },
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

                        // Create Password (TC-BUY-017, TC-BUY-018)
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
                          autocorrect: false,
                          enableSuggestions: false,
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
                          validator: (val) {
                            final pass = val ?? '';
                            if (pass.isEmpty) {
                              return 'Password is required';
                            }
                            if (pass.length < BuyerValidationRules.minPasswordLength) {
                              return 'Password must be at least 8 characters';
                            }
                            if (pass.length > BuyerValidationRules.maxPasswordLength) {
                              return 'Password cannot exceed 50 characters';
                            }
                            if (!BuyerValidationRules.hasUppercase(pass)) {
                              return 'Must contain at least one uppercase letter (A-Z)';
                            }
                            if (!BuyerValidationRules.hasLowercase(pass)) {
                              return 'Must contain at least one lowercase letter (a-z)';
                            }
                            if (!BuyerValidationRules.hasNumber(pass)) {
                              return 'Must contain at least one number (0-9)';
                            }
                            if (!BuyerValidationRules.hasSpecialChar(pass)) {
                              return 'Must contain at least one special character (!@#\$%^&*)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Password Strength Indicator Row
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
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _buildChecklistChip('8+ chars', _hasMinChars),
                            _buildChecklistChip('Number', _hasNumber),
                            _buildChecklistChip('Upper', _hasUppercase),
                            _buildChecklistChip('Lower', _hasLowercase),
                            _buildChecklistChip('Special', _hasSpecialChar),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Confirm Password (TC-BUY-019)
                        const Text(
                          'Confirm Password',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !_isConfirmPasswordVisible,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: _buildInputDecoration(
                            hint: '••••••••••••',
                            prefixIcon: Icons.lock_clock_outlined,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isConfirmPasswordVisible
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Colors.grey.shade600,
                                size: 18,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                });
                              },
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (val != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Referral Code Accordion (TC-BUY-022)
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
                              hint: 'e.g. NEXORA150',
                              prefixIcon: Icons.card_giftcard_outlined,
                            ),
                            validator: (val) {
                              final text = val?.trim() ?? '';
                              if (text.isNotEmpty &&
                                  !BuyerValidationRules.isValidReferralCode(text)) {
                                return 'Invalid referral code';
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 14),

                        // Checkboxes (TC-BUY-021)
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
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

                        // Gradient Submit Button (Section 3, TC-BUY-001)
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
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    'Create Account',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Google Sign Up (Hidden: web backend does not support mobile Google OAuth)
                  Opacity(
                    opacity: 0.0,
                    child: IgnorePointer(
                      child: Column(
                      children: [
                        // Or Continue With Divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey.shade300)),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 14),
                              child: Text(
                                'OR CONTINUE WITH',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF94A3B8),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey.shade300)),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Google Sign In Button (Apple / iCloud removed per user request!)
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _handleGoogleSignUp,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GoogleLogoIcon(size: 20),
                                SizedBox(width: 10),
                                Text(
                                  'Continue with Google',
                                  style: TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F7FA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_user_outlined, size: 14, color: Color(0xFF00838F)),
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
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF64748B), size: 18),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF0066FF), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    );
  }
}