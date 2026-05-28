// lib/features/qr_identity/presentation/pages/my_qr_page.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';
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

  @override
  void initState() {
    super.initState();
    _generateQr();
  }

  void _generateQr() {
    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    if (uid.isEmpty) return;
    setState(() => _qrData = QrTokenGenerator.generate(uid));
  }

  @override
  void dispose() {
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

              const SizedBox(height: 24),
 
              // ── Credencial Diaria Válida ──────────────────
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
                      'CREDENCIAL DIARIA ACTIVA',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.statusGranted,
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
                      '• El código es una credencial diaria y se renueva automáticamente cada 24 horas\n'
                      '• Funciona sin conexión a internet\n'
                      '• No comparta una captura de pantalla — no será válida',
                      style: AppTextStyles.bodySmall.copyWith(height: 1.8),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Dev simulator launcher (Visible only when QR Page is the root dashboard view in development)
              if (!Navigator.of(context).canPop()) ...[
                TextButton.icon(
                  onPressed: () => _showDevRoleSelectionBottomSheet(context),
                  icon: const Icon(Icons.developer_mode_rounded, size: 14, color: AppColors.textMuted),
                  label: Text(
                    'SIMULADOR DE ROLES (ENTORNO DE PRUEBAS)',
                    style: AppTextStyles.buttonSecondary.copyWith(
                      fontSize: 10,
                      letterSpacing: 1.0,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDevRoleSelectionBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppColors.surfaceBorder),
      ),
      builder: (context) {
        final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'SIMULADOR DE ROLES DE SEGURIDAD',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Seleccione un perfil para simular en esta sesión:',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGlow,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.primaryLight, size: 20),
                ),
                title: Text('Director / Mando (Total)', style: AppTextStyles.bodyLarge.copyWith(color: Colors.white)),
                subtitle: Text('General de Brigada · Dirección', style: AppTextStyles.bodySmall),
                onTap: () => _assignRole(uid, AppRole.director, 'Gral. Adrián Morales', 'General de Brigada'),
              ),
              const Divider(color: AppColors.surfaceBorder, height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.statusPending.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.security_rounded, color: AppColors.statusPending, size: 20),
                ),
                title: Text('Oficial de Guardia', style: AppTextStyles.bodyLarge.copyWith(color: Colors.white)),
                subtitle: Text('Capitán de Infantería · Control Diario', style: AppTextStyles.bodySmall),
                onTap: () => _assignRole(uid, AppRole.guardOfficer, 'Cap. Adrián Morales', 'Capitán de Infantería'),
              ),
              const Divider(color: AppColors.surfaceBorder, height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.statusGranted.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.statusGranted, size: 20),
                ),
                title: Text('Brigadier de Guardia (Garita)', style: AppTextStyles.bodyLarge.copyWith(color: Colors.white)),
                subtitle: Text('Brigadier de Guardia · Control de Accesos', style: AppTextStyles.bodySmall),
                onTap: () => _assignRole(uid, AppRole.guardBrigadier, 'Brig. Adrián Morales', 'Brigadier de Guardia'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _assignRole(String uid, AppRole role, String name, String rank) async {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Cargando entorno simulado...'),
        duration: Duration(seconds: 1),
      ),
    );
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'current_role': role.toFirestoreString(),
        'base_role': role.toFirestoreString(),
        'display_name': name,
        'rank': rank,
        'updated_at': Timestamp.now(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al asignar rol: $e')),
        );
      }
    }
  }
}
