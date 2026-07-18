import 'dart:ui';

import 'package:flutter/material.dart';

import '../utils/constants.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final bool hasGlow;
  final Color? borderColor;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(24),
    this.borderRadius,
    this.hasGlow = false,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(24);
    final effectiveBorderColor = borderColor ?? AppColors.cardBorder;
    final glowColor = borderColor ?? AppColors.primary;

    final card = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: hasGlow
            ? [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.16),
                  blurRadius: 30,
                  spreadRadius: -6,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 20,
                  spreadRadius: -6,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 22,
            sigmaY: 22,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.cardGlass,
              borderRadius: radius,
              border: Border.all(
                color: effectiveBorderColor,
                width: borderColor == null ? 1 : 1.4,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.085),
                  Colors.white.withValues(alpha: 0.018),
                ],
              ),
            ),
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );

    if (onTap == null) {
      return card;
    }

    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: card,
      ),
    );
  }
}