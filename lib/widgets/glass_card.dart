import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.margin,
    this.padding,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        margin: margin ?? const EdgeInsets.all(AppSpacing.sm),
        padding: padding ?? const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.glassBackground,
              AppColors.glassBackground.withOpacity(0.05),
            ],
          ),
          borderRadius: borderRadius ?? AppBorderRadius.circularLg,
          border: Border.all(
            color: AppColors.glassBorder,
            width: GlassEffect.borderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGlow.withOpacity(0.1),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: borderRadius ?? AppBorderRadius.circularLg,
          child: BackdropFilter(
            filter:  ImageFilter.blur(sigmaX: GlassEffect.blurSigma, sigmaY: GlassEffect.blurSigma),
            child: child,
          ),
        ),
      ),
    );
  }
}