// lib/core/config/app_config.dart
class AppConfig {
  AppConfig._();

  // ── Colecciones Firestore ────────────────────────────────
  static const String usersCollection = 'users';
  static const String vehiclesSubcollection = 'vehicles';
  static const String accessLogsCollection = 'access_logs';
  static const String visitorsCollection = 'visitors';
  static const String shiftLogsCollection = 'shift_logs';
  static const String shiftHandoffsCollection = 'shift_handoffs';
  static const String alertsCollection = 'alerts';
  static const String gatesCollection = 'gates';

  // ── Garita Principal ────────────────────────────────────
  static const String mainGateId = 'GARITA_PRINCIPAL';
  static const String mainGateName = 'Garita Principal';

  // ── QR Dinámico ──────────────────────────────────────────
  static const int qrRotationSeconds = 60;
  static const int qrClockToleranceWindows = 1;
  // SECRET embebido — en producción usar --dart-define=QR_SECRET=xxx
  static const String qrHmacSecret =
      String.fromEnvironment('QR_SECRET', defaultValue: 'SECURPASS_TACTICAL_2025_HMAC_KEY');

  // ── Paginación / Límites ──────────────────────────────────
  static const int accessLogPageSize = 50;
  static const int maxFcmTokensPerUser = 5;

  // ── Timeouts ─────────────────────────────────────────────
  static const Duration scannerDebounce = Duration(milliseconds: 1500);
  static const Duration offlineSyncDelay = Duration(seconds: 5);
}
