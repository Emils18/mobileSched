import 'package:flutter/material.dart';

class AppColors {
  static const Color backgroundDark = Color(0xFF0A0A0F);
  static const Color backgroundLight = Color(0xFF1A1A2E);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassBackground = Color(0x1AFFFFFF);
  static const Color primaryGlow = Color(0xFF6C63FF);
  static const Color secondaryGlow = Color(0xFF3F3D9E);
  static const Color successGreen = Color(0xFF00E5A0);
  static const Color errorRed = Color(0xFFFF4D6D);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF);
  static const Color cardHighlight = Color(0x33FFD700);
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppBorderRadius {
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;

  static BorderRadius circularSm = BorderRadius.circular(sm);
  static BorderRadius circularMd = BorderRadius.circular(md);
  static BorderRadius circularLg = BorderRadius.circular(lg);
  static BorderRadius circularXl = BorderRadius.circular(xl);
}

class GlassEffect {
  static const double blurSigma = 10.0;
  static const double opacity = 0.15;
  static const double borderWidth = 0.8;
}