import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/attendance_service.dart';
import '../utils/constants.dart';
import 'main_shell.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final TextEditingController _nameController = TextEditingController();

  final List<int> _selectedDays = [
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
    DateTime.saturday,
  ];

  TimeOfDay _timeIn = const TimeOfDay(hour: 16, minute: 30);
  TimeOfDay _timeOut = const TimeOfDay(hour: 21, minute: 30);

  int _step = 0;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_step == 0) {
      if (_nameController.text.trim().isEmpty) {
        _showMessage('Please enter your preferred name.');
        return;
      }
      FocusScope.of(context).unfocus();
      setState(() => _step = 1);
      return;
    }

    if (_step == 1) {
      if (_selectedDays.isEmpty) {
        _showMessage('Select at least one duty day.');
        return;
      }
      setState(() => _step = 2);
      return;
    }

    if (!_attendanceService.isScheduleValid(_timeIn, _timeOut)) {
      _showMessage('Time Out must be later than Time In.');
      return;
    }

    await _attendanceService.setUserName(_nameController.text.trim());
    await _attendanceService.setDutyDays(_selectedDays);
    await _attendanceService.setScheduledTimeIn(_timeIn);
    await _attendanceService.setScheduledTimeOut(_timeOut);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => const MainShell(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  void _back() {
    if (_step == 0) return;
    setState(() => _step--);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
  }

  Future<void> _pickTime({required bool isTimeIn}) async {
    final initialTime = isTimeIn ? _timeIn : _timeOut;
    final selected = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: isTimeIn ? "Select Shift Start (Time In)" : "Select Shift End (Time Out)",
    );
    if (selected == null) return;
    setState(() {
      if (isTimeIn) {
        _timeIn = selected;
      } else {
        _timeOut = selected;
      }
    });
  }

  void _selectPreset(List<int> days) {
    setState(() {
      _selectedDays
        ..clear()
        ..addAll(days);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // STEP PROGRESS HEADER
            _buildProgressHeader(),

            // STEP CONTENT
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                child: _buildStep(),
              ),
            ),

            // BOTTOM ACTION BAR
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: const BoxDecoration(
                color: AppColors.bgDeep,
                border: Border(
                  top: BorderSide(color: AppColors.cardBorder, width: 1),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: Icon(
                    _step == 2
                        ? Icons.check_circle_rounded
                        : Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: Text(
                    _step == 2 ? 'ENTER AWS HUB' : 'CONTINUE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // PROGRESS INDICATOR
  // =========================================================================
  Widget _buildProgressHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.bgDeep,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder, width: 1)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: _step > 0
                ? IconButton(
                    tooltip: 'Back',
                    onPressed: _back,
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.textTitle,
                      size: 20,
                    ),
                  )
                : null,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final bool isActive = index <= _step;
                final bool isCurrent = index == _step;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: isCurrent ? 28 : 8,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppColors.primary
                        : (isActive
                            ? AppColors.primary.withValues(alpha: 0.4)
                            : AppColors.cardBorder),
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              }),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '${_step + 1} of 3',
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildNameStep();
      case 1:
        return _buildDaysStep();
      default:
        return _buildScheduleStep();
    }
  }

  // =========================================================================
  // STEP 1: PREFERRED NAME
  // =========================================================================
  Widget _buildNameStep() {
    return SingleChildScrollView(
      key: const ValueKey('name-step'),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          // App Logo Card
          Container(
            width: 100,
            height: 100,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgDeep,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/mobilesched_logo.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.school_rounded,
                  color: AppColors.primary,
                  size: 48,
                ),
              ),
            ),
          ).animate().fadeIn(duration: 350.ms),

          const SizedBox(height: 24),
          const Text(
            'Welcome to AWS HUB',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textTitle,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your working scholar workspace for attendance, duty shifts, and stipend tracking.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textBody,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 32),

          // Name Input Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.bgDeep,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Preferred Name',
                  style: TextStyle(
                    color: AppColors.textTitle,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'This name will appear on your duty attendance and logs.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _next(),
                  style: const TextStyle(
                    color: AppColors.textTitle,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    hintText: 'E.g. Maria Santos',
                    hintStyle: const TextStyle(
                        color: AppColors.textMuted, fontSize: 14),
                    prefixIcon: const Icon(Icons.person_outline_rounded,
                        color: AppColors.primary, size: 20),
                    filled: true,
                    fillColor: AppColors.bgDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
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
  // STEP 2: DUTY DAYS (COMPACT & CLEAN)
  // =========================================================================
  Widget _buildDaysStep() {
    const days = [
      {'num': DateTime.monday, 'name': 'Monday', 'short': 'Mon'},
      {'num': DateTime.tuesday, 'name': 'Tuesday', 'short': 'Tue'},
      {'num': DateTime.wednesday, 'name': 'Wednesday', 'short': 'Wed'},
      {'num': DateTime.thursday, 'name': 'Thursday', 'short': 'Thu'},
      {'num': DateTime.friday, 'name': 'Friday', 'short': 'Fri'},
      {'num': DateTime.saturday, 'name': 'Saturday', 'short': 'Sat'},
      {'num': DateTime.sunday, 'name': 'Sunday', 'short': 'Sun'},
    ];

    return SingleChildScrollView(
      key: const ValueKey('days-step'),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.calendar_month_rounded,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose Duty Days',
                      style: TextStyle(
                        color: AppColors.textTitle,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Select active days for attendance alerts',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // QUICK PRESETS ROW (Saves student from tapping 6 times!)
          Row(
            children: [
              const Text(
                'Quick Presets:',
                style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              ActionChip(
                label: const Text('Mon – Fri'),
                labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary),
                backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.2)),
                onPressed: () => _selectPreset([1, 2, 3, 4, 5]),
              ),
              const SizedBox(width: 6),
              ActionChip(
                label: const Text('Mon – Sat'),
                labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary),
                backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.2)),
                onPressed: () => _selectPreset([1, 2, 3, 4, 5, 6]),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Grouped Days List
          Container(
            decoration: BoxDecoration(
              color: AppColors.bgDeep,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: days.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.cardBorder),
              itemBuilder: (context, index) {
                final dayNum = days[index]['num'] as int;
                final dayName = days[index]['name'] as String;
                final isSelected = _selectedDays.contains(dayNum);

                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedDays.remove(dayNum);
                      } else {
                        _selectedDays.add(dayNum);
                        _selectedDays.sort();
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.cardBorder,
                              width: 1.5,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 16)
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Text(
                          dayName,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.textTitle
                                : AppColors.textMuted,
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'On Duty',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // STEP 3: SCHEDULE (UNIFIED SHIFT CARD)
  // =========================================================================
  Widget _buildScheduleStep() {
    final timeInStr =
        MaterialLocalizations.of(context).formatTimeOfDay(_timeIn);
    final timeOutStr =
        MaterialLocalizations.of(context).formatTimeOfDay(_timeOut);

    return SingleChildScrollView(
      key: const ValueKey('schedule-step'),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.schedule_rounded,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Regular Shift Hours',
                      style: TextStyle(
                        color: AppColors.textTitle,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'You can customize per-day shifts in Settings later',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // UNIFIED SHIFT TIMELINE CARD
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.bgDeep,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Start Duty Box
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickTime(isTimeIn: true),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.bgDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.login_rounded,
                                      size: 15, color: AppColors.primary),
                                  SizedBox(width: 6),
                                  Text(
                                    'SHIFT START',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                timeInStr,
                                style: const TextStyle(
                                  color: AppColors.textTitle,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Tap to edit',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // End Duty Box
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickTime(isTimeIn: false),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.bgDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.logout_rounded,
                                      size: 15, color: AppColors.secondary),
                                  SizedBox(width: 6),
                                  Text(
                                    'SHIFT END',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                timeOutStr,
                                style: const TextStyle(
                                  color: AppColors.textTitle,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Tap to edit',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Informational Tip
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgDeep,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: AppColors.primary, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AWS HUB uses this regular schedule to remind you before shift start and end.',
                    style: TextStyle(
                      color: AppColors.textBody,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}