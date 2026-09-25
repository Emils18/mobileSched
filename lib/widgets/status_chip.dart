import 'package:flutter/material.dart';

import '../services/theme_service.dart';
import '../theme/app_theme.dart';

class StatusChip
    extends StatelessWidget {
  final String status;

  const StatusChip({
    super.key,
    required this.status,
  });

  Color _getColor(
    AppPalette palette,
  ) {
    switch (
        status.toUpperCase()) {
      case 'ON TIME':
      case 'SHIFT COMPLETED':
      case 'CURRENTLY ON DUTY':
        return palette.success;

      case 'ALMOST TIME IN':
      case 'TIME IN NOW':
      case 'TIME OUT NOW':
      case 'EARLY OUT':
        return palette.warning;

      case 'LATE':
      case 'LATE OUT':
      case 'LATE / MISSING TIME IN':
      case 'MISSING TIME OUT':
        return palette.error;

      case 'MANUAL ENTRY':
      case 'MANUAL':
      case 'OUTSIDE SCHEDULE':
        return palette.primary;

      case 'NO DUTY DAY':
      case 'NO DUTY TODAY':
      case 'DUTY LATER':
        return palette.textSecondary;

      default:
        return palette.textMuted;
    }
  }

  IconData _getIcon() {
    switch (
        status.toUpperCase()) {
      case 'ON TIME':
      case 'SHIFT COMPLETED':
        return Icons
            .check_circle_outline_rounded;

      case 'CURRENTLY ON DUTY':
        return Icons
            .work_outline_rounded;

      case 'LATE':
      case 'LATE OUT':
      case 'LATE / MISSING TIME IN':
      case 'MISSING TIME OUT':
        return Icons
            .warning_amber_rounded;

      case 'ALMOST TIME IN':
      case 'TIME IN NOW':
      case 'TIME OUT NOW':
        return Icons
            .notifications_active_outlined;

      case 'EARLY OUT':
        return Icons
            .timelapse_rounded;

      case 'OUTSIDE SCHEDULE':
        return Icons
            .schedule_rounded;

      case 'NO DUTY DAY':
      case 'NO DUTY TODAY':
        return Icons
            .weekend_outlined;

      case 'DUTY LATER':
        return Icons
            .event_available_outlined;

      default:
        return Icons
            .info_outline_rounded;
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final AppPalette palette =
        MobileSchedTheme.palette(
      ThemeService().preset,
    );

    final Color color =
        _getColor(
      palette,
    );

    return AnimatedContainer(
      duration:
          const Duration(
        milliseconds: 220,
      ),

      constraints:
          const BoxConstraints(
        maxWidth: 170,
      ),

      padding:
          const EdgeInsets
              .symmetric(
        horizontal: 10,
        vertical: 6,
      ),

      decoration:
          BoxDecoration(
        color:
            color.withValues(
          alpha: 0.12,
        ),

        borderRadius:
            BorderRadius.circular(
          20,
        ),

        border:
            Border.all(
          color:
              color.withValues(
            alpha: 0.36,
          ),
        ),
      ),

      child:
          Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          Icon(
            _getIcon(),
            color:
                color,
            size:
                13,
          ),

          const SizedBox(
            width: 5,
          ),

          Flexible(
            child:
                Text(
              status,

              maxLines:
                  1,

              overflow:
                  TextOverflow
                      .ellipsis,

              style:
                  TextStyle(
                color:
                    color,

                fontSize:
                    9,

                fontWeight:
                    FontWeight
                        .w800,

                letterSpacing:
                    0.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}