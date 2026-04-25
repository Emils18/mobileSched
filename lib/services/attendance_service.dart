import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/attendance_model.dart';

class AttendanceService extends ChangeNotifier {
  List<AttendanceModel> _attendances = [];
  static const String _storageKey = 'attendance_records';

  List<AttendanceModel> get attendances => List.unmodifiable(_attendances);

  // Get today's attendance record
  AttendanceModel? get todayAttendance {
    final today = DateTime.now();
    try {
      return _attendances.firstWhere(
        (record) =>
            record.timeIn.year == today.year &&
            record.timeIn.month == today.month &&
            record.timeIn.day == today.day,
      );
    } catch (e) {
      return null;
    }
  }

  // Get last 3 records for history preview
  List<AttendanceModel> get historyPreview {
    final sorted = List<AttendanceModel>.from(_attendances)
      ..sort((a, b) => b.timeIn.compareTo(a.timeIn));
    return sorted.take(5).toList();
  }

  // Today's status text
  String get todayStatus {
    final today = todayAttendance;
    if (today == null) return 'Not Started';
    if (today.timeOut != null) return 'Completed ✓';
    return 'Clocked In ⏺';
  }

  // Last Time In (today or most recent)
  String get lastTimeIn {
    if (todayAttendance != null) {
      return todayAttendance!.formattedTimeIn;
    }
    if (_attendances.isEmpty) return '—';
    final latest = _attendances.reduce((a, b) => a.timeIn.isAfter(b.timeIn) ? a : b);
    return latest.formattedTimeIn;
  }

  // Last Time Out (today or most recent)
  String get lastTimeOut {
    final completed = _attendances.where((a) => a.timeOut != null);
    if (todayAttendance?.timeOut != null) {
      return todayAttendance!.formattedTimeOut;
    }
    if (completed.isEmpty) return '—';
    final latest = completed.reduce((a, b) => a.timeOut!.isAfter(b.timeOut!) ? a : b);
    return latest.formattedTimeOut;
  }

  AttendanceService() {
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      _attendances = jsonList.map((json) => AttendanceModel.fromJson(json)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _attendances.map((record) => record.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  // Time In Logic
  Future<bool> timeIn(BuildContext context, {required VoidCallback onSuccess, required VoidCallback onError}) async {
    final now = DateTime.now();

    // Check if already timed in today
    if (todayAttendance != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Already have a Time In for today!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
      );
      onError();
      return false;
    }

    final newRecord = AttendanceModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timeIn: now,
      timeOut: null,
    );

    _attendances.add(newRecord);
    await _saveData();
    notifyListeners();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Time In recorded successfully!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
    );
    onSuccess();
    return true;
  }

  // Time Out Logic
  Future<bool> timeOut(BuildContext context, {required VoidCallback onSuccess, required VoidCallback onError}) async {
    final today = todayAttendance;

    if (today == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please do Time In first!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.orange),
      );
      onError();
      return false;
    }

    if (today.timeOut != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Time Out already recorded for today!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
      );
      onError();
      return false;
    }

    // Update existing record
    final index = _attendances.indexOf(today);
    final updatedRecord = AttendanceModel(
      id: today.id,
      timeIn: today.timeIn,
      timeOut: DateTime.now(),
    );
    _attendances[index] = updatedRecord;
    await _saveData();
    notifyListeners();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Time Out recorded successfully!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
    );
    onSuccess();
    return true;
  }
}