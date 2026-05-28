import 'package:flutter/material.dart';
import '../../core/config/theme/app_colors.dart';
import '../../core/config/theme/app_text_styles.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  factory StatusBadge.granted({String label = 'AUTORIZADO', IconData icon = Icons.check_circle_rounded}) {
    return StatusBadge(
      label: label,
      color: AppColors.statusGranted,
      icon: icon,
    );
  }

  factory StatusBadge.denied({String label = 'DENEGADO', IconData icon = Icons.cancel_rounded}) {
    return StatusBadge(
      label: label,
      color: AppColors.statusDenied,
      icon: icon,
    );
  }

  factory StatusBadge.pending({String label = 'PENDIENTE', IconData icon = Icons.hourglass_empty_rounded}) {
    return StatusBadge(
      label: label,
      color: AppColors.statusPending,
      icon: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
          ],
          Text(
            label.toUpperCase(),
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
