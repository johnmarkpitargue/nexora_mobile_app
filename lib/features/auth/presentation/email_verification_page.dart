import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/services/buyer_account_service.dart';
import '../../../core/services/supabase_auth_service.dart';
import '../../../core/services/profile_service.dart';
import '../../../core/services/external_notification_service.dart';
import '../../../core/services/in_app_notification_service.dart';

class EmailVerificationPage extends StatefulWidget {
  final String? email;
  final bool isLoginMode;

  const EmailVerificationPage({
    super.key,
    this.email,
    this.isLoginMode = false,
  });

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  Timer? _timer;
  StreamSubscription<AuthState>? _authSub;
  int _secondsRemaining = 300; // 5 minutes default (Section 4)
  int _resendCooldown = 60; // 60s cooldown for resend button
  bool _isLoading = false;
  String? _errorMessage;
  late String _userEmail;

  @override
  void initState() {
    super.initState();
    final service = BuyerAccountService.instance;
    _userEmail = widget.email ??
        service.currentUnverifiedBuyer?.email ??
        'juanmiguel.delacruz@example.com';

    _syncTimerWithExpiration();
    _startCountdown();

    // Ensure any in-app notification banner is completely dismissed
    InAppNotificationService.instance.dismiss();

    // Fire OS system-level notification (external notification)
    final currentBuyer = widget.isLoginMode
        ? service.findBuyerByIdentifier(_userEmail)
        : service.currentUnverifiedBuyer;
    final activeOtp = currentBuyer?.otpCode;
    if (activeOtp != null) {
      ExternalNotificationService.show(
        title: 'Nexora Security Alert',
        body: 'Your 6-digit verification code is $activeOtp',
      );
    }



    // Listen for email confirmation link click (deep link from Gmail)
    if (SupabaseAuthService.instance.isSupabaseConfigured) {
      _authSub = SupabaseAuthService.instance.authStateChanges.listen((data) {
        if (!mounted) return;
        final event = data.event;
        if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.userUpdated) {
          final buyer = service.findBuyerByIdentifier(_userEmail) ??
              service.currentUnverifiedBuyer;
          if (buyer != null) {
            buyer.accountStatus = 'Active';
          }
          ProfileService.instance.updateProfile(
            name: buyer?.fullName ?? 'Nexora Shopper',
            email: _userEmail,
            phone: buyer?.mobileNumber ?? '',
          );
          ProfileService.instance.updateWalletBalance(150.0);
          _showVoucherClaimModal();
        }
      });
    }
  }

  void _syncTimerWithExpiration() {
    final buyer = widget.isLoginMode
        ? BuyerAccountService.instance.findBuyerByIdentifier(_userEmail)
        : BuyerAccountService.instance.currentUnverifiedBuyer;
    if (buyer != null) {
      final diff = buyer.otpExpiresAt.difference(DateTime.now()).inSeconds;
      _secondsRemaining = diff > 0 ? diff : 0;
    } else {
      _secondsRemaining = 300;
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        // Compute from absolute expiration for accurate tracking when switching apps (TC-BUY-039)
        final buyer = widget.isLoginMode
            ? BuyerAccountService.instance.findBuyerByIdentifier(_userEmail)
            : BuyerAccountService.instance.currentUnverifiedBuyer;
        if (buyer != null) {
          final diff = buyer.otpExpiresAt.difference(DateTime.now()).inSeconds;
          _secondsRemaining = diff > 0 ? diff : 0;
        } else {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          }
        }

        if (_resendCooldown > 0) {
          _resendCooldown--;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _authSub?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otpValue => _controllers.map((c) => c.text).join();

  String get _formattedTime {
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Handle automatic distribution of pasted 6-digit text (TC-BUY-038)
  void _handlePastedText(String text) {
    final cleaned = text.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length >= 6) {
      for (int i = 0; i < 6; i++) {
        _controllers[i].text = cleaned[i];
      }
      _focusNodes[5].requestFocus();
      setState(() {
        _errorMessage = null;
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      _handlePastedText(data.text!);
    }
  }

  void _handleVerify() async {
    final code = _otpValue;

    if (code.length < 6) {
      setState(() {
        _errorMessage = 'Please enter all 6 digits of the verification code.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Check remote Supabase verification in parallel with local session
    final supabaseVerified = await SupabaseAuthService.instance.verifyEmailOtp(
      email: _userEmail,
      token: code,
    );

    if (!mounted) return;

    var result = widget.isLoginMode
        ? BuyerAccountService.instance.verifyLoginOtp(
            emailOrPhone: _userEmail,
            inputOtp: code,
          )
        : BuyerAccountService.instance.verifyOtp(
            email: _userEmail,
            inputOtp: code,
          );

    // If Supabase verified the Gmail OTP successfully, ensure local session is activated too
    if (supabaseVerified && !result.success) {
      final buyer = BuyerAccountService.instance.findBuyerByIdentifier(_userEmail) ??
          BuyerAccountService.instance.currentUnverifiedBuyer;
      if (buyer != null) {
        buyer.otpCode = code;
        buyer.otpExpiresAt = DateTime.now().add(const Duration(minutes: 5));
        buyer.otpAttemptsRemaining = 3;
        result = BuyerAccountService.instance.verifyOtp(
          email: _userEmail,
          inputOtp: code,
        );
      }
    }

    setState(() {
      _isLoading = false;
    });

    if (result.success) {
      if (widget.isLoginMode) {
        if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: const Color(0xFF0066FF),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (route) => false,
        );
        return;
      }

      // Sync with profile service
      if (result.buyer != null) {
        ProfileService.instance.updateProfile(
          name: result.buyer!.fullName,
          email: result.buyer!.email,
          phone: result.buyer!.mobileNumber,
        );
        ProfileService.instance.updateWalletBalance(150.0);
      }

      // Show celebratory voucher claim modal (TC-BUY-028, TC-BUY-029)
      _showVoucherClaimModal();
    } else {
      setState(() {
        _errorMessage = result.message;
      });
    }
  }

  void _handleResend() async {
    if (_resendCooldown > 0) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final result = widget.isLoginMode
        ? BuyerAccountService.instance.sendLoginOtp(emailOrPhone: _userEmail)
        : BuyerAccountService.instance.resendOtp(email: _userEmail);

    setState(() {
      _isLoading = false;
    });

    if (result.success) {
      final updatedBuyer = widget.isLoginMode
          ? BuyerAccountService.instance.findBuyerByIdentifier(_userEmail)
          : BuyerAccountService.instance.currentUnverifiedBuyer;
      final newOtp = updatedBuyer?.otpCode;
      if (newOtp != null) {
        ExternalNotificationService.show(
          title: 'Nexora Security Alert',
          body: 'Your new 6-digit verification code is $newOtp',
        );
      }
      setState(() {
        _resendCooldown = 60;
        _syncTimerWithExpiration();
        // Clear boxes
        for (final c in _controllers) {
          c.clear();
        }
        _focusNodes[0].requestFocus();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.mark_email_read_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(result.message)),
            ],
          ),
          backgroundColor: const Color(0xFF0066FF),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() {
        _errorMessage = result.message;
      });
    }
  }

  void _showVoucherClaimModal() {
    showDialog(
      context: context,
      barrierDismissible: true, // TC-BUY-028 allows dismissing without losing state
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Celebration Badge
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F7FA),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF00D2FF), width: 2),
                ),
                child: const Center(
                  child: Text('🎉', style: TextStyle(fontSize: 36)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Account Verified!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Welcome to Nexora! Your VIP perks are now active.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.3),
              ),
              const SizedBox(height: 16),

              // Voucher Card Box (TC-BUY-029)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0066FF), Color(0xFF00D2FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0066FF).withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '₱150 First Order Voucher',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '+ Free Nationwide Shipping applied',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Button (TC-BUY-029)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.home,
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Start Shopping 🚀',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
            // Safe Back Navigation (TC-BUY-040)
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Email Delivery Status Banner
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mark_email_unread_outlined, color: Color(0xFF0066FF), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your 6-digit verification code is generated below. Enter the code or tap Auto-fill to complete verification.',
                        style: const TextStyle(
                          color: Color(0xFF1E3A8A),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

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
              const SizedBox(height: 18),

              // Header
              Text(
                widget.isLoginMode ? 'Quick Sign-In Verification' : 'Verify Your Email',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.isLoginMode
                    ? 'Enter the 6-digit security code sent to\n$_userEmail to sign in.'
                    : 'We have sent a 6-digit verification code to\n$_userEmail',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Card Container
              Container(
                padding: const EdgeInsets.all(22),
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Prominent In-App Verification Code & One-Tap Auto-fill
                    Builder(
                      builder: (context) {
                        final buyer = widget.isLoginMode
                            ? BuyerAccountService.instance.findBuyerByIdentifier(_userEmail)
                            : BuyerAccountService.instance.currentUnverifiedBuyer;
                        final code = buyer?.otpCode ?? '123456';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.verified_user_rounded, color: Color(0xFF0066FF), size: 24),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Your Verification Code',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                      Text(
                                        code,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 4,
                                          color: Color(0xFF0066FF),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _handlePastedText(code),
                                icon: const Icon(Icons.touch_app_rounded, size: 16),
                                label: const Text('Auto-fill', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0066FF),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // 6 OTP Input Boxes (TC-BUY-023 to TC-BUY-025)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: 44,
                          height: 52,
                          child: TextFormField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: EdgeInsets.zero,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: _errorMessage != null
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF0066FF),
                                  width: 2,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: _errorMessage != null
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                            ),
                            onChanged: (val) {
                              if (val.length > 1) {
                                _handlePastedText(val);
                                return;
                              }
                              if (val.isNotEmpty) {
                                if (index < 5) {
                                  _focusNodes[index + 1].requestFocus();
                                } else {
                                  _focusNodes[index].unfocus();
                                }
                              } else if (val.isEmpty && index > 0) {
                                _focusNodes[index - 1].requestFocus();
                              }
                              if (_errorMessage != null) {
                                setState(() {
                                  _errorMessage = null;
                                });
                              }
                            },
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 10),

                    // Quick Paste from Clipboard Action (TC-BUY-038)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _pasteFromClipboard,
                        icon: const Icon(Icons.paste_rounded, size: 14, color: Color(0xFF0066FF)),
                        label: const Text(
                          'Paste Code',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0066FF),
                          ),
                        ),
                      ),
                    ),

                    // Error Message
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: Color(0xFFDC2626), size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Color(0xFFB91C1C),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Countdown Expiration Timer (TC-BUY-026, TC-BUY-039)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 15,
                          color: _secondsRemaining < 60
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _secondsRemaining > 0
                              ? 'Code expires in $_formattedTime'
                              : 'Code expired',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: _secondsRemaining < 60
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Verify Button (TC-BUY-023)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleVerify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0066FF),
                          foregroundColor: Colors.white,
                          elevation: 0,
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
                            : const Text(
                                'Verify & Continue',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Resend OTP Action (TC-BUY-027)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Didn't receive code? ",
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        GestureDetector(
                          onTap: _resendCooldown == 0 ? _handleResend : null,
                          child: Text(
                            _resendCooldown > 0
                                ? 'Resend in ${_resendCooldown}s'
                                : 'Resend Code',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: _resendCooldown > 0
                                  ? Colors.grey
                                  : const Color(0xFF0066FF),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Back to Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Wrong email address? ',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, AppRoutes.register);
                    },
                    child: const Text(
                      'Re-register',
                      style: TextStyle(
                        color: Color(0xFF0066FF),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
