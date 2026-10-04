import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/attendance_service.dart';
import '../services/notification_service.dart';
import '../services/google_form_service.dart';
import '../services/web_push_profile_service.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  final bool isFirstTime;
  final VoidCallback? onSaved;

  const SettingsScreen({
    super.key,
    this.isFirstTime = false,
    this.onSaved,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AttendanceService _service = AttendanceService();

  late final TextEditingController _nameController;
  late final TextEditingController _hourlyRateController;
  late List<int> _tempDays;
  late TimeOfDay _tempIn;
  late TimeOfDay _tempOut;
  late bool _isBrokenSchedule;

  final NotificationService _notifService = NotificationService();
  late int _timeInReminderMinutes;
  late int _timeOutReminderMinutes;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _service.getUserName());
    _hourlyRateController = TextEditingController(
        text: _service.getHourlyRate().toStringAsFixed(0));
    _tempDays = List<int>.from(_service.getDutyDays());
    _tempIn = _service.getScheduledTimeIn();
    _tempOut = _service.getScheduledTimeOut();
    _timeInReminderMinutes = _service.getTimeInReminderMinutes();
    _timeOutReminderMinutes = _service.getTimeOutReminderMinutes();
    _isBrokenSchedule = _service.isBrokenScheduleEnabled();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }

  Future<void> _customizeDaySchedule(int dayNumber) async {
    final currentIn = _service.getScheduledTimeInForDay(dayNumber);
    final currentOut = _service.getScheduledTimeOutForDay(dayNumber);

    final TimeOfDay? timeIn = await showTimePicker(
      context: context,
      initialTime: currentIn,
      helpText: "Time In for ${AppFormatters.getDayName(dayNumber)}",
    );

    if (timeIn == null || !mounted) return;

    final TimeOfDay? timeOut = await showTimePicker(
      context: context,
      initialTime: currentOut,
      helpText: "Time Out for ${AppFormatters.getDayName(dayNumber)}",
    );

    if (timeOut == null || !mounted) return;

    await _service.setCustomScheduleForDay(dayNumber, timeIn, timeOut);
    setState(() {});
  }

  Future<void> _setReminderMinutes({
    required bool isTimeIn,
    required int minutes,
  }) async {
    if (minutes >= 45) {
      final bool accepted = await showDialog<bool>(
            context: context,
            builder: (dialogContext) {
              return AlertDialog(
                backgroundColor: AppColors.bgDeep,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                title: const Text('Early Reminder Notice',
                    style: TextStyle(
                        color: AppColors.textTitle,
                        fontWeight: FontWeight.w800,
                        fontSize: 17)),
                content: Text(
                  'You selected $minutes minutes before duty. '
                  'AWS HUB will still remind you when your actual shift starts and ends.',
                  style: const TextStyle(
                      color: AppColors.textBody, fontSize: 13, height: 1.4),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Keep Current',
                        style: TextStyle(color: AppColors.textMuted)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary, elevation: 0),
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text('Use Reminder',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              );
            },
          ) ??
          false;

      if (!accepted || !mounted) return;
    }

    setState(() {
      if (isTimeIn) {
        _timeInReminderMinutes = minutes;
      } else {
        _timeOutReminderMinutes = minutes;
      }
    });
  }

  void _selectPreset(List<int> days) {
    setState(() {
      _tempDays
        ..clear()
        ..addAll(days);
    });
  }

  @override
  Widget build(BuildContext context) {
    final timeInStr =
        MaterialLocalizations.of(context).formatTimeOfDay(_tempIn);
    final timeOutStr =
        MaterialLocalizations.of(context).formatTimeOfDay(_tempOut);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: AppColors.bgDeep,
        elevation: 0,
        centerTitle: false,
        title: Text(
          widget.isFirstTime ? 'Initial Setup' : 'Settings',
          style: const TextStyle(
            color: AppColors.textTitle,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        leading: (widget.isFirstTime || !Navigator.canPop(context))
            ? null
            : IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded,
                    color: AppColors.textTitle),
              ),
        shape: const Border(
          bottom: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. SCHOLAR PROFILE
                    _buildSettingsGroup(
                      title: "Scholar Profile",
                      subtitle: "Your personal details for attendance logs",
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Preferred Name",
                            style: TextStyle(
                              color: AppColors.textTitle,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            style: const TextStyle(
                              color: AppColors.textTitle,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter your name',
                              hintStyle: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 13),
                              prefixIcon: const Icon(
                                  Icons.person_outline_rounded,
                                  color: AppColors.primary,
                                  size: 20),
                              filled: true,
                              fillColor: AppColors.bgDark,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: AppColors.cardBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: AppColors.cardBorder),
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
                    const SizedBox(height: 18),

                    // 2. DUTY DAYS & SCHEDULE
                    _buildSettingsGroup(
                      title: "Duty Schedule",
                      subtitle: "Days and shift hours you are assigned on duty",
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Presets row
                          Row(
                            children: [
                              const Text(
                                "Quick Presets:",
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ActionChip(
                                label: const Text('Mon – Fri'),
                                labelStyle: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary),
                                backgroundColor: AppColors.primary
                                    .withValues(alpha: 0.08),
                                side: BorderSide(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.2)),
                                onPressed: () => _selectPreset([1, 2, 3, 4, 5]),
                              ),
                              const SizedBox(width: 6),
                              ActionChip(
                                label: const Text('Mon – Sat'),
                                labelStyle: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary),
                                backgroundColor: AppColors.primary
                                    .withValues(alpha: 0.08),
                                side: BorderSide(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.2)),
                                onPressed: () =>
                                    _selectPreset([1, 2, 3, 4, 5, 6]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Days chips
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: List<Widget>.generate(7, (index) {
                              final int dayNumber = index + 1;
                              final bool isSelected =
                                  _tempDays.contains(dayNumber);

                              final dayIn = _service
                                  .getScheduledTimeInForDay(dayNumber);
                              final dayOut = _service
                                  .getScheduledTimeOutForDay(dayNumber);
                              final shiftLabel =
                                  _isBrokenSchedule && isSelected
                                      ? "${AppFormatters.getDayName(dayNumber)} (${AppFormatters.formatTimeOfDay(dayIn)}-${AppFormatters.formatTimeOfDay(dayOut)})"
                                      : AppFormatters.getDayName(dayNumber);

                              return FilterChip(
                                label: Text(shiftLabel),
                                selected: isSelected,
                                onSelected: (selected) async {
                                  if (_isBrokenSchedule) {
                                    if (isSelected && selected) {
                                      await _customizeDaySchedule(dayNumber);
                                      return;
                                    }
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
                                    if (selected) {
                                      await _customizeDaySchedule(dayNumber);
                                    }
                                  } else {
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
                                  }
                                },
                                selectedColor: AppColors.primary
                                    .withValues(alpha: 0.12),
                                backgroundColor: AppColors.bgDark,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textBody,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.cardBorder,
                                ),
                                showCheckmark: false,
                              );
                            }),
                          ),
                          const SizedBox(height: 14),

                          // Broken schedule switch
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              "Custom Daily Shifts",
                              style: TextStyle(
                                color: AppColors.textTitle,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: const Text(
                              "Enable to set different shift hours for specific days",
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                            value: _isBrokenSchedule,
                            activeColor: AppColors.primary,
                            onChanged: (val) async {
                              await _service.setBrokenScheduleEnabled(val);
                              setState(() => _isBrokenSchedule = val);
                            },
                          ),
                          const SizedBox(height: 8),

                          // Default Regular Schedule Pickers
                          const Text(
                            "Regular Shift Hours",
                            style: TextStyle(
                              color: AppColors.textTitle,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime: _tempIn,
                                    );
                                    if (time != null) {
                                      setState(() => _tempIn = time);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.bgDark,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: AppColors.cardBorder),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(Icons.login_rounded,
                                                size: 14,
                                                color: AppColors.primary),
                                            SizedBox(width: 5),
                                            Text(
                                              "SHIFT START",
                                              style: TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          timeInStr,
                                          style: const TextStyle(
                                            color: AppColors.textTitle,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime: _tempOut,
                                    );
                                    if (time != null) {
                                      setState(() => _tempOut = time);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.bgDark,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: AppColors.cardBorder),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(Icons.logout_rounded,
                                                size: 14,
                                                color: AppColors.secondary),
                                            SizedBox(width: 5),
                                            Text(
                                              "SHIFT END",
                                              style: TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          timeOutStr,
                                          style: const TextStyle(
                                            color: AppColors.textTitle,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
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
                    const SizedBox(height: 18),

                    // 3. HOURLY ALLOWANCE RATE
                    _buildSettingsGroup(
                      title: "Hourly Allowance Rate",
                      subtitle: "Used to compute your total duty stipend",
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Rate per hour (₱/hr)",
                            style: TextStyle(
                              color: AppColors.textTitle,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _hourlyRateController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            style: const TextStyle(
                              color: AppColors.textTitle,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Default: 12.00',
                              hintStyle: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 13),
                              prefixIcon: const Icon(Icons.payments_outlined,
                                  color: AppColors.success, size: 20),
                              filled: true,
                              fillColor: AppColors.bgDark,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: AppColors.cardBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: AppColors.cardBorder),
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
                    const SizedBox(height: 18),

                    // 4. DUTY REMINDERS
                    _buildSettingsGroup(
                      title: "Duty Reminders",
                      subtitle: "Notification alerts before your duty shifts",
                      child: Column(
                        children: [
                          _buildReminderRow(
                            title: "Before Shift Start",
                            icon: Icons.login_rounded,
                            value: _timeInReminderMinutes,
                            onChanged: (val) => _setReminderMinutes(
                                isTimeIn: true, minutes: val),
                          ),
                          const Divider(
                              height: 16, color: AppColors.cardBorder),
                          _buildReminderRow(
                            title: "Before Shift End",
                            icon: Icons.logout_rounded,
                            value: _timeOutReminderMinutes,
                            onChanged: (val) => _setReminderMinutes(
                                isTimeIn: false, minutes: val),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                if (kIsWeb) {
                                  await const WebPushProfileService()
                                      .showTestNotification();
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Test notification requested.')),
                                  );
                                  return;
                                }

                                final sent = await _notifService
                                    .showTestNotification();
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(sent
                                        ? 'Test notification sent.'
                                        : 'Notification could not be sent.'),
                                  ),
                                );
                              },
                              icon: const Icon(
                                  Icons.notifications_active_outlined,
                                  size: 16),
                              label: const Text("Send Test Notification"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(
                                    color: AppColors.cardBorder),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 5. GOOGLE FORM INTEGRATION
                    _buildSettingsGroup(
                      title: "Google Form Integration",
                      subtitle:
                          "Automatically open prefilled form when clocking attendance",
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          "Auto-Open Google Form",
                          style: TextStyle(
                            color: AppColors.textTitle,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: const Text(
                          "Prefills date, time, and student details",
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 12),
                        ),
                        value: GoogleFormService().isEnabled,
                        activeColor: AppColors.primary,
                        onChanged: (val) async {
                          await GoogleFormService().setEnabled(val);
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // PINNED SAVE CONFIGURATION BUTTON
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
              decoration: const BoxDecoration(
                color: AppColors.bgDeep,
                border: Border(
                  top: BorderSide(color: AppColors.cardBorder, width: 1),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final String name = _nameController.text.trim();
                    final double? rate =
                        double.tryParse(_hourlyRateController.text.trim());

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please enter your preferred name.')),
                      );
                      return;
                    }

                    if (_tempDays.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Select at least one duty day.')),
                      );
                      return;
                    }

                    if (!_service.isScheduleValid(_tempIn, _tempOut)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Shift End must be later than Shift Start.')),
                      );
                      return;
                    }

                    if (rate != null && rate >= 0) {
                      await _service.setHourlyRate(rate);
                    }

                    await _service.setUserName(name);
                    await _service.setDutyDays(_tempDays);
                    await _service.setScheduledTimeIn(_tempIn);
                    await _service.setScheduledTimeOut(_tempOut);
                    await _service.setTimeInReminderMinutes(
                        _timeInReminderMinutes);
                    await _service.setTimeOutReminderMinutes(
                        _timeOutReminderMinutes);

                    if (kIsWeb) {
                      await const WebPushProfileService().syncSchedule(
                        dutyDays: _tempDays,
                        timeInForDay: _service.getScheduledTimeInForDay,
                      );
                    } else {
                      await _notifService.scheduleReminders(
                        dutyDays: _tempDays,
                        timeIn: _tempIn,
                        timeOut: _tempOut,
                        timeInReminderMinutes: _timeInReminderMinutes,
                        timeOutReminderMinutes: _timeOutReminderMinutes,
                      );
                    }

                    widget.onSaved?.call();

                    if (context.mounted) {
                      await showDialog<void>(
                        context: context,
                        barrierDismissible: false,
                        barrierColor: Colors.black.withValues(alpha: 0.35),
                        builder: (_) => const _SaveSuccessOverlay(),
                      );
                    }

                    if (context.mounted && Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded,
                      color: Colors.white, size: 20),
                  label: const Text(
                    "SAVE SETTINGS",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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

  Widget _buildSettingsGroup({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgDeep,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildReminderRow({
    required String title,
    required IconData icon,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textTitle,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: value,
            borderRadius: BorderRadius.circular(12),
            items: AttendanceService.reminderMinuteOptions
                .map(
                  (minutes) => DropdownMenuItem<int>(
                    value: minutes,
                    child: Text(
                      '$minutes min before',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textTitle),
                    ),
                  ),
                )
                .toList(),
            onChanged: (val) {
              if (val != null && val != value) {
                onChanged(val);
              }
            },
          ),
        ),
      ],
    );
  }
}

class _SaveSuccessOverlay extends StatefulWidget {
  const _SaveSuccessOverlay();

  @override
  State<_SaveSuccessOverlay> createState() => _SaveSuccessOverlayState();
}

class _SaveSuccessOverlayState extends State<_SaveSuccessOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _iconScale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _scale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
      ),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 190,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: AppColors.bgDeep,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: AppColors.cardBorder, width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 30,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: ScaleTransition(
                      scale: _iconScale,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '✓',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Settings Saved',
                    style: TextStyle(
                      color: AppColors.textTitle,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Preferences updated',
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
        ),
      ),
    );
  }
}