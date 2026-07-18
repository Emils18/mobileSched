import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/constants.dart';

class PremiumButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final Future<void> Function() onTap;
  final bool isPrimary;
  final bool isEnabled;

  const PremiumButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onTap,
    this.isPrimary = true,
    this.isEnabled = true,
  });

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  bool _isLoading = false;

  bool get _canTap => widget.isEnabled && !_isLoading;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
    );

    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 0.97,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant PremiumButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!widget.isEnabled && oldWidget.isEnabled) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (!_canTap) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    HapticFeedback.lightImpact();

    try {
      await widget.onTap();
    } catch (_) {
      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleTapDown(TapDownDetails details) {
    if (_canTap) {
      _controller.forward();
    }
  }

  void _handleTapEnd() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    const primaryGradient = LinearGradient(
  colors: [
    AppColors.primary,
    AppColors.primaryDark,
  ],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

    return Semantics(
      button: true,
      enabled: widget.isEnabled,
      label: widget.text,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _handleTapDown,
        onTapUp: (_) {
          _handleTapEnd();
          _handleTap();
        },
        onTapCancel: _handleTapEnd,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: widget.isEnabled ? 1 : 0.45,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: double.infinity,
              constraints: const BoxConstraints(
                minHeight: 60,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 17,
              ),
              decoration: BoxDecoration(
                gradient: widget.isPrimary ? primaryGradient : null,
                color: widget.isPrimary
                    ? null
                    : AppColors.cardGlass,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: widget.isPrimary
                      ? Colors.transparent
                      : AppColors.cardBorder,
                  width: 1.4,
                ),
                boxShadow: widget.isPrimary && widget.isEnabled
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.30),
                          blurRadius: 18,
                          spreadRadius: -4,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : const [],
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _isLoading
                      ? const SizedBox(
                          key: ValueKey('loading'),
                          width: 23,
                          height: 23,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.4,
                          ),
                        )
                      : Row(
                          key: const ValueKey('content'),
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              widget.icon,
                              color: Colors.white,
                              size: 21,
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                widget.text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}