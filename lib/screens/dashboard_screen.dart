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

  void _showFeedback(String message, {bool isError = false}) {
    if (!context.mounted) return;
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
                color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        elevation: 4,
      ),
    );
  }

  Future<bool> _confirmRepeat(String action) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgDeep,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.cardBorder)),
        title: const Text("Repeat Action?",
            style: TextStyle(
                color: AppColors.textTitle,
                fontWeight: FontWeight.w800,
                fontSize: 18)),
        content: Text("You already logged $action today. Add another record?",
            style: const TextStyle(color: AppColors.textBody, fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel",
                  style: TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Add Another",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
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
      _showFeedback("Attendance logged: Clock In (${log.status})");

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
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.cardBorder)),
        title: const Text("Duty Accomplishment",
            style: TextStyle(
                color: AppColors.textTitle,
                fontWeight: FontWeight.w800,
                fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Briefly state your tasks or responsibilities completed during this shift.",
              style: TextStyle(
                  color: AppColors.textBody, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: accController,
              style: const TextStyle(
                  color: AppColors.textTitle, fontSize: 14),
              maxLines: 3,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.bgDark,
                hintText: "E.g., Library cataloging, office filing, desk assistance...",
                hintStyle: const TextStyle(
                    color: AppColors.textMuted, fontSize: 13),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.cardBorder)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.cardBorder)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel",
                  style: TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              if (accController.text.trim().isEmpty) return;
              Navigator.pop(context, true);
            },
            child: const Text("Submit & Clock Out",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
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
      _showFeedback("Attendance logged: Clock Out (${log.status})");

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
          final startStr =
              "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";
          final endStr =
              "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";

          return AlertDialog(
            backgroundColor: AppColors.bgDeep,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.cardBorder)),
            title: const Row(
              children: [
                Icon(Icons.event_busy_rounded, color: AppColors.orange, size: 22),
                SizedBox(width: 10),
                Text("Absence Request",
                    style: TextStyle(
                        color: AppColors.textTitle,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("TYPE OF LEAVE",
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5)),
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
                        selectedColor: AppColors.orange.withValues(alpha: 0.15),
                        backgroundColor: AppColors.bgDark,
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.orange : AppColors.textBody,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.orange
                              : AppColors.cardBorder,
                        ),
                        showCheckmark: false,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  const Text("DATES OF ABSENCE",
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5)),
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
                                if (endDate.isBefore(startDate)) {
                                  endDate = startDate;
                                }
                              });
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textTitle,
                            side: const BorderSide(color: AppColors.cardBorder),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text("From: $startStr",
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 8),
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
                            foregroundColor: AppColors.textTitle,
                            side: const BorderSide(color: AppColors.cardBorder),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text("To: $endStr",
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text("REASON FOR ABSENCE",
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: reasonController,
                    style: const TextStyle(
                        color: AppColors.textTitle, fontSize: 13),
                    maxLines: 2,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.bgDark,
                      hintText: "State your reason...",
                      hintStyle: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.cardBorder)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.cardBorder)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel",
                      style: TextStyle(color: AppColors.textMuted))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: () async {
                  final reason = reasonController.text.trim();
                  if (reason.isEmpty) return;
                  Navigator.pop(ctx);

                  _showFeedback("Absence Request ($selectedLeaveType) submitted.");

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
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
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
          final startDateStr =
              "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";
          final endDateStr =
              "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";

          return AlertDialog(
            backgroundColor: AppColors.bgDeep,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.cardBorder)),
            title: const Row(
              children: [
                Icon(Icons.more_time_rounded, color: AppColors.primary, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text("Overtime Authorization",
                      style: TextStyle(
                          color: AppColors.textTitle,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("AUTHORIZATION DATES",
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5)),
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
                                if (endDate.isBefore(startDate)) {
                                  endDate = startDate;
                                }
                              });
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textTitle,
                            side: const BorderSide(color: AppColors.cardBorder),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text("Start: $startDateStr",
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 8),
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
                            foregroundColor: AppColors.textTitle,
                            side: const BorderSide(color: AppColors.cardBorder),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text("End: $endDateStr",
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text("SHIFT TIMES",
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                                context: dialogCtx, initialTime: timeStart);
                            if (picked != null) {
                              setDialogState(() => timeStart = picked);
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textTitle,
                            side: const BorderSide(color: AppColors.cardBorder),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text("In: $startStr",
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                                context: dialogCtx, initialTime: timeEnd);
                            if (picked != null) {
                              setDialogState(() => timeEnd = picked);
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textTitle,
                            side: const BorderSide(color: AppColors.cardBorder),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text("Out: $endStr",
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text("SUPERVISOR NAME",
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: supervisorController,
                    style: const TextStyle(
                        color: AppColors.textTitle, fontSize: 13),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.bgDark,
                      hintText: "Enter supervisor name...",
                      hintStyle: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.cardBorder)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.cardBorder)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text("TASKS PERFORMED",
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: reasonController,
                    style: const TextStyle(
                        color: AppColors.textTitle, fontSize: 13),
                    maxLines: 2,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.bgDark,
                      hintText: "Describe tasks performed...",
                      hintStyle: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.cardBorder)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.cardBorder)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel",
                      style: TextStyle(color: AppColors.textMuted))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: () async {
                  final reason = reasonController.text.trim();
                  final supervisor = supervisorController.text.trim();
                  if (reason.isEmpty || supervisor.isEmpty) return;
                  Navigator.pop(ctx);

                  _showFeedback("Overtime authorization recorded.");
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
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
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
          final dateStr =
              "${incidentDate.year}-${incidentDate.month.toString().padLeft(2, '0')}-${incidentDate.day.toString().padLeft(2, '0')}";

          return AlertDialog(
            backgroundColor: AppColors.bgDeep,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.cardBorder)),
            title: const Row(
              children: [
                Icon(Icons.receipt_long_rounded, color: AppColors.secondary, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text("Excuse Slip Request",
                      style: TextStyle(
                          color: AppColors.textTitle,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("MISSING ATTENDANCE ACTION",
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                  Row(
                    children: ["Clock In", "Clock Out"].map((action) {
                      final isSelected = selectedAction == action;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(action),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setDialogState(() => selectedAction = action);
                            }
                          },
                          selectedColor:
                              AppColors.secondary.withValues(alpha: 0.15),
                          backgroundColor: AppColors.bgDark,
                          labelStyle: TextStyle(
                              color: isSelected
                                  ? AppColors.secondary
                                  : AppColors.textBody,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.secondary
                                : AppColors.cardBorder,
                          ),
                          showCheckmark: false,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text("INCIDENT DATE & TIME",
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5)),
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
                            if (picked != null) {
                              setDialogState(() => incidentDate = picked);
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textTitle,
                            side: const BorderSide(color: AppColors.cardBorder),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text("Date: $dateStr",
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                                context: dialogCtx, initialTime: incidentTime);
                            if (picked != null) {
                              setDialogState(() => incidentTime = picked);
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textTitle,
                            side: const BorderSide(color: AppColors.cardBorder),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text("Time: $timeStr",
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text("REASON",
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: excuseReasons.map((reason) {
                      final isSelected = selectedReason == reason;
                      return ChoiceChip(
                        label: Text(reason),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setDialogState(() => selectedReason = reason);
                          }
                        },
                        selectedColor:
                            AppColors.secondary.withValues(alpha: 0.15),
                        backgroundColor: AppColors.bgDark,
                        labelStyle: TextStyle(
                            color: isSelected
                                ? AppColors.secondary
                                : AppColors.textBody,
                            fontWeight: FontWeight.w700,
                            fontSize: 11),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.secondary
                              : AppColors.cardBorder,
                        ),
                        showCheckmark: false,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text("SUPERVISOR VERIFICATION",
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: supervisorController,
                    style: const TextStyle(
                        color: AppColors.textTitle, fontSize: 13),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.bgDark,
                      hintText: "Enter supervisor name...",
                      hintStyle: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.cardBorder)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.cardBorder)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel",
                      style: TextStyle(color: AppColors.textMuted))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
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
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
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
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.bgDeep,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.open_in_browser,
                  size: 28, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text(
              "Complete Google Form",
              style: TextStyle(
                  color: AppColors.textTitle,
                  fontSize: 18,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              "After submitting your prefilled attendance form, return to AWS HUB to confirm.",
              style: TextStyle(
                  color: AppColors.textBody, fontSize: 13, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.open_in_new, color: Colors.white, size: 18),
                label: const Text(
                  "Open Google Form",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _launchFormUrl(url);
                },
              ),
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
      _showFeedback("Attendance verified: Form marked submitted.");
    } else if (action == 'retry') {
      await _launchFormUrl(pending.url);
      return;
    } else if (action == 'cancel') {
      await _service.updateFormStatus(pending.logId, 'not_submitted');
      if (!context.mounted) return;
      _showFeedback("Attendance recorded: Form marked pending.");
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
        "title": "Scheduled Day Off",
        "sub": "No campus duty scheduled today.",
        "color": AppColors.textMuted,
        "icon": Icons.weekend_outlined,
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
          "title": "Shift Overdue (Clock In Required)",
          "sub": "Duty started at ${AppFormatters.formatTimeOfDay(schedIn)}.",
          "color": AppColors.error,
          "icon": Icons.warning_amber_rounded,
          "warn": true,
          "countdown": "Late by $minutes min",
        };
      } else {
        final diff = schedInDT.difference(now);
        final minutes = diff.inMinutes;
        if (minutes <= 15 && minutes > 0) {
          return {
            "title": "Shift Starting Soon",
            "sub": "Duty begins at ${AppFormatters.formatTimeOfDay(schedIn)}.",
            "color": AppColors.orange,
            "icon": Icons.alarm,
            "warn": false,
            "countdown": "Starts in $minutes min",
          };
        } else {
          return {
            "title": "Duty Later Today",
            "sub": "Scheduled for ${AppFormatters.formatTimeOfDay(schedIn)}.",
            "color": AppColors.primary,
            "icon": Icons.schedule,
            "warn": false,
            "countdown": "Starts in ${diff.inHours}h ${(diff.inMinutes % 60)}m",
          };
        }
      }
    }

    if (hasIn && !hasOut) {
      if (now.isAfter(schedOutDT)) {
        final diff = now.difference(schedOutDT);
        final minutes = diff.inMinutes;
        return {
          "title": "Shift Ended (Clock Out Required)",
          "sub": "Scheduled end was ${AppFormatters.formatTimeOfDay(schedOut)}.",
          "color": AppColors.error,
          "icon": Icons.timer_off_outlined,
          "warn": true,
          "countdown": "Past shift by $minutes min",
        };
      } else {
        final diff = schedOutDT.difference(now);
        final minutes = diff.inMinutes;
        if (minutes <= 15 && minutes > 0) {
          return {
            "title": "Shift Ending Soon",
            "sub": "Duty ends at ${AppFormatters.formatTimeOfDay(schedOut)}.",
            "color": AppColors.orange,
            "icon": Icons.alarm,
            "warn": false,
            "countdown": "Ends in $minutes min",
          };
        } else {
          return {
            "title": "Currently On Duty",
            "sub": "Duty ends at ${AppFormatters.formatTimeOfDay(schedOut)}.",
            "color": AppColors.success,
            "icon": Icons.work_outline_rounded,
            "warn": false,
            "countdown": "Remaining: ${diff.inHours}h ${(diff.inMinutes % 60)}m",
          };
        }
      }
    }

    if (hasOut) {
      return {
        "title": "Shift Completed",
        "sub": "Thank you for your duty service today.",
        "color": AppColors.success,
        "icon": Icons.check_circle_outline_rounded,
        "warn": false,
        "countdown": "",
      };
    }

    return {
      "title": "Working Scholar Hub",
      "sub": "Campus duty tracking active.",
      "color": AppColors.textMuted,
      "icon": Icons.school_outlined,
      "warn": false,
      "countdown": "",
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = _getDashboardState();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _loadData(),
          color: AppColors.primary,
          backgroundColor: AppColors.bgDeep,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. ACADEMIC CAMPUS HEADER
                _buildAcademicHeader(),
                const SizedBox(height: 16),

                // 2. GOOGLE FORM CONFIRMATION PROMPT (if pending)
                if (_pendingSubmission != null) ...[
                  _buildFormSubmissionBanner(),
                  const SizedBox(height: 16),
                ],

                // 3. DUTY STATION COMMAND CARD
                _buildDutyStationCard(state),
                const SizedBox(height: 14),

                // 4. STIPEND & HOURS METRIC CARDS (Bento Row)
                _buildMetricsBentoRow(),
                const SizedBox(height: 24),

                // 5. CAMPUS BULLETIN (Announcements & Birthdays)
                const HubUpdatesSection(),
                const SizedBox(height: 24),

                // 6. SCHOLAR ADMINISTRATIVE SERVICES
                _buildSectionHeader("Scholar Services"),
                const SizedBox(height: 10),
                _buildServicesDock(),
                const SizedBox(height: 24),

                // 7. TODAY'S DUTY LEDGER
                _buildSectionHeader(
                  "Today's Activity",
                  trailing: _todayLogs.isNotEmpty
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton.icon(
                              onPressed: () async {
                                await _service.undoLastLog();
                                _loadData();
                                _showFeedback("Last log undone.");
                              },
                              icon: const Icon(Icons.undo_rounded, size: 15),
                              label: const Text("Undo"),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.textMuted,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: AppColors.bgDeep,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(18)),
                                    title: const Text("Clear today's logs?",
                                        style: TextStyle(
                                            color: AppColors.textTitle,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 17)),
                                    content: const Text(
                                        "This will reset all duty records logged today.",
                                        style: TextStyle(
                                            color: AppColors.textBody,
                                            fontSize: 13)),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text("Cancel")),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.error,
                                            elevation: 0),
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text("Clear",
                                            style: TextStyle(
                                                color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await _service.clearTodayLogs();
                                  _loadData();
                                  _showFeedback("Today's logs cleared.");
                                }
                              },
                              icon: const Icon(Icons.delete_outline_rounded,
                                  size: 15, color: AppColors.error),
                              label: const Text("Clear",
                                  style: TextStyle(color: AppColors.error)),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        )
                      : null,
                ),
                const SizedBox(height: 10),
                _buildTodayLedgerCard(),
                const SizedBox(height: 24),

                // 8. RECENT HISTORY (1-Month Retention)
                _buildSectionHeader(
                  "Recent History",
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text("1-Month Retention",
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 10),
                _buildHistoryLedgerCard(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 1. CAMPUS HEADER
  // =========================================================================
  

Widget _buildAcademicHeader() {
    final greeting = AppFormatters.getGreeting();
    final displayName = _userName?.trim().isNotEmpty == true
        ? _userName!.trim()
        : 'Scholar';
    final initial =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'S';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.bgDeep,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25)),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, $displayName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textTitle,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Total days present: $_totalDays',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  // =========================================================================
  // 2. DUTY STATION COMMAND CARD
  // =========================================================================
  Widget _buildDutyStationCard(Map<String, dynamic> state) {
    final Color badgeColor = state['color'] as Color;
    final now = DateTime.now();
    final schedIn = _service.getScheduledTimeInForDay(now.weekday);
    final schedOut = _service.getScheduledTimeOutForDay(now.weekday);
    final isDuty = _dutyDays.contains(now.weekday);

    final shiftText = isDuty
        ? "Scheduled: ${AppFormatters.formatTimeOfDay(schedIn)} – ${AppFormatters.formatTimeOfDay(schedOut)}"
        : "No scheduled shift for today";

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgDeep,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: state['warn'] == true
              ? badgeColor.withValues(alpha: 0.5)
              : AppColors.cardBorder,
          width: state['warn'] == true ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Station Header: Live status + Countdown pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: badgeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    state['title'] as String,
                    style: TextStyle(
                      color: badgeColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              if ((state['countdown'] as String).isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    state['countdown'] as String,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Subtitle / Shift Schedule info
          Text(
            state['sub'] as String,
            style: const TextStyle(
              color: AppColors.textTitle,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.schedule_rounded,
                  color: AppColors.textMuted, size: 14),
              const SizedBox(width: 6),
              Text(
                shiftText,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 14),

          // TACTILE ATTENDANCE CONTROLS (Side-by-Side)
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _handleTimeIn,
                    icon: const Icon(Icons.login_rounded, size: 18),
                    label: const Text(
                      "Clock In",
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _handleTimeOut,
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text(
                      "Clock Out",
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textTitle,
                      side: const BorderSide(color: AppColors.cardBorder),
                      backgroundColor: AppColors.bgDark,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 3. STIPEND & HOURS METRIC BENTO CARDS
  // =========================================================================

Widget _buildMetricsBentoRow() {
    return Row(
      children: [
        // Box 1: Total Hours
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgDeep,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "TOTAL HOURS",
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Icon(Icons.schedule_rounded,
                        color: AppColors.primary.withValues(alpha: 0.7),
                        size: 18),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "${_monthlyHours.toStringAsFixed(1)} hrs",
                  style: const TextStyle(
                    color: AppColors.textTitle,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  "This month",
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Box 2: Allowance
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgDeep,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "ALLOWANCE",
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Icon(Icons.payments_outlined,
                        color: AppColors.success, size: 18),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "₱${_monthlyAllowance.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "₱${_hourlyRate.toStringAsFixed(2)} per hour",
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // 4. SCHOLAR ADMINISTRATIVE SERVICES
  // =========================================================================
  Widget _buildServicesDock() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.bgDeep,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          _buildServiceItem(
            icon: Icons.event_busy_rounded,
            title: "Absence",
            color: AppColors.orange,
            onTap: _showAbsenceDialog,
          ),
          Container(width: 1, height: 32, color: AppColors.cardBorder),
          _buildServiceItem(
            icon: Icons.more_time_rounded,
            title: "Overtime",
            color: AppColors.primary,
            onTap: _showOvertimeDialog,
          ),
          Container(width: 1, height: 32, color: AppColors.cardBorder),
          _buildServiceItem(
            icon: Icons.receipt_long_rounded,
            title: "Excuse Slip",
            color: AppColors.secondary,
            onTap: _showWorkAuthDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textTitle,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 5. DUTY LEDGER (TODAY)
  // =========================================================================
  Widget _buildTodayLedgerCard() {
    if (_todayLogs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.bgDeep,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.history_toggle_off_rounded,
                  color: AppColors.textMuted, size: 30),
              SizedBox(height: 8),
              Text(
                "No duty logs recorded yet today.",
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgDeep,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _todayLogs.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: AppColors.cardBorder),
        itemBuilder: (context, index) {
          final log = _todayLogs.reversed.toList()[index];
          final bool isTimeIn = log.type == 'in';
          final actionColor =
              isTimeIn ? AppColors.success : AppColors.primary;

          return Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: actionColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isTimeIn ? "Clock In" : "Clock Out",
                        style: TextStyle(
                          color: actionColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      AppFormatters.formatTime(log.timestamp),
                      style: const TextStyle(
                        color: AppColors.textTitle,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    StatusChip(status: log.status),
                  ],
                ),
                if (log.accomplishment?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.bgDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Text(
                      '“${log.accomplishment!.trim()}”',
                      style: const TextStyle(
                        color: AppColors.textBody,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // =========================================================================
  // 6. RECENT HISTORY LEDGER (1-MONTH)
  // =========================================================================
  Widget _buildHistoryLedgerCard() {
    if (_history.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.bgDeep,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Center(
          child: Text(
            "No historical duty records found.",
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgDeep,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _history.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: AppColors.cardBorder),
        itemBuilder: (context, index) {
          final log = _history[index];
          final bool isTimeIn = log.type == 'in';
          final actionColor =
              isTimeIn ? AppColors.success : AppColors.primary;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: actionColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isTimeIn
                        ? Icons.login_rounded
                        : Icons.logout_rounded,
                    color: actionColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppFormatters.formatDate(log.date),
                        style: const TextStyle(
                          color: AppColors.textTitle,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${isTimeIn ? 'In at' : 'Out at'} ${AppFormatters.formatTime(log.timestamp)}",
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusChip(status: log.status),
              ],
            ),
          );
        },
      ),
    );
  }

  // =========================================================================
  // HELPER: SECTION HEADERS & NOTICES
  // =========================================================================
  Widget _buildSectionHeader(String title, {Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textTitle,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildFormSubmissionBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgDeep,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.assignment_turned_in_outlined,
                  color: AppColors.orange, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Did you submit the attendance form?",
                  style: TextStyle(
                    color: AppColors.textTitle,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _submitConfirmation('yes'),
                    child: const Text("Yes, submitted",
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 36,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _submitConfirmation('retry'),
                  child: const Text("Re-open", style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 36,
                child: TextButton(
                  onPressed: () => _submitConfirmation('cancel'),
                  child: const Text("Not yet",
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}