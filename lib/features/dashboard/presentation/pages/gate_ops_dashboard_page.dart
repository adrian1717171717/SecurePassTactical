// lib/features/dashboard/presentation/pages/gate_ops_dashboard_page.dart
import 'dart:async';
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
import '../widgets/access_log_tile.dart';
import '../widgets/tactical_app_bar.dart';

// ── Providers ──────────────────────────────────────────────────────────────

/// Streams the latest 10 access-log entries for the gate compact list.
final _gateLogsStreamProvider =
    StreamProvider<QuerySnapshot<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('access_logs')
      .orderBy('timestamp', descending: true)
      .limit(10)
      .snapshots();
});

// ── Page ───────────────────────────────────────────────────────────────────

/// Operational dashboard for Brigadier, Subbrigadier, and Cadete de Guardia.
///
/// Designed to be used all day at the gate. Provides one-tap scan buttons,
/// a compact activity feed, and a "DAR PARTE" alert bottom sheet.
class GateOpsDashboardPage extends ConsumerStatefulWidget {
  const GateOpsDashboardPage({super.key});

  @override
  ConsumerState<GateOpsDashboardPage> createState() =>
      _GateOpsDashboardPageState();
}

class _GateOpsDashboardPageState extends ConsumerState<GateOpsDashboardPage> {
  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  // Simulated shift ID — in production this would come from a Firestore stream.
  static const String _currentShiftId = 'GRD-2026-001';

  @override
  void initState() {
    super.initState();
    // Update the clock every second
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  // ── Alert types for "Dar Parte" bottom sheet ───────────────────────────

  static const List<_AlertType> _alertTypes = [
    _AlertType(
      label: 'Intrusión detectada',
      icon: Icons.person_off_rounded,
      color: AppColors.alertRed,
    ),
    _AlertType(
      label: 'Vehículo sospechoso',
      icon: Icons.directions_car_filled_rounded,
      color: AppColors.statusDenied,
    ),
    _AlertType(
      label: 'Visitante sin autorización',
      icon: Icons.badge_outlined,
      color: AppColors.statusPending,
    ),
    _AlertType(
      label: 'Emergencia médica',
      icon: Icons.local_hospital_rounded,
      color: AppColors.alertAmber,
    ),
    _AlertType(
      label: 'Otra situación',
      icon: Icons.report_rounded,
      color: AppColors.textSecondary,
    ),
  ];

  void _showDarParteSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppColors.surfaceBorder),
      ),
      builder: (_) => _DarParteBottomSheet(alertTypes: _alertTypes),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final logsAsync = ref.watch(_gateLogsStreamProvider);
    final timeStr = DateFormat('HH:mm:ss').format(_now);
    final dateStr = DateFormat('EEE d MMM', 'es').format(_now);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: TacticalAppBar(
        title: 'GARITA PRINCIPAL',
        subtitle: 'PUESTO DE CONTROL',
        actions: [
          // Quick My QR access (Hidden for Kiosk accounts)
          if (userAsync.valueOrNull?.email != 'prevencion@securpass.mil')
            IconButton(
              onPressed: () => context.push(RouteNames.myQr),
              icon: const Icon(
                Icons.qr_code_rounded,
                color: AppColors.primaryLight,
                size: 20,
              ),
              tooltip: 'Mi Identidad / QR',
            ),
          const SizedBox(width: 6),
          // Wifi / connectivity indicator
          _ConnectivityBadge(),
          const SizedBox(width: 4),
          // Shift ID badge
          Container(
            margin: const EdgeInsets.only(right: 4),
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accentGlow,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppColors.accent.withOpacity(0.4),
              ),
            ),
            child: Text(
              _currentShiftId,
              style: AppTextStyles.mono.copyWith(
                fontSize: 10,
                color: AppColors.accent,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showDarParteSheet,
        backgroundColor: AppColors.alertRed,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.warning_amber_rounded),
        label: Text(
          'DAR PARTE',
          style: AppTextStyles.buttonPrimary.copyWith(fontSize: 13),
        ),
      ).animate().fadeIn(delay: 500.ms).scale(
          begin: const Offset(0.7, 0.7), duration: 350.ms),
      body: CustomScrollView(
        slivers: [
          // ── Clock header ─────────────────────────────────
          SliverToBoxAdapter(
            child: _ClockHeader(
              timeStr: timeStr,
              dateStr: dateStr,
              userAsync: userAsync,
            ).animate().fadeIn(duration: 400.ms),
          ),

          // ── Main action buttons ───────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Column(
                children: [
                  // ── ESCANEAR INGRESO ──────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 72,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push(RouteNames.scanner),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.statusGranted,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 6,
                        shadowColor:
                            AppColors.statusGranted.withOpacity(0.5),
                      ),
                      icon: const Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 30),
                      label: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ESCANEAR INGRESO',
                            style: AppTextStyles.buttonPrimary.copyWith(
                              fontSize: 18,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            'Registrar entrada al perímetro',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 100.ms, duration: 400.ms)
                      .slideX(begin: -0.05, end: 0),

                  const SizedBox(height: 12),

                  // ── ESCANEAR SALIDA ───────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 72,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push(
                        '${RouteNames.scanner}?mode=exit',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.statusDenied,
                        side: const BorderSide(
                          color: AppColors.statusDenied,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(
                          Icons.exit_to_app_rounded,
                          size: 30),
                      label: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ESCANEAR SALIDA',
                            style: AppTextStyles.buttonPrimary.copyWith(
                              fontSize: 18,
                              color: AppColors.statusDenied,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            'Registrar salida del perímetro',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.statusDenied.withOpacity(0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 400.ms)
                      .slideX(begin: 0.05, end: 0),
                ],
              ),
            ),
          ),

          // ── Recent activity header ────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ÚLTIMOS ACCESOS',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms),
          ),

          // ── Access log compact list ───────────────────────
          logsAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: _GateErrorBanner(message: e.toString()),
              ),
            ),
            data: (snapshot) {
              final docs = snapshot.docs;
              if (docs.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.inbox_outlined,
                              size: 36,
                              color: AppColors.textMuted.withOpacity(0.5)),
                          const SizedBox(height: 8),
                          Text('Sin accesos registrados',
                              style: AppTextStyles.bodyMedium),
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
                    eventType: data['event_type'] as String? ?? 'Evento',
                    timestamp: ts,
                    accessResult:
                        data['access_result'] as String? ?? 'pending',
                    vehiclePlate: data['vehicle_plate'] as String?,
                  )
                      .animate(delay: (index * 30).ms)
                      .fadeIn(duration: 250.ms);
                },
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// ── Clock header widget ────────────────────────────────────────────────────

