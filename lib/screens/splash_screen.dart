import 'dart:async';

import 'package:flutter/material.dart';

import '../services/attendance_service.dart';
import '../services/google_form_service.dart';
import '../services/notification_service.dart';
import '../services/pending_submission_service.dart';
import '../services/theme_service.dart';
import 'dashboard_screen.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  String _statusText = 'Starting MobileSched...';
  String? _savedName;
  bool _hasStartupError = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApplication();
    });
  }

  Future<void> _initializeApplication() async {
    try {
      await _runStartupTask(
        label: 'Loading attendance...',
        task: AttendanceService().init,
      );

      await _runStartupTask(
        label: 'Loading preferences...',
        task: GoogleFormService().init,
      );

      await _runStartupTask(
        label: 'Checking submissions...',
        task: PendingSubmissionService().init,
      );

      await _runStartupTask(
        label: 'Loading theme...',
        task: ThemeService().init,
      );

      await _initializeNotificationsSafely();

      final String? name = AttendanceService().getUserName();
      final bool hasName = name != null && name.trim().isNotEmpty;

      if (!mounted) {
        return;
      }

      setState(() {
        _savedName = hasName ? name.trim() : null;
        _statusText = hasName
            ? 'Welcome back, ${name.trim()}'
            : 'Welcome to MobileSched';
      });

      await Future<void>.delayed(
        const Duration(milliseconds: 1400),
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) {
            if (hasName) {
              return const DashboardScreen();
            }

            return const WelcomeScreen();
          },
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('MobileSched startup error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      setState(() {
        _hasStartupError = true;
        _statusText = 'Startup failed. Tap Retry.';
      });
    }
  }

  Future<void> _initializeNotificationsSafely() async {
    if (mounted) {
      setState(() {
        _statusText = 'Preparing notifications...';
      });
    }

    try {
      await NotificationService()
          .init()
          .timeout(const Duration(seconds: 8));
    } on TimeoutException {
      debugPrint(
        'Notification initialization timed out.',
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Notification initialization failed: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _runStartupTask({
    required String label,
    required Future<void> Function() task,
  }) async {
    if (mounted) {
      setState(() {
        _statusText = label;
      });
    }

    await task().timeout(
      const Duration(seconds: 10),
    );
  }

  Future<void> _retryStartup() async {
    setState(() {
      _hasStartupError = false;
      _statusText = 'Retrying...';
    });

    await _initializeApplication();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.scaffoldBackgroundColor,
              colors.primary.withValues(alpha: 0.18),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 130,
                    height: 130,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colors.surface.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(36),
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.20),
                          blurRadius: 40,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/mobilesched_logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return Icon(
                          Icons.schedule_rounded,
                          color: colors.primary,
                          size: 70,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'MobileSched',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 31,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _statusText,
                      key: ValueKey<String>(_statusText),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _hasStartupError
                            ? colors.error
                            : colors.onSurface.withValues(alpha: 0.68),
                        fontSize: _savedName != null ? 16 : 13,
                        fontWeight: _savedName != null
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (!_hasStartupError)
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: colors.primary,
                      ),
                    )
                  else
                    FilledButton.icon(
                      onPressed: _retryStartup,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}