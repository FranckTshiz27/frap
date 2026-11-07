import 'package:flutter/material.dart';
import 'package:mobile_fp/screens/home_screen.dart';
import 'package:mobile_fp/screens/splash_screen.dart';
import 'package:mobile_fp/theme/app_typography.dart';
import 'package:mobile_fp/utils/asset_precache.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final binding = WidgetsBinding.instance;
  binding.deferFirstFrame();
  try {
    await precacheAppAssets();
  } finally {
    binding.allowFirstFrame();
  }

  runApp(const FrapApp());
}

class FrapApp extends StatelessWidget {
  const FrapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FRAP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: AppTypography.fontFamily,
        textTheme: AppTypography.textTheme,
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/home': (_) => const HomeScreen(),
      },
    );
  }
}
