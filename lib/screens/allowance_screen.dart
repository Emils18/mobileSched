import 'package:flutter/material.dart';

import '../models/attendance_model.dart';
import '../services/attendance_service.dart';
import '../utils/constants.dart';

class AllowanceScreen extends StatefulWidget {
  final List<int>? dutyDays;
  final double? hourlyRate;
  final List<AttendanceModel>? history;

  const AllowanceScreen({
    super.key,
    this.dutyDays,
    this.hourlyRate,
    this.history,
  });

  @override
  State<AllowanceScreen> createState() => _AllowanceScreenState();
}

class _AllowanceScreenState extends State<AllowanceScreen> {
  final AttendanceService _service = AttendanceService();

  late List<int> _dutyDays;
  late double _hourlyRate;
  late List<AttendanceModel> _history;

  @override
  void initState() {
    super.initState();
    _dutyDays = widget.dutyDays ?? _service.getDutyDays();
    _hourlyRate = widget.hourlyRate ?? _service.getHourlyRate();
    _history = widget.history ?? _service.getHistory();
  }

  @override
  void didUpdateWidget(covariant AllowanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dutyDays != oldWidget.dutyDays) {
      _dutyDays = widget.dutyDays ?? _service.getDutyDays();
    }
    if (widget.hourlyRate != oldWidget.hourlyRate) {
      _hourlyRate = widget.hourlyRate ?? _service.getHourlyRate();
    }
    if (widget.history != oldWidget.history) {
      _history = widget.history ?? _service.getHistory();
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final logs = widget.history ?? _history;
    final dutyDays = widget.dutyDays ?? _dutyDays;
    final hourlyRate = widget.hourlyRate ?? _hourlyRate;

    final now = DateTime.now();
    final totalDaysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final currentDay = now.day;
    final monthName = _getMonthName(now.month);

    final monthLogs = logs.where((log) {
      return log.timestamp.year == now.year &&
          log.timestamp.month == now.month;
    }).toList();

    final dayMap = <String, List<AttendanceModel>>{};
    for (final log in monthLogs) {
      dayMap.putIfAbsent(log.date, () => []).add(log);
    }

    final dailyItems = <Map<String, dynamic>>[];
    double calculatedTotalHours = 0.0;
    int attendedCount = 0;
    int missedCount = 0;
    int dayOffCount = 0;

    for (int day = 1; day <= currentDay; day++) {
      final dateObj = DateTime(now.year, now.month, day);
      final monthStr = now.month.toString().padLeft(2, '0');
      final dayStr = day.toString().padLeft(2, '0');
      final dateKey = "${now.year}-$monthStr-$dayStr";

      final isDuty = dutyDays.contains(dateObj.weekday);
      final dayLogs = dayMap[dateKey] ?? [];
      dayLogs.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      AttendanceModel? inLog;
      double dayHours = 0.0;

      for (final log in dayLogs) {
        if (log.isClockIn) {
          inLog = log;
        } else if (log.isClockOut && inLog != null) {
          final duration = log.timestamp.difference(inLog.timestamp);
          if (!duration.isNegative) {
            dayHours += duration.inMinutes / 60.0;
          }
          inLog = null;
        }
      }

      calculatedTotalHours += dayHours;
      final earnings = dayHours * hourlyRate;

      String statusBadge;
      Color statusColor;

      if (dayHours > 0) {
        statusBadge = "Attended";
        statusColor = AppColors.success;
        attendedCount++;
      } else if (isDuty) {
        statusBadge = "Missed";
        statusColor = AppColors.error;
        missedCount++;
      } else {
        statusBadge = "Day Off";
        statusColor = AppColors.textMuted;
        dayOffCount++;
      }

      dailyItems.add({
        'day': AppFormatters.formatDate(dateKey),
        'hours': dayHours,
        'earnings': earnings,
        'statusBadge': statusBadge,
        'statusColor': statusColor,
        'hasLog': dayHours > 0,
        'isDuty': isDuty,
      });
    }

    final totalEarnings = calculatedTotalHours * hourlyRate;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text(
          "Scholar Allowance",
          style: TextStyle(
            color: AppColors.textTitle,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.bgDeep,
        elevation: 0,
        centerTitle: false,
        shape: const Border(
          bottom: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. SCHOLAR ALLOWANCE SUMMARY CARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.bgDeep,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "TOTAL EARNED THIS MONTH",
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "$monthName (Day $currentDay of $totalDaysInMonth)",
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Giant clear amount
                  Text(
                    "₱${totalEarnings.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: AppColors.textTitle,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Sub-details: Hours worked & hourly rate
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        "${calculatedTotalHours.toStringAsFixed(1)} hours worked",
                        style: const TextStyle(
                          color: AppColors.textBody,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Container(
                          width: 4, height: 4, decoration: const BoxDecoration(
                              color: AppColors.cardBorder, shape: BoxShape.circle)),
                      const SizedBox(width: 14),
                      const Icon(Icons.payments_outlined,
                          size: 16, color: AppColors.success),
                      const SizedBox(width: 6),
                      Text(
                        "₱${hourlyRate.toStringAsFixed(2)} per hour",
                        style: const TextStyle(
                          color: AppColors.textBody,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1, color: AppColors.cardBorder),
                  const SizedBox(height: 14),

                  // Month Progress Counters (Clear for students)
                  Row(
                    children: [
                      _buildSummaryPill(
                        label: "Attended",
                        count: attendedCount,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      _buildSummaryPill(
                        label: "Days Off",
                        count: dayOffCount,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 8),
                      _buildSummaryPill(
                        label: "Missed",
                        count: missedCount,
                        color: AppColors.error,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. DAILY ATTENDANCE & EARNINGS LEDGER
            const Text(
              "Daily Attendance & Earnings",
              style: TextStyle(
                color: AppColors.textTitle,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 10),

            // Ledger Grouped Card
            Container(
              decoration: BoxDecoration(
                color: AppColors.bgDeep,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dailyItems.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppColors.cardBorder),
                itemBuilder: (context, index) {
                  // Show most recent day on top
                  final item = dailyItems.reversed.toList()[index];
                  final double hours = item['hours'] as double;
                  final double earnings = item['earnings'] as double;
                  final String badge = item['statusBadge'] as String;
                  final Color color = item['statusColor'] as Color;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        // Left: Date + Status Badge
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['day'] as String,
                                style: const TextStyle(
                                  color: AppColors.textTitle,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    badge,
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Right: Hours & Earnings
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              hours > 0
                                  ? "+₱${earnings.toStringAsFixed(2)}"
                                  : "₱0.00",
                              style: TextStyle(
                                color: hours > 0
                                    ? AppColors.success
                                    : AppColors.textMuted,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              hours > 0
                                  ? "${hours.toStringAsFixed(1)} hrs"
                                  : "0 hrs",
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryPill({
    required String label,
    required int count,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.20)),
        ),
        child: Column(
          children: [
            Text(
              "$count",
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}