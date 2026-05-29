// lib/features/dashboard/presentation/pages/admin_dashboard_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';
import '../../../../core/services/stats_service.dart';
import '../../../../routing/route_names.dart';
import '../../../auth/domain/entities/app_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/stat_card.dart';
import '../widgets/access_log_tile.dart';
import '../widgets/tactical_app_bar.dart';
import '../widgets/tactical_chart_widget.dart';

// ── Providers ──────────────────────────────────────────────────────────────

/// Streams the latest 20 access-log documents ordered by timestamp desc.
final _accessLogsStreamProvider =
    StreamProvider.autoDispose<QuerySnapshot<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('access_logs')
      .orderBy('timestamp', descending: true)
      .limit(20)
      .snapshots();
});

// ── Page ───────────────────────────────────────────────────────────────────

/// Dashboard for Director, Subdirector, and Jefe de Escuela roles.
///
/// Shows real-time stats, a live access-log feed, and a notifications FAB.
/// On wide screens (> 900 px) a [NavigationRail] side panel is displayed.
class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 900;

    return userAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text('Error: $e', style: AppTextStyles.bodyMedium),
        ),
      ),
      data: (user) {
        if (user == null) return const SizedBox.shrink();

        final displayName = user.displayName;
        final roleName = user.currentRole.displayName.toUpperCase();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: TacticalAppBar(
            title: 'PANEL DE MANDO',
            subtitle: roleName,
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
                tooltip: 'Escáner de Acceso',
              ),
              const SizedBox(width: 8),
              // User name chip
              Container(
                margin: const EdgeInsets.only(right: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGlow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.4), width: 1),
                ),
                child: Text(
                  displayName,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primaryLight,
                    fontSize: 11,
                  ),
                ),
              ),
              // Logout
              IconButton(
                onPressed: () async {
                  await ref.read(signOutProvider)(context);
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
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push(RouteNames.alertsInbox),
            backgroundColor: AppColors.alertRed,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.notifications_rounded),
            label: Text(
              'ALERTAS',
              style: AppTextStyles.buttonPrimary.copyWith(fontSize: 13),
            ),
          ).animate().fadeIn(delay: 600.ms).scale(
              begin: const Offset(0.8, 0.8), duration: 300.ms),
          body: isWide
              ? Row(
                  children: [
                    _SideRailNav(
                      onAlerts: () => context.push(RouteNames.alertsInbox),
                      onUsers: () => context.push(RouteNames.adminUsers),
                      onReports: () => context.push(RouteNames.adminReports),
                    ),
                    const VerticalDivider(
                        width: 1, color: AppColors.surfaceBorder),
                    Expanded(child: _AdminBody()),
                  ],
                )
              : _AdminBody(),
        );
      },
    );
  }
}

// ── Body ───────────────────────────────────────────────────────────────────

class _AdminBody extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(_accessLogsStreamProvider);

    return CustomScrollView(
      slivers: [
        // ── Stat cards row ──────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ESTADO ACTUAL',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 12),
                _StatsGrid(),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05, end: 0),
        ),

        // ── Activity chart ───────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: _AdminActivityChart(),
          ).animate().fadeIn(delay: 180.ms, duration: 400.ms),
        ),

        // ── Section header ───────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'ACTIVIDAD EN TIEMPO REAL',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 2.5,
                  ),
                ),
                const Spacer(),
                // Live indicator dot
                _LiveDot(),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
        ),

        // ── Access log list ────────────────────────────────
        logsAsync.when(
          loading: () => const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (e, _) => SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _ErrorBanner(message: e.toString()),
            ),
          ),
          data: (snapshot) {
            final docs = snapshot.docs;
            if (docs.isEmpty) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(
                    child: _EmptyLogs(),
                  ),
                ),
              );
            }
            return SliverList.separated(
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox.shrink(),
              itemBuilder: (context, index) {
                final data = docs[index].data();
                final ts = (data['timestamp'] as Timestamp?)?.toDate() ??
                    DateTime.now();
                return AccessLogTile(
                  personName: data['person_name'] as String? ?? 'Desconocido',
                  rank: data['rank'] as String? ?? '—',
                  eventType: data['event_type'] as String? ?? 'Evento',
                  timestamp: ts,
                  accessResult:
                      data['access_result'] as String? ?? 'pending',
                  vehiclePlate: data['vehicle_plate'] as String?,
                )
                    .animate(delay: (index * 40).ms)
                    .fadeIn(duration: 300.ms)
                    .slideX(begin: 0.05, end: 0);
              },
            );
          },
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

// ── Stats grid ─────────────────────────────────────────────────────────────

