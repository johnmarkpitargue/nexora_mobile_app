import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/routes/app_routes.dart';
import 'app/theme/nexora_theme.dart';
import 'core/constants/supabase_constants.dart';
import 'core/services/external_notification_service.dart';
import 'core/services/in_app_notification_service.dart';

import 'core/services/buyer_account_service.dart';
import 'core/services/supabase_auth_service.dart';
import 'core/services/order_chat_service.dart';
import 'core/services/order_service.dart';
import 'core/network/api_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request system notification permission for receiving messages when app is in background/minimized
  ExternalNotificationService.requestPermission();

  // Initialize central HTTP API Client for Laravel Sanctum authentication
  try {
    await ApiClient.instance.init();
  } catch (e) {
    debugPrint('ApiClient initialization notice: $e');
  }

  try {
    await Supabase.initialize(
      url: SupabaseConstants.url,
      // ignore: deprecated_member_use
      anonKey: SupabaseConstants.anonKey,
    );
    SupabaseAuthService.instance.initAuthStateListener();
    OrderChatService.instance.ensureInitialized();
    OrderService.instance.ensureInitialized();
  } catch (e) {
    debugPrint('Supabase initialization notice: $e');
  }

  // Restore persisted buyer accounts and active login session
  try {
    await BuyerAccountService.instance.ensureInitialized();
  } catch (e) {
    debugPrint('BuyerAccountService initialization notice: $e');
  }

  runApp(const NexoraApp());
}

class NexoraApp extends StatelessWidget {
  const NexoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nexora',
      navigatorKey: InAppNotificationService.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: NexoraTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}