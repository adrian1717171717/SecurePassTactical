// lib/features/dashboard/presentation/widgets/stat_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';

/// A compact stat card used on the admin and control-chief dashboards.
///
/// Displays a large [value] number, a [label], and a colored [icon].
/// Supports an optional [onTap] callback and animates a subtle scale
/// on hover via [MouseRegion] + [AnimatedScale].
class StatCard extends StatefulWidget {
  /// Short label shown below the value, e.g. "Vehículos Dentro".
  final String label;

  /// The primary numeric string, e.g. "42".
  final String value;

  /// Icon displayed prominently with the [color] tint.
  final IconData icon;

  /// Accent color used for the icon, glow, and borders.
  final Color color;

  /// Optional tap callback. If null the card is non-interactive.
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.04 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: AppColors.cardGradient,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hovered
                    ? widget.color.withOpacity(0.6)
                    : AppColors.surfaceBorder,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _hovered
                      ? widget.color.withOpacity(0.2)
                      : Colors.black.withOpacity(0.3),
                  blurRadius: _hovered ? 16 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Icon with glow ───────────────────────────
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.color,
                    size: 22,
                  ),
                ),

                const SizedBox(height: 12),

                // ── Value (large counter) ────────────────────
                Text(
                  widget.value,
                  style: AppTextStyles.counterSmall.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.0,
                  ),
                ).animate(key: ValueKey(widget.value)).fadeIn(duration: 300.ms),

                const SizedBox(height: 4),

                // ── Label ────────────────────────────────────
                Text(
                  widget.label.toUpperCase(),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textMuted,
                    letterSpacing: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
