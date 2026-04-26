import 'package:flutter/material.dart';
import '../utils/constants.dart';

class PremiumButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final Future<void> Function() onTap;
  final bool isPrimary;

  const PremiumButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onTap,
    this.isPrimary = true,
  });

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    await _controller.forward();
    await _controller.reverse();
    try {
      await widget.onTap();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color1 = widget.isPrimary ? AppColors.primary : AppColors.cardBorder;
    final color2 = widget.isPrimary ? const Color(0xFF007BFF) : Colors.transparent;

    return GestureDetector(
      onTapDown: (_) {
        if (!_isLoading) {
          _controller.forward();
        }
      },
      onTapUp: (_) => _handleTap(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: widget.isPrimary
                ? LinearGradient(
                    colors: [color1, color2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight)
                : null,
            color: widget.isPrimary ? null : AppColors.cardGlass,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isPrimary
                  ? Colors.transparent
                  : AppColors.cardBorder,
              width: 1.5,
            ),
            boxShadow: widget.isPrimary
                ? [
                    BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8))
                  ]
                : [],
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(widget.icon, color: Colors.white, size: 22),
                      const SizedBox(width: 12),
                      Text(
                        widget.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}