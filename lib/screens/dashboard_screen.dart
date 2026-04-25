import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/attendance_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/premium_button.dart';
import '../utils/constants.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isTimeInLoading = false;
  bool _isTimeOutLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.2,
            colors: [
              AppColors.backgroundLight,
              AppColors.backgroundDark,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Text('MobileSched', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5))
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: -0.2, end: 0),
                
                const SizedBox(height: AppSpacing.md),
                
                // Status Card
                Consumer<AttendanceService>(
                  builder: (context, service, _) {
                    return GlassCard(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Today Status', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: service.todayStatus == 'Completed ✓' 
                                      ? AppColors.successGreen.withOpacity(0.2) 
                                      : AppColors.primaryGlow.withOpacity(0.2),
                                  borderRadius: AppBorderRadius.circularSm,
                                ),
                                child: Text(service.todayStatus, style: TextStyle(color: service.todayStatus == 'Completed ✓' ? AppColors.successGreen : AppColors.primaryGlow, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Last Time In', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(service.lastTimeIn, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Last Time Out', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(service.lastTimeOut, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 100.ms, duration: 500.ms).slideX(begin: -0.1, end: 0);
                  },
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Action Buttons Row
                Row(
                  children: [
                    Expanded(
                      child: PremiumButton(
                        label: 'TIME IN',
                        icon: Icons.login_rounded,
                        isLoading: _isTimeInLoading,
                        onPressed: () async {
                          setState(() => _isTimeInLoading = true);
                          await context.read<AttendanceService>().timeIn(
                            context,
                            onSuccess: () => setState(() => _isTimeInLoading = false),
                            onError: () => setState(() => _isTimeInLoading = false),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: PremiumButton(
                        label: 'TIME OUT',
                        icon: Icons.logout_rounded,
                        isLoading: _isTimeOutLoading,
                        gradientStart: AppColors.secondaryGlow,
                        gradientEnd: AppColors.primaryGlow,
                        onPressed: () async {
                          setState(() => _isTimeOutLoading = true);
                          await context.read<AttendanceService>().timeOut(
                            context,
                            onSuccess: () => setState(() => _isTimeOutLoading = false),
                            onError: () => setState(() => _isTimeOutLoading = false),
                          );
                        },
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 200.ms).scale(delay: 200.ms),
                
                const SizedBox(height: AppSpacing.lg),
                
                // History Preview Card
                Consumer<AttendanceService>(
                  builder: (context, service, _) {
                    final history = service.historyPreview;
                    return GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.history, color: AppColors.primaryGlow, size: 20),
                              SizedBox(width: 8),
                              Text('Recent Attendance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          if (history.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Text('No records yet. Tap TIME IN!', style: TextStyle(color: AppColors.textSecondary)),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: history.length,
                              separatorBuilder: (_, __) => const Divider(color: AppColors.glassBorder, height: 16),
                              itemBuilder: (context, index) {
                                final record = history[index];
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(record.formattedDate, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                        const SizedBox(height: 4),
                                        Text('${record.formattedTimeIn} → ${record.formattedTimeOut}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: record.isCompleted ? AppColors.successGreen.withOpacity(0.15) : AppColors.primaryGlow.withOpacity(0.15),
                                        borderRadius: AppBorderRadius.circularSm,
                                      ),
                                      child: Text(record.duration, style: TextStyle(color: record.isCompleted ? AppColors.successGreen : AppColors.primaryGlow, fontSize: 11)),
                                    ),
                                  ],
                                );
                              },
                            ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 300.ms);
                  },
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Settings / Schedule Card
                GlassCard(
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.schedule, color: AppColors.primaryGlow, size: 20),
                          SizedBox(width: 8),
                          Text('Schedule & Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ListTile(
                        leading: const Icon(Icons.work, color: AppColors.primaryGlow),
                        title: const Text('Work Schedule', style: TextStyle(color: Colors.white)),
                        subtitle: const Text('Mon - Fri, 9:00 AM - 6:00 PM', style: TextStyle(color: AppColors.textSecondary)),
                        dense: true,
                      ),
                      ListTile(
                        leading: const Icon(Icons.notifications_none, color: AppColors.primaryGlow),
                        title: const Text('Reminders', style: TextStyle(color: Colors.white)),
                        subtitle: const Text('Get notified before shift', style: TextStyle(color: AppColors.textSecondary)),
                        dense: true,
                      ),
                      ListTile(
                        leading: const Icon(Icons.person_outline, color: AppColors.primaryGlow),
                        title: const Text('Profile Settings', style: TextStyle(color: Colors.white)),
                        subtitle: const Text('Manage your account', style: TextStyle(color: AppColors.textSecondary)),
                        dense: true,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}