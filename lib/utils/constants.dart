import 'package:flutter/material.dart';

class AppColors {
  static const Color bgDeep = Color(0xFF050B14);
  static const Color bgDark = Color(0xFF0A1222);
  
  static const Color primary = Color(0xFF00F0FF); 
  static const Color secondary = Color(0xFF00FF87); 
  static const Color accentPurple = Color(0xFF8A2BE2);
  
  static const Color cardGlass = Color(0x0FFFFFFF);
  static const Color cardBorder = Color(0x1AFFFFFF);
  
  static const Color textTitle = Color(0xFFFFFFFF);
  static const Color textBody = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF475569);
  
  static const Color success = Color(0xFF00FF87);
  static const Color error = Color(0xFFFF3B30);
  static const Color warning = Color(0xFFFFCC00);
  static const Color orange = Color(0xFFFF9500); // For late warnings
}

class AppFormatters {
  static String formatTime(DateTime? time) {
    if (time == null) return "--:--";
    int h = time.hour;
    int m = time.minute;
    String amPm = h >= 12 ? "PM" : "AM";
    if (h > 12) h -= 12;
    if (h == 0) h = 12;
    String mStr = m.toString().padLeft(2, '0');
    return "$h:$mStr $amPm";
  }

  static String formatTimeOfDay(TimeOfDay time) {
    int h = time.hour;
    int m = time.minute;
    String amPm = h >= 12 ? "PM" : "AM";
    if (h > 12) h -= 12;
    if (h == 0) h = 12;
    String mStr = m.toString().padLeft(2, '0');
    return "$h:$mStr $amPm";
  }

  static String formatDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      final y = parts[0];
      final m = int.parse(parts[1]);
      final d = int.parse(parts[2]);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return "${months[m - 1]} $d, $y";
    } catch (e) {
      return dateStr;
    }
  }

  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good morning";
    if (hour < 17) return "Good afternoon";
    return "Good evening";
  }

  static String getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}