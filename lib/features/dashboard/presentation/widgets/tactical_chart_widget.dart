// lib/features/dashboard/presentation/widgets/tactical_chart_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';

/// Modelo de datos para una serie del gráfico.
class ChartSeries {
  final String label;
  final Color color;
  final List<int> hourlyData; // 24 buckets (0–23)

  const ChartSeries({
    required this.label,
    required this.color,
    required this.hourlyData,
  });
}

/// Widget de gráfico táctico interactivo con barras por hora.
///
/// Soporta hasta 2 series superpuestas (p.ej. peatonal + vehicular).
/// Las barras tienen tooltips al hover y la hora actual se destaca.
/// No depende de ninguna librería de gráficos externa.
class TacticalBarChart extends StatefulWidget {
  final List<ChartSeries> series;
  final double height;
  final bool showLegend;
  final String? emptyMessage;

  const TacticalBarChart({
    super.key,
    required this.series,
    this.height = 120,
    this.showLegend = true,
    this.emptyMessage,
  });

  @override
  State<TacticalBarChart> createState() => _TacticalBarChartState();
}

class _TacticalBarChartState extends State<TacticalBarChart> {
  int? _hoveredHour;

  @override
  Widget build(BuildContext context) {
    // Compute max across all series for normalisation
    int maxCount = 1;
    for (final s in widget.series) {
      for (final v in s.hourlyData) {
        if (v > maxCount) maxCount = v;
      }
    }

    final currentHour = DateTime.now().hour;
    final hasData = widget.series.any((s) => s.hourlyData.any((v) => v > 0));

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Bars ──────────────────────────────────────────────
          SizedBox(
            height: widget.height,
            child: hasData
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(24, (hour) {
                      final isCurrentHour = hour == currentHour;
                      final isHovered = _hoveredHour == hour;

                      // Build stacked bars per series
                      return Expanded(
                        child: MouseRegion(
                          cursor: SystemMouseCursors.basic,
                          onEnter: (_) =>
                              setState(() => _hoveredHour = hour),
                          onExit: (_) =>
                              setState(() => _hoveredHour = null),
                          child: Tooltip(
                            message: _buildTooltip(hour),
                            preferBelow: false,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: AppColors.surfaceBorder),
                            ),
                            textStyle: AppTextStyles.labelSmall.copyWith(
                              fontSize: 10,
                              color: AppColors.textPrimary,
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 1),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // Bar label (only on hover or high value)
                                  if (isHovered && _totalAt(hour) > 0)
                                    Text(
                                      _totalAt(hour).toString(),
                                      style:
                                          AppTextStyles.labelSmall.copyWith(
                                        fontSize: 8,
                                        color: isCurrentHour
                                            ? AppColors.accent
                                            : AppColors.primary,
                                      ),
                                    ),

                                  // Stacked bar columns (one per series)
                                  ...widget.series.reversed.map((s) {
                                    final val = s.hourlyData[hour];
                                    final ratio = val / maxCount;
                                    final barH =
                                        (ratio * (widget.height - 20))
                                            .clamp(val > 0 ? 2.0 : 0.0,
                                                widget.height - 20);
                                    final barColor = isCurrentHour
                                        ? AppColors.accent
                                        : s.color;

                                    return AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 600),
                                      curve: Curves.easeOutCubic,
                                      height: barH,
                                      margin: const EdgeInsets.only(top: 1),
                                      decoration: BoxDecoration(
                                        color: barColor.withOpacity(
                                            isHovered
                                                ? 1.0
                                                : isCurrentHour
                                                    ? 0.95
                                                    : 0.55),
                                        borderRadius:
                                            const BorderRadius.vertical(
                                                top: Radius.circular(2)),
                                        boxShadow: (isCurrentHour ||
                                                isHovered)
                                            ? [
                                                BoxShadow(
                                                  color:
                                                      barColor.withOpacity(0.4),
                                                  blurRadius: 6,
                                                )
                                              ]
                                            : null,
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  )
                : Center(
                    child: Text(
                      widget.emptyMessage ?? 'Sin datos aún',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ),
          ),

          const SizedBox(height: 6),

          // ── Hour labels (every 3h) ────────────────────────────
          Row(
            children: List.generate(24, (hour) {
              final showLabel = hour % 3 == 0;
              return Expanded(
                child: Text(
                  showLabel ? hour.toString().padLeft(2, '0') : '',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontSize: 8,
                    color: hour == DateTime.now().hour
                        ? AppColors.accent
                        : AppColors.textMuted,
                  ),
                ),
              );
            }),
          ),

          if (widget.showLegend) ...[
            const SizedBox(height: 10),
            // ── Legend ─────────────────────────────────────────
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                ...widget.series.map(
                  (s) => _LegendDot(color: s.color, label: s.label),
                ),
                _LegendDot(color: AppColors.accent, label: 'Hora actual'),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  String _buildTooltip(int hour) {
    final buf = StringBuffer('${hour.toString().padLeft(2, '0')}:00h\n');
    for (final s in widget.series) {
      buf.write('${s.label}: ${s.hourlyData[hour]}\n');
    }
    return buf.toString().trimRight();
  }

  int _totalAt(int hour) {
    int total = 0;
    for (final s in widget.series) {
      total += s.hourlyData[hour];
    }
    return total;
  }
}

// ── Legend dot ──────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTextStyles.labelSmall
              .copyWith(fontSize: 10, color: AppColors.textMuted),
        ),
      ],
    );
  }
}
