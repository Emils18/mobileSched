import 'dart:convert';

import 'package:flutter/material.dart';

import 'web_push_profile_stub.dart'
    if (dart.library.html) 'web_push_profile_web.dart' as bridge;

class WebPushProfileService {
  const WebPushProfileService();

  Future<void> syncSchedule({
    required List<int> dutyDays,
    required TimeOfDay Function(int weekday) timeInForDay,
  }) async {
    final sortedDays = dutyDays.toSet().toList()..sort();

    // OneSignal Free currently allows 6 Data Tags per user.
    // Store up to six duty slots as "<weekday>@<HH:mm>".
    final tags = <String, String>{};

    for (var slot = 1; slot <= 6; slot++) {
      if (slot <= sortedDays.length) {
        final weekday = sortedDays[slot - 1];
        final time = timeInForDay(weekday);

        tags['duty_slot_$slot'] =
            '$weekday@${_formatTime(time)}';
      } else {
        // Empty values remove stale slots in OneSignal.
        tags['duty_slot_$slot'] = '';
      }
    }

    bridge.syncOneSignalTags(jsonEncode(tags));
  }

  Future<void> setEnabled(bool enabled) async {
    bridge.setOneSignalPushEnabled(enabled);
  }

  Future<void> showTestNotification() async {
    bridge.showOneSignalTestNotification();
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }
}
