import 'package:flutter/material.dart';

class PrefilledFormService {
  static const String _clockInBaseUrl =
      'https://docs.google.com/forms/d/e/1FAIpQLSfFwpdtAEM14JG6l6FlI-sxnwBRlC8A-71HqIgYF8gGyL58gw/viewform';

  static const String _absenceBaseUrl =
      'https://docs.google.com/forms/d/e/1FAIpQLScrCpasXj8y86o0_nHze3cg2NlXeN0-HN5pIMBq72SpCjYGng/viewform';

  static const String _overtimeBaseUrl =
      'https://docs.google.com/forms/d/e/1FAIpQLScObi5NaADs3O3HGn45zL4_ysRi469XLVCIWI-g1S4lk2p3Kg/viewform';

  static const String _excuseSlipBaseUrl =
      'https://docs.google.com/forms/d/e/1FAIpQLSesisStOL7pxLdZRn9XBRnPhcGtczeDk7P3pQX3n_KDWAfTbw/viewform';

  String buildClockInUrl(TimeOfDay time) {
    final hour = time.hour.toString();
    final minute = time.minute.toString().padLeft(2, '0');
    final query = {
      'entry.311364925': 'Clock In',
      'entry.1072714220_hour': hour,
      'entry.1072714220_minute': minute,
    };
    return _buildUrl(_clockInBaseUrl, query);
  }

  String buildClockOutUrl(TimeOfDay time, String accomplishment) {
    final hhmm =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    final query = {
      'entry.311364925': 'Clock Out',
      'entry.1943230368': hhmm,
      'entry.1843883804': accomplishment,
    };
    return _buildUrl(_clockInBaseUrl, query);
  }

  String buildAbsenceUrl({
    required String leaveType,
    required String startDate,
    required String endDate,
    required String reason,
  }) {
    final query = {
      'entry.311364925': leaveType,
      'entry.564886930': startDate,
      'entry.1517924971': endDate,
      'entry.1072714220': reason,
    };
    return _buildUrl(_absenceBaseUrl, query);
  }

  String buildOvertimeUrl({
    required String reason,
    required String startDate,
    required TimeOfDay timeStart,
    required String endDate,
    required TimeOfDay timeEnd,
    required String supervisor,
  }) {
    final query = {
      'entry.1072714220': reason,
      'entry.564886930': startDate,
      'entry.1517924971_hour': timeStart.hour.toString(),
      'entry.1517924971_minute': timeStart.minute.toString().padLeft(2, '0'),
      'entry.1118593729': endDate,
      'entry.1795724848_hour': timeEnd.hour.toString(),
      'entry.1795724848_minute': timeEnd.minute.toString().padLeft(2, '0'),
      'entry.2014934774': supervisor,
    };
    return _buildUrl(_overtimeBaseUrl, query);
  }

  String buildExcuseSlipUrl({
    required String missingAction,
    required String date,
    required TimeOfDay time,
    required String reason,
    required String supervisor,
  }) {
    final query = {
      'entry.311364925': missingAction,
      'entry.564886930': date,
      'entry.1517924971_hour': time.hour.toString(),
      'entry.1517924971_minute': time.minute.toString().padLeft(2, '0'),
      'entry.1072714220': reason,
      'entry.2080756385': supervisor,
    };
    return _buildUrl(_excuseSlipBaseUrl, query);
  }

  String _buildUrl(String baseUrl, Map<String, String> params) {
    final queryString = params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return '$baseUrl?$queryString';
  }
}