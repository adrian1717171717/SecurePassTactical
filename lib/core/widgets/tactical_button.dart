import 'package:flutter/material.dart';
import '../../core/config/theme/app_colors.dart';
import '../../core/config/theme/app_text_styles.dart';

enum TacticalButtonType { primary, secondary, alert }

class TacticalButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final TacticalButtonType type;
  final double? width;
  final double height;

  const TacticalButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.type = TacticalButtonType.primary,
    this.width,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null && !isLoading;

    final Color colorBackground = switch (type) {
      TacticalButtonType.primary => isEnabled
          ? AppColors.primary
          : AppColors.primary.withOpacity(0.3),
      TacticalButtonType.secondary => Colors.transparent,
      TacticalButtonType.alert => isEnabled
          ? AppColors.alertRed
          : AppColors.alertRed.withOpacity(0.3),
    };

    final Color colorBorder = switch (type) {
      TacticalButtonType.primary => Colors.transparent,
      TacticalButtonType.secondary => isEnabled
          ? AppColors.primary
          : AppColors.primary.withOpacity(0.3),
      TacticalButtonType.alert => Colors.transparent,
    };

    final Color colorText = switch (type) {
      TacticalButtonType.primary => isEnabled ? AppColors.surface : AppColors.textMuted,
      TacticalButtonType.secondary => isEnabled ? AppColors.primary : AppColors.primary.withOpacity(0.4),
      TacticalButtonType.alert => isEnabled ? Colors.white : Colors.white.withOpacity(0.5),
    };

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: Material(
        color: colorBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: colorBorder != Colors.transparent
              ? BorderSide(color: colorBorder, width: 1.5)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          splashColor: colorText.withOpacity(0.15),
          highlightColor: colorText.withOpacity(0.05),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(colorText),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: colorText, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label.toUpperCase(),
                        style: AppTextStyles.labelMedium.copyWith(
                          color: colorText,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
