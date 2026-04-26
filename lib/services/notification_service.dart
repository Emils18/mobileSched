import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  late SharedPreferences _prefs;

  // Preference keys
  static const String _keyEnabled = 'notif_enabled';
  static const String _keySound = 'notif_sound';
  static const String _keyVibration = 'notif_vibration';
  static const String _keyPersistent = 'notif_persistent';

  // Current values
  bool _enabled = true;
  bool _sound = true;
  bool _vibration = true;
  bool _persistent = false;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSettings();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'mobilesched_high',
      'MobileSched Reminders',
      description: 'Important reminders for Time In / Time Out',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);

    await androidPlugin?.requestNotificationsPermission();
  }

  void _loadSettings() {
    _enabled = _prefs.getBool(_keyEnabled) ?? true;
    _sound = _prefs.getBool(_keySound) ?? true;
    _vibration = _prefs.getBool(_keyVibration) ?? true;
    _persistent = _prefs.getBool(_keyPersistent) ?? false;
  }

  // Getters
  bool get isEnabled => _enabled;
  bool get isSoundEnabled => _sound;
  bool get isVibrationEnabled => _vibration;
  bool get isPersistentEnabled => _persistent;

  // Setters
  Future<void> setEnabled(bool value) async {
    _enabled = value;
    await _prefs.setBool(_keyEnabled, value);
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

  /// Returns true if the notification was sent, false if blocked by the enabled toggle.
  Future<bool> showTestNotification({
    String? title,
    String? body,
  }) async {
    if (!_enabled) return false;

    final String finalTitle = title ?? 'MobileSched Reminder';
    final String finalBody = body ?? 'Notifications are working correctly.';

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'mobilesched_high',
      'MobileSched Reminders',
      channelDescription: 'Important reminders for Time In / Time Out',
      importance: Importance.max,
      priority: Priority.high,          // allowed in notification details
      playSound: _sound,
      enableVibration: _vibration,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      ongoing: _persistent,
      autoCancel: !_persistent,
    );

    final NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _plugin.show(0, finalTitle, finalBody, details);
    return true;
  }
}