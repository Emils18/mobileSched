import 'package:flutter/material.dart';

import '../models/attendance_model.dart';
import '../services/attendance_service.dart';
import '../utils/constants.dart';
import '../widgets/glass_card.dart';

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

  @override
  Widget build(BuildContext context) {
    final logs = widget.history ?? _history;
    final dutyDays = widget.dutyDays ?? _dutyDays;
    final hourlyRate = widget.hourlyRate ?? _hourlyRate;

    final now = DateTime.now();
    final totalDaysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final currentDay = now.day;

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

      String statusText;
      if (dayHours > 0) {
        statusText =
            "${dayHours.toStringAsFixed(1)}h • ₱${earnings.toStringAsFixed(2)}";
      } else if (isDuty) {
        statusText = "Missed (₱0.00)";
      } else {
        statusText = "Day Off";
      }

      dailyItems.add({
        'day': AppFormatters.formatDate(dateKey),
        'hours': dayHours,
        'earnings': earnings,
        'statusText': statusText,
        'hasLog': dayHours > 0,
        'isDuty': isDuty,
      });
    }

    final totalEarnings = calculatedTotalHours * hourlyRate;

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        title: const Text(
          "Allowance Tracker",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.bgDeep,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Top summary GlassCard
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "THIS MONTH",
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          "Day 1-$currentDay/$totalDaysInMonth",
                          style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "₱${totalEarnings.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        "${calculatedTotalHours.toStringAsFixed(1)} hrs total",
                        style: const TextStyle(
                          color: AppColors.textBody,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.payments_outlined,
                          size: 16, color: AppColors.secondary),
                      const SizedBox(width: 6),
                      Text(
                        "₱${hourlyRate.toStringAsFixed(2)}/hr rate",
                        style: const TextStyle(
                          color: AppColors.textBody,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Daily list below
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: dailyItems.length,
                itemBuilder: (context, index) {
                  final item = dailyItems.reversed.toList()[index];
                  final bool hasLog = item['hasLog'] as bool;
                  final bool isDuty = item['isDuty'] as bool;

                  Color borderColor = AppColors.cardBorder;
                  Color textColor = AppColors.textMuted;
                  if (hasLog) {
                    borderColor = AppColors.success.withValues(alpha: 0.5);
                    textColor = AppColors.success;
                  } else if (isDuty) {
                    borderColor = AppColors.error.withValues(alpha: 0.4);
                    textColor = AppColors.error;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.cardGlass,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item['day'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              item['statusText'] as String,
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
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
}
