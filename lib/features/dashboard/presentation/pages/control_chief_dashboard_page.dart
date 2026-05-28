// lib/features/dashboard/presentation/pages/control_chief_dashboard_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';
import '../../../auth/domain/entities/app_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/stat_card.dart';
import '../widgets/access_log_tile.dart';
import '../widgets/tactical_app_bar.dart';

// ── Providers ──────────────────────────────────────────────────────────────

/// Streams all access logs from today (for analytics derivation).
final _controlLogsStreamProvider =
    StreamProvider<QuerySnapshot<Map<String, dynamic>>>((ref) {
  // Compute the start of today in UTC for the Firestore query.
  final todayStart = DateTime.now();
  final start = DateTime(todayStart.year, todayStart.month, todayStart.day);
  return FirebaseFirestore.instance
      .collection('access_logs')
      .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
      .orderBy('timestamp', descending: true)
      .limit(50)
      .snapshots();
});

/// Streams visitors currently marked as inside the perimeter.
final _controlVisitorsInsideProvider =
    StreamProvider<QuerySnapshot<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('visitors')
      .where('status', isEqualTo: 'inside')
      .snapshots();
});

// ── Page ───────────────────────────────────────────────────────────────────

/// Read-only analytics dashboard for the Jefe de Control role.
///
/// Displays today's entry/exit counts, a custom bar-chart activity
/// visualization built with plain [Container] widgets, and the full
/// access-log list. Includes an export button to generate a report.
class ControlChiefDashboardPage extends ConsumerWidget {
  const ControlChiefDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final logsAsync = ref.watch(_controlLogsStreamProvider);
    final visitorsAsync = ref.watch(_controlVisitorsInsideProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: TacticalAppBar(
        title: 'CENTRO DE CONTROL',
        subtitle: userAsync.valueOrNull?.currentRole.displayName.toUpperCase(),
        actions: [
          // Export report button
          IconButton(
            onPressed: () => _showExportDialog(context),
            icon: const Icon(
              Icons.upload_file_rounded,
              color: AppColors.primary,
              size: 22,
            ),
            tooltip: 'Exportar reporte',
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // ── Stats overview ───────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    label: 'RESUMEN DEL DÍA',
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  _StatsOverview(
                    logsAsync: logsAsync,
                    visitorsAsync: visitorsAsync,
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: -0.05, end: 0),
          ),

          // ── Activity bar chart ───────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    label: 'ACTIVIDAD POR HORA',
                    color: AppColors.accent,
                  ),
                  const SizedBox(height: 14),
                  _ActivityBarChart(logsAsync: logsAsync),
                ],
              ),
            ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
          ),

          // ── Access log list header ────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: _SectionHeader(
                label: 'REGISTROS DE ACCESO (HOY)',
                color: AppColors.textSecondary,
              ),
            ).animate().fadeIn(delay: 250.ms),
          ),

          // ── Access log list (read-only) ───────────────────
          logsAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _ControlErrorBanner(message: e.toString()),
              ),
            ),
            data: (snapshot) {
              final docs = snapshot.docs;
              if (docs.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.layers_clear_rounded,
                            size: 48,
                            color: AppColors.textMuted.withOpacity(0.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Sin registros hoy',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return SliverList.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data();
                  final ts =
                      (data['timestamp'] as Timestamp?)?.toDate() ??
                          DateTime.now();
                  return AccessLogTile(
                    personName:
                        data['person_name'] as String? ?? 'Desconocido',
                    rank: data['rank'] as String? ?? '—',
                    eventType:
                        data['event_type'] as String? ?? 'Evento',
                    timestamp: ts,
                    accessResult:
                        data['access_result'] as String? ?? 'pending',
                    vehiclePlate: data['vehicle_plate'] as String?,
                  )
                      .animate(delay: (index * 25).ms)
                      .fadeIn(duration: 250.ms);
                },
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.surfaceBorder),
        ),
        title: Row(
          children: [
            const Icon(Icons.picture_as_pdf_rounded,
                color: AppColors.primary, size: 22),
            const SizedBox(width: 10),
            Text(
              'EXPORTAR REPORTE',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.primary,
                letterSpacing: 1.5,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Generar reporte de actividad para:',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 12),
            _ExportOption(
              label: 'Reporte Diario (${DateFormat('dd/MM/yyyy').format(DateTime.now())})',
              icon: Icons.today_rounded,
            ),
            const SizedBox(height: 8),
            _ExportOption(
              label: 'Reporte de Guardia Actual',
              icon: Icons.assignment_rounded,
            ),
            const SizedBox(height: 8),
            _ExportOption(
              label: 'Resumen de Visitantes',
              icon: Icons.badge_rounded,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar',
                style: AppTextStyles.buttonSecondary),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              // In production: trigger PDF generation via a use case
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Generando reporte PDF…',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textPrimary),
                  ),
                  backgroundColor: AppColors.surfaceElevated,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary),
            icon: const Icon(Icons.download_rounded,
                color: Colors.white, size: 18),
            label: Text(
              'EXPORTAR',
              style: AppTextStyles.buttonPrimary.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats overview ─────────────────────────────────────────────────────────

class _StatsOverview extends StatelessWidget {
  final AsyncValue<QuerySnapshot<Map<String, dynamic>>> logsAsync;
  final AsyncValue<QuerySnapshot<Map<String, dynamic>>> visitorsAsync;

  const _StatsOverview({
    required this.logsAsync,
    required this.visitorsAsync,
  });

  @override
  Widget build(BuildContext context) {
    int entries = 0;
    int exits = 0;
    int denied = 0;

    logsAsync.whenData((snap) {
      for (final doc in snap.docs) {
        final d = doc.data();
        final type = (d['event_type'] as String? ?? '').toLowerCase();
        final result = (d['access_result'] as String? ?? '').toLowerCase();
        if (type.contains('ingreso') || type.contains('entrada')) entries++;
        if (type.contains('salida') || type.contains('egreso')) exits++;
        if (result == 'denied') denied++;
      }
    });

    final visitorsInside =
        visitorsAsync.valueOrNull?.docs.length ?? 0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.5,
      children: [
        StatCard(
          label: 'Entradas Hoy',
          value: entries.toString(),
          icon: Icons.login_rounded,
          color: AppColors.statusGranted,
        ),
        StatCard(
          label: 'Salidas Hoy',
          value: exits.toString(),
          icon: Icons.logout_rounded,
          color: AppColors.statusDenied,
        ),
        StatCard(
          label: 'Visitantes Dentro',
          value: visitorsInside.toString(),
          icon: Icons.badge_rounded,
          color: AppColors.statusPending,
        ),
        StatCard(
          label: 'Alertas Enviadas',
          value: denied.toString(),
          icon: Icons.notifications_active_rounded,
          color: AppColors.alertRed,
        ),
      ],
    );
  }
}

// ── Activity bar chart ─────────────────────────────────────────────────────

/// A simple 24-bucket (by-hour) bar chart built entirely with
/// [Container] widgets — no external chart library required.
class _ActivityBarChart extends StatelessWidget {
  final AsyncValue<QuerySnapshot<Map<String, dynamic>>> logsAsync;

  const _ActivityBarChart({required this.logsAsync});

  @override
  Widget build(BuildContext context) {
    // Build 24-bucket count map
    final counts = List<int>.filled(24, 0);

    logsAsync.whenData((snap) {
      for (final doc in snap.docs) {
        final ts = (doc.data()['timestamp'] as Timestamp?)?.toDate();
        if (ts != null) counts[ts.hour]++;
      }
    });

    final maxCount = counts.reduce((a, b) => a > b ? a : b);
    final effective = maxCount == 0 ? 1 : maxCount;

    // Only show every 3rd hour label to avoid crowding
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          // Bars
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(24, (hour) {
                final count = counts[hour];
                final ratio = count / effective;
                final isCurrentHour =
                    DateTime.now().hour == hour;
                final barColor = isCurrentHour
                    ? AppColors.accent
                    : AppColors.primary;

                return Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 1),
                    child: Tooltip(
                      message: '${hour.toString().padLeft(2, '0')}h: $count eventos',
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (count > 0)
                            Text(
                              count.toString(),
                              style: AppTextStyles.labelSmall.copyWith(
                                fontSize: 7,
                                color: barColor.withOpacity(0.8),
                              ),
                            ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutCubic,
                            height: (ratio * 80).clamp(2.0, 80.0),
                            decoration: BoxDecoration(
                              color: barColor.withOpacity(
                                  isCurrentHour ? 1.0 : 0.6),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(3)),
                              boxShadow: isCurrentHour
                                  ? [
                                      BoxShadow(
                                        color: AppColors.accentGlow,
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 6),

          // Hour labels (every 3 hours)
          Row(
            children: List.generate(24, (hour) {
              final showLabel = hour % 3 == 0;
              return Expanded(
                child: Text(
                  showLabel ? '${hour.toString().padLeft(2, '0')}' : '',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontSize: 8,
                    color: AppColors.textMuted,
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 12),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ChartLegendDot(
                  color: AppColors.primary, label: 'Eventos'),
              const SizedBox(width: 16),
              _ChartLegendDot(
                  color: AppColors.accent, label: 'Hora actual'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartLegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

// ── Export dialog option row ───────────────────────────────────────────────

class _ExportOption extends StatelessWidget {
  final String label;
  final IconData icon;

  const _ExportOption({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textMuted, size: 16),
        ],
      ),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;

  const _SectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: color,
            letterSpacing: 2.5,
          ),
        ),
      ],
    );
  }
}

class _ControlErrorBanner extends StatelessWidget {
  final String message;
  const _ControlErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.alertRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.alertRed.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.alertRed, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.alertRed),
            ),
          ),
        ],
      ),
    );
  }
}
