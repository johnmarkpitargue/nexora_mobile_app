import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/routes/app_routes.dart';
import 'app/theme/nexora_theme.dart';
import 'core/constants/supabase_constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: SupabaseConstants.url,
      // ignore: deprecated_member_use
      anonKey: SupabaseConstants.anonKey,
    );
  } catch (e) {
    debugPrint('Supabase initialization notice: $e');
  }

  runApp(const NexoraApp());
}

class NexoraApp extends StatelessWidget {
  const NexoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nexora',
      debugShowCheckedModeBanner: false,
      theme: NexoraTheme.lightTheme,
      initialRoute: AppRoutes.landing,
      routes: AppRoutes.routes,
    );
  }
}