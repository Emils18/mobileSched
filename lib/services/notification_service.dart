import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance =
      NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  late SharedPreferences _prefs;
  bool _initialized = false;

  static const String _channelId = 'mobilesched_reminders_v2';
  static const String _channelName = 'MobileSched Reminders';

  static const String _keyEnabled = 'notif_enabled';
  static const String _keySound = 'notif_sound';
  static const String _keyVibration = 'notif_vibration';
  static const String _keyPersistent = 'notif_persistent';

  bool _enabled = true;
  bool _sound = true;
  bool _vibration = true;
  bool _persistent = false;

  bool get isEnabled => _enabled;
  bool get isSoundEnabled => _sound;
  bool get isVibrationEnabled => _vibration;
  bool get isPersistentEnabled => _persistent;

  Future<void> init() async {
    if (_initialized) {
      return;
    }

    _prefs = await SharedPreferences.getInstance();
    _loadSettings();

    tz.initializeTimeZones();

    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(
        tz.getLocation(timezone.identifier),
      );
    } catch (_) {
      tz.setLocalLocation(
        tz.getLocation('Asia/Manila'),
      );
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initializationSettings);

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    const AndroidNotificationChannel channel =
        AndroidNotificationChannel(
      _channelId,
      _channelName,
      description:
          'Important reminders for clocking in and clocking out.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await androidPlugin?.createNotificationChannel(channel);

    _initialized = true;
  }

  void _loadSettings() {
    _enabled = _prefs.getBool(_keyEnabled) ?? true;
    _sound = _prefs.getBool(_keySound) ?? true;
    _vibration = _prefs.getBool(_keyVibration) ?? true;
    _persistent = _prefs.getBool(_keyPersistent) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    await _prefs.setBool(_keyEnabled, value);

    if (!value) {
      await cancelAllReminders();
    }
  }

  Future<void> setSound(bool value) async {
    _sound = value;
    await _prefs.setBool(_keySound, value);
  }

  Future<void> setVibration(bool value) async {
    _vibration = value;
    await _prefs.setBool(_keyVibration, value);
  }

  Future<void> setPersistent(bool value) async {
    _persistent = value;
    await _prefs.setBool(_keyPersistent, value);
  }

  NotificationDetails _notificationDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription:
            'Important reminders for clocking in and clocking out.',
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        playSound: _sound,
        enableVibration: _vibration,
        ongoing: _persistent,
        autoCancel: !_persistent,
        icon: '@mipmap/launcher_icon',
        largeIcon: const DrawableResourceAndroidBitmap(
          '@mipmap/launcher_icon',
        ),
        styleInformation: const BigTextStyleInformation(''),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: _sound,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
  }

  Future<bool> showTestNotification({
    String? title,
    String? body,
  }) async {
    if (!_enabled) {
      return false;
    }

    await init();

    await _plugin.show(
      1,
      title ?? 'MobileSched Reminder',
      body ?? 'Notifications are working correctly.',
      _notificationDetails(),
    );

    return true;
  }

  Future<void> scheduleReminders({
    required List<int> dutyDays,
    required TimeOfDay timeIn,
    required TimeOfDay timeOut,
  }) async {
    await init();
    await cancelScheduledReminders();

    if (!_enabled || dutyDays.isEmpty) {
      return;
    }

    for (final weekday in dutyDays) {
      await _scheduleReminder(
        id: _notificationId(weekday, 1),
        weekday: weekday,
        time: _subtractMinutes(timeIn, 15),
        title: 'Almost Time In',
        body: 'Your duty starts in 15 minutes. Prepare to clock in.',
      );

      await _scheduleReminder(
        id: _notificationId(weekday, 2),
        weekday: weekday,
        time: timeIn,
        title: 'Time In Now',
        body: 'Your shift is starting. Open MobileSched and clock in.',
      );

      await _scheduleReminder(
        id: _notificationId(weekday, 3),
        weekday: weekday,
        time: _addMinutes(timeIn, 10),
        title: 'Clock In Missing',
        body: 'You have not clocked in yet. Please clock in now.',
      );

      await _scheduleReminder(
        id: _notificationId(weekday, 4),
        weekday: weekday,
        time: _addMinutes(timeIn, 20),
        title: 'Still Not Clocked In',
        body: 'MobileSched is still waiting for your Time In.',
      );

      await _scheduleReminder(
        id: _notificationId(weekday, 5),
        weekday: weekday,
        time: _addMinutes(timeIn, 30),
        title: 'Final Time In Reminder',
        body: 'You are already late. Record your Time In now.',
      );

      await _scheduleReminder(
        id: _notificationId(weekday, 6),
        weekday: weekday,
        time: _subtractMinutes(timeOut, 15),
        title: 'Almost Time Out',
        body:
            'Your shift ends in 15 minutes. Prepare your accomplishment.',
      );

      await _scheduleReminder(
        id: _notificationId(weekday, 7),
        weekday: weekday,
        time: timeOut,
        title: 'Time Out Now',
        body:
            'Your shift has ended. Record your accomplishment and clock out.',
      );

      await _scheduleReminder(
        id: _notificationId(weekday, 8),
        weekday: weekday,
        time: _addMinutes(timeOut, 10),
        title: 'Clock Out Missing',
        body: 'You have not clocked out yet. Please complete it now.',
      );

      await _scheduleReminder(
        id: _notificationId(weekday, 9),
        weekday: weekday,
        time: _addMinutes(timeOut, 20),
        title: 'Still Not Clocked Out',
        body:
            'Do not forget to submit your accomplishment and clock out.',
      );

      await _scheduleReminder(
        id: _notificationId(weekday, 10),
        weekday: weekday,
        time: _addMinutes(timeOut, 30),
        title: 'Final Time Out Reminder',
        body: 'Your attendance record is incomplete. Clock out now.',
      );
    }
  }

  Future<void> _scheduleReminder({
    required int id,
    required int weekday,
    required TimeOfDay time,
    required String title,
    required String body,
  }) async {
    final scheduledDate = _nextWeekdayTime(
      weekday,
      time,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      _notificationDetails(),
      androidScheduleMode:
          AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents:
          DateTimeComponents.dayOfWeekAndTime,
      payload: 'mobilesched_reminder',
    );
  }

  Future<void> cancelTodayTimeInReminders() async {
    final weekday = DateTime.now().weekday;

    for (int type = 1; type <= 5; type++) {
      await _plugin.cancel(
        _notificationId(weekday, type),
      );
    }
  }

  Future<void> cancelTodayTimeOutReminders() async {
    final weekday = DateTime.now().weekday;

    for (int type = 6; type <= 10; type++) {
      await _plugin.cancel(
        _notificationId(weekday, type),
      );
    }
  }

  Future<void> cancelScheduledReminders() async {
    for (int weekday = 1; weekday <= 7; weekday++) {
      for (int type = 1; type <= 10; type++) {
        await _plugin.cancel(
          _notificationId(weekday, type),
        );
      }
    }
  }

  Future<void> cancelAllReminders() async {
    await _plugin.cancelAll();
  }

  Future<List<PendingNotificationRequest>>
      getPendingReminders() async {
    return _plugin.pendingNotificationRequests();
  }

  int _notificationId(int weekday, int type) {
    return (weekday * 100) + type;
  }

  tz.TZDateTime _nextWeekdayTime(
    int weekday,
    TimeOfDay time,
  ) {
    final now = tz.TZDateTime.now(tz.local);

    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    while (scheduled.weekday != weekday ||
        !scheduled.isAfter(now)) {
      scheduled = scheduled.add(
        const Duration(days: 1),
      );
    }

    return scheduled;
  }

  TimeOfDay _addMinutes(
    TimeOfDay time,
    int minutes,
  ) {
    final totalMinutes =
        ((time.hour * 60) + time.minute + minutes) %
            (24 * 60);

    return TimeOfDay(
      hour: totalMinutes ~/ 60,
      minute: totalMinutes % 60,
    );
  }

  TimeOfDay _subtractMinutes(
    TimeOfDay time,
    int minutes,
  ) {
    var totalMinutes =
        (time.hour * 60) + time.minute - minutes;

    while (totalMinutes < 0) {
      totalMinutes += 24 * 60;
    }

    return TimeOfDay(
      hour: totalMinutes ~/ 60,
      minute: totalMinutes % 60,
    );
  }
}