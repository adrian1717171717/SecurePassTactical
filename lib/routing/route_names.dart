// lib/routing/route_names.dart
class RouteNames {
  RouteNames._();

  static const String login = '/login';
  static const String dashboard = '/dashboard';

  // ── Operativos ───────────────────────────────────────────
  static const String scanner = '/scanner';
  static const String manualEntry = '/manual-entry';
  static const String accessLogDetail = '/access-log/:id';

  // ── Visitantes ───────────────────────────────────────────
  static const String visitorRegister = '/visitor/register';
  static const String visitorExit = '/visitor/exit';

  // ── Guardia ──────────────────────────────────────────────
  static const String shiftHandoff = '/shift/handoff';
  static const String shiftSummary = '/shift/summary';
  static const String shiftReport = '/shift/report';

  // ── QR Personal ──────────────────────────────────────────
  static const String myQr = '/my-qr';

  // ── Alertas ──────────────────────────────────────────────
  static const String alertsInbox = '/alerts';

  // ── Admin ────────────────────────────────────────────────
  static const String adminUsers = '/admin/users';
  static const String adminGates = '/admin/gates';
  static const String adminReports = '/admin/reports';
}
