import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/supabase_constants.dart';
import 'core/network/api_client.dart';
import 'core/theme/rider_theme.dart';
import 'core/services/external_notification_service.dart';
import 'core/services/in_app_notification_service.dart';
import 'core/services/chat_service.dart';
import 'core/services/delivery_service.dart';
import 'features/auth/presentation/rider_landing_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient.instance.init();

  // Request system notification permission for receiving customer/dispatch messages when app is in background/minimized
  ExternalNotificationService.requestPermission();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  try {
    await Supabase.initialize(
      url: SupabaseConstants.url,
      // ignore: deprecated_member_use
      anonKey: SupabaseConstants.anonKey,
    );
    RiderChatService.instance.ensureInitialized();
    DeliveryService.instance.ensureInitialized();
  } catch (e) {
    debugPrint('Supabase initialization notice: $e');
  }

  runApp(const NexoraRiderApp());
}

class NexoraRiderApp extends StatelessWidget {
  const NexoraRiderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nexora Rider',
      navigatorKey: InAppNotificationService.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: RiderTheme.lightTheme,
      home: const RiderLandingPage(),
    );
  }
}
