// lib/features/dashboard/presentation/widgets/tactical_app_bar.dart
import 'package:flutter/material.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';

/// A reusable tactical AppBar used across all dashboard views.
///
/// Implements [PreferredSizeWidget] so it can be used directly
/// as the [Scaffold.appBar] property.
class TacticalAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// The primary title shown in the AppBar.
  final String title;

  /// Optional subtitle shown below the title in a smaller style.
  final String? subtitle;

  /// Whether to show a back-navigation button on the left.
  /// Defaults to false.
  final bool showBackButton;

  /// Additional action widgets placed at the trailing end of the AppBar.
  final List<Widget>? actions;

  const TacticalAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showBackButton = false,
    this.actions,
  });

  @override
  Size get preferredSize => Size.fromHeight(subtitle != null ? 72.0 : 56.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceBorder, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: preferredSize.height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                // ── Leading: back button OR shield icon ────────────
                if (showBackButton)
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    tooltip: 'Volver',
                  )
                else
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryGlow,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),

                const SizedBox(width: 12),

                // ── Title + optional subtitle ───────────────────────
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.headlineSmall.copyWith(
                          letterSpacing: 2.0,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 1),
                        Text(
                          subtitle!,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textMuted,
                            letterSpacing: 1.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Actions ────────────────────────────────────────
                if (actions != null)
                  ...actions!.map(
                    (action) => Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: action,
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
