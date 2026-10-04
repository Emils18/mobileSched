import 'package:flutter/material.dart';

class AppColors {
  // Brand colors
  static const Color brandNavy = Color(0xFF103F87);
  static const Color brandCream = Color(0xFFFEF8F2);
  static const Color brandOrange = Color(0xFFE5791E);
  static const Color brandSky = Color(0xFF2D8DCC);

  // App foundation — WHITE / LIGHT
  static const Color bgDeep = Color(0xFFFFFFFF);   // page background
  static const Color bgDark = Color(0xFFF7F9FB);   // nav bar, alt surface
  static const Color bgSoft = Color(0xFFEDF1F5);   // secondary surface

  // Accents
  static const Color primary = brandSky;
  static const Color primaryDark = brandNavy;
  static const Color secondary = brandOrange;
  static const Color accentPurple = brandSky;

  // Cards
  static const Color cardGlass = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE5E9EE);

  // Text
  static const Color textTitle = Color(0xFF1F2A37);
  static const Color textBody = Color(0xFF4B5563);
  static const Color textMuted = Color(0xFF6B7280);

  // Status
  static const Color success = Color(0xFF1E8E5A);
  static const Color error = Color(0xFFC0392B);
  static const Color warning = Color(0xFFD97706);
  static const Color orange = brandOrange;
}

class AppFormatters {
  static String formatTime(DateTime? time) {
    if (time == null) return '--:--';

    int hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';

    hour %= 12;

    if (hour == 0) {
      hour = 12;
    }

    return '$hour:$minute $period';
  }

  static String formatTimeOfDay(TimeOfDay time) {
    int hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';

    hour %= 12;

    if (hour == 0) {
      hour = 12;
    }

    return '$hour:$minute $period';
  }

  static String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);

      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];

      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (_) {
      return dateString;
    }
  }

  static String formatFullDate(DateTime date) {
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];

    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];

    return '${weekdays[date.weekday - 1]}, '
        '${months[date.month - 1]} ${date.day}';
  }

  static String getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good morning';
    }

    if (hour < 17) {
      return 'Good afternoon';
    }

    return 'Good evening';
  }

  static String getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    if (weekday < 1 || weekday > 7) {
      return '';
    }

    return days[weekday - 1];
  }

  static String durationUntil(
    DateTime target,
    DateTime current,
  ) {
    final difference = target.difference(current);

    if (difference.isNegative) {
      return '0m';
    }

    final hours = difference.inHours;
    final minutes = difference.inMinutes.remainder(60);

    if (hours == 0) {
      return '${difference.inMinutes}m';
    }

    return '${hours}h ${minutes}m';
  }
}