import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemePreset {
  midnight,
  ocean,
  violet,
  light,
}

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();

  factory ThemeService() => _instance;

  ThemeService._internal();

  static const String _themeKey = 'mobilesched_theme';

  SharedPreferences? _prefs;

  AppThemePreset _preset = AppThemePreset.light;

  AppThemePreset get preset => _preset;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();

    final String? savedTheme = _prefs!.getString(_themeKey);

    // Force light regardless of saved preference.
    final AppThemePreset loadedTheme = AppThemePreset.light;

    if (_preset != loadedTheme) {
      _preset = loadedTheme;
      notifyListeners();
    }

    // Clean up any old saved theme value
    if (savedTheme != null && savedTheme != 'light') {
      await _prefs!.setString(_themeKey, 'light');
    }
  }

  Future<void> setPreset(AppThemePreset preset) async {
    // Locked to light — no-op.
    if (_preset == AppThemePreset.light) return;

    _preset = AppThemePreset.light;
    notifyListeners();
  }

  String getName(AppThemePreset preset) {
    switch (preset) {
      case AppThemePreset.midnight:
        return 'Midnight Navy';
      case AppThemePreset.ocean:
        return 'Azure Blue';
      case AppThemePreset.violet:
        return 'Warm Amber';
      case AppThemePreset.light:
        return 'Day Mode';
    }
  }

  String getDescription(AppThemePreset preset) {
    switch (preset) {
      case AppThemePreset.midnight:
        return 'Premium navy and blue';
      case AppThemePreset.ocean:
        return 'Rich blue with sky accents';
      case AppThemePreset.violet:
        return 'Warm orange and navy';
      case AppThemePreset.light:
        return 'Clean white and blue';
    }
  }

  IconData getIcon(AppThemePreset preset) {
    switch (preset) {
      case AppThemePreset.midnight:
        return Icons.dark_mode_rounded;
      case AppThemePreset.ocean:
        return Icons.water_rounded;
      case AppThemePreset.violet:
        return Icons.wb_sunny_rounded;
      case AppThemePreset.light:
        return Icons.light_mode_rounded;
    }
  }
}