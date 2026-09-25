import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemePreset {
  midnight,
  ocean,
  violet,
  light,
}

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance =
      ThemeService._internal();

  factory ThemeService() => _instance;

  ThemeService._internal();

  static const String _themeKey =
      'mobilesched_theme';

  SharedPreferences? _prefs;

  AppThemePreset _preset =
      AppThemePreset.midnight;

  AppThemePreset get preset => _preset;

  Future<void> init() async {
    _prefs ??=
        await SharedPreferences.getInstance();

    final String? savedTheme =
        _prefs!.getString(_themeKey);

    final AppThemePreset loadedTheme =
        AppThemePreset.values.firstWhere(
      (theme) =>
          theme.name == savedTheme,
      orElse: () =>
          AppThemePreset.midnight,
    );

    if (_preset != loadedTheme) {
      _preset = loadedTheme;

      // IMPORTANT:
      // Makes the saved theme apply to the
      // whole MaterialApp after startup.
      notifyListeners();
    }
  }

  Future<void> setPreset(
    AppThemePreset preset,
  ) async {
    _prefs ??=
        await SharedPreferences.getInstance();

    if (_preset == preset) {
      return;
    }

    _preset = preset;

    await _prefs!.setString(
      _themeKey,
      preset.name,
    );

    // Rebuilds MobileSched globally.
    notifyListeners();
  }

  String getName(
    AppThemePreset preset,
  ) {
    switch (preset) {
      case AppThemePreset.midnight:
        return 'Midnight Navy';

      case AppThemePreset.ocean:
        return 'Azure Blue';

      case AppThemePreset.violet:
        // Internal enum stays violet so old
        // saved settings do not break.
        return 'Warm Amber';

      case AppThemePreset.light:
        return 'Cream Light';
    }
  }

  String getDescription(
    AppThemePreset preset,
  ) {
    switch (preset) {
      case AppThemePreset.midnight:
        return 'Premium navy and blue';

      case AppThemePreset.ocean:
        return 'Rich blue with sky accents';

      case AppThemePreset.violet:
        return 'Warm orange and navy';

      case AppThemePreset.light:
        return 'Clean cream and navy';
    }
  }

  IconData getIcon(
    AppThemePreset preset,
  ) {
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