class _StatsGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dailyStatsProvider);

    return statsAsync.when(
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => Text('Error: $e', style: AppTextStyles.bodySmall),
      data: (stats) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 12 * 3) / 4;
            final useGrid = cardWidth < 120;

            final cards = [
              StatCard(
                label: 'Personas Dentro',
                value: stats.peopleCurrentlyInside.toString(),
                icon: Icons.people_alt_rounded,
                color: AppColors.primary,
              ),
              StatCard(
                label: 'Vehículos',
                value: stats.uniqueVehicles.toString(),
                icon: Icons.directions_car_rounded,
                color: AppColors.statusGranted,
              ),
              StatCard(
                label: 'Visitantes',
                value: stats.uniqueVisitors.toString(),
                icon: Icons.badge_rounded,
                color: AppColors.statusPending,
              ),
              StatCard(
                label: 'Movimientos',
                value: stats.totalMovements.toString(),
                icon: Icons.swap_vert_rounded,
                color: AppColors.accent,
              ),
            ];

            if (useGrid) {
              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.4,
                children: cards,
              );
            }

            return Row(
              children: cards
                  .map(
                    (card) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: card,
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        );
      },
    );
  }
}

// ── Side rail navigation ────────────────────────────────────────────────────

class _SideRailNav extends StatefulWidget {
  final VoidCallback onAlerts;
  final VoidCallback onUsers;
  final VoidCallback onReports;

  const _SideRailNav({
    required this.onAlerts,
    required this.onUsers,
    required this.onReports,
  });

  @override
  State<_SideRailNav> createState() => _SideRailNavState();
}

class _SideRailNavState extends State<_SideRailNav> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: NavigationRail(
        backgroundColor: AppColors.surface,
        selectedIndex: _selected,
        onDestinationSelected: (index) {
          setState(() => _selected = index);
          switch (index) {
            case 0:
              break;
            case 1:
              widget.onAlerts();
            case 2:
              widget.onUsers();
            case 3:
              widget.onReports();
          }
        },
        labelType: NavigationRailLabelType.all,
        selectedIconTheme:
            const IconThemeData(color: AppColors.primary, size: 22),
        unselectedIconTheme:
            const IconThemeData(color: AppColors.textMuted, size: 20),
        selectedLabelTextStyle: AppTextStyles.labelSmall.copyWith(
          color: AppColors.primary,
          fontSize: 10,
          letterSpacing: 0.8,
        ),
        unselectedLabelTextStyle: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textMuted,
          fontSize: 10,
        ),
        indicatorColor: AppColors.primaryGlow,
        destinations: const [
          NavigationRailDestination(
            icon: Icon(Icons.dashboard_rounded),
            label: Text('INICIO'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.notifications_rounded),
            label: Text('ALERTAS'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.manage_accounts_rounded),
            label: Text('USUARIOS'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.bar_chart_rounded),
            label: Text('REPORTES'),
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────

class _LiveDot extends StatefulWidget {
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
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

class _EmptyLogs extends StatelessWidget {
  const _EmptyLogs();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.event_note_rounded,
            size: 48, color: AppColors.textMuted.withOpacity(0.5)),
        const SizedBox(height: 12),
        Text(
          'Sin actividad registrada',
          style: AppTextStyles.bodyMedium,
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.alertRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: AppColors.alertRed.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.alertRed, size: 20),
          const SizedBox(width: 10),
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

// ── Admin Activity Chart ────────────────────────────────────────────────────

/// Gráfico táctico de actividad diaria para el dashboard de administración.
/// Muestra dos series: movimientos peatonales y vehiculares por hora.
class _AdminActivityChart extends ConsumerWidget {
  const _AdminActivityChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dailyStatsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
              'ACTIVIDAD POR HORA (HOY)',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primary,
                letterSpacing: 2.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        statsAsync.when(
          loading: () => const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (e, _) => const SizedBox.shrink(),
          data: (stats) {
            final pedestrian = List<int>.filled(24, 0);
            final vehicular = List<int>.filled(24, 0);

            for (final entry in stats.activityByHourPedestrian.entries) {
              pedestrian[entry.key.clamp(0, 23)] = entry.value;
            }
            for (final entry in stats.activityByHourVehicular.entries) {
              vehicular[entry.key.clamp(0, 23)] = entry.value;
            }

            return TacticalBarChart(
              height: 100,
              series: [
                ChartSeries(
                  label: 'Peatonal',
                  color: AppColors.primary,
                  hourlyData: pedestrian,
                ),
                ChartSeries(
                  label: 'Vehicular',
                  color: AppColors.statusGranted,
                  hourlyData: vehicular,
                ),
              ],
              emptyMessage: 'Sin actividad hoy',
            );
          },
        ),
      ],
    );
  }
}

