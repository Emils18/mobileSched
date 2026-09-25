import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/attendance_service.dart';
import '../services/google_form_service.dart';
import '../services/notification_service.dart';
import '../services/pending_submission_service.dart';
import '../services/theme_service.dart';
import 'dashboard_screen.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
  });

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  String _statusText = 'Starting AWS HUB...';

  String? _savedName;

  bool _hasStartupError = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 850,
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.88,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        _initializeApplication();
      },
    );
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

      final String? name =
          AttendanceService().getUserName();

      final bool hasName =
          name != null &&
          name.trim().isNotEmpty;

      if (!mounted) {
        return;
      }

      setState(() {
        _savedName =
            hasName
                ? name.trim()
                : null;

        _statusText =
            hasName
                ? 'Welcome back, ${name.trim()}'
                : 'Welcome to AWS HUB';
      });

      await Future<void>.delayed(
        const Duration(
          milliseconds: 1050,
        ),
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
      debugPrint(
        'AWS HUB startup error: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _hasStartupError = true;

        _statusText =
            'Startup failed. Tap Retry.';
      });
    }
  }

  Future<void> _initializeNotificationsSafely() async {
    // iPhone PWA uses OneSignal Web Push.
    if (kIsWeb) {
      if (mounted) {
        setState(() {
          _statusText =
              'Preparing AWS HUB...';
        });
      }

      return;
    }

    if (mounted) {
      setState(() {
        _statusText =
            'Preparing notifications...';
      });
    }

    try {
      await NotificationService()
          .init()
          .timeout(
            const Duration(
              seconds: 8,
            ),
          );
    } on TimeoutException {
      debugPrint(
        'Notification initialization timed out.',
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Notification initialization failed: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );
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
      const Duration(
        seconds: 10,
      ),
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
  Widget build(
    BuildContext context,
  ) {
    final ThemeData theme =
        Theme.of(context);

    final ColorScheme colors =
        theme.colorScheme;

    final bool isDark =
        theme.brightness ==
            Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.scaffoldBackgroundColor,
              Color.lerp(
                    theme.scaffoldBackgroundColor,
                    colors.primary,
                    isDark ? 0.16 : 0.08,
                  ) ??
                  theme.scaffoldBackgroundColor,
              Color.lerp(
                    theme.scaffoldBackgroundColor,
                    colors.secondary,
                    isDark ? 0.08 : 0.04,
                  ) ??
                  theme.scaffoldBackgroundColor,
            ],
          ),
        ),

        child: Stack(
          children: [
            // Top brand glow
            Positioned(
              top: -110,
              right: -100,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primary.withValues(
                    alpha:
                        isDark
                            ? 0.12
                            : 0.07,
                  ),
                ),
              ),
            ),

            // Bottom orange glow
            Positioned(
              bottom: -130,
              left: -100,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.secondary.withValues(
                    alpha:
                        isDark
                            ? 0.11
                            : 0.06,
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 28,
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            width: 118,
                            height: 118,
                            padding:
                                const EdgeInsets.all(
                              10,
                            ),
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(
                                32,
                              ),
                              color: colors.surface
                                  .withValues(
                                alpha:
                                    isDark
                                        ? 0.78
                                        : 0.95,
                              ),
                              border: Border.all(
                                color: colors.primary
                                    .withValues(
                                  alpha: 0.30,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.primary
                                      .withValues(
                                    alpha:
                                        isDark
                                            ? 0.24
                                            : 0.14,
                                  ),
                                  blurRadius: 34,
                                  spreadRadius: -5,
                                  offset:
                                      const Offset(
                                    0,
                                    14,
                                  ),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(
                                24,
                              ),
                              child: Image.asset(
                                'assets/images/mobilesched_logo.png',
                                fit: BoxFit.cover,
                                errorBuilder: (
                                  context,
                                  error,
                                  stackTrace,
                                ) {
                                  return Icon(
                                    Icons.hub_rounded,
                                    color:
                                        colors.primary,
                                    size: 62,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 26,
                        ),

                        Text(
                          'AWS HUB',
                          textAlign:
                              TextAlign.center,
                          style: theme
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                            fontSize: 34,
                            fontWeight:
                                FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        Container(
                          height: 4,
                          width: 72,
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(
                              20,
                            ),
                            gradient:
                                LinearGradient(
                              colors: [
                                colors.primary,
                                colors.secondary,
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        Text(
                          'Attendance • Schedule • Updates',
                          textAlign:
                              TextAlign.center,
                          style: theme
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                            fontSize: 11,
                            fontWeight:
                                FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),

                        const SizedBox(
                          height: 30,
                        ),

                        AnimatedSwitcher(
                          duration:
                              const Duration(
                            milliseconds: 260,
                          ),
                          child: Text(
                            _statusText,
                            key: ValueKey<String>(
                              _statusText,
                            ),
                            textAlign:
                                TextAlign.center,
                            style: TextStyle(
                              color:
                                  _hasStartupError
                                      ? colors.error
                                      : colors
                                          .onSurface
                                          .withValues(
                                        alpha: 0.70,
                                      ),
                              fontSize:
                                  _savedName !=
                                          null
                                      ? 14
                                      : 12,
                              fontWeight:
                                  _savedName !=
                                          null
                                      ? FontWeight
                                          .w700
                                      : FontWeight
                                          .w600,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 18,
                        ),

                        if (!_hasStartupError)
                          SizedBox(
                            width: 150,
                            child:
                                ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(
                                20,
                              ),
                              child:
                                  LinearProgressIndicator(
                                minHeight: 4,
                                color:
                                    colors.primary,
                                backgroundColor:
                                    colors.primary
                                        .withValues(
                                  alpha: 0.12,
                                ),
                              ),
                            ),
                          )
                        else
                          FilledButton.icon(
                            onPressed:
                                _retryStartup,
                            icon:
                                const Icon(
                              Icons
                                  .refresh_rounded,
                            ),
                            label:
                                const Text(
                              'Retry',
                            ),
                          ),

                        const SizedBox(
                          height: 34,
                        ),

                        Text(
                          'Working Scholar Hub',
                          style: theme
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                            fontSize: 10,
                            fontWeight:
                                FontWeight.w600,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}