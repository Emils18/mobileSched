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

  late SharedPreferences _prefs;

  AppThemePreset _preset = AppThemePreset.midnight;

  AppThemePreset get preset => _preset;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    final savedTheme = _prefs.getString(_themeKey);

    _preset = AppThemePreset.values.firstWhere(
      (theme) => theme.name == savedTheme,
      orElse: () => AppThemePreset.midnight,
    );
  }

  Future<void> setPreset(AppThemePreset preset) async {
    if (_preset == preset) {
      return;
    }

    _preset = preset;

    await _prefs.setString(
      _themeKey,
      preset.name,
    );

    notifyListeners();
  }

  String getName(AppThemePreset preset) {
    switch (preset) {
      case AppThemePreset.midnight:
        return 'Midnight Blue';

      case AppThemePreset.ocean:
        return 'Ocean Neon';

      case AppThemePreset.violet:
        return 'Violet Glow';

      case AppThemePreset.light:
        return 'Clean Light';
    }
  }

  String getDescription(AppThemePreset preset) {
    switch (preset) {
      case AppThemePreset.midnight:
        return 'Deep blue premium theme';

      case AppThemePreset.ocean:
        return 'Fresh teal and cyan theme';

      case AppThemePreset.violet:
        return 'Purple futuristic theme';

      case AppThemePreset.light:
        return 'Bright and clean theme';
    }
  }

  IconData getIcon(AppThemePreset preset) {
    switch (preset) {
      case AppThemePreset.midnight:
        return Icons.nightlight_round;

      case AppThemePreset.ocean:
        return Icons.water_rounded;

      case AppThemePreset.violet:
        return Icons.auto_awesome_rounded;

      case AppThemePreset.light:
        return Icons.light_mode_rounded;
    }
  }
}