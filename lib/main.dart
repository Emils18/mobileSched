import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/splash_screen.dart';
import 'services/attendance_service.dart';
import 'services/google_form_service.dart';
import 'services/notification_service.dart';
import 'services/pending_submission_service.dart';
import 'services/theme_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await Future.wait([
    AttendanceService().init(),
    NotificationService().init(),
    GoogleFormService().init(),
    PendingSubmissionService().init(),
    ThemeService().init(),
  ]);

  runApp(const MobileSchedApp());
}

class MobileSchedApp extends StatelessWidget {
  const MobileSchedApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService();

    return AnimatedBuilder(
      animation: themeService,
      builder: (context, child) {
        final palette = MobileSchedTheme.palette(
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