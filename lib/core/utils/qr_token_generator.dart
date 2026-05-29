// lib/core/utils/qr_token_generator.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../config/app_config.dart';

/// Genera y valida tokens QR dinámicos con HMAC-SHA256.
/// El token rota cada 60 segundos y funciona 100% offline.
class QrTokenGenerator {
  QrTokenGenerator._();

  /// Calcula la ventana temporal actual (timestamp en segundos)
  static int currentWindow() {
    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
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
  /// Verifica que el token no tenga más de 24 horas (86400 segundos) de antigüedad.
  static bool validate({
    required String uid,
    required int window,
    required String token,
  }) {
    final now = currentWindow();
    // 86400 segundos = 24 horas exactas
    if (now - window > 86400 || now < window) {
      return false; // Expirado o fecha futura inválida
    }
    
    final candidate = _computeHmac(uid, window);
    return candidate == token;
  }

  /// Genera el payload para un QR de sticker vehicular
  /// Formato: VH:<plate>:<stickerSerial>
  static String generateVehicleSticker({
    required String plate,
    required String stickerSerial,
  }) {
    return 'VH:$plate:$stickerSerial';
  }

  /// Segundos de validez total de un QR recién generado
  static int secondsUntilRotation() {
    return 86400; // 24 horas
  }
}
