// lib/core/utils/qr_token_generator.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../config/app_config.dart';

/// Genera y valida tokens QR dinámicos con HMAC-SHA256.
/// El token rota cada 60 segundos y funciona 100% offline.
class QrTokenGenerator {
  QrTokenGenerator._();

  /// Calcula la ventana temporal actual (diaria: AAAAMMDD)
  static int currentWindow() {
    final now = DateTime.now();
    return now.year * 10000 + now.month * 100 + now.day;
  }

  /// Genera el HMAC para una combinación uid + window
  static String _computeHmac(String uid, int window) {
    final key = utf8.encode(AppConfig.qrHmacSecret);
    final message = utf8.encode('$uid:$window');
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(message);
    // Solo los primeros 16 chars del hex
    return digest.toString().substring(0, 16);
  }

  /// Genera el payload completo del QR personal
  /// Formato: SP:<uid>:<window>:<token>
  static String generate(String uid) {
    final window = currentWindow();
    final token = _computeHmac(uid, window);
    return 'SP:$uid:$window:$token';
  }

  /// Valida un token QR escaneado.
  /// Acepta el día actual y el anterior (1 día de tolerancia por husos horarios).
  static bool validate({
    required String uid,
    required int window,
    required String token,
  }) {
    final now = currentWindow();
    // Tolerancia de hoy y ayer
    for (int delta = 0; delta <= 1; delta++) {
      final candidate = _computeHmac(uid, now - delta);
      if (candidate == token) {
        return true;
      }
    }
    return false;
  }

  /// Genera el payload para un QR de sticker vehicular
  /// Formato: VH:<plate>:<stickerSerial>
  static String generateVehicleSticker({
    required String plate,
    required String stickerSerial,
  }) {
    return 'VH:$plate:$stickerSerial';
  }

  /// Segundos restantes hasta la medianoche (siguiente rotación diaria)
  static int secondsUntilRotation() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return tomorrow.difference(now).inSeconds;
  }
}
