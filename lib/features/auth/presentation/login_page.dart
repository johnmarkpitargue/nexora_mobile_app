import 'package:flutter/material.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/nexora_theme.dart';
import '../../../core/services/buyer_account_service.dart';
import '../../../core/services/profile_service.dart';
import '../../../core/services/supabase_auth_service.dart';
import 'widgets/auth_components.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _rememberMe = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateToHomeOrPop() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args == true || args == 'popOnSuccess') {
      Navigator.pop(context, true);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
    }
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    var result = BuyerAccountService.instance.loginBuyer(
      emailOrPhone: _emailController.text,
      password: _passwordController.text,
    );

    if (!result.success && SupabaseAuthService.instance.isSupabaseConfigured) {
      final supabaseResult = await SupabaseAuthService.instance.signInWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (supabaseResult.success && supabaseResult.user != null) {
        final user = supabaseResult.user!;
        final fullName =
            supabaseResult.profile?['full_name'] ??
            user.userMetadata?['full_name'] ??
            _emailController.text.split('@').first;
        BuyerAccountService.instance.establishGoogleSession(
          name: fullName,
          email: user.email ?? _emailController.text,
        );
        result = BuyerOpResult.ok(message: supabaseResult.message);
      }
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      final buyer = result.buyer;
      if (buyer != null) {
        ProfileService.instance.updateProfile(
          name: buyer.fullName,
          email: buyer.email,
          phone: buyer.mobileNumber,
        );
      }
      _navigateToHomeOrPop();
      return;
    }

    if (result.buyer?.accountStatus == 'Unverified') {
      _showVerificationDialog(result.buyer!.email);
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(result.message)));
  }

  Future<void> _showVerificationDialog(String email) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.mark_email_unread_outlined),
        title: const Text('Verify your email'),
        content: Text(
          'Enter the 6-digit code sent to $email before signing in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Not now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pushNamed(
                context,
                AppRoutes.emailVerification,
                arguments: email,
              );
            },
            child: const Text('Verify email'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    final success = await SupabaseAuthService.instance.signInWithGoogle();
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _navigateToHomeOrPop();
      return;
    }
    final error = SupabaseAuthService.instance.lastGoogleError;
    if (error != null && error.isNotEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Google sign-in: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageScaffold(
      title: 'Welcome back',
      subtitle: 'Sign in to track orders, save favorites, and pick up where you left off.',
      content: Form(
        key: _formKey,
        child: AuthSection(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [
                  AutofillHints.username,
                  AutofillHints.email,
                ],
                decoration: const InputDecoration(
                  labelText: 'Email or Mobile',
                  hintText: 'name@example.com',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email or mobile number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => _handleLogin(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    tooltip: _isPasswordVisible
                        ? 'Hide password'
                        : 'Show password',
                    onPressed: () => setState(
                      () => _isPasswordVisible = !_isPasswordVisible,
                    ),
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                children: [
                  Semantics(
                    label: 'Remember me',
                    checked: _rememberMe,
                    child: InkWell(
                      onTap: () => setState(() => _rememberMe = !_rememberMe),
                      borderRadius: BorderRadius.circular(12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            activeColor: NexoraTheme.primary,
                            onChanged: (value) =>
                                setState(() => _rememberMe = value ?? false),
                          ),
                          const Text(
                            'Remember me',
                            style: TextStyle(
                              color: Color(0xFF334155),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.forgotPassword,
                      arguments: _emailController.text.trim(),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: NexoraTheme.primary,
                    ),
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AuthPrimaryButton(
                label: 'Sign In',
                loading: _isLoading,
                onPressed: _handleLogin,
              ),
              const SizedBox(height: 20),
              const AuthDivider(),
              const SizedBox(height: 20),
              AuthGoogleButton(
                loading: _isLoading,
                onPressed: _handleGoogleSignIn,
              ),
            ],
          ),
        ),
      ),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Flexible(
            child: Text(
              'New to Nexora?',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.register),
            style: TextButton.styleFrom(
              foregroundColor: NexoraTheme.primary,
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
            child: const Text('Create Account'),
          ),
        ],
      ),
    );
  }
}
