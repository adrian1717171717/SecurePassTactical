// lib/features/dashboard/presentation/pages/guard_officer_dashboard_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';
import '../../../../routing/route_names.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/stat_card.dart';
import '../widgets/access_log_tile.dart';
import '../widgets/tactical_app_bar.dart';

// ── Providers ──────────────────────────────────────────────────────────────

/// Streams all access logs for the current shift (most recent first, limit 30).
final _officerLogsStreamProvider =
    StreamProvider<QuerySnapshot<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('access_logs')
      .orderBy('timestamp', descending: true)
      .limit(30)
      .snapshots();
});

/// Streams visitors currently marked as still inside the perimeter.
final _visitorsInsideProvider =
    StreamProvider<QuerySnapshot<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('visitors')
      .where('status', isEqualTo: 'inside')
      .snapshots();
});

/// Streams all bitacora entries for the current shift (most recent first, limit 30).
final _bitacoraStreamProvider =
    StreamProvider<QuerySnapshot<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('novedades_bitacora')
      .orderBy('timestamp', descending: true)
      .limit(30)
      .snapshots();
});

// ── Page ───────────────────────────────────────────────────────────────────

/// Master-control dashboard for the Oficial de Guardia role.
///
/// Shows a shift summary card, live access-log feed, pending visitors list,
/// and bottom action buttons for reports, handoff, and shift closure.
class GuardOfficerDashboardPage extends ConsumerWidget {
  const GuardOfficerDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final logsAsync = ref.watch(_officerLogsStreamProvider);
    final visitorsAsync = ref.watch(_visitorsInsideProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: TacticalAppBar(
        title: 'PANEL OFICIAL DE GUARDIA',
        subtitle: userAsync.valueOrNull?.displayName ?? '—',
        actions: [
          // Quick My QR access
          IconButton(
            onPressed: () => context.push(RouteNames.myQr),
            icon: const Icon(
              Icons.qr_code_rounded,
              color: AppColors.primaryLight,
              size: 22,
            ),
            tooltip: 'Mi Identidad / QR',
          ),
          const SizedBox(width: 8),
          // Quick Scanner access for testing
          IconButton(
            onPressed: () => context.push(RouteNames.scanner),
            icon: const Icon(
              Icons.qr_code_scanner_rounded,
              color: AppColors.primary,
              size: 22,
            ),
            tooltip: 'Probar Escáner',
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () async {
              final signOut = ref.read(signOutProvider);
              await signOut();
              if (context.mounted) context.go(RouteNames.login);
            },
            icon: const Icon(
              Icons.logout_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Scrollable content ─────────────────────────────
          Expanded(
            child: CustomScrollView(
              slivers: [
                // ── Shift summary card ──────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: _ShiftSummaryCard(logsAsync: logsAsync)
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: -0.05, end: 0),
                  ),
                ),

                // ── Libro de Imaginaria Digital ──────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: _ImaginariaCard(
                      bitacoraAsync: ref.watch(_bitacoraStreamProvider),
                      user: userAsync.valueOrNull,
                      shiftId: 'GRD-${DateFormat('yyyyMMdd').format(DateTime.now())}-001',
                    ).animate().fadeIn(duration: 400.ms),
                  ),
                ),

                // ── Próximamente: Parte de Compañías ─────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1524),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.statusPending.withOpacity(0.35)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.statusPending.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.people_alt_rounded,
                              color: AppColors.statusPending,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'PARTE DE COMPAÑÍAS',
                                      style: AppTextStyles.labelMedium.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.statusPending.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: AppColors.statusPending.withOpacity(0.4), width: 0.5),
                                      ),
                                      child: Text(
                                        'EN COLA',
                                        style: AppTextStyles.labelSmall.copyWith(
                                          color: AppColors.statusPending,
                                          fontSize: 8,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Módulo para Oficiales de Semana: Formación diaria, control de francos, castigados, policlínicos y personal de guardia por curso y compañía.',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 100.ms),
                  ),
                ),

