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
    final ColorScheme colors = theme.colorScheme;
    final BorderRadius radius = borderRadius ?? BorderRadius.circular(24);
    final Color effectiveBorderColor = borderColor ?? theme.dividerColor;

    final Widget card = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: radius,
        border: Border.all(
          color: effectiveBorderColor,
          width: borderColor == null ? 1 : 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060C2340),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Padding(
          padding: padding,
          child: child,
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