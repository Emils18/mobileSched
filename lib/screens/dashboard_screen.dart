import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/attendance_service.dart';
import '../services/notification_service.dart';
import '../services/google_form_service.dart';
import '../services/prefilled_form_service.dart';
import '../services/pending_submission_service.dart';
import '../models/attendance_model.dart';
import '../utils/constants.dart';
import '../widgets/glass_card.dart';
import '../widgets/premium_button.dart';
import '../widgets/status_chip.dart';
import '../widgets/hub_updates_section.dart';
import '../services/web_push_profile_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  final AttendanceService _service = AttendanceService();
  List<AttendanceModel> _todayLogs = [];
  List<AttendanceModel> _history = [];

  String? _userName;
  List<int> _dutyDays = [];
  int _totalDays = 0;

  double _monthlyHours = 0.0;
  double _monthlyAllowance = 0.0;
  double _hourlyRate = 12.0;

  DateTime _currentTime = DateTime.now();
  Timer? _timer;

  PendingSubmission? _pendingSubmission;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _loadData();
    _startTimer();
    _checkPendingSubmission();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _scheduleSavedReminders();

      if (!mounted) {
        return;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPendingSubmission();
    }
  }

  void _checkPendingSubmission() {
    final pending = PendingSubmissionService().pending;
    if (pending != null && mounted) {
      setState(() => _pendingSubmission = pending);
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  void _loadData() {
    if (!mounted) {
      return;
    }

    setState(() {
      _userName = _service.getUserName();
      _dutyDays = _service.getDutyDays();
      _todayLogs = _service.getTodayLogs();
      _history = _service.getHistory().take(5).toList();
      _totalDays = _service.getTotalDaysPresent();
      _monthlyHours = _service.getMonthlyHours();
      _monthlyAllowance = _service.getEstimatedMonthlyAllowance();
      _hourlyRate = _service.getHourlyRate();
    });
  }

  Future<void> _scheduleSavedReminders() async {
    try {
      if (kIsWeb) {
        await const WebPushProfileService().syncSchedule(
          dutyDays: _service.getDutyDays(),
          timeInForDay: _service.getScheduledTimeInForDay,
        );
        return;
      }

      await NotificationService().scheduleReminders(
        dutyDays: _service.getDutyDays(),
        timeIn: _service.getScheduledTimeIn(),
        timeOut: _service.getScheduledTimeOut(),
        timeInReminderMinutes:
            _service.getTimeInReminderMinutes(),
        timeOutReminderMinutes:
            _service.getTimeOutReminderMinutes(),
      );
    } catch (error) {
      debugPrint('Failed to schedule reminders: $error');
    }
  }

  // ignore: unused_element
  void _showAllowanceBreakdownDialog() {
    final logs = _service.getHistory();
    final now = DateTime.now();
    final totalDaysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final currentDay = now.day;

    final monthLogs = logs.where((log) {
      return log.timestamp.year == now.year &&
          log.timestamp.month == now.month;
    }).toList();

    final dayMap = <String, List<AttendanceModel>>{};
    for (final log in monthLogs) {
      dayMap.putIfAbsent(log.date, () => []).add(log);
    }

    final dailyItems = <Map<String, dynamic>>[];
    double calculatedTotalHours = 0.0;

    for (int day = 1; day <= currentDay; day++) {
      final dateObj = DateTime(now.year, now.month, day);
      final monthStr = now.month.toString().padLeft(2, '0');
      final dayStr = day.toString().padLeft(2, '0');
      final dateKey = "${now.year}-$monthStr-$dayStr";

      final isDuty = _dutyDays.contains(dateObj.weekday);
      final dayLogs = dayMap[dateKey] ?? [];
      dayLogs.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      AttendanceModel? inLog;
      double dayHours = 0.0;

      for (final log in dayLogs) {
        if (log.isClockIn) {
          inLog = log;
        } else if (log.isClockOut && inLog != null) {
          final duration = log.timestamp.difference(inLog.timestamp);
          if (!duration.isNegative) {
            dayHours += duration.inMinutes / 60.0;
          }
          inLog = null;
        }
      }

      calculatedTotalHours += dayHours;
      final earnings = dayHours * _hourlyRate;

      String statusText;
      if (dayHours > 0) {
        statusText = "${dayHours.toStringAsFixed(1)}h • ₱${earnings.toStringAsFixed(2)}";
      } else if (isDuty) {
        statusText = "Missed (₱0.00)";
      } else {
        statusText = "Day Off";
      }

      dailyItems.add({
        'day': AppFormatters.formatDate(dateKey),
        'hours': dayHours,
        'earnings': earnings,
        'statusText': statusText,
        'hasLog': dayHours > 0,
        'isDuty': isDuty,
      });
    }

    final totalEarnings = calculatedTotalHours * _hourlyRate;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgDeep,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.cardBorder)),
        title: Row(
          children: [
            const Icon(Icons.payments_rounded, color: AppColors.success),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Allowance Tracker (Day 1-$currentDay/$totalDaysInMonth)",
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 360,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Rate: ₱${_hourlyRate.toStringAsFixed(2)}/hr • Month Total: ${calculatedTotalHours.toStringAsFixed(1)} hrs",
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: dailyItems.reversed.map((item) {
                      final bool hasLog = item['hasLog'] as bool;
                      final bool isDuty = item['isDuty'] as bool;

                      Color borderColor = AppColors.cardBorder;
                      Color textColor = AppColors.textMuted;
                      if (hasLog) {
                        borderColor = AppColors.success.withValues(alpha: 0.5);
                        textColor = AppColors.success;
                      } else if (isDuty) {
                        borderColor = AppColors.error.withValues(alpha: 0.4);
                        textColor = AppColors.error;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.cardGlass,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item['day'] as String,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  item['statusText'] as String,
                                  textAlign: TextAlign.end,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("ACCUMULATED ALLOWANCE",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                    Text("₱${totalEarnings.toStringAsFixed(2)}",
                        style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w900, fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close", style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }



  void _showFeedback(String message, {bool isError = false}) {
    if (!context.mounted) return;
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
                color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
                child: Text(message,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600))),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(24),
        elevation: 10,
      ),
    );
  }

  Future<bool> _confirmRepeat(String action) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgDeep,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.cardBorder)),
        title: const Text("Repeat Action?",
            style: TextStyle(color: Colors.white)),
        content: Text("You already logged $action today. Add another record?",
            style: const TextStyle(color: AppColors.textBody)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel",
                  style: TextStyle(color: AppColors.textBody))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Add Another",
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _handleTimeIn() async {
    try {
      if (_service.hasLogOfTypeToday('in')) {
        final proceed = await _confirmRepeat("Clock In");
        if (!proceed) return;
      }
      final log = await _service.timeIn();
      if (!kIsWeb) {
        await NotificationService().cancelTodayTimeInReminders();
      }
      if (!context.mounted) return;
      _showFeedback("Local log saved (${log.status})");

      if (GoogleFormService().isEnabled) {
        final now = TimeOfDay.fromDateTime(log.timestamp);
        final url = PrefilledFormService().buildClockInUrl(now);
        await _showFormInstructionAndLaunch(url, log.id, 'in');
      }

      _loadData();
    } catch (e) {
      _showFeedback(e.toString().replaceAll('Exception: ', ''), isError: true);
    }
  }

  Future<void> _handleTimeOut() async {
    final TextEditingController accController = TextEditingController();

    final shouldProceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgDeep,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.cardBorder)),
        title: const Text("Daily Accomplishment",
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("What did you accomplish today?",
                style: TextStyle(color: AppColors.textBody, fontSize: 14)),
            const SizedBox(height: 16),
            TextField(
              controller: accController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.3),
                hintText: "Enter accomplishment...",
                hintStyle: const TextStyle(color: AppColors.textMuted),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel",
                  style: TextStyle(color: AppColors.textBody))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              if (accController.text.trim().isEmpty) return;
              Navigator.pop(context, true);
            },
            child: const Text("Submit",
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (shouldProceed != true) return;

    try {
      if (_service.hasLogOfTypeToday('out')) {
        final proceed = await _confirmRepeat("Clock Out");
        if (!proceed) return;
      }
      final log = await _service.timeOut(
        accController.text.trim(),
      );
      if (!kIsWeb) {
        await NotificationService().cancelTodayTimeOutReminders();
      }
      if (!context.mounted) return;
      _showFeedback("Local log saved (${log.status})");

      if (GoogleFormService().isEnabled) {
        final now = TimeOfDay.fromDateTime(log.timestamp);
        final url = PrefilledFormService().buildClockOutUrl(
            now, accController.text.trim());
        await _showFormInstructionAndLaunch(url, log.id, 'out');
      }

      _loadData();
    } catch (e) {
      _showFeedback(e.toString().replaceAll('Exception: ', ''), isError: true);
    }
  }

 


