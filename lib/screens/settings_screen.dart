import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/attendance_service.dart';
import '../services/notification_service.dart';
import '../services/google_form_service.dart';
import '../services/theme_service.dart';
import '../services/web_push_profile_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/premium_button.dart';

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
      helpText: "Select Time In for ${AppFormatters.getDayName(dayNumber)}",
    );

    if (timeIn == null || !mounted) return;

    final TimeOfDay? timeOut = await showTimePicker(
      context: context,
      initialTime: currentOut,
      helpText: "Select Time Out for ${AppFormatters.getDayName(dayNumber)}",
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
                title: const Text('Very Early Reminder'),
                content: Text(
                  'You selected $minutes minutes before duty. '
                  'This does not replace the required notification at your '
                  'actual duty time. AWS HUB will still remind you at '
                  '${isTimeIn ? 'Time In' : 'Time Out'} and again if the '
                  'attendance action is still missing.',
                ),
                actions: [
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(dialogContext, false),
                    child: const Text('KEEP CURRENT'),
                  ),
                  FilledButton(
                    onPressed: () =>
                        Navigator.pop(dialogContext, true),
                    child: const Text('USE EARLY REMINDER'),
                  ),
                ],
              );
            },
          ) ??
          false;

      if (!accepted || !mounted) {
        return;
      }
    }

    setState(() {
      if (isTimeIn) {
        _timeInReminderMinutes = minutes;
      } else {
        _timeOutReminderMinutes = minutes;
      }
    });
  }

  Widget _buildReminderPicker({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required int value,
    required bool isTimeIn,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colors.primary, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              borderRadius: BorderRadius.circular(14),
              items: AttendanceService.reminderMinuteOptions
                  .map(
                    (minutes) => DropdownMenuItem<int>(
                      value: minutes,
                      child: Text('$minutes min'),
                    ),
                  )
                  .toList(),
              onChanged: (minutes) {
                if (minutes == null || minutes == value) {
                  return;
                }

                _setReminderMinutes(
                  isTimeIn: isTimeIn,
                  minutes: minutes,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(
    BuildContext context,
    StateSetter setModalState,
  ) {
    final ThemeService themeService = ThemeService();
    final AppThemePreset currentTheme = themeService.preset;
    final ThemeData theme = Theme.of(context);

    final double modalWidth = MediaQuery.sizeOf(context).width - 48;
    final bool useSingleColumn = modalWidth < 460;
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
          'Choose how AWS HUB looks on your device.',
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

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(
          backgroundColor: AppColors.bgDark,
          title: Text(
            widget.isFirstTime ? 'Welcome to AWS HUB' : 'Settings',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
          leading: (widget.isFirstTime || !Navigator.canPop(context))
              ? null
              : IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
          bottom: TabBar(
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
              Tab(text: 'Allowance & Theme'),
              Tab(text: 'Form'),
            ],
          ),
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              Expanded(
                child: TabBarView(
                  physics: const ClampingScrollPhysics(),
                  children: [
                    // TAB 1: Schedule
                    SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
                          _buildSettingsLabel(context, 'DUTY DAYS & SHIFTS'),
                          const SizedBox(height: 4),
                          Text(
                            _isBrokenSchedule
                                ? 'Tap a day chip to customize its shift time.'
                                : 'Select active duty days.',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(fontSize: 10),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 5,
                            runSpacing: 5,
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

                              return ChoiceChip(
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
                          _buildSettingsSwitch(
                            context: context,
                            title: 'Custom / Broken Schedule',
                            subtitle:
                                'Turn ON to customize daily shift times per day.',
                            icon: Icons.splitscreen_rounded,
                            value: _isBrokenSchedule,
                            onChanged: (val) async {
                              await _service
                                  .setBrokenScheduleEnabled(val);
                              setState(() => _isBrokenSchedule = val);
                            },
                          ),
                          const SizedBox(height: 8),
                          _buildSettingsLabel(
                              context, 'DEFAULT FALLBACK SCHEDULE'),
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

                    // TAB 2: Allowance & Theme
                    SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSettingsLabel(
                              context, 'HOURLY ALLOWANCE RATE (₱/hr)'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _hourlyRateController,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Default ₱12.00/hr',
                              prefixIcon: Icon(Icons.payments_outlined),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildThemeSelector(
                            context,
                            (fn) => setState(fn),
                          ),
                          const SizedBox(height: 12),
                          _buildSettingsLabel(
                            context,
                            'REQUIRED DUTY REMINDERS',
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: colorScheme.primary
                                  .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: colorScheme.primary
                                    .withValues(alpha: 0.22),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.lock_clock_rounded,
                                  color: colorScheme.primary,
                                  size: 21,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Duty reminders cannot be turned off '
                                    'inside AWS HUB. The default is 15 '
                                    'minutes before Time In and Time Out. '
                                    'The actual duty-time alert and missing '
                                    'attendance reminders stay active.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 11,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildReminderPicker(
                            context: context,
                            title: 'Before Time In',
                            subtitle:
                                'Choose when the first Time In reminder appears.',
                            icon: Icons.login_rounded,
                            value: _timeInReminderMinutes,
                            isTimeIn: true,
                          ),
                          const SizedBox(height: 8),
                          _buildReminderPicker(
                            context: context,
                            title: 'Before Time Out',
                            subtitle:
                                'Choose when the first Time Out reminder appears.',
                            icon: Icons.logout_rounded,
                            value: _timeOutReminderMinutes,
                            isTimeIn: false,
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                if (kIsWeb) {
                                  await const WebPushProfileService()
                                      .showTestNotification();

                                  if (!context.mounted) return;

                                  ScaffoldMessenger.of(context)
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Test notification requested.',
                                        ),
                                      ),
                                    );
                                  return;
                                }

                                final sent = await _notifService
                                    .showTestNotification();

                                if (!context.mounted) return;

                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        sent
                                            ? 'Notification sent successfully.'
                                            : 'Notification could not be sent.',
                                      ),
                                    ),
                                  );
                              },
                              icon: const Icon(
                                Icons.notifications_active_rounded,
                                size: 18,
                              ),
                              label: const Text('Test Notification'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colorScheme.primary,
                                side: BorderSide(
                                  color: colorScheme.primary,
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
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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

              // Save Action Button
              Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: 80 + MediaQuery.of(context).padding.bottom,
                ),
                child: PremiumButton(
                  text: 'SAVE CONFIGURATION',
                  icon: Icons.save_rounded,
                  onTap: () async {
                    final String name = _nameController.text.trim();
                    final double? rate =
                        double.tryParse(_hourlyRateController.text.trim());

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

                    if (!_service.isScheduleValid(_tempIn, _tempOut)) {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content:
                                Text('Time Out must be later than Time In.'),
                          ),
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
                      _timeInReminderMinutes,
                    );
                    await _service.setTimeOutReminderMinutes(
                      _timeOutReminderMinutes,
                    );

                    if (kIsWeb) {
                      await const WebPushProfileService().syncSchedule(
                        dutyDays: _tempDays,
                        timeInForDay:
                            _service.getScheduledTimeInForDay,
                      );
                    } else {
                      await _notifService.scheduleReminders(
                        dutyDays: _tempDays,
                        timeIn: _tempIn,
                        timeOut: _tempOut,
                        timeInReminderMinutes:
                            _timeInReminderMinutes,
                        timeOutReminderMinutes:
                            _timeOutReminderMinutes,
                      );
                    }

                    widget.onSaved?.call();

                    if (context.mounted) {
                      await showDialog<void>(
                        context: context,
                        barrierDismissible: false,
                        barrierColor:
                            Colors.black.withValues(alpha: 0.55),
                        builder: (_) => const _SaveSuccessOverlay(),
                      );
                    }

                    if (context.mounted && Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
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
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 1000), () {
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 56,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Settings Saved',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}