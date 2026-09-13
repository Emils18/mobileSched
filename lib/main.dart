import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await Supabase.initialize(
    url: 'https://kigculljqtosfwldzgch.supabase.co',
    publishableKey: 'sb_publishable_YVTSzNoD11FYvW_O6L11cg_0g0v9WgN',
  );

  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    try {
      await NotificationService().init();
    } catch (error) {
      debugPrint('Notification initialization failed: $error');
    }
  }

  runApp(const MobileSchedApp());
}

class MobileSchedApp extends StatefulWidget {
  const MobileSchedApp({super.key});

  @override
  State<MobileSchedApp> createState() => _MobileSchedAppState();
}

class _MobileSchedAppState extends State<MobileSchedApp> {
  final ThemeService _themeService = ThemeService();

  void _updateSystemUiOverlay(AppPalette palette) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            palette.isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            palette.isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: palette.background,
        systemNavigationBarIconBrightness:
            palette.isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeService,
      builder: (context, child) {
        final AppPalette palette = MobileSchedTheme.palette(
          _themeService.preset,
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateSystemUiOverlay(palette);
        });

        return MaterialApp(
          title: 'MobileSched',
          debugShowCheckedModeBanner: false,
          theme: MobileSchedTheme.build(
            _themeService.preset,
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}