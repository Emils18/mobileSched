import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/attendance_model.dart';
import '../utils/constants.dart';

class AttendanceService {
  static final AttendanceService _instance = AttendanceService._internal();
  factory AttendanceService() => _instance;
  AttendanceService._internal();

  late SharedPreferences _prefs;
  static const String _historyKey = 'mobilesched_logs';
  static const String _nameKey = 'mobilesched_user_name';
  static const String _dutyDaysKey = 'mobilesched_duty_days';
  static const String _timeInKey = 'mobilesched_time_in';
  static const String _timeOutKey = 'mobilesched_time_out';

  final _uuid = const Uuid();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- SETTINGS / SCHEDULE (unchanged) ---
  String? getUserName() => _prefs.getString(_nameKey);
  Future<void> setUserName(String name) async =>
      await _prefs.setString(_nameKey, name);

  List<int> getDutyDays() {
    final days = _prefs.getStringList(_dutyDaysKey);
    if (days == null) return [1, 2, 3, 4, 5, 6];
    return days.map((e) => int.parse(e)).toList();
  }

  Future<void> setDutyDays(List<int> days) async {
    await _prefs.setStringList(_dutyDaysKey, days.map((e) => e.toString()).toList());
  }

  TimeOfDay getScheduledTimeIn() {
    final str = _prefs.getString(_timeInKey);
    if (str == null) return const TimeOfDay(hour: 16, minute: 30);
    final parts = str.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Future<void> setScheduledTimeIn(TimeOfDay time) async {
    await _prefs.setString(_timeInKey, "${time.hour}:${time.minute}");
  }

  TimeOfDay getScheduledTimeOut() {
    final str = _prefs.getString(_timeOutKey);
    if (str == null) return const TimeOfDay(hour: 21, minute: 30);
    final parts = str.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Future<void> setScheduledTimeOut(TimeOfDay time) async {
    await _prefs.setString(_timeOutKey, "${time.hour}:${time.minute}");
  }

  // --- ATTENDANCE LOGS ---
  List<AttendanceModel> _getRawLogs() {
    final List<String>? data = _prefs.getStringList(_historyKey);
    if (data == null) return [];
    return data.map((e) => AttendanceModel.fromJson(e)).toList();
  }

  Future<void> _saveLogs(List<AttendanceModel> logs) async {
    final data = logs.map((e) => e.toJson()).toList();
    await _prefs.setStringList(_historyKey, data);
  }

  /// Returns all logs in reverse chronological order.
  List<AttendanceModel> getHistory() => _getRawLogs().reversed.toList();

  /// Returns logs for today (date == current date).
  List<AttendanceModel> getTodayLogs() {
    final todayStr = _todayString();
    return _getRawLogs().where((l) => l.date == todayStr).toList();
  }

  int getTotalDaysPresent() {
    final dates = _getRawLogs().map((l) => l.date).toSet();
    return dates.length;
  }

  String _todayString() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  String _calculateInStatus(DateTime timestamp) {
    final weekday = timestamp.weekday;
    if (!getDutyDays().contains(weekday)) return "NO DUTY DAY";

    final schedIn = getScheduledTimeIn();
    final schedOut = getScheduledTimeOut();
    final schedInDT = DateTime(timestamp.year, timestamp.month, timestamp.day, schedIn.hour, schedIn.minute);
    final schedOutDT = DateTime(timestamp.year, timestamp.month, timestamp.day, schedOut.hour, schedOut.minute);

    if (timestamp.isBefore(schedInDT.subtract(const Duration(minutes: 15)))) return "OUTSIDE SCHEDULE";
    if (timestamp.isAfter(schedOutDT)) return "OUTSIDE SCHEDULE";
    if (timestamp.isAfter(schedInDT)) return "LATE";
    return "ON TIME";
  }

  String _calculateOutStatus(DateTime timestamp) {
    final weekday = timestamp.weekday;
    if (!getDutyDays().contains(weekday)) return "NO DUTY DAY";

    final schedIn = getScheduledTimeIn();
    final schedOut = getScheduledTimeOut();
    final schedInDT = DateTime(timestamp.year, timestamp.month, timestamp.day, schedIn.hour, schedIn.minute);
    final schedOutDT = DateTime(timestamp.year, timestamp.month, timestamp.day, schedOut.hour, schedOut.minute);

    if (timestamp.isBefore(schedInDT)) return "OUTSIDE SCHEDULE";
    if (timestamp.isAfter(schedOutDT)) return "MANUAL ENTRY";
    if (timestamp.isBefore(schedOutDT.subtract(const Duration(minutes: 15)))) return "MANUAL ENTRY";
    return "ON TIME";
  }

  Future<AttendanceModel> timeIn() async {
    final now = DateTime.now();
    final status = _calculateInStatus(now);
    final log = AttendanceModel(
      id: _uuid.v4(),
      timestamp: now,
      type: 'in',
      status: status,
    );
    final logs = _getRawLogs();
    logs.add(log);
    await _saveLogs(logs);
    return log;
  }

  // NEW method – update form status of a specific log
  Future<void> updateFormStatus(String logId, String? formStatus) async {
    final logs = _getRawLogs();
    final index = logs.indexWhere((log) => log.id == logId);
    if (index != -1) {
      logs[index] = AttendanceModel(
        id: logs[index].id,
        timestamp: logs[index].timestamp,
        type: logs[index].type,
        status: logs[index].status,
        accomplishment: logs[index].accomplishment,
        formStatus: formStatus,
      );
      await _saveLogs(logs);
    }
  }

  Future<AttendanceModel> timeOut(String accomplishment) async {
    final now = DateTime.now();
    final status = _calculateOutStatus(now);
    final log = AttendanceModel(
      id: _uuid.v4(),
      timestamp: now,
      type: 'out',
      status: status,
      accomplishment: accomplishment,
    );
    final logs = _getRawLogs();
    logs.add(log);
    await _saveLogs(logs);
    return log;
  }

  Future<void> undoLastLog() async {
    final logs = _getRawLogs();
    if (logs.isNotEmpty) {
      logs.removeLast();
      await _saveLogs(logs);
    }
  }

  Future<void> clearTodayLogs() async {
    final todayStr = _todayString();
    final logs = _getRawLogs().where((l) => l.date != todayStr).toList();
    await _saveLogs(logs);
  }

  bool hasLogOfTypeToday(String type) {
    final todayStr = _todayString();
    return _getRawLogs().any((l) => l.date == todayStr && l.type == type);
  }
}