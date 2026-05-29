// lib/routing/route_names.dart
class RouteNames {
  RouteNames._();

  static const String login = '/login';
  static const String dashboard = '/dashboard';

  // ── Operativos ───────────────────────────────────────────
  static const String scanner = '/scanner';

  // ── Guardia ──────────────────────────────────────────────
  static const String shiftHandoff = '/shift/handoff';
  static const String shiftSummary = '/shift/summary';
  static const String bitacoraHistory = '/bitacora/history';
  static const String bitacoraFilter = '/bitacora/filter';

  // ── QR Personal ──────────────────────────────────────────
  static const String myQr = '/my-qr';

  // ── Perfil ───────────────────────────────────────────────
  static const String profile = '/profile';

  // ── Alertas ──────────────────────────────────────────────
  static const String alertsInbox = '/alerts';

  // ── Vehículos ────────────────────────────────────────────
  static const String vehicles = '/vehicles';

  // ── Admin ────────────────────────────────────────────────
  static const String adminUsers = '/admin/users';
  static const String adminReports = '/admin/reports';
}
