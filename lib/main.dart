import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/supabase_constants.dart';
import 'core/theme/rider_theme.dart';
import 'features/auth/presentation/rider_landing_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      debugShowCheckedModeBanner: false,
      theme: RiderTheme.lightTheme,
      home: const RiderLandingPage(),
    );
  }
}
