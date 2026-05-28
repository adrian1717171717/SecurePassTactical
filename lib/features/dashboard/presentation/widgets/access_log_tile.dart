// lib/features/dashboard/presentation/widgets/access_log_tile.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';

/// Compact list tile representing a single access-log entry.
///
/// Designed for dense lists where many entries are visible at once.
class AccessLogTile extends StatelessWidget {
  /// Full name of the person accessing.
  final String personName;

  /// Military rank or designation, e.g. "Sgto. 1ro".
  final String rank;

  /// Human-readable event type, e.g. "Ingreso Vehicular".
  final String eventType;

  /// When the event occurred (local time displayed as HH:mm).
  final DateTime timestamp;

  /// Access result: 'granted', 'denied', or 'pending'.
  final String accessResult;

  /// Optional vehicle plate shown in monospace on the trailing side.
  final String? vehiclePlate;

  const AccessLogTile({
    super.key,
    required this.personName,
    required this.rank,
    required this.eventType,
    required this.timestamp,
    required this.accessResult,
    this.vehiclePlate,
  });

  // ── Helpers ────────────────────────────────────────────────

  Color get _statusColor {
    return switch (accessResult.toLowerCase()) {
      'granted' || 'permitido' => AppColors.statusGranted,
      'denied' || 'denegado' => AppColors.statusDenied,
      _ => AppColors.statusPending,
    };
  }

  IconData get _statusIcon {
    return switch (accessResult.toLowerCase()) {
      'granted' || 'permitido' => Icons.check_circle_rounded,
      'denied' || 'denegado' => Icons.cancel_rounded,
      _ => Icons.hourglass_top_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(timestamp);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceBorder.withOpacity(0.6)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // ── Status color bar ──────────────────────────────
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: _statusColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
            ),

            const SizedBox(width: 10),

            // ── Status icon ───────────────────────────────────
            Icon(
              _statusIcon,
              color: _statusColor,
              size: 16,
            ),

            const SizedBox(width: 10),

            // ── Person info (name + rank + event) ─────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      personName,
                      style: AppTextStyles.labelLarge.copyWith(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Rank + event type
                    Text(
                      '$rank • $eventType',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 8),

            // ── Trailing: time + optional plate ───────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Time
                  Text(
                    timeStr,
                    style: AppTextStyles.mono.copyWith(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  // Vehicle plate (optional)
                  if (vehiclePlate != null) ...[
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGlow,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        vehiclePlate!,
                        style: AppTextStyles.mono.copyWith(
                          fontSize: 10,
                          color: AppColors.primaryLight,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
