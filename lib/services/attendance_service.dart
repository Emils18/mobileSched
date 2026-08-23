import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/attendance_model.dart';

class AttendanceService {
  static final AttendanceService _instance = AttendanceService._internal();

  factory AttendanceService() => _instance;

  AttendanceService._internal();

  static const String _historyKey = 'mobilesched_logs';
  static const String _nameKey = 'mobilesched_user_name';
  static const String _dutyDaysKey = 'mobilesched_duty_days';
  static const String _timeInKey = 'mobilesched_time_in';
  static const String _timeOutKey = 'mobilesched_time_out';

  // New keys for Broken Schedule, Hourly Rate, and Custom Daily Schedules
  static const String _isBrokenScheduleKey = 'mobilesched_is_broken_schedule';
  static const String _customSchedulesKey = 'mobilesched_custom_schedules';
  static const String _hourlyRateKey = 'mobilesched_hourly_rate';

  static const TimeOfDay _defaultTimeIn = TimeOfDay(
    hour: 16,
    minute: 30,
  );

  static const TimeOfDay _defaultTimeOut = TimeOfDay(
    hour: 21,
    minute: 30,
  );

  late SharedPreferences _prefs;

  final Uuid _uuid = const Uuid();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await checkAndCleanExpiredHistory();
  }

  // ---------------- USER NAME ----------------
  String? getUserName() {
    final name = _prefs.getString(_nameKey)?.trim();

    if (name == null || name.isEmpty) {
      return null;
    }

    return name;
  }

  Future<void> setUserName(String name) async {
    await _prefs.setString(
      _nameKey,
      name.trim(),
    );
  }

  // ---------------- DUTY DAYS ----------------
  List<int> getDutyDays() {
    final storedDays = _prefs.getStringList(_dutyDaysKey);

    if (storedDays == null || storedDays.isEmpty) {
      return [1, 2, 3, 4, 5, 6];
    }

    final parsedDays = storedDays
        .map(int.tryParse)
        .whereType<int>()
        .where((day) => day >= 1 && day <= 7)
        .toSet()
        .toList()
      ..sort();

    if (parsedDays.isEmpty) {
      return [1, 2, 3, 4, 5, 6];
    }

    return parsedDays;
  }

  Future<void> setDutyDays(List<int> days) async {
    final validDays = days
        .where((day) => day >= 1 && day <= 7)
        .toSet()
        .toList()
      ..sort();

    await _prefs.setStringList(
      _dutyDaysKey,
      validDays.map((day) => day.toString()).toList(),
    );
  }

  // ---------------- BROKEN / CUSTOM SCHEDULE SUPPORT ----------------
  bool isBrokenScheduleEnabled() {
    return _prefs.getBool(_isBrokenScheduleKey) ?? false;
  }

  Future<void> setBrokenScheduleEnabled(bool enabled) async {
    await _prefs.setBool(_isBrokenScheduleKey, enabled);
  }

  TimeOfDay getScheduledTimeIn() {
    return _parseStoredTime(
      _prefs.getString(_timeInKey),
      _defaultTimeIn,
    );
  }

  TimeOfDay getScheduledTimeInForDay(int weekday) {
    if (!isBrokenScheduleEnabled()) {
      return getScheduledTimeIn();
    }

    final customSchedules = _getCustomSchedulesMap();
    final dayData = customSchedules[weekday.toString()];

    if (dayData != null && dayData['in'] != null) {
      return _parseStoredTime(dayData['in'], getScheduledTimeIn());
    }

    return getScheduledTimeIn();
  }

  Future<void> setScheduledTimeIn(TimeOfDay time) async {
    await _prefs.setString(
      _timeInKey,
      '${time.hour}:${time.minute}',
    );
  }

  TimeOfDay getScheduledTimeOut() {
    return _parseStoredTime(
      _prefs.getString(_timeOutKey),
      _defaultTimeOut,
    );
  }

  TimeOfDay getScheduledTimeOutForDay(int weekday) {
    if (!isBrokenScheduleEnabled()) {
      return getScheduledTimeOut();
    }

    final customSchedules = _getCustomSchedulesMap();
    final dayData = customSchedules[weekday.toString()];

    if (dayData != null && dayData['out'] != null) {
      return _parseStoredTime(dayData['out'], getScheduledTimeOut());
    }

    return getScheduledTimeOut();
  }

  Future<void> setScheduledTimeOut(TimeOfDay time) async {
    await _prefs.setString(
      _timeOutKey,
      '${time.hour}:${time.minute}',
    );
  }

  Future<void> setCustomScheduleForDay(
    int weekday,
    TimeOfDay timeIn,
    TimeOfDay timeOut,
  ) async {
    final customSchedules = _getCustomSchedulesMap();

    customSchedules[weekday.toString()] = {
      'in': '${timeIn.hour}:${timeIn.minute}',
      'out': '${timeOut.hour}:${timeOut.minute}',
    };

    await _prefs.setString(_customSchedulesKey, jsonEncode(customSchedules));
  }

  Map<String, dynamic> _getCustomSchedulesMap() {
    final jsonString = _prefs.getString(_customSchedulesKey);
    if (jsonString == null || jsonString.isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}

    return {};
  }

  bool isScheduleValid(TimeOfDay timeIn, TimeOfDay timeOut) {
    return _minutesOfDay(timeOut) > _minutesOfDay(timeIn);
  }

  // ---------------- HOURLY RATE & ALLOWANCE CALCULATOR ----------------
  double getHourlyRate() {
    return _prefs.getDouble(_hourlyRateKey) ?? 12.0;
  }

  Future<void> setHourlyRate(double rate) async {
    await _prefs.setDouble(_hourlyRateKey, rate);
  }

  double getMonthlyHours([DateTime? month]) {
    final target = month ?? DateTime.now();
    final logs = _getRawLogs();

    final targetLogs = logs.where((log) {
      return log.timestamp.year == target.year &&
          log.timestamp.month == target.month;
    }).toList();

    // Group logs by day to pair Clock In and Clock Out
    final dayMap = <String, List<AttendanceModel>>{};
    for (final log in targetLogs) {
      dayMap.putIfAbsent(log.date, () => []).add(log);
    }

    double totalMinutes = 0;

    for (final dayLogs in dayMap.values) {
      dayLogs.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      AttendanceModel? clockInLog;

      for (final log in dayLogs) {
        if (log.isClockIn) {
          clockInLog = log;
        } else if (log.isClockOut && clockInLog != null) {
          final duration = log.timestamp.difference(clockInLog.timestamp);
          if (!duration.isNegative) {
            totalMinutes += duration.inMinutes;
          }
          clockInLog = null; // Reset for next pair
        }
      }
    }

    return totalMinutes / 60.0;
  }

  double getEstimatedMonthlyAllowance([DateTime? month]) {
    return getMonthlyHours(month) * getHourlyRate();
  }

  // ---------------- 1-MONTH DATA EXPIRATION & CLEANUP ----------------
  Future<void> checkAndCleanExpiredHistory() async {
    final now = DateTime.now();
    final cutoffDate = DateTime(now.year, now.month - 1, 1);

    final logs = _getRawLogs();
    final activeLogs = logs.where((log) {
      return log.timestamp.isAfter(cutoffDate) ||
          log.timestamp.isAtSameMomentAs(cutoffDate);
    }).toList();

    if (activeLogs.length != logs.length) {
      await _saveLogs(activeLogs);
    }
  }

  // ---------------- ATTENDANCE LOGS & HISTORY ----------------
  List<AttendanceModel> getHistory() {
    final logs = _getRawLogs()
      ..sort(
        (first, second) => second.timestamp.compareTo(first.timestamp),
      );

    return logs;
  }

  List<AttendanceModel> getTodayLogs() {
    final today = _todayString();

    final logs = _getRawLogs()
        .where((log) => log.date == today)
        .toList()
      ..sort(
        (first, second) => first.timestamp.compareTo(second.timestamp),
      );

    return logs;
  }

  int getTotalDaysPresent() {
    final datesWithClockIn = _getRawLogs()
        .where((log) => log.type == 'in')
        .map((log) => log.date)
        .toSet();

    return datesWithClockIn.length;
  }

  bool hasLogOfTypeToday(String type) {
    final normalizedType = type.toLowerCase();
    final today = _todayString();

    return _getRawLogs().any(
      (log) => log.date == today && log.type == normalizedType,
    );
  }

  Future<AttendanceModel> timeIn() async {
    final now = DateTime.now();

    final log = AttendanceModel(
      id: _uuid.v4(),
      timestamp: now,
      type: 'in',
      status: _calculateInStatus(now),
      formStatus: null,
    );

    final logs = _getRawLogs();
    logs.add(log);

    await _saveLogs(logs);

    return log;
  }

  Future<AttendanceModel> timeOut(String accomplishment) async {
    final cleanAccomplishment = accomplishment.trim();

    if (cleanAccomplishment.isEmpty) {
      throw Exception('Please enter your daily accomplishment.');
    }

    final now = DateTime.now();

    final log = AttendanceModel(
      id: _uuid.v4(),
      timestamp: now,
      type: 'out',
      status: _calculateOutStatus(now),
      accomplishment: cleanAccomplishment,
      formStatus: null,
    );

    final logs = _getRawLogs();
    logs.add(log);

    await _saveLogs(logs);

    return log;
  }

  Future<void> updateFormStatus(
    String logId,
    String? formStatus,
  ) async {
    final logs = _getRawLogs();
    final index = logs.indexWhere((log) => log.id == logId);

    if (index == -1) {
      return;
    }

    logs[index] = formStatus == null
        ? logs[index].copyWith(clearFormStatus: true)
        : logs[index].copyWith(formStatus: formStatus);

    await _saveLogs(logs);
  }

  Future<bool> undoLastLog() async {
    final logs = _getRawLogs();
    final today = _todayString();

    final todayIndexes = <int>[];

    for (int index = 0; index < logs.length; index++) {
      if (logs[index].date == today) {
        todayIndexes.add(index);
      }
    }

    if (todayIndexes.isEmpty) {
      return false;
    }

    int latestIndex = todayIndexes.first;

    for (final index in todayIndexes.skip(1)) {
      if (logs[index]
          .timestamp
          .isAfter(logs[latestIndex].timestamp)) {
        latestIndex = index;
      }
    }

    logs.removeAt(latestIndex);
    await _saveLogs(logs);

    return true;
  }

  Future<void> clearTodayLogs() async {
    final today = _todayString();

    final remainingLogs = _getRawLogs()
        .where((log) => log.date != today)
        .toList();

    await _saveLogs(remainingLogs);
  }

  List<AttendanceModel> _getRawLogs() {
    final data = _prefs.getStringList(_historyKey);

    if (data == null || data.isEmpty) {
      return [];
    }

    final validLogs = <AttendanceModel>[];

    for (final item in data) {
      try {
        final log = AttendanceModel.fromJson(item);

        if (log.id.isNotEmpty) {
          validLogs.add(log);
        }
      } catch (_) {
        // Ignore invalid entry instead of crashing
      }
    }

    return validLogs;
  }

  Future<void> _saveLogs(List<AttendanceModel> logs) async {
    final encodedLogs = logs
        .map((log) => log.toJson())
        .toList();

    await _prefs.setStringList(
      _historyKey,
      encodedLogs,
    );
  }

  String _calculateInStatus(DateTime timestamp) {
    if (!getDutyDays().contains(timestamp.weekday)) {
      return 'NO DUTY DAY';
    }

    final scheduledIn = getScheduledTimeInForDay(timestamp.weekday);
    final scheduledOut = getScheduledTimeOutForDay(timestamp.weekday);

    final scheduledInDate = _combineDateAndTime(
      timestamp,
      scheduledIn,
    );

    final scheduledOutDate = _combineDateAndTime(
      timestamp,
      scheduledOut,
    );

    final earliestAllowed = scheduledInDate.subtract(
      const Duration(minutes: 15),
    );

    if (timestamp.isBefore(earliestAllowed) ||
        timestamp.isAfter(scheduledOutDate)) {
      return 'OUTSIDE SCHEDULE';
    }

    if (timestamp.isAfter(scheduledInDate)) {
      return 'LATE';
    }

    return 'ON TIME';
  }

  String _calculateOutStatus(DateTime timestamp) {
    if (!getDutyDays().contains(timestamp.weekday)) {
      return 'NO DUTY DAY';
    }

    final scheduledIn = getScheduledTimeInForDay(timestamp.weekday);
    final scheduledOut = getScheduledTimeOutForDay(timestamp.weekday);

    final scheduledInDate = _combineDateAndTime(
      timestamp,
      scheduledIn,
    );

    final scheduledOutDate = _combineDateAndTime(
      timestamp,
      scheduledOut,
    );

    final earliestAllowed = scheduledOutDate.subtract(
      const Duration(minutes: 15),
    );

    if (timestamp.isBefore(scheduledInDate)) {
      return 'OUTSIDE SCHEDULE';
    }

    if (timestamp.isBefore(earliestAllowed)) {
      return 'EARLY OUT';
    }

    if (timestamp.isAfter(scheduledOutDate.add(
      const Duration(minutes: 15),
    ))) {
      return 'LATE OUT';
    }

    return 'ON TIME';
  }

  TimeOfDay _parseStoredTime(
    String? value,
    TimeOfDay fallback,
  ) {
    if (value == null || value.isEmpty) {
      return fallback;
    }

    final parts = value.split(':');

    if (parts.length != 2) {
      return fallback;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return fallback;
    }

    return TimeOfDay(
      hour: hour,
      minute: minute,
    );
  }

  DateTime _combineDateAndTime(
    DateTime date,
    TimeOfDay time,
  ) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  int _minutesOfDay(TimeOfDay time) {
    return (time.hour * 60) + time.minute;
  }

  String _todayString() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');

    return '${now.year}-$month-$day';
  }
}