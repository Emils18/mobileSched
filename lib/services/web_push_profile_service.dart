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
    final tags = <String, String>{
      'aws_hub_pwa': 'true',
      'aws_hub_timezone': 'Asia/Manila',
    };

    for (var weekday = 1; weekday <= 7; weekday++) {
      final enabled = dutyDays.contains(weekday);
      final time = timeInForDay(weekday);

      tags['duty_$weekday'] = enabled ? 'true' : 'false';
      tags['time_in_$weekday'] = enabled ? _formatTime(time) : '';
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
