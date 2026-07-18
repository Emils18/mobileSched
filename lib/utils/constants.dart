import 'package:flutter/material.dart';

class AppColors {
  static const Color bgDeep = Color(0xFF050B14);
  static const Color bgDark = Color(0xFF0A1222);
  static const Color bgSoft = Color(0xFF101B30);

  static const Color primary = Color(0xFF00F0FF);
  static const Color primaryDark = Color(0xFF007BFF);
  static const Color secondary = Color(0xFF00FF87);
  static const Color accentPurple = Color(0xFF8A2BE2);

  static const Color cardGlass = Color(0x0FFFFFFF);
  static const Color cardBorder = Color(0x1AFFFFFF);

  static const Color textTitle = Color(0xFFFFFFFF);
  static const Color textBody = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  static const Color success = Color(0xFF00FF87);
  static const Color error = Color(0xFFFF3B30);
  static const Color warning = Color(0xFFFFCC00);
  static const Color orange = Color(0xFFFF9500);
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
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (_) {
      return dateString;
    }
  }

  static String formatFullDate(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
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
    const days = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];

    if (weekday < 1 || weekday > 7) {
      return '';
    }

    return days[weekday - 1];
  }

  static String durationUntil(DateTime target, DateTime current) {
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