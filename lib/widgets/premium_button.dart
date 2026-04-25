import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/constants.dart';

class PremiumButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? gradientStart;
  final Color? gradientEnd;
  final bool isLoading;

  const PremiumButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.gradientStart,
    this.gradientEnd,
    this.isLoading = false,
  });

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton> with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: Transform.scale(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.gradientStart ?? AppColors.primaryGlow,
                widget.gradientEnd ?? AppColors.secondaryGlow,
              ],
            ),
            borderRadius: AppBorderRadius.circularXl,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGlow.withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              else
                Icon(widget.icon, color: Colors.white),
              const SizedBox(width: AppSpacing.sm),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ).animate().shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.3)),
      ),
    );
  }
}