                // ── Pending visitors warning ────────────────
                visitorsAsync.when(
                  loading: () => const SliverToBoxAdapter(
                    child: SizedBox.shrink(),
                  ),
                  error: (_, __) => const SliverToBoxAdapter(
                    child: SizedBox.shrink(),
                  ),
                  data: (snap) {
                    if (snap.docs.isEmpty) {
                      return const SliverToBoxAdapter(
                          child: SizedBox.shrink());
                    }
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 4, 16, 4),
                        child: _PendingVisitorsCard(docs: snap.docs)
                            .animate()
                            .fadeIn(delay: 150.ms, duration: 400.ms),
                      ),
                    );
                  },
                ),

                // ── Live feed header ────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                    child: Row(
                      children: [
                        Container(
                          width: 3,
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'REGISTRO DE ACCESOS',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.textSecondary,
                            letterSpacing: 2,
                          ),
                        ),
                        const Spacer(),
                        _OfficerLiveDot(),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                ),

                // ── Access log ──────────────────────────────
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
                      child: _OfficerErrorBanner(message: e.toString()),
                    ),
                  ),
                  data: (snapshot) {
                    final docs = snapshot.docs;
                    if (docs.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.assignment_outlined,
                                  size: 48,
                                  color:
                                      AppColors.textMuted.withOpacity(0.4),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Sin registros en esta guardia',
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
                            (data['timestamp'] as Timestamp?)
                                    ?.toDate() ??
                                DateTime.now();
                        return AccessLogTile(
                          personName: data['person_name'] as String? ??
                              'Desconocido',
                          rank: data['rank'] as String? ?? '—',
                          eventType:
                              data['event_type'] as String? ?? 'Evento',
                          timestamp: ts,
                          accessResult:
                              data['access_result'] as String? ??
                                  'pending',
                          vehiclePlate:
                              data['vehicle_plate'] as String?,
                        )
                            .animate(delay: (index * 30).ms)
                            .fadeIn(duration: 250.ms);
                      },
                    );
                  },
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
          ),

          // ── Bottom action row ──────────────────────────────
          _BottomActionRow(
            onReports: () => context.push(RouteNames.shiftReport),
            onHandoff: () => context.push(RouteNames.shiftHandoff),
            onClose: () => _showCloseShiftDialog(context, ref),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
        ],
      ),
    );
  }

  void _showCloseShiftDialog(BuildContext context, WidgetRef ref) {
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
            const Icon(Icons.lock_rounded,
                color: AppColors.statusPending, size: 22),
            const SizedBox(width: 10),
            Text(
              'CERRAR GUARDIA',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.statusPending,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        content: Text(
          '¿Confirmar cierre de guardia y generación del parte en PDF?\n\n'
          'Esta acción no se puede deshacer.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar',
                style: AppTextStyles.buttonSecondary),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push(RouteNames.shiftSummary);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusPending,
            ),
            child: Text(
              'CERRAR & GENERAR PDF',
              style: AppTextStyles.buttonPrimary.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shift summary card ─────────────────────────────────────────────────────

class _ShiftSummaryCard extends StatelessWidget {
  final AsyncValue<QuerySnapshot<Map<String, dynamic>>> logsAsync;

  const _ShiftSummaryCard({required this.logsAsync});

  @override
  Widget build(BuildContext context) {
    // Derive stats from the stream
    int entries = 0;
    int exits = 0;
    DateTime? startTime;

    logsAsync.whenData((snap) {
      for (final doc in snap.docs) {
        final d = doc.data();
        final type = (d['event_type'] as String? ?? '').toLowerCase();
        if (type.contains('ingreso') || type.contains('entrada')) entries++;
        if (type.contains('salida') || type.contains('egreso')) exits++;
        final ts = (d['timestamp'] as Timestamp?)?.toDate();
        if (ts != null && (startTime == null || ts.isBefore(startTime!))) {
          startTime = ts;
        }
      }
    });

    final startStr = startTime != null
        ? DateFormat('HH:mm').format(startTime!)
        : '--:--';
    final shiftId = 'GRD-${DateFormat('yyyyMMdd').format(DateTime.now())}-001';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF111827), Color(0xFF162035)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGlow,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.4)),
                ),
                child: Text(
                  shiftId,
                  style: AppTextStyles.mono.copyWith(
                    fontSize: 11,
                    color: AppColors.primaryLight,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'INICIO ${startStr}h',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textMuted,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Stats row
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Entradas',
                  value: entries.toString(),
                  icon: Icons.login_rounded,
                  color: AppColors.statusGranted,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  label: 'Salidas',
                  value: exits.toString(),
                  icon: Icons.logout_rounded,
                  color: AppColors.statusDenied,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  label: 'Total Eventos',
                  value:
                      (entries + exits).toString(),
                  icon: Icons.swap_vert_rounded,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Pending visitors card ──────────────────────────────────────────────────

class _PendingVisitorsCard extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  const _PendingVisitorsCard({required this.docs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.statusPending.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.statusPending.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.statusPending, size: 18),
              const SizedBox(width: 8),
              Text(
                'VISITANTES PENDIENTES DE SALIDA (${docs.length})',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.statusPending,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...docs.take(5).map(
                (doc) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _PendingVisitorRow(data: doc.data()),
                ),
              ),
          if (docs.length > 5)
            Text(
              '+ ${docs.length - 5} más…',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.statusPending.withOpacity(0.7),
              ),
            ),
        ],
      ),
    );
  }
}

