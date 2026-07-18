import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/splash_screen.dart';
import 'services/theme_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const MobileSchedApp());
}

class MobileSchedApp extends StatelessWidget {
  const MobileSchedApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeService themeService = ThemeService();

    return AnimatedBuilder(
      animation: themeService,
      builder: (context, child) {
        final AppPalette palette = MobileSchedTheme.palette(
          themeService.preset,
        );

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

        return MaterialApp(
          title: 'MobileSched',
          debugShowCheckedModeBanner: false,
          theme: MobileSchedTheme.build(
            themeService.preset,
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}