void _showAbsenceDialog() {
    final reasonController = TextEditingController();
   String selectedLeaveType = 'Sick';

    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now();

    final leaveOptions = ['Sick', 'Academic', 'Emergency'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final now = DateTime.now();
          final startStr = "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";
          final endStr = "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";

          return AlertDialog(
            backgroundColor: AppColors.bgDeep,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: AppColors.cardBorder)),
            title: const Row(
              children: [
                Icon(Icons.event_busy_rounded, color: AppColors.orange),
                SizedBox(width: 10),
                Text("Absence Request", style: TextStyle(color: Colors.white, fontSize: 18)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("TYPE OF LEAVE:", style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: leaveOptions.map((type) {
                      final isSelected = selectedLeaveType == type;
                      return ChoiceChip(
                        label: Text(type),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setDialogState(() => selectedLeaveType = type);
                          }
                        },
                        selectedColor: AppColors.orange.withValues(alpha: 0.2),
                        backgroundColor: AppColors.cardGlass,
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.orange : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                        showCheckmark: false,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  const Text("DATES OF ABSENCE:", style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: dialogCtx,
                              initialDate: startDate,
                              firstDate: DateTime(now.year, now.month - 1),
                              lastDate: DateTime(now.year, now.month + 2),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                startDate = picked;
                                if (endDate.isBefore(startDate)) endDate = startDate;
                              });
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: AppColors.cardBorder),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: Text("Start: $startStr", style: const TextStyle(fontSize: 11)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: dialogCtx,
                              initialDate: endDate,
                              firstDate: startDate,
                              lastDate: DateTime(now.year, now.month + 2),
                            );
                            if (picked != null) {
                              setDialogState(() => endDate = picked);
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: AppColors.cardBorder),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: Text("End: $endStr", style: const TextStyle(fontSize: 11)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text("REASON FOR ABSENCE:", style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: reasonController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.3),
                      hintText: "Enter detailed reason...",
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel", style: TextStyle(color: AppColors.textBody))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () async {
                  final reason = reasonController.text.trim();
                  if (reason.isEmpty) return;
                  Navigator.pop(ctx);

                  _showFeedback("Absence Request ($selectedLeaveType) saved.");

                  if (GoogleFormService().isEnabled) {
                    final url = PrefilledFormService().buildAbsenceUrl(
                      leaveType: selectedLeaveType,
                      startDate: startStr,
                      endDate: endStr,
                      reason: reason,
                    );
                    await _launchFormUrl(url);
                  }
                },
                child: const Text("Submit & Open Form",
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }



void _showOvertimeDialog() {
    final reasonController = TextEditingController();
    final supervisorController = TextEditingController();
    final now = DateTime.now();

    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now();
    TimeOfDay timeStart = const TimeOfDay(hour: 17, minute: 0);
    TimeOfDay timeEnd = const TimeOfDay(hour: 19, minute: 0);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final startStr = AppFormatters.formatTimeOfDay(timeStart);
          final endStr = AppFormatters.formatTimeOfDay(timeEnd);
          final startDateStr = "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";
          final endDateStr = "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";

          return AlertDialog(
            backgroundColor: AppColors.bgDeep,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: AppColors.cardBorder)),
            title: const Row(
              children: [
                Icon(Icons.more_time_rounded, color: AppColors.primary),
                SizedBox(width: 10),
                Expanded(
                  child: Text("Overtime / Work Authorization",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("WORK AUTHORIZATION DATES:",
                      style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: dialogCtx,
                              initialDate: startDate,
                              firstDate: DateTime(now.year, now.month - 1),
                              lastDate: DateTime(now.year, now.month + 2),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                startDate = picked;
                                if (endDate.isBefore(startDate)) endDate = startDate;
                              });
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: AppColors.cardBorder),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: Text("Start: $startDateStr", style: const TextStyle(fontSize: 10)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: dialogCtx,
                              initialDate: endDate,
                              firstDate: startDate,
                              lastDate: DateTime(now.year, now.month + 2),
                            );
                            if (picked != null) setDialogState(() => endDate = picked);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: AppColors.cardBorder),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: Text("End: $endDateStr", style: const TextStyle(fontSize: 10)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text("OVERTIME SHIFT TIMES:",
                      style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(context: dialogCtx, initialTime: timeStart);
                            if (picked != null) setDialogState(() => timeStart = picked);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: AppColors.cardBorder),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: Text("Time In: $startStr", style: const TextStyle(fontSize: 11)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(context: dialogCtx, initialTime: timeEnd);
                            if (picked != null) setDialogState(() => timeEnd = picked);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: AppColors.cardBorder),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: Text("Time Out: $endStr", style: const TextStyle(fontSize: 11)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text("SUPERVISOR NAME:",
                      style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: supervisorController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.3),
                      hintText: "Enter supervisor name...",
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text("REASON / TASKS PERFORMED:",
                      style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: reasonController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.3),
                      hintText: "Enter tasks...",
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel", style: TextStyle(color: AppColors.textBody))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () async {
                  final reason = reasonController.text.trim();
                  final supervisor = supervisorController.text.trim();
                  if (reason.isEmpty || supervisor.isEmpty) return;
                  Navigator.pop(ctx);

                  _showFeedback("Overtime Request recorded.");
                  _loadData();

                  if (GoogleFormService().isEnabled) {
                    final url = PrefilledFormService().buildOvertimeUrl(
                      reason: reason,
                      startDate: startDateStr,
                      timeStart: timeStart,
                      endDate: endDateStr,
                      timeEnd: timeEnd,
                      supervisor: supervisor,
                    );
                    await _launchFormUrl(url);
                  }
                },
                child: const Text("Submit & Open Form",
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showWorkAuthDialog() {
    final supervisorController = TextEditingController();
    final now = DateTime.now();
    DateTime incidentDate = DateTime.now();
    TimeOfDay incidentTime = TimeOfDay.fromDateTime(now);
    String selectedAction = "Clock In";
    String selectedReason = "Forgot";

    final excuseReasons = [
      "Forgot",
      "Emergency",
      "Phone Battery",
      "Technical Issue : No Internet",
      "System Error",
      "OB"
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final timeStr = AppFormatters.formatTimeOfDay(incidentTime);
          final dateStr = "${incidentDate.year}-${incidentDate.month.toString().padLeft(2, '0')}-${incidentDate.day.toString().padLeft(2, '0')}";

          return AlertDialog(
            backgroundColor: AppColors.bgDeep,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: AppColors.cardBorder)),
            title: const Row(
              children: [
                Icon(Icons.receipt_long_rounded, color: AppColors.secondary),
                SizedBox(width: 10),
                Expanded(
                  child: Text("Clock In/Out Excuse Slip",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("MISSING ACTION:",
                      style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    children: ["Clock In", "Clock Out"].map((action) {
                      final isSelected = selectedAction == action;
                      return ChoiceChip(
                        label: Text(action),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setDialogState(() => selectedAction = action);
                        },
                        selectedColor: AppColors.secondary.withValues(alpha: 0.2),
                        backgroundColor: AppColors.cardGlass,
                        labelStyle: TextStyle(
                            color: isSelected ? AppColors.secondary : Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 11),
                        showCheckmark: false,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text("INCIDENT DATE & TIME:",
                      style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: dialogCtx,
                              initialDate: incidentDate,
                              firstDate: DateTime(now.year, now.month - 1),
                              lastDate: DateTime(now.year, now.month + 2),
                            );
                            if (picked != null) setDialogState(() => incidentDate = picked);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: AppColors.cardBorder),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: Text("Date: $dateStr", style: const TextStyle(fontSize: 10)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(context: dialogCtx, initialTime: incidentTime);
                            if (picked != null) setDialogState(() => incidentTime = picked);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: AppColors.cardBorder),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: Text("Time: $timeStr", style: const TextStyle(fontSize: 11)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text("REASON FOR FAILURE:",
                      style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: excuseReasons.map((reason) {
                      final isSelected = selectedReason == reason;
                      return ChoiceChip(
                        label: Text(reason),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setDialogState(() => selectedReason = reason);
                        },
                        selectedColor: AppColors.secondary.withValues(alpha: 0.2),
                        backgroundColor: AppColors.cardGlass,
                        labelStyle: TextStyle(
                            color: isSelected ? AppColors.secondary : Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 10),
                        showCheckmark: false,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text("SUPERVISOR VERIFICATION:",
                      style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: supervisorController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.3),
                      hintText: "Enter supervisor name...",
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel", style: TextStyle(color: AppColors.textBody))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () async {
                  final supervisor = supervisorController.text.trim();
                  if (supervisor.isEmpty) return;
                  Navigator.pop(ctx);

                  _showFeedback("Excuse Slip Request submitted.");

                  if (GoogleFormService().isEnabled) {
                    final url = PrefilledFormService().buildExcuseSlipUrl(
                      missingAction: selectedAction,
                      date: dateStr,
                      time: incidentTime,
                      reason: selectedReason,
                      supervisor: supervisor,
                    );
                    await _launchFormUrl(url);
                  }
                },
                child: const Text("Submit & Open Form",
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }














  Future<void> _showFormInstructionAndLaunch(
      String url, String logId, String type) async {
    await showModalBottomSheet(
      context: context,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassCard(
        padding: const EdgeInsets.all(24),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.open_in_browser,
                size: 40, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              "After submitting the form, return to AWS HUB to confirm.",
              style: TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            PremiumButton(
              text: "Open Form",
              icon: Icons.open_in_new,
              onTap: () async {
                Navigator.pop(ctx);
                await _launchFormUrl(url);
              },
            ),
          ],
        ),
      ),
    );

    final pending = PendingSubmission(
      logId: logId,
      type: type,
      url: url,
    );
    await PendingSubmissionService().setPending(pending);
    if (!context.mounted) return;
    setState(() => _pendingSubmission = pending);
  }

  Future<void> _launchFormUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!context.mounted) return;
      _showFeedback("Could not open browser", isError: true);
    }
  }

  Future<void> _submitConfirmation(String action) async {
    final pending = _pendingSubmission;
    if (pending == null) return;

    if (action == 'yes') {
      await _service.updateFormStatus(pending.logId, 'submitted');
      if (!context.mounted) return;
      _showFeedback("Google Form submitted successfully");
    } else if (action == 'retry') {
      await _launchFormUrl(pending.url);
      return;
    } else if (action == 'cancel') {
      await _service.updateFormStatus(pending.logId, 'not_submitted');
      if (!context.mounted) return;
      _showFeedback("Form marked as not submitted");
    }

    await PendingSubmissionService().clear();
    if (!context.mounted) return;
    setState(() {
      _pendingSubmission = null;
      _loadData();
    });
  }

  Map<String, dynamic> _getDashboardState() {
    final now = _currentTime;
    final weekday = now.weekday;
    final isDutyDay = _dutyDays.contains(weekday);

    if (!isDutyDay) {
      return {
        "title": "No Duty Today",
        "sub": "Enjoy your day off.",
        "color": AppColors.textMuted,
        "icon": Icons.weekend,
        "warn": false,
        "countdown": "",
      };
    }

    final schedIn = _service.getScheduledTimeInForDay(weekday);
    final schedOut = _service.getScheduledTimeOutForDay(weekday);

    final schedInDT = DateTime(
        now.year, now.month, now.day, schedIn.hour, schedIn.minute);
    final schedOutDT = DateTime(
        now.year, now.month, now.day, schedOut.hour, schedOut.minute);

    final hasIn = _todayLogs.any((l) => l.type == 'in');
    final hasOut = _todayLogs.any((l) => l.type == 'out');

    if (!hasIn) {
      if (now.isAfter(schedInDT)) {
        final diff = now.difference(schedInDT);
        final minutes = diff.inMinutes;
        return {
          "title": "Late / Missing Time In",
          "sub": "Shift started at ${AppFormatters.formatTimeOfDay(schedIn)}.",
          "color": AppColors.error,
          "icon": Icons.warning_amber_rounded,
          "warn": true,
          "countdown": "You are late by $minutes minutes",
        };
      } else {
        final diff = schedInDT.difference(now);
        final minutes = diff.inMinutes;
        if (minutes <= 15 && minutes > 0) {
          return {
            "title": "Almost Time In",
            "sub":
                "Shift starts at ${AppFormatters.formatTimeOfDay(schedIn)}.",
            "color": AppColors.orange,
            "icon": Icons.alarm,
            "warn": false,
            "countdown": "Starts in $minutes minutes",
          };
        } else {
          return {
            "title": "Duty Later",
            "sub":
                "Shift starts at ${AppFormatters.formatTimeOfDay(schedIn)}.",
            "color": AppColors.primary,
            "icon": Icons.schedule,
            "warn": false,
            "countdown":
                "Starts in ${diff.inHours}h ${(diff.inMinutes % 60)}m",
          };
        }
      }
    }

    if (hasIn && !hasOut) {
      if (now.isAfter(schedOutDT)) {
        final diff = now.difference(schedOutDT);
        final minutes = diff.inMinutes;
        return {
          "title": "Missing Time Out",
          "sub":
              "Shift ended at ${AppFormatters.formatTimeOfDay(schedOut)}.",
          "color": AppColors.error,
          "icon": Icons.timer_off,
          "warn": true,
          "countdown": "You are late by $minutes minutes",
        };
      } else {
        final diff = schedOutDT.difference(now);
        final minutes = diff.inMinutes;
        if (minutes <= 15 && minutes > 0) {
          return {
            "title": "Time Out Now",
            "sub":
                "Shift ends at ${AppFormatters.formatTimeOfDay(schedOut)}.",
            "color": AppColors.orange,
            "icon": Icons.alarm,
            "warn": false,
            "countdown": "Ends in $minutes minutes",
          };
        } else {
          return {
            "title": "Currently On Duty",
            "sub":
                "Time out at ${AppFormatters.formatTimeOfDay(schedOut)}.",
            "color": AppColors.secondary,
            "icon": Icons.work_outline,
            "warn": false,
            "countdown":
                "Ends in ${diff.inHours}h ${(diff.inMinutes % 60)}m",
          };
        }
      }
    }

    if (hasOut) {
      return {
        "title": "Shift Completed",
        "sub": "Great job today.",
        "color": AppColors.textMuted,
        "icon": Icons.task_alt,
        "warn": false,
        "countdown": "",
      };
    }

    return {
      "title": "Unknown",
      "sub": "",
      "color": AppColors.textMuted,
      "icon": Icons.help,
      "warn": false,
      "countdown": "",
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = _getDashboardState();

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Stack(
        children: [
          const SizedBox.shrink(),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async => _loadData(),
              color: AppColors.primary,
              backgroundColor: AppColors.bgDark,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.sizeOf(context).width < 380 ? 16 : 24,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(_totalDays)
                        .animate()
                        .fadeIn(duration: 300.ms),

                    const SizedBox(height: 22),

                    _buildHeroCard(state).animate().fadeIn(duration: 400.ms),
                    const SizedBox(height: 16),

                    PremiumButton(
                      text: "CLOCK IN",
                      icon: Icons.login_rounded,
                      onTap: _handleTimeIn,
                    ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                    const SizedBox(height: 16),
                    PremiumButton(
                      text: "CLOCK OUT",
                      icon: Icons.logout_rounded,
                      onTap: _handleTimeOut,
                    ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
                    const SizedBox(height: 24),

                    if (_pendingSubmission != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: _buildConfirmationCard(),
                      ),

                    if (state['warn'])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          borderColor: state['color'],
                          child: Row(
                            children: [
                              Icon(Icons.warning_rounded,
                                  color: state['color']),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Text(
                                      "Action Required: ${state['title']}",
                                      style: TextStyle(
                                          color: state['color'],
                                          fontWeight: FontWeight.bold))),
                            ],
                          ),
                        ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(
                            duration: 1500.ms,
                            color: (state['color'] as Color)
                                .withValues(alpha: 0.2)),
                      ),

                    // TOTAL MONTHLY HOURS & ALLOWANCE CARD
                    _buildAllowanceCard().animate().fadeIn(duration: 400.ms),
                    const SizedBox(height: 10),

                    _buildScheduleCard().animate().fadeIn(duration: 400.ms),
                    const SizedBox(height: 24),

                    const HubUpdatesSection(),

                    const SizedBox(height: 28),

                    // EXCUSE SLIPS & REQUESTS SECTION
                    const Text("Excuse Slips & Requests",
                        style: TextStyle(
                            color: AppColors.textTitle,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    _buildRequestsSection(),
                    const SizedBox(height: 28),

                    const Text("Today Logs",
                        style: TextStyle(
                            color: AppColors.textTitle,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    _buildTodayLogs(),
                    if (_todayLogs.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.undo, size: 18),
                              label: const Text("Undo Last"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textBody,
                                side: const BorderSide(
                                    color: AppColors.cardBorder),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () async {
                                await _service.undoLastLog();
                                _loadData();
                                _showFeedback("Last log undone.");
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: const Text("Clear Today"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: BorderSide(
                                    color: AppColors.error
                                        .withValues(alpha: 0.5)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: AppColors.bgDeep,
                                    title: const Text("Clear today's logs?",
                                        style: TextStyle(color: Colors.white)),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text("Cancel")),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.error),
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text("Clear"),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await _service.clearTodayLogs();
                                  _loadData();
                                  _showFeedback("Today logs cleared.");
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Recent History",
                            style: TextStyle(
                                color: AppColors.textTitle,
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: const Text("🗓️ 1-Month Retention",
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildHistorySection(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllowanceCard() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("MONTHLY HOURS",
                        style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.7)),
                    const SizedBox(height: 6),
                    Text("${_monthlyHours.toStringAsFixed(1)} hrs",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              Container(height: 36, width: 1, color: AppColors.cardBorder),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        "ESTIMATED ALLOWANCE (@₱${_hourlyRate.toStringAsFixed(0)}/hr)",
                        style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.7)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text("₱${_monthlyAllowance.toStringAsFixed(2)}",
                            style: const TextStyle(
                                color: AppColors.success,
                                fontSize: 20,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(width: 6),
                        const Icon(Icons.info_outline_rounded,
                            color: AppColors.textMuted, size: 16),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

 Widget _buildRequestsSection() {
    return Row(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showAbsenceDialog,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardGlass,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.event_busy_rounded, color: AppColors.orange, size: 24),
                    SizedBox(height: 6),
                    Text("Absence", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showOvertimeDialog,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardGlass,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.more_time_rounded, color: AppColors.primary, size: 24),
                    SizedBox(height: 6),
                    Text("Overtime", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showWorkAuthDialog,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardGlass,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.receipt_long_rounded, color: AppColors.secondary, size: 24),
                    SizedBox(height: 6),
                    Text("Excuse Slip", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }







  Widget _buildConfirmationCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderColor: AppColors.orange.withValues(alpha: 0.5),
      hasGlow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.assignment_turned_in_outlined,
                color: AppColors.orange,
                size: 24,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Did you submit the Google Form?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _submitConfirmation('yes'),
              icon: const Icon(
                Icons.check_circle_outline_rounded,
                size: 19,
              ),
              label: const Text('Yes, submitted'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.success,
                side: const BorderSide(
                  color: AppColors.success,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _submitConfirmation('retry'),
              icon: const Icon(
                Icons.refresh_rounded,
                size: 19,
              ),
              label: const Text('Open form again'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(
                  color: AppColors.primary,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _submitConfirmation('cancel'),
              icon: const Icon(
                Icons.close_rounded,
                size: 19,
              ),
              label: const Text('Not submitted'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(
                  color: AppColors.error,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildHeader(int totalDays) {
    final greeting = AppFormatters.getGreeting();
    final displayName = _userName?.trim().isNotEmpty == true
        ? _userName!.trim()
        : 'User';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting, $displayName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textBody,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Total days present: $totalDays',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(Map<String, dynamic> state) {
    Color badgeColor = state['color'] as Color;
    return GlassCard(
      hasGlow: state['warn'],
      borderColor: state['warn']
          ? badgeColor.withValues(alpha: 0.5)
          : AppColors.cardBorder,
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: badgeColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                          color: badgeColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: badgeColor, blurRadius: 4)
                          ]),
                    ).animate(onPlay: (controller) => controller.repeat())
                        .fadeIn(duration: 1.seconds)
                        .then()
                        .fadeOut(duration: 1.seconds),
                    const SizedBox(width: 8),
                    Text("Live Status",
                        style: TextStyle(
                            color: badgeColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              Icon(state['icon'],
                  color: Colors.white.withValues(alpha: 0.2), size: 48),
            ],
          ),
          const SizedBox(height: 24),
          Text(state['title'],
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Text(state['sub'],
              style: const TextStyle(color: AppColors.textBody, fontSize: 15)),
          if (state['countdown'].isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(state['countdown'],
                  style: TextStyle(
                      color: badgeColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard() {
    final now = DateTime.now();
    final weekday = now.weekday;
    final schedIn = _service.getScheduledTimeInForDay(weekday);
    final schedOut = _service.getScheduledTimeOutForDay(weekday);

    return GlassCard(
      padding: const EdgeInsets.symmetric(
        vertical: 18,
        horizontal: 18,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildScheduleItem(
              label: 'SCHEDULED IN',
              value: AppFormatters.formatTimeOfDay(schedIn),
              icon: Icons.login_rounded,
              alignment: CrossAxisAlignment.start,
            ),
          ),
          Container(
            height: 44,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            color: AppColors.cardBorder,
          ),
          Expanded(
            child: _buildScheduleItem(
              label: 'SCHEDULED OUT',
              value: AppFormatters.formatTimeOfDay(schedOut),
              icon: Icons.logout_rounded,
              alignment: CrossAxisAlignment.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem({
    required String label,
    required String value,
    required IconData icon,
    required CrossAxisAlignment alignment,
  }) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (alignment == CrossAxisAlignment.start) ...[
              Icon(
                icon,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.7,
                ),
              ),
            ),
            if (alignment == CrossAxisAlignment.end) ...[
              const SizedBox(width: 6),
              Icon(
                icon,
                color: AppColors.primary,
                size: 16,
              ),
            ],
          ],
        ),
        const SizedBox(height: 7),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignment == CrossAxisAlignment.start
              ? Alignment.centerLeft
              : Alignment.centerRight,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodayLogs() {
    if (_todayLogs.isEmpty) {
      return const GlassCard(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.history_toggle_off_rounded,
                color: AppColors.textMuted,
                size: 34,
              ),
              SizedBox(height: 10),
              Text(
                'No logs yet today.',
                style: TextStyle(
                  color: AppColors.textBody,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _todayLogs.reversed.map((log) {
        final bool isTimeIn = log.type == 'in';

        final Color actionColor = isTimeIn
            ? AppColors.success
            : AppColors.orange;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: actionColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isTimeIn
                            ? Icons.login_rounded
                            : Icons.logout_rounded,
                        color: actionColor,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isTimeIn ? 'Clock In' : 'Clock Out',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            AppFormatters.formatTime(log.timestamp),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textBody,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (log.accomplishment?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  Text(
                    log.accomplishment!.trim(),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (log.formStatus != null)
                      _buildFormStatusChip(log.formStatus!),
                    StatusChip(status: log.status),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFormStatusChip(String formStatus) {
    Color color;
    String text;
    switch (formStatus) {
      case 'submitted':
        color = AppColors.success;
        text = "Form Submitted";
        break;
      case 'pending':
        color = AppColors.orange;
        text = "Form Pending";
        break;
      case 'not_submitted':
        color = AppColors.error;
        text = "Form Not Submitted";
        break;
      default:
        color = AppColors.textMuted;
        text = "Unknown";
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildHistorySection() {
    if (_history.isEmpty) {
      return const GlassCard(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No records found.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Column(
      children: _history.map((log) {
        final bool isTimeIn = log.type == 'in';

        final Color actionColor = isTimeIn
            ? AppColors.success
            : AppColors.orange;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: actionColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        isTimeIn
                            ? Icons.login_rounded
                            : Icons.logout_rounded,
                        color: actionColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppFormatters.formatDate(log.date),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            AppFormatters.formatTime(log.timestamp),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textBody,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (log.accomplishment?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  Text(
                    '“${log.accomplishment!.trim()}”',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 13),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (log.formStatus != null)
                      _buildFormStatusChip(log.formStatus!),
                    StatusChip(status: log.status),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

