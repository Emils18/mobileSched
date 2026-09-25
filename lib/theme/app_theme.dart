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

  bool get isDark =>
      brightness == Brightness.dark;
}

class MobileSchedTheme {
  // ============================================================
  // OFFICIAL BRAND COLORS
  // ============================================================

  static const Color brandNavy =
      Color(0xFF103F87);

  static const Color brandCream =
      Color(0xFFFEF8F2);

  static const Color brandOrange =
      Color(0xFFE5791E);

  static const Color brandSky =
      Color(0xFF2D8DCC);

  // ============================================================
  // MIDNIGHT
  // Main recommended MobileSched dark theme.
  // ============================================================

  static const AppPalette midnight =
      AppPalette(
    background: Color(0xFF07172E),
    backgroundSecondary:
        Color(0xFF0B2447),

    surface: Color(0xCC0D294B),
    surfaceStrong:
        Color(0xFF0E2B4F),

    border: Color(0x4D2D8DCC),

    primary: brandSky,
    secondary: brandOrange,

    textPrimary: brandCream,
    textSecondary:
        Color(0xFFD8E3EF),
    textMuted:
        Color(0xFF91A6BA),

    success:
        Color(0xFF35A86B),
    warning:
        Color(0xFFF2B544),
    error:
        Color(0xFFE05252),

    brightness: Brightness.dark,
  );

  // ============================================================
  // OCEAN
  // Stronger blue-focused variation.
  // ============================================================

  static const AppPalette ocean =
      AppPalette(
    background:
        Color(0xFF08283E),
    backgroundSecondary:
        Color(0xFF0A3452),

    surface:
        Color(0xCC0C4162),
    surfaceStrong:
        Color(0xFF0D3D5D),

    border:
        Color(0x592D8DCC),

    primary: brandSky,
    secondary: brandOrange,

    textPrimary: brandCream,
    textSecondary:
        Color(0xFFD9EAF4),
    textMuted:
        Color(0xFF8BA8B9),

    success:
        Color(0xFF35A86B),
    warning:
        Color(0xFFF2B544),
    error:
        Color(0xFFE05252),

    brightness: Brightness.dark,
  );

  // ============================================================
  // WARM
  //
  // We keep the enum name "violet" for now so nothing breaks.
  // Later we rename its DISPLAY name inside ThemeService.
  // ============================================================

  static const AppPalette violet =
      AppPalette(
    background:
        Color(0xFF21170F),
    backgroundSecondary:
        Color(0xFF302114),

    surface:
        Color(0xCC402818),
    surfaceStrong:
        Color(0xFF3A2416),

    border:
        Color(0x66E5791E),

    primary: brandOrange,
    secondary: brandSky,

    textPrimary: brandCream,
    textSecondary:
        Color(0xFFF0DDD0),
    textMuted:
        Color(0xFFB49A86),

    success:
        Color(0xFF35A86B),
    warning:
        Color(0xFFF2B544),
    error:
        Color(0xFFE05252),

    brightness: Brightness.dark,
  );

  // ============================================================
  // LIGHT
  // Official cream / navy MobileSched theme.
  // ============================================================

  static const AppPalette light =
      AppPalette(
    background: brandCream,
    backgroundSecondary:
        Color(0xFFF4ECE4),

    surface:
        Color(0xF5FFFFFF),
    surfaceStrong:
        Color(0xFFFFFFFF),

    border:
        Color(0x26103F87),

    primary: brandNavy,
    secondary: brandOrange,

    textPrimary:
        Color(0xFF102844),
    textSecondary:
        Color(0xFF40566F),
    textMuted:
        Color(0xFF7B8C9E),

    success:
        Color(0xFF238B57),
    warning:
        Color(0xFFC97918),
    error:
        Color(0xFFC94747),

    brightness: Brightness.light,
  );

