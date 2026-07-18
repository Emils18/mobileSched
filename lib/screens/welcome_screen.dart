import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/attendance_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_button.dart';
import 'dashboard_screen.dart';

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

  TimeOfDay _timeIn = const TimeOfDay(
    hour: 16,
    minute: 30,
  );

  TimeOfDay _timeOut = const TimeOfDay(
    hour: 21,
    minute: 30,
  );

  int _step = 0;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_step == 0) {
      if (_nameController.text.trim().isEmpty) {
        _showMessage(
          'Please enter your preferred name.',
        );

        return;
      }

      FocusScope.of(context).unfocus();

      setState(() {
        _step = 1;
      });

      return;
    }

    if (_step == 1) {
      if (_selectedDays.isEmpty) {
        _showMessage(
          'Select at least one duty day.',
        );

        return;
      }

      setState(() {
        _step = 2;
      });

      return;
    }

    if (!_attendanceService.isScheduleValid(
      _timeIn,
      _timeOut,
    )) {
      _showMessage(
        'Time Out must be later than Time In.',
      );

      return;
    }

    await _attendanceService.setUserName(
      _nameController.text.trim(),
    );

    await _attendanceService.setDutyDays(
      _selectedDays,
    );

    await _attendanceService.setScheduledTimeIn(
      _timeIn,
    );

    await _attendanceService.setScheduledTimeOut(
      _timeOut,
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (
          context,
          animation,
          secondaryAnimation,
        ) {
          return const DashboardScreen();
        },
        transitionDuration: const Duration(milliseconds: 550),
        transitionsBuilder: (
          context,
          animation,
          secondaryAnimation,
          child,
        ) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _back() {
    if (_step == 0) {
      return;
    }

    setState(() {
      _step--;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  Future<void> _pickTime({
    required bool isTimeIn,
  }) async {
    final initialTime = isTimeIn ? _timeIn : _timeOut;

    final selected = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (selected == null) {
      return;
    }

    setState(() {
      if (isTimeIn) {
        _timeIn = selected;
      } else {
        _timeOut = selected;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = MobileSchedTheme.palette(
      ThemeService().preset,
    );

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomRight,
            colors: [
              colors.background,
              colors.backgroundSecondary,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildProgressHeader(colors),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (
                    child,
                    animation,
                  ) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.08, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _buildStep(colors),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  10,
                  24,
                  26,
                ),
                child: PremiumButton(
                  text: _step == 2
                      ? 'START USING MOBILESCHED'
                      : 'CONTINUE',
                  icon: _step == 2
                      ? Icons.rocket_launch_rounded
                      : Icons.arrow_forward_rounded,
                  onTap: _next,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressHeader(AppPalette colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        18,
        18,
        18,
        0,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: _step > 0
                ? IconButton(
                    onPressed: _back,
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: colors.textPrimary,
                    ),
                  )
                : null,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (index) {
                  final active = index <= _step;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    width: index == _step ? 34 : 9,
                    height: 9,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 4,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? colors.primary
                          : colors.border,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: index == _step
                          ? [
                              BoxShadow(
                                color: colors.primary.withValues(alpha: 0.35),
                                blurRadius: 12,
                              ),
                            ]
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: Text(
                '${_step + 1}/3',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(AppPalette colors) {
    switch (_step) {
      case 0:
        return _buildNameStep(colors);

      case 1:
        return _buildDaysStep(colors);

      default:
        return _buildScheduleStep(colors);
    }
  }

  Widget _buildNameStep(AppPalette colors) {
    return SingleChildScrollView(
      key: const ValueKey('name-step'),
      keyboardDismissBehavior:
          ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(
        28,
        34,
        28,
        20,
      ),
      child: Column(
        children: [
          Hero(
            tag: 'mobilesched-logo',
            child: Container(
              width: 145,
              height: 145,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(35),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.22),
                    blurRadius: 35,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: Image.asset(
                  'assets/images/mobilesched_logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (
                    context,
                    error,
                    stackTrace,
                  ) {
                    return Container(
                      color: colors.surfaceStrong,
                      child: Icon(
                        Icons.schedule_rounded,
                        color: colors.primary,
                        size: 64,
                      ),
                    );
                  },
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(
                duration: 500.ms,
              )
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1, 1),
              ),
          const SizedBox(height: 32),
          Text(
            'Welcome to MobileSched',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your smarter and simpler way to manage attendance and daily schedules.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 15,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 38),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'WHAT SHOULD WE CALL YOU?',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              _next();
            },
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
            decoration: const InputDecoration(
              hintText: 'Enter your preferred name',
              prefixIcon: Icon(
                Icons.person_outline_rounded,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysStep(AppPalette colors) {
    const dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return SingleChildScrollView(
      key: const ValueKey('days-step'),
      padding: const EdgeInsets.fromLTRB(
        28,
        42,
        28,
        20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIntroIcon(
            colors: colors,
            icon: Icons.calendar_month_rounded,
          ),
          const SizedBox(height: 24),
          Text(
            'Select your duty days',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 29,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'MobileSched will use these days to calculate your live attendance status.',
            style: TextStyle(
              color: colors.textSecondary,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 30),
          ...List.generate(
            7,
            (index) {
              final dayNumber = index + 1;
              final selected = _selectedDays.contains(
                dayNumber,
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      setState(() {
                        if (selected) {
                          _selectedDays.remove(dayNumber);
                        } else {
                          _selectedDays.add(dayNumber);
                          _selectedDays.sort();
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 17,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? colors.primary.withValues(alpha: 0.13)
                            : colors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: selected
                              ? colors.primary
                              : colors.border,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: colors.primary.withValues(alpha: 0.10),
                                  blurRadius: 16,
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selected
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            color: selected
                                ? colors.primary
                                : colors.textMuted,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              dayNames[index],
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (selected)
                            Text(
                              'Selected',
                              style: TextStyle(
                                color: colors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleStep(AppPalette colors) {
    return SingleChildScrollView(
      key: const ValueKey('schedule-step'),
      padding: const EdgeInsets.fromLTRB(
        28,
        42,
        28,
        20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIntroIcon(
            colors: colors,
            icon: Icons.schedule_rounded,
          ),
          const SizedBox(height: 24),
          Text(
            'Set your schedule',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 29,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Choose your regular Time In and Time Out schedule. You can update this later.',
            style: TextStyle(
              color: colors.textSecondary,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 36),
          _buildTimeCard(
            colors: colors,
            title: 'TIME IN',
            time: _timeIn,
            icon: Icons.login_rounded,
            onTap: () {
              _pickTime(
                isTimeIn: true,
              );
            },
          ),
          const SizedBox(height: 18),
          _buildTimeCard(
            colors: colors,
            title: 'TIME OUT',
            time: _timeOut,
            icon: Icons.logout_rounded,
            onTap: () {
              _pickTime(
                isTimeIn: false,
              );
            },
          ),
          const SizedBox(height: 26),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.20),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: colors.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your attendance status will be calculated using this schedule.',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 13,
                      height: 1.45,
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

  Widget _buildIntroIcon({
    required AppPalette colors,
    required IconData icon,
  }) {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.22),
        ),
      ),
      child: Icon(
        icon,
        color: colors.primary,
        size: 31,
      ),
    );
  }

  Widget _buildTimeCard({
    required AppPalette colors,
    required String title,
    required TimeOfDay time,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final formattedTime = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(time);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      formattedTime,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.surfaceStrong,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.edit_rounded,
                  color: colors.textMuted,
                  size: 19,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}