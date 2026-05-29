// lib/features/qr_identity/presentation/pages/my_qr_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/utils/qr_token_generator.dart';
import '../../../auth/domain/entities/app_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class MyQrPage extends ConsumerStatefulWidget {
  const MyQrPage({super.key});

  @override
  ConsumerState<MyQrPage> createState() => _MyQrPageState();
}

class _MyQrPageState extends ConsumerState<MyQrPage> {
  String _qrData = '';
  Timer? _rotationTimer;
  DateTime? _generatedAt;
  int _secondsUntilRefresh = 86400; // 24 hours in seconds

  @override
  void initState() {
    super.initState();
    _generateQr();
    // Countdown to 24h expiration
    _rotationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_generatedAt == null) return;
      
      final elapsed = DateTime.now().difference(_generatedAt!).inSeconds;
      final remaining = 86400 - elapsed;
      
      setState(() {
        _secondsUntilRefresh = remaining > 0 ? remaining : 0;
      });
    });
  }

  void _generateQr() {
    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    if (uid.isEmpty) return;
    setState(() {
      _generatedAt = DateTime.now();
      _secondsUntilRefresh = 86400;
      _qrData = QrTokenGenerator.generate(uid);
    });
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text('MI CÓDIGO QR', style: AppTextStyles.headlineMedium),
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).pop(),
              )
            : IconButton(
                icon: const Icon(Icons.logout_rounded),
                onPressed: () async {
                  await ref.read(signOutProvider)(context);
                },
                tooltip: 'Cerrar sesión',
              ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Perfil ─────────────────────────────────
              if (user != null) ...[
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.surfaceElevated,
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? const Icon(Icons.person_rounded,
                          size: 40, color: AppColors.textSecondary)
                      : null,
                ),
                const SizedBox(height: 12),
                Text(user.displayName, style: AppTextStyles.headlineSmall),
                Text(user.rank, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (user.cedula.isNotEmpty) ...[
                      const Icon(Icons.badge_outlined, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text('C.I. ${user.cedula}', style: AppTextStyles.bodySmall),
                    ],
                    if (user.cedula.isNotEmpty && user.phone != null && user.phone!.isNotEmpty)
                      const Text('  |  ', style: TextStyle(color: AppColors.surfaceBorder)),
                    if (user.phone != null && user.phone!.isNotEmpty) ...[
                      const Icon(Icons.phone_outlined, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(user.phone!, style: AppTextStyles.bodySmall),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                // Year level and unit for cadets
                if (user.yearLevel != null && user.yearLevel!.isNotEmpty)
                  Text(
                    '${user.yearLevel} · ${user.unit}',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGlow,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Text(
                    user.currentRole.displayName.toUpperCase(),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primaryLight,
                      letterSpacing: 2,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
              ],

              // ── QR con borde ──────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: _qrData.isNotEmpty
                    ? QrImageView(
                        data: _qrData,
                        version: QrVersions.auto,
                        size: 240,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF0A0E14),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF0A0E14),
                        ),
                      )
                    : const SizedBox(
                        width: 240,
                        height: 240,
                        child: Center(child: CircularProgressIndicator()),
                      ),
              )
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .scale(begin: const Offset(0.95, 0.95)),

              const SizedBox(height: 16),

              // ── Rotation Timer ─────────────────────────
              if (_secondsUntilRefresh > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_outlined,
                          size: 14,
                          color: _secondsUntilRefresh <= 3600
                              ? AppColors.alertRed
                              : AppColors.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        'Expira en ${_formatDuration(Duration(seconds: _secondsUntilRefresh))}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: _secondsUntilRefresh <= 3600
                              ? AppColors.alertRed
                              : AppColors.textMuted,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: _generateQr,
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  label: const Text('RENOVAR CÓDIGO (VENCIDO)'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.alertRed),
                ),

              const SizedBox(height: 16),

              // ── Credencial Diaria Válida ──────────────────
              if (_secondsUntilRefresh > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.statusGranted.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.statusGranted.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_user_rounded,
                          color: AppColors.statusGranted, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'CREDENCIAL ACTIVA',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.statusGranted,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.alertRed.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.alertRed.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.gpp_bad_rounded,
                          color: AppColors.alertRed, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'CREDENCIAL VENCIDA',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.alertRed,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 28),

              // ── Instrucciones ─────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Text('INSTRUCCIONES DE USO',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.primary,
                            )),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Presente este QR al Brigadier o Cadete de Guardia\n'
                      '• El código es válido exactamente por 24 horas\n'
                      '• Funciona sin conexión a internet durante su vigencia\n'
                      '• No comparta una captura de pantalla — no será válida',
                      style: AppTextStyles.bodySmall.copyWith(height: 1.8),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}