  static AppPalette palette(
    AppThemePreset preset,
  ) {
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

  static ThemeData build(
    AppThemePreset preset,
  ) {
    final colors =
        palette(preset);

    final colorScheme =
        ColorScheme(
      brightness:
          colors.brightness,

      primary:
          colors.primary,
      onPrimary:
          Colors.white,

      secondary:
          colors.secondary,
      onSecondary:
          Colors.white,

      error:
          colors.error,
      onError:
          Colors.white,

      surface:
          colors.surfaceStrong,
      onSurface:
          colors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,

      brightness:
          colors.brightness,

      scaffoldBackgroundColor:
          colors.background,

      canvasColor:
          colors.background,

      cardColor:
          colors.surfaceStrong,

      primaryColor:
          colors.primary,

      colorScheme:
          colorScheme,

      dividerColor:
          colors.border,

      splashColor:
          colors.primary.withValues(
        alpha: 0.12,
      ),

      highlightColor:
          colors.primary.withValues(
        alpha: 0.08,
      ),

      // ========================================================
      // ICONS
      // ========================================================

      iconTheme: IconThemeData(
        color:
            colors.textSecondary,
      ),

      // ========================================================
      // TEXT SELECTION
      // ========================================================

      textSelectionTheme:
          TextSelectionThemeData(
        cursorColor:
            colors.primary,

        selectionColor:
            colors.primary.withValues(
          alpha: 0.28,
        ),

        selectionHandleColor:
            colors.primary,
      ),

      // ========================================================
      // TEXT
      // ========================================================

      textTheme: TextTheme(
        displayLarge:
            TextStyle(
          color:
              colors.textPrimary,
          fontWeight:
              FontWeight.w900,
          letterSpacing: -1,
        ),

        displayMedium:
            TextStyle(
          color:
              colors.textPrimary,
          fontWeight:
              FontWeight.w900,
        ),

        headlineLarge:
            TextStyle(
          color:
              colors.textPrimary,
          fontWeight:
              FontWeight.w900,
        ),

        headlineMedium:
            TextStyle(
          color:
              colors.textPrimary,
          fontWeight:
              FontWeight.w800,
        ),

        titleLarge:
            TextStyle(
          color:
              colors.textPrimary,
          fontWeight:
              FontWeight.w800,
        ),

        titleMedium:
            TextStyle(
          color:
              colors.textPrimary,
          fontWeight:
              FontWeight.w700,
        ),

        titleSmall:
            TextStyle(
          color:
              colors.textSecondary,
          fontWeight:
              FontWeight.w700,
        ),

        bodyLarge:
            TextStyle(
          color:
              colors.textSecondary,
        ),

        bodyMedium:
            TextStyle(
          color:
              colors.textSecondary,
        ),

        bodySmall:
            TextStyle(
          color:
              colors.textMuted,
        ),

        labelLarge:
            TextStyle(
          color:
              colors.textPrimary,
          fontWeight:
              FontWeight.w700,
        ),
      ),

      // ========================================================
      // APP BAR
      // ========================================================

      appBarTheme:
          AppBarTheme(
        elevation: 0,
        centerTitle: false,

        backgroundColor:
            Colors.transparent,

        foregroundColor:
            colors.textPrimary,

        surfaceTintColor:
            Colors.transparent,

        iconTheme:
            IconThemeData(
          color:
              colors.textPrimary,
        ),

        titleTextStyle:
            TextStyle(
          color:
              colors.textPrimary,
          fontSize: 20,
          fontWeight:
              FontWeight.w800,
        ),
      ),

      // ========================================================
      // BUTTONS
      // ========================================================

      filledButtonTheme:
          FilledButtonThemeData(
        style:
            FilledButton.styleFrom(
          foregroundColor:
              Colors.white,

          backgroundColor:
              colors.primary,

          padding:
              const EdgeInsets
                  .symmetric(
            horizontal: 20,
            vertical: 15,
          ),

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              16,
            ),
          ),

          textStyle:
              const TextStyle(
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),

      elevatedButtonTheme:
          ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(
          foregroundColor:
              Colors.white,

          backgroundColor:
              colors.primary,

          elevation: 0,

          padding:
              const EdgeInsets
                  .symmetric(
            horizontal: 20,
            vertical: 15,
          ),

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              16,
            ),
          ),

          textStyle:
              const TextStyle(
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),

      outlinedButtonTheme:
          OutlinedButtonThemeData(
        style:
            OutlinedButton.styleFrom(
          foregroundColor:
              colors.primary,

          side: BorderSide(
            color:
                colors.border,
          ),

          padding:
              const EdgeInsets
                  .symmetric(
            horizontal: 18,
            vertical: 14,
          ),

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              16,
            ),
          ),

          textStyle:
              const TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),

      textButtonTheme:
          TextButtonThemeData(
        style:
            TextButton.styleFrom(
          foregroundColor:
              colors.primary,

          textStyle:
              const TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),

      // ========================================================
      // SNACKBAR
      // ========================================================

      snackBarTheme:
          SnackBarThemeData(
        behavior:
            SnackBarBehavior.floating,

        backgroundColor:
            colors.surfaceStrong,

        contentTextStyle:
            TextStyle(
          color:
              colors.textPrimary,

          fontWeight:
              FontWeight.w600,
        ),

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            18,
          ),
        ),
      ),

      // ========================================================
      // DIALOG
      // ========================================================

      dialogTheme:
          DialogThemeData(
        backgroundColor:
            colors.surfaceStrong,

        surfaceTintColor:
            Colors.transparent,

        titleTextStyle:
            TextStyle(
          color:
              colors.textPrimary,
          fontSize: 20,
          fontWeight:
              FontWeight.w800,
        ),

        contentTextStyle:
            TextStyle(
          color:
              colors.textSecondary,
          fontSize: 14,
        ),

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            26,
          ),

