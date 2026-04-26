import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/dashboard_screen.dart';
import 'services/attendance_service.dart';
import 'services/notification_service.dart';
import 'services/google_form_service.dart';
import 'services/pending_submission_service.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.bgDeep,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await AttendanceService().init();
  await NotificationService().init();
  await GoogleFormService().init();
  await PendingSubmissionService().init();

  runApp(const MioSchedApp());
}

class MioSchedApp extends StatelessWidget {
  const MioSchedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MioSched',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.bgDeep,
        fontFamily: 'Inter',
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        timePickerTheme: TimePickerThemeData(
          backgroundColor: AppColors.bgDark,
          hourMinuteTextColor: Colors.white,
          dayPeriodTextColor: Colors.white,
          dialHandColor: AppColors.primary,
          dialBackgroundColor: Colors.black.withValues(alpha: 0.3),  // fixed
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}