import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/attendance_service.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AttendanceService(),
      child: MaterialApp(
        title: 'MobileSched',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Colors.transparent,
          useMaterial3: true,
        ),
        home: const DashboardScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