class _PendingVisitorRow extends StatelessWidget {
  final Map<String, dynamic> data;

  const _PendingVisitorRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final name = data['full_name'] as String? ?? 'Desconocido';
    final entryTs = (data['entry_timestamp'] as Timestamp?)?.toDate();
    final entryStr = entryTs != null
        ? 'Ingresó: ${DateFormat('HH:mm').format(entryTs)}'
        : '';

    return Row(
      children: [
        const Icon(Icons.person_outline_rounded,
            color: AppColors.statusPending, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            name,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        if (entryStr.isNotEmpty)
          Text(
            entryStr,
            style: AppTextStyles.mono.copyWith(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
      ],
    );
  }
}

// ── Bottom action row ──────────────────────────────────────────────────────

class _BottomActionRow extends StatelessWidget {
  final VoidCallback onReports;
  final VoidCallback onHandoff;
  final VoidCallback onClose;

  const _BottomActionRow({
    required this.onReports,
    required this.onHandoff,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.surfaceBorder),
        ),
      ),
      child: Row(
        children: [
          // VER REPORTES
          Expanded(
            child: _ActionButton(
              label: 'VER REPORTES',
              icon: Icons.bar_chart_rounded,
              color: AppColors.primary,
              onTap: onReports,
            ),
          ),
          const SizedBox(width: 8),
          // ENTREGAR GUARDIA
          Expanded(
            child: _ActionButton(
              label: 'ENTREGAR GUARDIA',
              icon: Icons.swap_horizontal_circle_rounded,
              color: AppColors.accent,
              onTap: onHandoff,
            ),
          ),
          const SizedBox(width: 8),
          // CERRAR GUARDIA & PDF
          Expanded(
            child: _ActionButton(
              label: 'CERRAR & PDF',
              icon: Icons.picture_as_pdf_rounded,
              color: AppColors.statusPending,
              onTap: onClose,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.35)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 5),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelSmall.copyWith(
                  color: color,
                  fontSize: 9,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────

class _OfficerLiveDot extends StatefulWidget {
  @override
  State<_OfficerLiveDot> createState() => _OfficerLiveDotState();
}

class _OfficerLiveDotState extends State<_OfficerLiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FadeTransition(
          opacity: _ctrl,
          child: Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          'EN VIVO',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.accent,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _OfficerErrorBanner extends StatelessWidget {
  final String message;
  const _OfficerErrorBanner({required this.message});

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

// ── Libro de Imaginaria Widgets ─────────────────────────────────────────────

class _ImaginariaCard extends ConsumerWidget {
  final AsyncValue<QuerySnapshot<Map<String, dynamic>>> bitacoraAsync;
  final dynamic user;
  final String shiftId;

  const _ImaginariaCard({
    required this.bitacoraAsync,
    required this.user,
    required this.shiftId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return bitacoraAsync.when(
      loading: () => Container(
        height: 100,
        decoration: const BoxDecoration(
          color: AppColors.surface,
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.alertRed.withOpacity(0.4)),
        ),
        child: Text('Error al cargar bitácora: $e', style: AppTextStyles.bodySmall.copyWith(color: AppColors.alertRed)),
      ),
      data: (snap) {
        final docs = snap.docs;
        DateTime? lastReportTime;
        if (docs.isNotEmpty) {
          final ts = docs.first.data()['timestamp'] as Timestamp?;
          lastReportTime = ts?.toDate();
        }

        final int minutesSinceLastReport = lastReportTime != null
            ? DateTime.now().difference(lastReportTime).inMinutes
            : 999;
        final bool isOverdue = minutesSinceLastReport >= 60;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isOverdue 
                  ? AppColors.alertRed.withOpacity(0.6) 
                  : AppColors.surfaceBorder,
              width: isOverdue ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabecera
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isOverdue 
                          ? AppColors.alertRed.withOpacity(0.12)
                          : AppColors.primaryGlow,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.book_rounded,
                      color: isOverdue ? AppColors.alertRed : AppColors.primaryLight,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LIBRO DE IMAGINARIA DIGITAL',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lastReportTime != null 
                              ? 'Último reporte hace $minutesSinceLastReport min'
                              : 'Sin reportes cargados hoy',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  // Indicador de Alerta
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOverdue 
                          ? AppColors.alertRed.withOpacity(0.15)
                          : AppColors.statusGranted.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isOverdue 
                            ? AppColors.alertRed.withOpacity(0.4)
                            : AppColors.statusGranted.withOpacity(0.4),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isOverdue ? Icons.warning_amber_rounded : Icons.verified_user_rounded,
                          color: isOverdue ? AppColors.alertRed : AppColors.statusGranted,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isOverdue ? 'REPORTE PENDIENTE' : 'SERVICIO AL DÍA',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isOverdue ? AppColors.alertRed : AppColors.statusGranted,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate(onPlay: (c) => isOverdue ? c.repeat() : c.stop())
                      .shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.1)),
                ],
              ),
              const SizedBox(height: 16),

              // Botones Rápidos de Registro
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                      label: const Text('SIN NOVEDAD'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.statusGranted,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _registerSinNovedad(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit_note_rounded, size: 16, color: AppColors.primaryLight),
                      label: const Text('REGISTRAR NOVEDAD'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _showNewNovedadSheet(context),
                    ),
                  ),
                ],
              ),

              if (docs.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(color: AppColors.surfaceBorder, height: 1),
                const SizedBox(height: 10),
                Text(
                  'ÚLTIMAS NOVEDADES REGISTRADAS',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textMuted,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                ...docs.take(3).map((d) {
                  final data = d.data();
                  final ts = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                  final timeStr = DateFormat('HH:mm').format(ts);
                  final desc = data['description'] as String? ?? '';
                  final isNov = data['is_novedad'] as bool? ?? false;
                  final author = data['author_name'] as String? ?? '—';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '[$timeStr]',
                          style: AppTextStyles.mono.copyWith(
                            color: isNov ? AppColors.alertRed : AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            desc,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isNov ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          author.split(' ').last,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _registerSinNovedad(BuildContext context) async {
    final senderName = user != null ? user.displayName : 'Oficial de Guardia';
    final senderRank = user != null ? user.rank : '—';
    final senderUid = user != null ? user.uid : '—';

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registrando reporte sin novedad...')),
    );

    try {
      await FirebaseFirestore.instance.collection('novedades_bitacora').add({
        'shift_id': shiftId,
        'timestamp': FieldValue.serverTimestamp(),
        'time_label': DateFormat('HH:mm').format(DateTime.now()),
        'is_novedad': false,
        'description': 'A la hora, el servicio de guardia se mantiene sin novedad en prevención y garitas.',
        'author_uid': senderUid,
        'author_name': senderName,
        'author_rank': senderRank,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Reporte registrado con éxito'),
            backgroundColor: AppColors.statusGranted,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrar novedad: $e')),
        );
      }
    }
  }

  void _showNewNovedadSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _NewNovedadSheet(shiftId: shiftId, user: user),
    );
  }
}

class _NewNovedadSheet extends StatefulWidget {
  final String shiftId;
  final dynamic user;
  const _NewNovedadSheet({required this.shiftId, required this.user});

  @override
  State<_NewNovedadSheet> createState() => _NewNovedadSheetState();
}

class _NewNovedadSheetState extends State<_NewNovedadSheet> {
  final _ctrl = TextEditingController();
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGlow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit_note_rounded, color: AppColors.primaryLight, size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('REGISTRAR NOVEDAD', style: AppTextStyles.headlineSmall),
                  Text('Libro de Imaginaria de Guardia', style: AppTextStyles.bodySmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _ctrl,
            maxLines: 4,
            style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Descripción del suceso o novedad',
              alignLabelWithHint: true,
              hintText: 'Ej. Recepción de encomienda destinada al Director...',
            ),
            autofocus: true,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveNovedad,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('REGISTRAR EN BITÁCORA'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveNovedad() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escriba el suceso o novedad')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final senderName = widget.user != null ? widget.user.displayName : 'Oficial de Guardia';
      final senderRank = widget.user != null ? widget.user.rank : '—';
      final senderUid = widget.user != null ? widget.user.uid : '—';

      await FirebaseFirestore.instance.collection('novedades_bitacora').add({
        'shift_id': widget.shiftId,
        'timestamp': FieldValue.serverTimestamp(),
        'time_label': DateFormat('HH:mm').format(DateTime.now()),
        'is_novedad': true,
        'description': text,
        'author_uid': senderUid,
        'author_name': senderName,
        'author_rank': senderRank,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Novedad registrada con éxito'),
            backgroundColor: AppColors.statusGranted,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrar novedad: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
