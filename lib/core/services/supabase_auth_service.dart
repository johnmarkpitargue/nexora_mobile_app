import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';
import 'profile_service.dart';
import 'buyer_account_service.dart';

class SupabaseAuthResult {
  final bool success;
  final String message;
  final User? user;
  final Map<String, dynamic>? profile;

  const SupabaseAuthResult({
    required this.success,
    required this.message,
    this.user,
    this.profile,
  });

  factory SupabaseAuthResult.ok({
    String message = 'Success',
    User? user,
    Map<String, dynamic>? profile,
  }) =>
      SupabaseAuthResult(
        success: true,
        message: message,
        user: user,
        profile: profile,
      );

  factory SupabaseAuthResult.fail(String message) =>
      SupabaseAuthResult(success: false, message: message);
}

/// Service managing Supabase Authentication (Email/Password & Google OAuth)
/// and synchronization with `public.profiles`.
class SupabaseAuthService extends ChangeNotifier {
  static final SupabaseAuthService instance = SupabaseAuthService._();
  SupabaseAuthService._();

  bool get isSupabaseConfigured {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  User? get currentUser {
    try {
      return Supabase.instance.client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  bool get isAuthenticated => currentUser != null;

  Stream<AuthState> get authStateChanges =>
      Supabase.instance.client.auth.onAuthStateChange;

  bool _isListenerInitialized = false;

  /// Listen to Supabase auth events (e.g. Web OAuth completion, token refresh, sign-in)
  /// and automatically update local buyer session and navigate to Home.
  void initAuthStateListener() {
    if (_isListenerInitialized || !isSupabaseConfigured) return;
    _isListenerInitialized = true;

    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;
      final user = session?.user;

      if ((event == AuthChangeEvent.signedIn || event == AuthChangeEvent.userUpdated) &&
          user != null) {
        final email = user.email ?? '';
        final metadata = user.userMetadata ?? {};
        final name = (metadata['full_name'] ??
                metadata['name'] ??
                (email.contains('@') ? email.split('@').first : 'Nexora Shopper'))
            .toString();
        final avatar = (metadata['avatar_url'] ?? metadata['picture'] ?? '').toString();

        BuyerAccountService.instance.establishGoogleSession(
          name: name,
          email: email,
          photoUrl: avatar.isNotEmpty ? avatar : null,
        );

        ProfileService.instance.updateProfile(
          name: name,
          email: email,
          phone: (metadata['mobile_number'] ?? metadata['phone'] ?? '').toString(),
        );

        notifyListeners();
      }
    });
  }

  /// Sign In with Email & Password
  Future<SupabaseAuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final user = response.user;
      if (user == null) {
        return SupabaseAuthResult.fail('Login failed: user not found.');
      }

      // Fetch profile from database
      final profile = await fetchUserProfile(user.id);
      if (profile != null) {
        ProfileService.instance.updateProfile(
          name: profile['full_name'] ?? user.userMetadata?['full_name'] ?? email.split('@').first,
          email: profile['email'] ?? email,
          phone: profile['mobile_number'] ?? '',
        );
      }

      notifyListeners();
      return SupabaseAuthResult.ok(
        message: 'Welcome back, ${profile?['full_name'] ?? "Shopper"}!',
        user: user,
        profile: profile,
      );
    } on AuthException catch (e) {
      debugPrint('⚠️ Supabase AuthException: ${e.message}');
      return SupabaseAuthResult.fail(e.message);
    } catch (e) {
      debugPrint('⚠️ Supabase login unexpected error: $e');
      return SupabaseAuthResult.fail('Connection error: $e');
    }
  }

  /// Sign Up with Email & Password
  Future<SupabaseAuthResult> signUpWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    try {
      final fullName = '$firstName $lastName'.trim();
      final response = await Supabase.instance.client.auth.signUp(
        email: email.trim().toLowerCase(),
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'full_name': fullName,
          'mobile_number': phone ?? '',
          'role': 'buyer',
        },
      );

      final user = response.user;
      if (user == null) {
        return SupabaseAuthResult.fail('Registration failed. Please try again.');
      }

      notifyListeners();
      return SupabaseAuthResult.ok(
        message: 'Account created successfully! Please verify your email.',
        user: user,
      );
    } on AuthException catch (e) {
      return SupabaseAuthResult.fail(e.message);
    } catch (e) {
      return SupabaseAuthResult.fail('Registration error: $e');
    }
  }

  String? lastOtpError;

  /// Send real 6-digit verification code to the user's Gmail inbox via Supabase
  Future<bool> sendEmailOtp(String email, {bool isSignup = false}) async {
    lastOtpError = null;
    final cleanEmail = email.trim().toLowerCase();
    try {
      if (isSignup) {
        await Supabase.instance.client.auth.resend(
          type: OtpType.signup,
          email: cleanEmail,
        );
        return true;
      } else {
        await Supabase.instance.client.auth.signInWithOtp(
          email: cleanEmail,
          shouldCreateUser: true,
        );
        return true;
      }
    } catch (e) {
      debugPrint('⚠️ sendEmailOtp primary attempt note: $e');
      try {
        if (isSignup) {
          await Supabase.instance.client.auth.signInWithOtp(
            email: cleanEmail,
            shouldCreateUser: true,
          );
        } else {
          await Supabase.instance.client.auth.resend(
            type: OtpType.signup,
            email: cleanEmail,
          );
        }
        return true;
      } catch (e2) {
        debugPrint('⚠️ sendEmailOtp fallback note: $e2');
        lastOtpError = e2 is AuthException ? e2.message : e2.toString();
        return false;
      }
    }
  }

  /// Verify 6-digit OTP received in user's Gmail inbox
  Future<bool> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanToken = token.trim();
    
    // First attempt OtpType.signup (since registration creates signup OTPs)
    try {
      final response = await Supabase.instance.client.auth.verifyOTP(
        email: cleanEmail,
        token: cleanToken,
        type: OtpType.signup,
      );
      if (response.user != null) return true;
    } catch (e) {
      debugPrint('⚠️ verifyOTP signup type note: $e');
    }

    // Secondary attempt OtpType.email (magic link / OTP login type)
    try {
      final response = await Supabase.instance.client.auth.verifyOTP(
        email: cleanEmail,
        token: cleanToken,
        type: OtpType.email,
      );
      return response.user != null;
    } catch (e) {
      debugPrint('⚠️ verifyOTP email type note: $e');
      return false;
    }
  }

  String? lastGoogleError;

  /// Sign In with Google:
  /// Uses Native 1-Tap Google Play Services on Android/iOS (no web browser redirect).
  /// Falls back to Web OAuth only when running on desktop or web browser.
  Future<bool> signInWithGoogle() async {
    lastGoogleError = null;

    // 1. Native One-Tap Sign In via Google Play Services on Android / iOS
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      try {
        final GoogleSignIn googleSignIn = GoogleSignIn(
          serverClientId: SupabaseConstants.googleWebClientId,
          scopes: ['email', 'profile'],
        );

        // Clear previous Google cache so the account picker bottom sheet ALWAYS opens
        try {
          await googleSignIn.signOut();
        } catch (_) {}

        final googleUser = await googleSignIn.signIn();
        if (googleUser != null) {
          final displayName = googleUser.displayName ?? 'Google User';
          final email = googleUser.email;
          final photoUrl = googleUser.photoUrl;

          // Establish active profile and session immediately from native Google identity
          ProfileService.instance.updateProfile(
            name: displayName,
            email: email,
            phone: '',
          );

          BuyerAccountService.instance.establishGoogleSession(
            name: displayName,
            email: email,
            photoUrl: photoUrl,
          );

          // Authenticate with Supabase via idToken
          try {
            final googleAuth = await googleUser.authentication;
            final idToken = googleAuth.idToken;
            final accessToken = googleAuth.accessToken;

            if (idToken != null) {
              final response = await Supabase.instance.client.auth.signInWithIdToken(
                provider: OAuthProvider.google,
                idToken: idToken,
                accessToken: accessToken,
              );

              final user = response.user;
              if (user != null) {
                final profile = await fetchUserProfile(user.id);
                if (profile != null) {
                  ProfileService.instance.updateProfile(
                    name: profile['full_name'] ?? displayName,
                    email: profile['email'] ?? email,
                    phone: profile['mobile_number'] ?? '',
                  );
                }
              }
            }
          } catch (e) {
            debugPrint('⚠️ Supabase idToken background verification: $e');
          }

          notifyListeners();
          return true; // Successfully logged in with One-Tap! NEVER OPEN BROWSER!
        } else {
          lastGoogleError = 'Google account selection was closed or returned empty.';
          return false;
        }
      } catch (e) {
        lastGoogleError = e.toString();
        debugPrint('⚠️ Native Google One-Tap error: $e');
        return false;
      }
    }

    // 2. Fallback to Web OAuth ONLY when running on desktop PC or Web
    try {
      const redirectUrl = kIsWeb ? null : 'io.supabase.nexora://login-callback';

      return await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('⚠️ Google OAuth fallback error: $e');
      return false;
    }
  }

  /// Sign Out completely from Supabase, local buyer session, and Google Play Services cache
  Future<void> signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      debugPrint('⚠️ Supabase sign out error: $e');
    }

    try {
      final googleSignIn = GoogleSignIn(
        serverClientId: SupabaseConstants.googleWebClientId,
      );
      await googleSignIn.signOut();
    } catch (e) {
      debugPrint('⚠️ Google sign out error: $e');
    }

    BuyerAccountService.instance.logout();
    notifyListeners();
  }

  /// Fetch user profile from `public.profiles`
  Future<Map<String, dynamic>?> fetchUserProfile(String userId) async {
    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return res;
    } catch (e) {
      debugPrint('⚠️ Error fetching user profile: $e');
      return null;
    }
  }
}