          side:
              BorderSide(
            color:
                colors.border,
          ),
        ),
      ),

      // ========================================================
      // BOTTOM SHEET
      // ========================================================

      bottomSheetTheme:
          const BottomSheetThemeData(
        backgroundColor:
            Colors.transparent,

        surfaceTintColor:
            Colors.transparent,

        elevation: 0,

        showDragHandle: false,
      ),

      // ========================================================
      // SWITCH
      // ========================================================

      switchTheme:
          SwitchThemeData(
        thumbColor:
            WidgetStateProperty
                .resolveWith<Color?>(
          (states) {
            if (states.contains(
              WidgetState.selected,
            )) {
              return colors.primary;
            }

            return colors.textMuted;
          },
        ),

        trackColor:
            WidgetStateProperty
                .resolveWith<Color?>(
          (states) {
            if (states.contains(
              WidgetState.selected,
            )) {
              return colors.primary
                  .withValues(
                alpha: 0.35,
              );
            }

            return colors.border;
          },
        ),
      ),

      // ========================================================
      // CHECKBOX
      // ========================================================

      checkboxTheme:
          CheckboxThemeData(
        fillColor:
            WidgetStateProperty
                .resolveWith<Color?>(
          (states) {
            if (states.contains(
              WidgetState.selected,
            )) {
              return colors.primary;
            }

            return null;
          },
        ),

        checkColor:
            const WidgetStatePropertyAll(
          Colors.white,
        ),

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            5,
          ),
        ),
      ),

      // ========================================================
      // CHIPS
      // ========================================================

      chipTheme:
          ChipThemeData(
        backgroundColor:
            colors.surface,

        selectedColor:
            colors.primary.withValues(
          alpha: 0.16,
        ),

        disabledColor:
            colors.surface,

        labelStyle:
            TextStyle(
          color:
              colors.textSecondary,

          fontWeight:
              FontWeight.w700,
        ),

        secondaryLabelStyle:
            TextStyle(
          color:
              colors.primary,

          fontWeight:
              FontWeight.w800,
        ),

        side:
            BorderSide(
          color:
              colors.border,
        ),

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            16,
          ),
        ),
      ),

      // ========================================================
      // INPUTS
      // ========================================================

      inputDecorationTheme:
          InputDecorationTheme(
        filled: true,

        fillColor:
            colors.surfaceStrong,

        hintStyle:
            TextStyle(
          color:
              colors.textMuted,
        ),

        labelStyle:
            TextStyle(
          color:
              colors.textSecondary,
        ),

        prefixIconColor:
            colors.textMuted,

        suffixIconColor:
            colors.textMuted,

        contentPadding:
            const EdgeInsets
                .symmetric(
          horizontal: 18,
          vertical: 17,
        ),

        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            18,
          ),

          borderSide:
              BorderSide(
            color:
                colors.border,
          ),
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            18,
          ),

          borderSide:
              BorderSide(
            color:
                colors.border,
          ),
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            18,
          ),

          borderSide:
              BorderSide(
            color:
                colors.primary,
            width: 1.6,
          ),
        ),

        errorBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            18,
          ),

          borderSide:
              BorderSide(
            color:
                colors.error,
          ),
        ),

        focusedErrorBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            18,
          ),

          borderSide:
              BorderSide(
            color:
                colors.error,
            width: 1.6,
          ),
        ),
      ),

      // ========================================================
      // TIME PICKER
      // ========================================================

      timePickerTheme:
          TimePickerThemeData(
        backgroundColor:
            colors.surfaceStrong,

        hourMinuteTextColor:
            colors.textPrimary,

        hourMinuteColor:
            colors.primary.withValues(
          alpha: 0.14,
        ),

        dayPeriodTextColor:
            colors.textPrimary,

        dayPeriodColor:
            colors.primary.withValues(
          alpha: 0.14,
        ),

        dialHandColor:
            colors.primary,

        dialBackgroundColor:
            colors.backgroundSecondary,

        dialTextColor:
            colors.textPrimary,

        entryModeIconColor:
            colors.primary,

        helpTextStyle:
            TextStyle(
          color:
              colors.textSecondary,

          fontWeight:
              FontWeight.w700,
        ),
      ),

      // ========================================================
      // DATE PICKER
      // ========================================================

      datePickerTheme:
          DatePickerThemeData(
        backgroundColor:
            colors.surfaceStrong,

        surfaceTintColor:
            Colors.transparent,

        headerBackgroundColor:
            colors.primary,

        headerForegroundColor:
            Colors.white,

        dayForegroundColor:
            WidgetStatePropertyAll(
          colors.textPrimary,
        ),

        todayForegroundColor:
            WidgetStatePropertyAll(
          colors.secondary,
        ),

        todayBorder:
            BorderSide(
          color:
              colors.secondary,
        ),

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            24,
          ),
        ),
      ),

      // ========================================================
      // PROGRESS
      // ========================================================

      progressIndicatorTheme:
          ProgressIndicatorThemeData(
        color:
            colors.primary,

        linearTrackColor:
            colors.border,
      ),
    );
  }
}