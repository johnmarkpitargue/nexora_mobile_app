import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/buyer_account_service.dart';
import '../../../core/services/profile_service.dart';

/// Interactive Account Security & Credentials Management Modal
/// Complies with Mobile Blackbox Test Cases BUY-ACCT-003 to BUY-ACCT-009
void showAccountSecurityModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const AccountSecurityBottomSheet(),
  );
}

class AccountSecurityBottomSheet extends StatefulWidget {
  const AccountSecurityBottomSheet({super.key});

  @override
  State<AccountSecurityBottomSheet> createState() =>
      _AccountSecurityBottomSheetState();
}

enum SecurityView {
  menu,
  changePassword,
  changeEmail,
  verifyEmailOtp,
  changePhone,
  verifyPhoneOtp,
}

class _AccountSecurityBottomSheetState
    extends State<AccountSecurityBottomSheet> {
  SecurityView _currentView = SecurityView.menu;

  // Change Password Controllers
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _passwordError;

  // Change Email Controllers
  final _newEmailCtrl = TextEditingController();
  final _emailOtpCtrl = TextEditingController();
  String? _emailError;
  int _emailSecondsRemaining = 300;
  Timer? _emailTimer;

  // Change Phone Controllers
  final _newPhoneCtrl = TextEditingController();
  final _phoneOtpCtrl = TextEditingController();
  String? _phoneError;
  int _phoneSecondsRemaining = 300;
  Timer? _phoneTimer;

  @override
  void dispose() {
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _newEmailCtrl.dispose();
    _emailOtpCtrl.dispose();
    _newPhoneCtrl.dispose();
    _phoneOtpCtrl.dispose();
    _emailTimer?.cancel();
    _phoneTimer?.cancel();
    super.dispose();
  }

  void _startEmailTimer() {
    _emailTimer?.cancel();
    _emailSecondsRemaining = 300;
    _emailTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_emailSecondsRemaining <= 1) {
        timer.cancel();
        if (mounted) setState(() => _emailSecondsRemaining = 0);
      } else {
        if (mounted) setState(() => _emailSecondsRemaining--);
      }
    });
  }

  void _startPhoneTimer() {
    _phoneTimer?.cancel();
    _phoneSecondsRemaining = 300;
    _phoneTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_phoneSecondsRemaining <= 1) {
        timer.cancel();
        if (mounted) setState(() => _phoneSecondsRemaining = 0);
      } else {
        if (mounted) setState(() => _phoneSecondsRemaining--);
      }
    });
  }

  void _handleChangePassword() {
    setState(() => _passwordError = null);
    final current = _currentPasswordCtrl.text;
    final newPass = _newPasswordCtrl.text;
    final confirm = _confirmPasswordCtrl.text;

    final result = BuyerAccountService.instance.changePassword(
      oldPassword: current,
      newPassword: newPass,
      confirmPassword: confirm,
    );

    if (!result.success) {
      setState(() => _passwordError = result.message);
      return;
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Password updated successfully! Other sessions terminated.'),
          ],
        ),
        backgroundColor: Color(0xFF0066FF),
      ),
    );
  }

  void _handleRequestEmailChange() {
    setState(() => _emailError = null);
    final email = _newEmailCtrl.text.trim();

    final result = BuyerAccountService.instance.requestChangeEmail(
      newEmail: email,
    );
    if (!result.success) {
      setState(() => _emailError = result.message);
      return;
    }

    _startEmailTimer();
    setState(() => _currentView = SecurityView.verifyEmailOtp);
  }

  void _handleVerifyEmailOtp() {
    setState(() => _emailError = null);
    final otp = _emailOtpCtrl.text.trim();

    final result = BuyerAccountService.instance.verifyChangeEmailOtp(otp: otp);
    if (!result.success) {
      setState(() => _emailError = result.message);
      return;
    }

    ProfileService.instance.updateProfile(email: _newEmailCtrl.text.trim());
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('Email updated to ${_newEmailCtrl.text.trim()}!'),
          ],
        ),
        backgroundColor: const Color(0xFF0066FF),
      ),
    );
  }

  void _handleRequestPhoneChange() {
    setState(() => _phoneError = null);
    final phone = _newPhoneCtrl.text.trim();

    final result = BuyerAccountService.instance.requestChangePhone(
      newPhone: phone,
    );
    if (!result.success) {
      setState(() => _phoneError = result.message);
      return;
    }

    _startPhoneTimer();
    setState(() => _currentView = SecurityView.verifyPhoneOtp);
  }

  void _handleVerifyPhoneOtp() {
    setState(() => _phoneError = null);
    final otp = _phoneOtpCtrl.text.trim();

    final result = BuyerAccountService.instance.verifyChangePhoneOtp(otp: otp);
    if (!result.success) {
      setState(() => _phoneError = result.message);
      return;
    }

    final normalized = BuyerValidationRules.normalizePhone(
      _newPhoneCtrl.text.trim(),
    );
    BuyerAccountService.instance.currentBuyerSession?.mobileNumber = normalized;
    ProfileService.instance.updateProfile(phone: normalized);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('Mobile number updated to $normalized!'),
          ],
        ),
        backgroundColor: const Color(0xFF0066FF),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final maxHeight =
        media.size.height * (_currentView == SecurityView.menu ? 0.58 : 0.86);

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600, maxHeight: maxHeight),
          child: Material(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                10,
                20,
                media.viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outline,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (_currentView != SecurityView.menu)
                          IconButton(
                            tooltip: 'Back to security options',
                            icon: const Icon(Icons.arrow_back_rounded),
                            onPressed: () {
                              setState(() {
                                _currentView = SecurityView.menu;
                                _passwordError = null;
                                _emailError = null;
                                _phoneError = null;
                              });
                            },
                          ),
                        Expanded(
                          child: Text(
                            _getHeaderTitle(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_currentView == SecurityView.menu) _buildMenuView(),
                    if (_currentView == SecurityView.changePassword)
                      _buildChangePasswordView(),
                    if (_currentView == SecurityView.changeEmail)
                      _buildChangeEmailView(),
                    if (_currentView == SecurityView.verifyEmailOtp)
                      _buildVerifyEmailOtpView(),
                    if (_currentView == SecurityView.changePhone)
                      _buildChangePhoneView(),
                    if (_currentView == SecurityView.verifyPhoneOtp)
                      _buildVerifyPhoneOtpView(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool get _hasLinkedPhone {
    final rawPhone =
        BuyerAccountService.instance.currentBuyerSession?.mobileNumber ??
        ProfileService.instance.phone;
    final clean = rawPhone.trim();
    return clean.isNotEmpty &&
        clean != '09000000000' &&
        clean != '+63 917 123 4567';
  }

  String _getHeaderTitle() {
    switch (_currentView) {
      case SecurityView.menu:
        return 'Security & Credentials';
      case SecurityView.changePassword:
        return 'Change Password';
      case SecurityView.changeEmail:
        return 'Change Email Address';
      case SecurityView.verifyEmailOtp:
        return 'Verify New Email';
      case SecurityView.changePhone:
        return _hasLinkedPhone ? 'Change Mobile Number' : 'Add Mobile Number';
      case SecurityView.verifyPhoneOtp:
        return _hasLinkedPhone ? 'Verify New Mobile' : 'Verify Mobile Number';
    }
  }

  Widget _buildMenuView() {
    final currentEmail =
        BuyerAccountService.instance.currentBuyerSession?.email ??
        ProfileService.instance.email;
    final hasPhone = _hasLinkedPhone;
    final displayPhone = hasPhone
        ? (BuyerAccountService.instance.currentBuyerSession?.mobileNumber ??
                ProfileService.instance.phone)
            .trim()
        : 'No mobile number added';
    final phoneAction = hasPhone ? 'Change' : 'Add';

    return Column(
      children: [
        _buildSecurityTile(
          icon: Icons.lock_outline_rounded,
          title: 'Account Password',
          subtitle: 'Update your login password and terminate active sessions',
          actionText: 'Change',
          onTap: () =>
              setState(() => _currentView = SecurityView.changePassword),
        ),
        const Divider(height: 1),
        _buildSecurityTile(
          icon: Icons.email_outlined,
          title: 'Registered Email',
          subtitle: currentEmail,
          actionText: 'Change',
          onTap: () => setState(() => _currentView = SecurityView.changeEmail),
        ),
        const Divider(height: 1),
        _buildSecurityTile(
          icon: Icons.phone_android_rounded,
          title: 'Mobile Phone',
          subtitle: displayPhone,
          actionText: phoneAction,
          onTap: () => setState(() => _currentView = SecurityView.changePhone),
        ),
      ],
    );
  }

  Widget _buildSecurityTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onTap,
    bool isToggle = false,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 2),
        leading: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: isToggle
            ? const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionText,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildChangePasswordView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ensure your new password contains at least 8 characters, with uppercase, lowercase, number, and special character.',
          style: TextStyle(
            fontSize: 12.5,
            color: Color(0xFF64748B),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),

        if (_passwordError != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.redAccent.shade100),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _passwordError!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Current Password
        const Text(
          'Current Password',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _currentPasswordCtrl,
          obscureText: _obscureCurrent,
          decoration: _inputDecoration(
            hint: 'Enter current password (Mamimili@2026)',
            suffixIcon: IconButton(
              icon: Icon(
                _obscureCurrent ? Icons.visibility_off : Icons.visibility,
                size: 18,
              ),
              onPressed: () =>
                  setState(() => _obscureCurrent = !_obscureCurrent),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // New Password
        const Text(
          'New Password',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _newPasswordCtrl,
          obscureText: _obscureNew,
          decoration: _inputDecoration(
            hint: 'Min 8 chars, 1 uppercase, 1 symbol',
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNew ? Icons.visibility_off : Icons.visibility,
                size: 18,
              ),
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Confirm Password
        const Text(
          'Confirm New Password',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _confirmPasswordCtrl,
          obscureText: _obscureConfirm,
          decoration: _inputDecoration(
            hint: 'Re-enter new password',
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                size: 18,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Submit Button
        _primaryButton(
          label: 'Update Password',
          onPressed: _handleChangePassword,
        ),
      ],
    );
  }

  Widget _buildChangeEmailView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'A 6-digit verification code will be sent to your new email. Your current email remains active until verified.',
          style: TextStyle(
            fontSize: 12.5,
            color: Color(0xFF64748B),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),

        if (_emailError != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.redAccent.shade100),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _emailError!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        const Text(
          'New Email Address',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _newEmailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: _inputDecoration(hint: 'new.email@example.com'),
        ),
        const SizedBox(height: 20),

        _primaryButton(
          label: 'Send Verification Code',
          onPressed: _handleRequestEmailChange,
        ),
      ],
    );
  }

  Widget _buildVerifyEmailOtpView() {
    final minutes = (_emailSecondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_emailSecondsRemaining % 60).toString().padLeft(2, '0');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter the 6-digit verification code sent to ${_newEmailCtrl.text.trim()}',
          style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 4),
        Text(
          'Code expires in $minutes:$seconds',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0066FF),
          ),
        ),
        const SizedBox(height: 16),

        if (_emailError != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.redAccent.shade100),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _emailError!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        TextField(
          controller: _emailOtpCtrl,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 8,
          ),
          decoration: _inputDecoration(hint: '123456'),
        ),
        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _emailSecondsRemaining == 0
                  ? _handleRequestEmailChange
                  : null,
              child: Text(
                _emailSecondsRemaining == 0
                    ? 'Resend Code'
                    : 'Resend available soon',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _emailSecondsRemaining == 0
                      ? const Color(0xFF0066FF)
                      : Colors.grey,
                ),
              ),
            ),
            Text(
              'QA Test Code: 123456',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _primaryButton(
          label: 'Confirm & Change Email',
          onPressed: _handleVerifyEmailOtp,
        ),
      ],
    );
  }

  Widget _buildChangePhoneView() {
    final hasPhone = _hasLinkedPhone;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hasPhone
              ? 'Enter your new 11-digit Philippine mobile number starting with 09. A verification OTP will be sent.'
              : 'Enter your 11-digit Philippine mobile number starting with 09 to link it to your account. A verification OTP will be sent.',
          style: const TextStyle(
            fontSize: 12.5,
            color: Color(0xFF64748B),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),

        if (_phoneError != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.redAccent.shade100),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _phoneError!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        Text(
          hasPhone ? 'New Mobile Number' : 'Mobile Number',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _newPhoneCtrl,
          keyboardType: TextInputType.phone,
          maxLength: 11,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _inputDecoration(hint: '09XXXXXXXXX'),
        ),
        const SizedBox(height: 16),

        _primaryButton(
          label: 'Send Verification Code',
          onPressed: _handleRequestPhoneChange,
        ),
      ],
    );
  }

  Widget _buildVerifyPhoneOtpView() {
    final minutes = (_phoneSecondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_phoneSecondsRemaining % 60).toString().padLeft(2, '0');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter the 6-digit verification code sent to ${_newPhoneCtrl.text.trim()}',
          style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 4),
        Text(
          'Code expires in $minutes:$seconds',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0066FF),
          ),
        ),
        const SizedBox(height: 16),

        if (_phoneError != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.redAccent.shade100),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _phoneError!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        TextField(
          controller: _phoneOtpCtrl,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 8,
          ),
          decoration: _inputDecoration(hint: '123456'),
        ),
        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _phoneSecondsRemaining == 0
                  ? _handleRequestPhoneChange
                  : null,
              child: Text(
                _phoneSecondsRemaining == 0
                    ? 'Resend Code'
                    : 'Resend available soon',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _phoneSecondsRemaining == 0
                      ? const Color(0xFF0066FF)
                      : Colors.grey,
                ),
              ),
            ),
            Text(
              'QA Test Code: 123456',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _primaryButton(
          label: _hasLinkedPhone
              ? 'Confirm & Change Mobile'
              : 'Confirm & Link Mobile',
          onPressed: _handleVerifyPhoneOtp,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({required String hint, Widget? suffixIcon}) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: theme.colorScheme.onSurfaceVariant,
        fontSize: 13,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: theme.colorScheme.surfaceContainer,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Widget _primaryButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton(
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
