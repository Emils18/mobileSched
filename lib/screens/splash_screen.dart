import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/attendance_service.dart';
import '../services/google_form_service.dart';
import '../services/notification_service.dart';
import '../services/pending_submission_service.dart';
import '../services/theme_service.dart';
import '../utils/constants.dart';
import 'main_shell.dart';
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

  String _statusText = 'Starting AWS HUB...';
  bool _hasStartupError = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
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
        label: 'Loading appearance...',
        task: ThemeService().init,
      );

      await _initializeNotificationsSafely();

      final String? name = AttendanceService().getUserName();
      final bool hasName = name != null && name.trim().isNotEmpty;

      if (!mounted) return;

      setState(() {
        _statusText =
            hasName ? 'Welcome back, ${name.trim()}' : 'Welcome to AWS HUB';
      });

      await Future<void>.delayed(const Duration(milliseconds: 900));

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) {
            if (hasName) return const MainShell();
            return const WelcomeScreen();
          },
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('AWS HUB startup error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _hasStartupError = true;
        _statusText = 'Startup failed. Tap Retry.';
      });
    }
  }

  Future<void> _initializeNotificationsSafely() async {
    if (kIsWeb) {
      if (mounted) setState(() => _statusText = 'Preparing AWS HUB...');
      return;
    }

    if (mounted) setState(() => _statusText = 'Preparing notifications...');

    try {
      await NotificationService().init().timeout(
            const Duration(seconds: 8),
          );
    } on TimeoutException {
      debugPrint('Notification initialization timed out.');
    } catch (error, stackTrace) {
      debugPrint('Notification initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _runStartupTask({
    required String label,
    required Future<void> Function() task,
  }) async {
    if (mounted) setState(() => _statusText = label);
    await task().timeout(const Duration(seconds: 10));
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
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 118,
                    height: 118,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      color: AppColors.cardGlass,
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/mobilesched_logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.hub_rounded,
                          color: AppColors.primary,
                          size: 62,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'AWS HUB',
                    style: TextStyle(
                      color: AppColors.textTitle,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 3,
                    width: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Attendance • Schedule • Updates',
                    style: TextStyle(
                      color: AppColors.textBody,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    child: Text(
                      _statusText,
                      key: ValueKey<String>(_statusText),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _hasStartupError
                            ? AppColors.error
                            : AppColors.textBody,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (!_hasStartupError)
                    SizedBox(
                      width: 160,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: const LinearProgressIndicator(
                          minHeight: 4,
                          color: AppColors.primary,
                          backgroundColor: Color(0xFFE5E9EE),
                        ),
                      ),
                    )
                  else
                    FilledButton.icon(
                      onPressed: _retryStartup,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  const SizedBox(height: 32),
                  const Text(
                    'Working Scholar Hub',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
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