import 'package:flutter/material.dart';

class PrefilledFormService {
  static const String _baseUrl =
      'https://docs.google.com/forms/d/e/1FAIpQLSfFwpdtAEM14JG6l6FlI-sxnwBRlC8A-71HqIgYF8gGyL58gw/viewform';

  String buildClockInUrl(TimeOfDay time) {
    final hour = time.hour.toString();
    final minute = time.minute.toString();
    final query = {
      'entry.311364925': 'Clock In',
      'entry.1072714220_hour': hour,
      'entry.1072714220_minute': minute,
    };
    return _buildUrl(query);
  }

  String buildClockOutUrl(TimeOfDay time, String accomplishment) {
    final hhmm =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    final query = {
      'entry.311364925': 'Clock Out',
      'entry.1943230368': hhmm,
      'entry.1843883804': accomplishment,
    };
    return _buildUrl(query);
  }

  String _buildUrl(Map<String, String> params) {
    final queryString = params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return '$_baseUrl?$queryString';
  }
}