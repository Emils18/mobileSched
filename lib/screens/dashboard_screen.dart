import 'dart:async';
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
  TimeOfDay _schedIn = const TimeOfDay(hour: 16, minute: 30);
  TimeOfDay _schedOut = const TimeOfDay(hour: 21, minute: 30);
  int _totalDays = 0;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_userName == null || _userName!.isEmpty) {
        _showSettingsSheet(isFirstTime: true);
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
    setState(() {
      _userName = _service.getUserName();
      _dutyDays = _service.getDutyDays();
      _schedIn = _service.getScheduledTimeIn();
      _schedOut = _service.getScheduledTimeOut();
      _todayLogs = _service.getTodayLogs();
      _history = _service.getHistory().take(3).toList();
      _totalDays = _service.getTotalDaysPresent();
    });
  }

  // ---------------- Settings Sheet (identical to before, no warnings) ----------------
  void _showSettingsSheet({bool isFirstTime = false}) {
    final TextEditingController nameController =
        TextEditingController(text: _userName);
    List<int> tempDays = List.from(_dutyDays);
    TimeOfDay tempIn = _schedIn;
    TimeOfDay tempOut = _schedOut;

    final notifService = NotificationService();
    bool notifEnabled = notifService.isEnabled;
    bool soundEnabled = notifService.isSoundEnabled;
    bool vibrationEnabled = notifService.isVibrationEnabled;
    bool persistentEnabled = notifService.isPersistentEnabled;

    showModalBottomSheet(
      context: context,
      isDismissible: !isFirstTime,
      enableDrag: !isFirstTime,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: GlassCard(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(32)),
            padding: const EdgeInsets.all(32),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isFirstTime ? "Welcome to MioSched" : "Settings & Schedule",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isFirstTime
                        ? "Set your name and default duty schedule."
                        : "Update your profile and schedule.",
                    style: const TextStyle(color: AppColors.textBody),
                  ),
                  const SizedBox(height: 32),

                  // Name Input
                  const Text("PREFERRED NAME",
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.2),
                      hintText: "Enter your name",
                      hintStyle:
                          TextStyle(color: Colors.white.withValues(alpha: 0.2)),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Duty days
                  const Text("DUTY DAYS",
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(7, (index) {
                      int dayNum = index + 1;
                      bool isSelected = tempDays.contains(dayNum);
                      return ChoiceChip(
                        label: Text(AppFormatters.getDayName(dayNum)),
                        selected: isSelected,
                        onSelected: (val) => setModalState(() {
                          if (val) {
                            tempDays.add(dayNum);
                          } else {
                            tempDays.remove(dayNum);
                          }
                        }),
                        selectedColor: AppColors.primary.withValues(alpha: 0.2),
                        backgroundColor:
                            Colors.black.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textBody),
                        side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // Time pickers
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimePickerBox("TIME IN", tempIn, () async {
                          final t = await showTimePicker(
                              context: context, initialTime: tempIn);
                          if (t != null) setModalState(() => tempIn = t);
                        }),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child:
                            _buildTimePickerBox("TIME OUT", tempOut, () async {
                          final t = await showTimePicker(
                              context: context, initialTime: tempOut);
                          if (t != null) setModalState(() => tempOut = t);
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Notification Settings
                  const Text("NOTIFICATIONS",
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1)),
                  const SizedBox(height: 12),

                  SwitchListTile(
                    title: const Text("Enable Notifications",
                        style: TextStyle(color: Colors.white)),
                    subtitle: const Text("Turn all alerts on/off",
                        style: TextStyle(
                            color: AppColors.textBody, fontSize: 12)),
                    value: notifEnabled,
                    activeThumbColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) async {
                      await notifService.setEnabled(val);
                      setModalState(() => notifEnabled = val);
                    },
                  ),

                  SwitchListTile(
                    title: const Text("Sound",
                        style: TextStyle(color: Colors.white)),
                    subtitle: const Text("Play sound on notification",
                        style: TextStyle(
                            color: AppColors.textBody, fontSize: 12)),
                    value: soundEnabled,
                    activeThumbColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: notifEnabled
                        ? (val) async {
                            await notifService.setSound(val);
                            setModalState(() => soundEnabled = val);
                          }
                        : null,
                  ),

                  SwitchListTile(
                    title: const Text("Vibration",
                        style: TextStyle(color: Colors.white)),
                    subtitle: const Text("Vibrate when notified",
                        style: TextStyle(
                            color: AppColors.textBody, fontSize: 12)),
                    value: vibrationEnabled,
                    activeThumbColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: notifEnabled
                        ? (val) async {
                            await notifService.setVibration(val);
                            setModalState(() => vibrationEnabled = val);
                          }
                        : null,
                  ),

                  SwitchListTile(
                    title: const Text("Persistent",
                        style: TextStyle(color: Colors.white)),
                    subtitle: const Text("Cannot swipe away notification",
                        style: TextStyle(
                            color: AppColors.textBody, fontSize: 12)),
                    value: persistentEnabled,
                    activeThumbColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: notifEnabled
                        ? (val) async {
                            await notifService.setPersistent(val);
                            setModalState(() => persistentEnabled = val);
                          }
                        : null,
                  ),

                  const SizedBox(height: 18),

                  // Test Notification button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.notifications_active_rounded),
                      label: const Text("Test Notification"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        final sent = await notifService.showTestNotification();
                        if (!context.mounted) return;   // use context.mounted
                        if (sent) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Notification sent"),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Enable notifications first"),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Google Form Settings
                  const Text("GOOGLE FORM",
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1)),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text("Submit to Google Form",
                        style: TextStyle(color: Colors.white)),
                    subtitle: const Text(
                        "Automatically send logs to your Form",
                        style:
                            TextStyle(color: AppColors.textBody, fontSize: 12)),
                    value: GoogleFormService().isEnabled,
                    activeThumbColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) async {
                      await GoogleFormService().setEnabled(val);
                      setModalState(() {});
                    },
                  ),

                  const SizedBox(height: 28),

                  // Save Configuration
                  SizedBox(
                    width: double.infinity,
                    child: PremiumButton(
                      text: "Save Configuration",
                      icon: Icons.save_rounded,
                      onTap: () async {
                        final name = nameController.text.trim();
                        if (name.isNotEmpty) {
                          await _service.setUserName(name);
                          await _service.setDutyDays(tempDays);
                          await _service.setScheduledTimeIn(tempIn);
                          await _service.setScheduledTimeOut(tempOut);
                          _loadData();
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimePickerBox(String label, TimeOfDay time, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(AppFormatters.formatTimeOfDay(time),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showFeedback(String message, {bool isError = false}) {
    // Here we don't need a context.mounted check because this method is always called after a check or in a context that is guaranteed (but to be safe we can add one)
    if (!context.mounted) return;   // extra safety
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

  // --------------- Clock In (with form instruction + pending) ---------------
  Future<void> _handleTimeIn() async {
    try {
      if (_service.hasLogOfTypeToday('in')) {
        final proceed = await _confirmRepeat("Clock In");
        if (!proceed) return;
      }
      final log = await _service.timeIn();
      if (!context.mounted) return;   // context.mounted
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

  // --------------- Clock Out (with form instruction + pending) ---------------
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
      final log = await _service.timeOut(accController.text.trim());
      if (!context.mounted) return;   // context.mounted
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

  /// Shows instruction bottom sheet, then opens form, saves pending.
  Future<void> _showFormInstructionAndLaunch(
      String url, String logId, String type) async {
    // Show instruction
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
            const Icon(Icons.open_in_browser, size: 40, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              "After submitting the form, return to MobileSched to confirm.",
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

    // Save pending submission
    final pending = PendingSubmission(
      logId: logId,
      type: type,
      url: url,
    );
    await PendingSubmissionService().setPending(pending);
    if (!context.mounted) return;   // after await
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

  // ---------- Confirmation actions ----------
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

  // ---------------- Real-time Status Logic (unchanged) ----------------
  Map<String, dynamic> _getDashboardState() {
    // ... identical ...
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

    final schedInDT = DateTime(
        now.year, now.month, now.day, _schedIn.hour, _schedIn.minute);
    final schedOutDT = DateTime(
        now.year, now.month, now.day, _schedOut.hour, _schedOut.minute);

    final hasIn = _todayLogs.any((l) => l.type == 'in');
    final hasOut = _todayLogs.any((l) => l.type == 'out');

    if (!hasIn) {
      if (now.isAfter(schedInDT)) {
        final diff = now.difference(schedInDT);
        final minutes = diff.inMinutes;
        return {
          "title": "Late / Missing Time In",
          "sub": "Shift started at ${AppFormatters.formatTimeOfDay(_schedIn)}.",
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
                "Shift starts at ${AppFormatters.formatTimeOfDay(_schedIn)}.",
            "color": AppColors.orange,
            "icon": Icons.alarm,
            "warn": false,
            "countdown": "Starts in $minutes minutes",
          };
        } else {
          return {
            "title": "Duty Later",
            "sub":
                "Shift starts at ${AppFormatters.formatTimeOfDay(_schedIn)}.",
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
              "Shift ended at ${AppFormatters.formatTimeOfDay(_schedOut)}.",
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
                "Shift ends at ${AppFormatters.formatTimeOfDay(_schedOut)}.",
            "color": AppColors.orange,
            "icon": Icons.alarm,
            "warn": false,
            "countdown": "Ends in $minutes minutes",
          };
        } else {
          return {
            "title": "Currently On Duty",
            "sub":
                "Time out at ${AppFormatters.formatTimeOfDay(_schedOut)}.",
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

  // ---------------- Build Method (with confirmation card) ----------------
  @override
  Widget build(BuildContext context) {
    final state = _getDashboardState();
    final liveTimeStr = AppFormatters.formatTime(_currentTime);

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Stack(
        children: [
          _buildGlowingOrbs(state['color'] as Color),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async => _loadData(),
              color: AppColors.primary,
              backgroundColor: AppColors.bgDark,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(_totalDays)
                        .animate()
                        .fadeIn(duration: 300.ms),
                    const SizedBox(height: 32),
                    Center(
                      child: Text(
                        liveTimeStr,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 2),
                      ),
                    ).animate().fadeIn(duration: 500.ms),
                    const SizedBox(height: 16),

                    // Pending submission confirmation card
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
                    _buildHeroCard(state).animate().fadeIn(duration: 400.ms),
                    const SizedBox(height: 16),
                    _buildScheduleCard().animate().fadeIn(duration: 400.ms),
                    const SizedBox(height: 24),
                    if (state['countdown'].isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(state['countdown'],
                            style: TextStyle(
                                color: state['color'],
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                      ).animate().fadeIn(duration: 300.ms),
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
                    const Text("Recent History",
                        style: TextStyle(
                            color: AppColors.textTitle,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
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

  Widget _buildConfirmationCard() {
    // No unused pending variable
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderColor: AppColors.orange.withValues(alpha: 0.5),
      hasGlow: true,
      child: Column(
        children: [
          const Text(
            "Did you submit the Google Form?",
            style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.success,
                    side: const BorderSide(color: AppColors.success),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _submitConfirmation('yes'),
                  child: const Text("Yes, submitted"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _submitConfirmation('retry'),
                  child: const Text("Retry"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _submitConfirmation('cancel'),
                  child: const Text("Cancel"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- Helper Widgets (unchanged) ----------------
  Widget _buildGlowingOrbs(Color stateColor) {
    return Stack(
      children: [
        Positioned(
          top: -50,
          right: -50,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: stateColor.withValues(alpha: 0.15),
              boxShadow: [
                BoxShadow(
                    color: stateColor.withValues(alpha: 0.15),
                    blurRadius: 150,
                    spreadRadius: 50)
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(int totalDays) {
    final greeting = AppFormatters.getGreeting();
    final displayName = _userName ?? "User";

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("$greeting, $displayName ",
                style: const TextStyle(
                    color: AppColors.textBody,
                    fontSize: 16,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text("Total days present: $totalDays",
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
        GestureDetector(
          onTap: () => _showSettingsSheet(),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppColors.cardGlass,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cardBorder)),
            child:
                const Icon(Icons.tune_rounded, color: Colors.white, size: 24),
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
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("SCHEDULED IN",
                  style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(AppFormatters.formatTimeOfDay(_schedIn),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          Container(height: 30, width: 1, color: AppColors.cardBorder),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text("SCHEDULED OUT",
                  style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(AppFormatters.formatTimeOfDay(_schedOut),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodayLogs() {
    if (_todayLogs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text("No logs yet today.",
              style: TextStyle(
                  color: AppColors.textBody.withValues(alpha: 0.6))),
        ),
      );
    }
    return Column(
      children: _todayLogs.reversed.map((log) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                    log.type == 'in'
                        ? Icons.login_rounded
                        : Icons.logout_rounded,
                    color: log.type == 'in'
                        ? AppColors.success
                        : AppColors.orange,
                    size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppFormatters.formatTime(log.timestamp),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                      if (log.accomplishment != null)
                        Text(log.accomplishment!,
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                // Form status chip
                if (log.formStatus != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _buildFormStatusChip(log.formStatus!),
                  ),
                const SizedBox(width: 8),
                StatusChip(status: log.status),
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text("No records found.",
              style: TextStyle(
                  color: AppColors.textBody.withValues(alpha: 0.5))),
        ),
      );
    }
    return Column(
      children: _history.map((log) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: GlassCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                    log.type == 'in'
                        ? Icons.login_rounded
                        : Icons.logout_rounded,
                    color: log.type == 'in'
                        ? AppColors.success
                        : AppColors.orange,
                    size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppFormatters.formatDate(log.date),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                      Text(AppFormatters.formatTime(log.timestamp),
                          style: const TextStyle(
                              color: AppColors.textBody, fontSize: 13)),
                      if (log.accomplishment != null)
                        Text("“${log.accomplishment}”",
                            style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                                fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
                StatusChip(status: log.status),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}