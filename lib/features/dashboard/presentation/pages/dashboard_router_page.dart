import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';
import '../../../../routing/route_names.dart';
import '../../../auth/domain/entities/role_permissions.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../qr_identity/presentation/pages/my_qr_page.dart';
import 'admin_dashboard_page.dart';
import 'control_chief_dashboard_page.dart';
import 'guard_officer_dashboard_page.dart';
import 'gate_ops_dashboard_page.dart';

/// Enruta al dashboard correcto según el rol actual del usuario.
/// Escucha cambios de rol en tiempo real vía Riverpod stream.
class DashboardRouterPage extends ConsumerWidget {
  const DashboardRouterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const _LoadingScaffold(),
      error: (e, _) => _ErrorScaffold(message: e.toString()),
      data: (user) {
        if (user == null) return const _LoadingScaffold();

        final child = switch (user.currentRole.dashboardType) {
          DashboardType.admin => const AdminDashboardPage(),
          DashboardType.controlChief => const ControlChiefDashboardPage(),
          DashboardType.guardOfficer => const GuardOfficerDashboardPage(),
          DashboardType.gateOps => const GateOpsDashboardPage(),
          DashboardType.preventionDevice => const GateOpsDashboardPage(),
          DashboardType.baseUser => const MyQrPage(),
          DashboardType.unassigned => _PendingApprovalPage(
              displayName: user.displayName,
              rank: user.rank,
            ),
        };

        return _EmergencyAlertWrapper(child: child);
      },
    );
  }
}

// ── Loading ──────────────────────────────────────────────────

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield_rounded, color: AppColors.primary, size: 48),
            const SizedBox(height: 16),
            Text('SECURPASS TACTICAL', style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.primary,
              letterSpacing: 3,
            )),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

// ── Error ────────────────────────────────────────────────────

class _ErrorScaffold extends StatelessWidget {
  final String message;
  const _ErrorScaffold({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.alertRed, size: 48),
            const SizedBox(height: 16),
            Text('Error de conexión', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(message, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pending Approval (replaces the old role simulator) ────────

class _PendingApprovalPage extends ConsumerWidget {
  final String displayName;
  final String rank;
  const _PendingApprovalPage({required this.displayName, required this.rank});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shield_outlined, color: AppColors.primary, size: 64)
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .scale(begin: const Offset(0.8, 0.8)),
                const SizedBox(height: 16),
                Text(
                  'SECURPASS TACTICAL',
                  style: AppTextStyles.headlineSmall.copyWith(
                    letterSpacing: 3,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'CUENTA REGISTRADA',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.statusPending,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.hourglass_top_rounded,
                          color: AppColors.statusPending, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        displayName,
                        style: AppTextStyles.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      if (rank.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(rank, style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        )),
                      ],
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.statusPending.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.statusPending.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'PENDIENTE DE ASIGNACIÓN',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.statusPending,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Su cuenta ha sido creada correctamente. '
                              'Un administrador debe asignarle un rol operativo '
                              'para acceder al sistema. Comuníquese con el '
                              'Director o Subdirector de la institución.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // QR button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push(RouteNames.myQr),
                    icon: const Icon(Icons.qr_code_2_rounded, size: 22),
                    label: Text(
                      'VER MI CÓDIGO QR',
                      style: AppTextStyles.buttonPrimary.copyWith(
                        color: Colors.white,
                        letterSpacing: 1.5,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => ref.read(signOutProvider)(context),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('CERRAR SESIÓN'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.surfaceBorder),
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

// ── Emergency Alert Overlay ──────────────────────────────────

class _EmergencyAlertWrapper extends StatefulWidget {
  final Widget child;
  const _EmergencyAlertWrapper({required this.child});

  @override
  State<_EmergencyAlertWrapper> createState() => _EmergencyAlertWrapperState();
}

class _EmergencyAlertWrapperState extends State<_EmergencyAlertWrapper> {
  final Set<String> _acknowledgedAlerts = {};

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('alerts')
              .orderBy('timestamp', descending: true)
              .limit(1)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const SizedBox.shrink();
            }

            final doc = snapshot.data!.docs.first;
            final data = doc.data();
            final alertId = doc.id;

            final isEmergency = data['is_emergency'] as bool? ?? false;
            if (!isEmergency || _acknowledgedAlerts.contains(alertId)) {
              return const SizedBox.shrink();
            }

            final ts = (data['timestamp'] as Timestamp?)?.toDate();
            if (ts == null) return const SizedBox.shrink();

            // Solo mostrar alertas creadas en los últimos 10 minutos
            final diff = DateTime.now().difference(ts);
            if (diff.inMinutes > 10) {
              return const SizedBox.shrink();
            }

            final isSafarancho = data['type'] == 'safarancho';
            final title = isSafarancho ? '¡SAFARANCHO GENERAL!' : '¡INCIDENTE DE SEGURIDAD!';
            final sender = data['sender'] ?? 'Comando de Guardia';
            final message = data['message'] ?? '';

            return _EmergencyOverlay(
              title: title,
              sender: sender,
              message: message,
              onAcknowledge: () {
                setState(() {
                  _acknowledgedAlerts.add(alertId);
                });
              },
            );
          },
        ),
      ],
    );
  }
}

class _EmergencyOverlay extends StatefulWidget {
  final String title;
  final String sender;
  final String message;
  final VoidCallback onAcknowledge;

  const _EmergencyOverlay({
    required this.title,
    required this.sender,
    required this.message,
    required this.onAcknowledge,
  });

  @override
  State<_EmergencyOverlay> createState() => _EmergencyOverlayState();
}

class _EmergencyOverlayState extends State<_EmergencyOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _glowCtrl,
        builder: (context, child) {
          return Container(
            color: Colors.black.withOpacity(0.92),
            padding: const EdgeInsets.all(24),
            child: child!,
          );
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF140808),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.alertRed.withOpacity(0.8),
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.alertRed.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.alertRed.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.alertRed.withOpacity(0.3)),
                    ),
                    child: const Icon(
                      Icons.campaign_rounded,
                      color: AppColors.alertRed,
                      size: 54,
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 600.ms),
                  const SizedBox(height: 20),

                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.alertRed,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    widget.sender.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textMuted,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.surfaceBorder, height: 1),
                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: widget.onAcknowledge,
                      icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                      label: Text(
                        '¡ENTENDIDO / ENTERADO!',
                        style: AppTextStyles.buttonPrimary.copyWith(
                          letterSpacing: 1.5,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.alertRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 4,
                        shadowColor: AppColors.alertRed.withOpacity(0.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