class _ClockHeader extends StatelessWidget {
  final String timeStr;
  final String dateStr;
  final AsyncValue<dynamic> userAsync;

  const _ClockHeader({
    required this.timeStr,
    required this.dateStr,
    required this.userAsync,
  });

  @override
  Widget build(BuildContext context) {
    final userName = userAsync.valueOrNull?.displayName ?? '—';
    final rank = userAsync.valueOrNull?.rank ?? '—';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          // Clock
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeStr,
                  style: AppTextStyles.monoLarge.copyWith(
                    color: AppColors.accent,
                    fontSize: 28,
                  ),
                ),
                Text(
                  dateStr.toUpperCase(),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textMuted,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Container(
            width: 1,
            height: 40,
            color: AppColors.surfaceBorder,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          // Operator info
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                userName,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
              ),
              Text(
                rank.toUpperCase(),
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Connectivity badge ─────────────────────────────────────────────────────

class _ConnectivityBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // In production, watch a connectivity provider here.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.statusGranted.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border:
            Border.all(color: AppColors.statusGranted.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_rounded,
              color: AppColors.statusGranted, size: 12),
          const SizedBox(width: 4),
          Text(
            'EN LÍNEA',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.statusGranted,
              fontSize: 9,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dar Parte bottom sheet ─────────────────────────────────────────────────

class _AlertType {
  final String label;
  final IconData icon;
  final Color color;

  const _AlertType({
    required this.label,
    required this.icon,
    required this.color,
  });
}

class _DarParteBottomSheet extends StatelessWidget {
  final List<_AlertType> alertTypes;

  const _DarParteBottomSheet({required this.alertTypes});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.alertRed.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: AppColors.alertRed, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DAR PARTE',
                    style: AppTextStyles.headlineSmall.copyWith(
                      letterSpacing: 2,
                      color: AppColors.alertRed,
                    ),
                  ),
                  Text(
                    'Seleccione el tipo de novedad',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Alert type list
          ...alertTypes.map(
            (type) => _AlertTypeTile(
              alertType: type,
              onTap: () {
                Navigator.of(context).pop();
                // In production: fire alert to Firestore + FCM
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(type.icon, color: type.color, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          'Parte enviado: ${type.label}',
                          style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    backgroundColor: AppColors.surfaceElevated,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                          color: type.color.withOpacity(0.5)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertTypeTile extends StatelessWidget {
  final _AlertType alertType;
  final VoidCallback onTap;

  const _AlertTypeTile({required this.alertType, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: alertType.color.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(alertType.icon, color: alertType.color, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    alertType.label,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: alertType.color.withOpacity(0.6), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Gate error banner ──────────────────────────────────────────────────────

class _GateErrorBanner extends StatelessWidget {
  final String message;
  const _GateErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.alertRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.alertRed.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.alertRed, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.alertRed)),
          ),
        ],
      ),
    );
  }
}
