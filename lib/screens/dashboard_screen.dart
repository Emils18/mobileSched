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
import '../services/theme_service.dart';
import '../theme/app_theme.dart';

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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _scheduleSavedReminders();

      if (!mounted) {
        return;
      }

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
    if (!mounted) {
      return;
    }

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

  Future<void> _scheduleSavedReminders() async {
    try {
      await NotificationService().scheduleReminders(
        dutyDays: _service.getDutyDays(),
        timeIn: _service.getScheduledTimeIn(),
        timeOut: _service.getScheduledTimeOut(),
      );
    } catch (error) {
      debugPrint('Failed to schedule reminders: $error');
    }
  }

  void _showSettingsSheet({bool isFirstTime = false}) {
    showModalBottomSheet<void>(
      context: context,
      isDismissible: !isFirstTime,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _SettingsSheetContent(
          service: _service,
          userName: _userName,
          dutyDays: _dutyDays,
          schedIn: _schedIn,
          schedOut: _schedOut,
          isFirstTime: isFirstTime,
          onSaved: () {
            _loadData();
          },
        );
      },
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
      await NotificationService().cancelTodayTimeInReminders();
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
      await NotificationService().cancelTodayTimeOutReminders();
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
        const SizedBox(width: 12),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showSettingsSheet(),
            borderRadius: BorderRadius.circular(50),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.cardGlass,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.cardBorder,
                ),
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
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
      padding: const EdgeInsets.symmetric(
        vertical: 18,
        horizontal: 18,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildScheduleItem(
              label: 'SCHEDULED IN',
              value: AppFormatters.formatTimeOfDay(_schedIn),
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
              value: AppFormatters.formatTimeOfDay(_schedOut),
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

class _SettingsSheetContent extends StatefulWidget {
  final AttendanceService service;
  final String? userName;
  final List<int> dutyDays;
  final TimeOfDay schedIn;
  final TimeOfDay schedOut;
  final bool isFirstTime;
  final VoidCallback onSaved;

  const _SettingsSheetContent({
    required this.service,
    required this.userName,
    required this.dutyDays,
    required this.schedIn,
    required this.schedOut,
    required this.isFirstTime,
    required this.onSaved,
  });

  @override
  State<_SettingsSheetContent> createState() => _SettingsSheetContentState();
}

class _SettingsSheetContentState extends State<_SettingsSheetContent> {
  late final TextEditingController _nameController;
  late List<int> _tempDays;
  late TimeOfDay _tempIn;
  late TimeOfDay _tempOut;

  final NotificationService _notifService = NotificationService();
  late bool _notifEnabled;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userName);
    _tempDays = List<int>.from(widget.dutyDays);
    _tempIn = widget.schedIn;
    _tempOut = widget.schedOut;
    _notifEnabled = _notifService.isEnabled;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Widget _buildThemeSelector(
    BuildContext context,
    StateSetter setModalState,
  ) {
    final ThemeService themeService = ThemeService();
    final AppThemePreset currentTheme = themeService.preset;
    final ThemeData theme = Theme.of(context);

    final double modalWidth = MediaQuery.sizeOf(context).width - 48;
    final bool useSingleColumn = modalWidth < 320;
    final double cardWidth =
        useSingleColumn ? modalWidth : (modalWidth - 10) / 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSettingsLabel(
          context,
          'APP THEME',
        ),
        const SizedBox(height: 7),
        Text(
          'Choose how MobileSched looks on your device.',
          style: theme.textTheme.bodySmall?.copyWith(
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: AppThemePreset.values.map((preset) {
            final AppPalette palette = MobileSchedTheme.palette(preset);
            final bool isSelected = currentTheme == preset;

            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () async {
                  await themeService.setPreset(preset);

                  if (!context.mounted) {
                    return;
                  }

                  setModalState(() {});
                },
                child: Container(
                  width: cardWidth,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? palette.primary.withValues(alpha: 0.14)
                        : theme.colorScheme.surface.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? palette.primary
                          : theme.dividerColor,
                      width: isSelected ? 1.6 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: palette.primary.withValues(alpha: 0.16),
                              blurRadius: 18,
                              spreadRadius: -4,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 39,
                        height: 39,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              palette.primary,
                              palette.secondary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          themeService.getIcon(preset),
                          color: Colors.white,
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              themeService.getName(preset),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              themeService.getDescription(preset),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 9,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 5),
                        Icon(
                          Icons.check_circle_rounded,
                          color: palette.primary,
                          size: 19,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSettingsLabel(
    BuildContext context,
    String text,
  ) {
    return Text(
      text,
      style: TextStyle(
        color: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.color
            ?.withValues(alpha: 0.68),
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSettingsSwitch({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Future<void> Function(bool value) onChanged,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: value,
        activeThumbColor: colorScheme.primary,
        onChanged: enabled
            ? (newValue) {
                onChanged(newValue);
              }
            : null,
        secondary: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: colorScheme.primary,
            size: 21,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimePickerBox({
    required BuildContext context,
    required String label,
    required TimeOfDay time,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.dividerColor,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      icon,
                      color: colors.primary,
                      size: 18,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.edit_rounded,
                    color: colors.onSurface.withValues(alpha: 0.45),
                    size: 17,
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                label,
                style: TextStyle(
                  color: colors.onSurface.withValues(alpha: 0.55),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 5),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  AppFormatters.formatTimeOfDay(time),
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);

    return DefaultTabController(
      length: 3,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: mediaQuery.viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bgDark,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              border: Border.all(
                color: AppColors.cardBorder,
                width: 1.4,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Header
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary,
                            colorScheme.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isFirstTime
                                ? 'Welcome to MobileSched'
                                : 'Settings & Schedule',
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            widget.isFirstTime
                                ? 'Set up profile & duty schedule.'
                                : 'Configure schedule, theme, & alerts.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (!widget.isFirstTime)
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                          size: 22,
                        ),
                        tooltip: 'Close',
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Navigation Tabs
                TabBar(
                  indicatorColor: colorScheme.primary,
                  labelColor: colorScheme.primary,
                  unselectedLabelColor:
                      colorScheme.onSurface.withValues(alpha: 0.6),
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: const [
                    Tab(text: 'Schedule'),
                    Tab(text: 'Theme & Alerts'),
                    Tab(text: 'Form'),
                  ],
                ),

                const SizedBox(height: 12),

                SizedBox(
                  height: 380,
                  child: TabBarView(
                    physics: const ClampingScrollPhysics(),
                    children: [
                      // TAB 1: Schedule
                      SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSettingsLabel(context, 'PREFERRED NAME'),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Enter your preferred name',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildSettingsLabel(context, 'DUTY DAYS'),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 5,
                              runSpacing: 5,
                              children: List<Widget>.generate(7, (index) {
                                final int dayNumber = index + 1;
                                final bool isSelected =
                                    _tempDays.contains(dayNumber);
                                return ChoiceChip(
                                  label: Text(
                                      AppFormatters.getDayName(dayNumber)),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        if (!_tempDays.contains(dayNumber)) {
                                          _tempDays.add(dayNumber);
                                          _tempDays.sort();
                                        }
                                      } else {
                                        _tempDays.remove(dayNumber);
                                      }
                                    });
                                  },
                                  selectedColor: colorScheme.primary
                                      .withValues(alpha: 0.17),
                                  backgroundColor: colorScheme.surface,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.onSurface
                                            .withValues(alpha: 0.72),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                  showCheckmark: false,
                                );
                              }),
                            ),
                            const SizedBox(height: 10),
                            _buildSettingsLabel(context, 'REGULAR SCHEDULE'),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTimePickerBox(
                                    context: context,
                                    label: 'TIME IN',
                                    time: _tempIn,
                                    icon: Icons.login_rounded,
                                    onTap: () async {
                                      final time = await showTimePicker(
                                        context: context,
                                        initialTime: _tempIn,
                                      );
                                      if (time != null) {
                                        setState(() => _tempIn = time);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildTimePickerBox(
                                    context: context,
                                    label: 'TIME OUT',
                                    time: _tempOut,
                                    icon: Icons.logout_rounded,
                                    onTap: () async {
                                      final time = await showTimePicker(
                                        context: context,
                                        initialTime: _tempOut,
                                      );
                                      if (time != null) {
                                        setState(() => _tempOut = time);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // TAB 2: Theme & Alerts
                      SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildThemeSelector(
                              context,
                              (fn) => setState(fn),
                            ),
                            const SizedBox(height: 12),
                            _buildSettingsLabel(context, 'NOTIFICATIONS'),
                            _buildSettingsSwitch(
                              context: context,
                              title: 'Enable notifications',
                              subtitle: 'Turn all MobileSched alerts on/off.',
                              icon: Icons.notifications_active_outlined,
                              value: _notifEnabled,
                              onChanged: (val) async {
                                await _notifService.setEnabled(val);
                                if (val) {
                                  await _notifService.scheduleReminders(
                                    dutyDays: _tempDays,
                                    timeIn: _tempIn,
                                    timeOut: _tempOut,
                                  );
                                }
                                setState(() => _notifEnabled = val);
                              },
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _notifEnabled
                                    ? () async {
                                        final sent = await _notifService
                                            .showTestNotification();
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context)
                                          ..hideCurrentSnackBar()
                                          ..showSnackBar(
                                            SnackBar(
                                              content: Text(sent
                                                  ? 'Notification sent successfully.'
                                                  : 'Enable notifications first.'),
                                            ),
                                          );
                                      }
                                    : null,
                                icon: const Icon(
                                    Icons.notifications_active_rounded,
                                    size: 18),
                                label: const Text('Test Notification'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: colorScheme.primary,
                                  side: BorderSide(
                                    color: _notifEnabled
                                        ? colorScheme.primary
                                        : theme.dividerColor,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // TAB 3: Google Form Integration
                      SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSettingsLabel(
                                context, 'GOOGLE FORM INTEGRATION'),
                            const SizedBox(height: 10),
                            _buildSettingsSwitch(
                              context: context,
                              title: 'Submit to Google Form',
                              subtitle:
                                  'Automatically open prefilled Google Form when clocking attendance.',
                              icon: Icons.description_outlined,
                              value: GoogleFormService().isEnabled,
                              onChanged: (val) async {
                                await GoogleFormService().setEnabled(val);
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Save Action Button
                PremiumButton(
                  text: 'SAVE CONFIGURATION',
                  icon: Icons.save_rounded,
                  onTap: () async {
                    final String name = _nameController.text.trim();

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text('Please enter your preferred name.'),
                          ),
                        );
                      return;
                    }

                    if (_tempDays.isEmpty) {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text('Select at least one duty day.'),
                          ),
                        );
                      return;
                    }

                    if (!widget.service.isScheduleValid(_tempIn, _tempOut)) {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text('Time Out must be later than Time In.'),
                          ),
                        );
                      return;
                    }

                    await widget.service.setUserName(name);
                    await widget.service.setDutyDays(_tempDays);
                    await widget.service.setScheduledTimeIn(_tempIn);
                    await widget.service.setScheduledTimeOut(_tempOut);

                    await _notifService.scheduleReminders(
                      dutyDays: _tempDays,
                      timeIn: _tempIn,
                      timeOut: _tempOut,
                    );

                    widget.onSaved();

                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}