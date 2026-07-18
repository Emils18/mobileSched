import 'package:flutter/material.dart';

import '../utils/constants.dart';

class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({
    super.key,
    required this.status,
  });

  Color _getColor() {
    switch (status.toUpperCase()) {
      case 'ON TIME':
      case 'SHIFT COMPLETED':
      case 'CURRENTLY ON DUTY':
        return AppColors.success;

      case 'ALMOST TIME IN':
      case 'TIME IN NOW':
      case 'TIME OUT NOW':
      case 'EARLY OUT':
        return AppColors.orange;

      case 'LATE':
      case 'LATE OUT':
      case 'LATE / MISSING TIME IN':
      case 'MISSING TIME OUT':
        return AppColors.error;

      case 'MANUAL ENTRY':
      case 'MANUAL':
      case 'OUTSIDE SCHEDULE':
        return AppColors.primary;

      case 'NO DUTY DAY':
      case 'NO DUTY TODAY':
      case 'DUTY LATER':
        return AppColors.textBody;

      default:
        return AppColors.textMuted;
    }
  }

  IconData _getIcon() {
    switch (status.toUpperCase()) {
      case 'ON TIME':
      case 'SHIFT COMPLETED':
        return Icons.check_circle_outline_rounded;

      case 'LATE':
      case 'LATE OUT':
      case 'LATE / MISSING TIME IN':
      case 'MISSING TIME OUT':
        return Icons.warning_amber_rounded;

      case 'EARLY OUT':
        return Icons.timelapse_rounded;

      case 'OUTSIDE SCHEDULE':
        return Icons.schedule_rounded;

      case 'NO DUTY DAY':
      case 'NO DUTY TODAY':
        return Icons.weekend_outlined;

      default:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return Container(
      constraints: const BoxConstraints(
        maxWidth: 150,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.38),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIcon(),
            color: color,
            size: 12,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              status,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}