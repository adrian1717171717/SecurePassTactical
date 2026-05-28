// lib/routing/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/domain/entities/app_role.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/dashboard/presentation/pages/dashboard_router_page.dart';
import '../features/access_control/presentation/pages/scanner_page.dart';
import '../features/qr_identity/presentation/pages/my_qr_page.dart';
import '../features/alerts/presentation/pages/alerts_inbox_page.dart';
import '../features/guard_shift/presentation/pages/handoff_page.dart';
import '../features/guard_shift/presentation/pages/shift_summary_page.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final userAsync = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: RouteNames.login,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isAuthenticated = userAsync.valueOrNull != null;
      final isOnLogin = state.matchedLocation == RouteNames.login;

      if (!isAuthenticated && !isOnLogin) return RouteNames.login;
      if (isAuthenticated && isOnLogin) return RouteNames.dashboard;
      return null;
    },
    routes: [
      // ── Auth ─────────────────────────────────────────────
      GoRoute(
        path: RouteNames.login,
        name: 'login',
        builder: (_, __) => const LoginPage(),
      ),

      // ── Dashboard (enruta por rol) ─────────────────────
      GoRoute(
        path: RouteNames.dashboard,
        name: 'dashboard',
        builder: (_, __) => const DashboardRouterPage(),
      ),

      // ── Escáner ────────────────────────────────────────
      GoRoute(
        path: RouteNames.scanner,
        name: 'scanner',
        builder: (_, __) => const ScannerPage(),
        redirect: (context, state) {
          final role = userAsync.valueOrNull?.currentRole;
          if (role == null || 
              !(role.canScanAccess || role.isHighCommand || role == AppRole.guardOfficer)) {
            return RouteNames.dashboard;
          }
          return null;
        },
      ),

      // ── QR Personal ────────────────────────────────────
      GoRoute(
        path: RouteNames.myQr,
        name: 'myQr',
        builder: (_, __) => const MyQrPage(),
      ),

      // ── Relevo de Guardia ──────────────────────────────
      GoRoute(
        path: RouteNames.shiftHandoff,
        name: 'shiftHandoff',
        builder: (_, __) => const HandoffPage(),
        redirect: (context, state) {
          final role = userAsync.valueOrNull?.currentRole;
          if (role == null || role != AppRole.guardOfficer) {
            return RouteNames.dashboard;
          }
          return null;
        },
      ),

      // ── Resumen de Guardia (Cierre y PDF) ───────────────
      GoRoute(
        path: RouteNames.shiftSummary,
        name: 'shiftSummary',
        builder: (_, __) => const ShiftSummaryPage(),
        redirect: (context, state) {
          final role = userAsync.valueOrNull?.currentRole;
          if (role == null || role != AppRole.guardOfficer) {
            return RouteNames.dashboard;
          }
          return null;
        },
      ),

      // ── Alertas ────────────────────────────────────────
      GoRoute(
        path: RouteNames.alertsInbox,
        name: 'alertsInbox',
        builder: (_, __) => const AlertsInboxPage(),
        redirect: (context, state) {
          final role = userAsync.valueOrNull?.currentRole;
          if (role == null || !role.receivesVipAlerts) {
            return RouteNames.dashboard;
          }
          return null;
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          'Ruta no encontrada: ${state.uri}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    ),
  );
});
