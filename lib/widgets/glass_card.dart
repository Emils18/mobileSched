import 'package:flutter/material.dart';

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
    final ThemeData theme = Theme.of(context);

    final ColorScheme colors =
        theme.colorScheme;

    final bool isDark =
        theme.brightness == Brightness.dark;

    final BorderRadius radius =
        borderRadius ??
            BorderRadius.circular(24);

    final Color effectiveBorderColor =
        borderColor ??
            theme.dividerColor;

    final Color glowColor =
        borderColor ??
            colors.primary;

    final Widget card = AnimatedContainer(
      duration: const Duration(
        milliseconds: 260,
      ),
      curve: Curves.easeOutCubic,

      width: width,
      height: height,

      decoration: BoxDecoration(
        borderRadius: radius,

        boxShadow: hasGlow
            ? [
                BoxShadow(
                  color: glowColor.withValues(
                    alpha: isDark
                        ? 0.18
                        : 0.12,
                  ),
                  blurRadius: 26,
                  spreadRadius: -7,
                  offset: const Offset(
                    0,
                    8,
                  ),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isDark
                        ? 0.18
                        : 0.07,
                  ),
                  blurRadius: 18,
                  spreadRadius: -8,
                  offset: const Offset(
                    0,
                    8,
                  ),
                ),
              ],
      ),

      child: ClipRRect(
        borderRadius: radius,

        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: radius,

            border: Border.all(
              color: effectiveBorderColor,
              width: borderColor == null
                  ? 1
                  : 1.4,
            ),
          ),

          child: Padding(
            padding: padding,
            child: child,
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