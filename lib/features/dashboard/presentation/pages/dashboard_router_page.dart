import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';
import '../../../../routing/route_names.dart';
import '../../../auth/domain/entities/app_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../qr_identity/presentation/pages/my_qr_page.dart';
import 'admin_dashboard_page.dart';
import 'control_chief_dashboard_page.dart';
import 'guard_officer_dashboard_page.dart';
import 'gate_ops_dashboard_page.dart';

/// Enruta al dashboard correcto según el rol actual del usuario.
/// Este widget escucha cambios de rol en tiempo real (Riverpod stream).
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

        final child = switch (user.currentRole) {
          AppRole.director ||
          AppRole.subDirector ||
          AppRole.schoolChief =>
            const AdminDashboardPage(),
          AppRole.controlChief => const ControlChiefDashboardPage(),
          AppRole.guardOfficer => const GuardOfficerDashboardPage(),
          AppRole.guardBrigadier ||
          AppRole.guardSubBrigadier ||
          AppRole.guardCadet =>
            const GateOpsDashboardPage(),
          _ => const MyQrPage(),
        };

        return _EmergencyAlertWrapper(child: child);
      },
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  final String message;
  const _ErrorScaffold({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Error de conexión', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(message, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _UnknownRolePage extends ConsumerStatefulWidget {
  final String uid;
  const _UnknownRolePage({required this.uid});

  @override
  ConsumerState<_UnknownRolePage> createState() => _UnknownRolePageState();
}

class _UnknownRolePageState extends ConsumerState<_UnknownRolePage> {
  bool _isUpdating = false;

  Future<void> _assignRole(AppRole role, String name, String rank, String unit) async {
    setState(() => _isUpdating = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).update({
        'current_role': role.toFirestoreString(),
        'base_role': role.toFirestoreString(),
        'display_name': name,
        'rank': rank,
        'unit': unit,
        'updated_at': Timestamp.now(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al asignar rol: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF050810), Color(0xFF0A0E14), Color(0xFF0D1520)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
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
                    'PERFIL CREADO — SIN ROL ASIGNADO',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.statusPending,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Su cuenta se ha creado en el sistema. Para realizar pruebas e interactuar con los diferentes paneles del módulo táctico, elija un rol institucional para auto-asignarse un perfil de prueba:',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 32),
                  if (_isUpdating)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 2.2,
                      children: [
                        _buildDevRoleCard(
                          title: 'DIRECTOR / MANDO',
                          subtitle: 'Director de la Escuela\nAcceso total y alertas VIP',
                          icon: Icons.admin_panel_settings_rounded,
                          color: AppColors.primaryLight,
                          onTap: () => _assignRole(
                            AppRole.director,
                            'Gral. Adrián Morales',
                            'General de Brigada',
                            'Dirección General',
                          ),
                        ),
                        _buildDevRoleCard(
                          title: 'OFICIAL DE GUARDIA',
                          subtitle: 'Mando operativo del día\nParte diario PDF, relevo de guardia',
                          icon: Icons.security_rounded,
                          color: AppColors.statusPending,
                          onTap: () => _assignRole(
                            AppRole.guardOfficer,
                            'Cap. Adrián Morales',
                            'Capitán de Infantería',
                            'Cuerpo de Oficiales de Guardia',
                          ),
                        ),
                        _buildDevRoleCard(
                          title: 'BRIGADIER DE GUARDIA',
                          subtitle: 'Operador en Garita Principal\nEscaneo de QR, placa y registro de accesos',
                          icon: Icons.qr_code_scanner_rounded,
                          color: AppColors.statusGranted,
                          onTap: () => _assignRole(
                            AppRole.guardBrigadier,
                            'Brig. Adrián Morales',
                            'Brigadier de Guardia',
                            'Sección Garita Principal',
                          ),
                        ),
                        _buildDevRoleCard(
                          title: 'JEFE DE CONTROL',
                          subtitle: 'Monitoreo y Auditoría\nEstadísticas y reportes de lectura',
                          icon: Icons.analytics_rounded,
                          color: AppColors.primaryGlow,
                          onTap: () => _assignRole(
                            AppRole.controlChief,
                            'Tcnl. Adrián Morales',
                            'Teniente Coronel',
                            'Centro de Operaciones de Control',
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  // Premium personal identity button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push(RouteNames.myQr),
                      icon: const Icon(Icons.qr_code_2_rounded, size: 22),
                      label: Text(
                        'VER MI IDENTIDAD (MI QR Y PERFIL)',
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
                        elevation: 4,
                        shadowColor: AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => ref.read(signOutProvider)(),
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
      ),
    );
  }

  Widget _buildDevRoleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
                  // Blinking emergency icon
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

                  // Alert Header
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

                  // Sender
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

                  // Message
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

                  // Acknowledge Button
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
