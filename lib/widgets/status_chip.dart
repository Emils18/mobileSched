import 'package:flutter/material.dart';
import '../utils/constants.dart';

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip({super.key, required this.status});

  Color getColor() {
    switch (status) {
      case "ON TIME":
      case "Almost Time In":
      case "Time In Now":
      case "Time Out Now":
        return AppColors.orange;
      case "LATE":
      case "Late / Missing Time In":
      case "Missing Time Out":
        return AppColors.error;
      case "MANUAL ENTRY":
      case "MANUAL":
      case "OUTSIDE SCHEDULE":
        return AppColors.primary;
      case "NO DUTY DAY":
      case "No Duty Today":
      case "Duty Later":
      case "Currently On Duty":
      case "Shift Completed":
        return AppColors.success;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = getColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}