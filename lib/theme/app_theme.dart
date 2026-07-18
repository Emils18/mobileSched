import 'package:flutter/material.dart';

import '../services/theme_service.dart';

class AppPalette {
  final Color background;
  final Color backgroundSecondary;
  final Color surface;
  final Color surfaceStrong;
  final Color border;
  final Color primary;
  final Color secondary;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color success;
  final Color warning;
  final Color error;
  final Brightness brightness;

  const AppPalette({
    required this.background,
    required this.backgroundSecondary,
    required this.surface,
    required this.surfaceStrong,
    required this.border,
    required this.primary,
    required this.secondary,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.success,
    required this.warning,
    required this.error,
    required this.brightness,
  });

  bool get isDark => brightness == Brightness.dark;
}

class MobileSchedTheme {
  static const AppPalette midnight = AppPalette(
    background: Color(0xFF020617),
    backgroundSecondary: Color(0xFF071124),
    surface: Color(0xB3142035),
    surfaceStrong: Color(0xFF111D32),
    border: Color(0x2638BDF8),
    primary: Color(0xFF22D3EE),
    secondary: Color(0xFF2563EB),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFFB7C5D9),
    textMuted: Color(0xFF70839D),
    success: Color(0xFF34D399),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFFB7185),
    brightness: Brightness.dark,
  );

  static const AppPalette ocean = AppPalette(
    background: Color(0xFF00141C),
    backgroundSecondary: Color(0xFF002633),
    surface: Color(0xB3083642),
    surfaceStrong: Color(0xFF0A3946),
    border: Color(0x3345F3FF),
    primary: Color(0xFF2DD4BF),
    secondary: Color(0xFF38BDF8),
    textPrimary: Color(0xFFF0FDFA),
    textSecondary: Color(0xFFA7F3D0),
    textMuted: Color(0xFF6A9BA3),
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    error: Color(0xFFFB7185),
    brightness: Brightness.dark,
  );

  static const AppPalette violet = AppPalette(
    background: Color(0xFF0D0618),
    backgroundSecondary: Color(0xFF1B0B2D),
    surface: Color(0xB3291744),
    surfaceStrong: Color(0xFF2A1645),
    border: Color(0x335B21B6),
    primary: Color(0xFFC084FC),
    secondary: Color(0xFF6366F1),
    textPrimary: Color(0xFFFAF5FF),
    textSecondary: Color(0xFFD8B4FE),
    textMuted: Color(0xFF967BA8),
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    error: Color(0xFFFB7185),
    brightness: Brightness.dark,
  );

  static const AppPalette light = AppPalette(
    background: Color(0xFFF4F8FC),
    backgroundSecondary: Color(0xFFE9F2FA),
    surface: Color(0xE6FFFFFF),
    surfaceStrong: Color(0xFFFFFFFF),
    border: Color(0x1F0F4C81),
    primary: Color(0xFF0284C7),
    secondary: Color(0xFF2563EB),
    textPrimary: Color(0xFF102033),
    textSecondary: Color(0xFF40566F),
    textMuted: Color(0xFF71839A),
    success: Color(0xFF059669),
    warning: Color(0xFFD97706),
    error: Color(0xFFE11D48),
    brightness: Brightness.light,
  );

  static AppPalette palette(AppThemePreset preset) {
    switch (preset) {
      case AppThemePreset.midnight:
        return midnight;

      case AppThemePreset.ocean:
        return ocean;

      case AppThemePreset.violet:
        return violet;

      case AppThemePreset.light:
        return light;
    }
  }

  static ThemeData build(AppThemePreset preset) {
    final colors = palette(preset);

    final colorScheme = ColorScheme(
      brightness: colors.brightness,
      primary: colors.primary,
      onPrimary: colors.isDark ? Colors.black : Colors.white,
      secondary: colors.secondary,
      onSecondary: Colors.white,
      error: colors.error,
      onError: Colors.white,
      surface: colors.surfaceStrong,
      onSurface: colors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: colors.brightness,
      scaffoldBackgroundColor: colors.background,
      primaryColor: colors.primary,
      colorScheme: colorScheme,
      dividerColor: colors.border,
      splashColor: colors.primary.withValues(alpha: 0.12),
      highlightColor: colors.primary.withValues(alpha: 0.08),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.primary,
        selectionColor: colors.primary.withValues(alpha: 0.30),
        selectionHandleColor: colors.primary,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.w900,
        ),
        displayMedium: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.w900,
        ),
        headlineLarge: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.w900,
        ),
        headlineMedium: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
        titleLarge: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
        titleMedium: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(
          color: colors.textSecondary,
        ),
        bodyMedium: TextStyle(
          color: colors.textSecondary,
        ),
        bodySmall: TextStyle(
          color: colors.textMuted,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: colors.textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        showDragHandle: false,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.surfaceStrong,
        contentTextStyle: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceStrong,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return colors.primary;
            }

            return colors.textMuted;
          },
        ),
        trackColor: WidgetStateProperty.resolveWith<Color?>(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return colors.primary.withValues(alpha: 0.35);
            }

            return colors.border;
          },
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surface,
        selectedColor: colors.primary.withValues(alpha: 0.16),
        disabledColor: colors.surface,
        labelStyle: TextStyle(
          color: colors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
        secondaryLabelStyle: TextStyle(
          color: colors.primary,
          fontWeight: FontWeight.w800,
        ),
        side: BorderSide(
          color: colors.border,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceStrong,
        hintStyle: TextStyle(
          color: colors.textMuted,
        ),
        labelStyle: TextStyle(
          color: colors.textSecondary,
        ),
        prefixIconColor: colors.textMuted,
        suffixIconColor: colors.textMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: colors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: colors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: colors.primary,
            width: 1.6,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: colors.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: colors.error,
            width: 1.6,
          ),
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: colors.surfaceStrong,
        hourMinuteTextColor: colors.textPrimary,
        hourMinuteColor: colors.primary.withValues(alpha: 0.14),
        dayPeriodTextColor: colors.textPrimary,
        dayPeriodColor: colors.primary.withValues(alpha: 0.14),
        dialHandColor: colors.primary,
        dialBackgroundColor: colors.backgroundSecondary,
        dialTextColor: colors.textPrimary,
        entryModeIconColor: colors.primary,
        helpTextStyle: TextStyle(
          color: colors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}