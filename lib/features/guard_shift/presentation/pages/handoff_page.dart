// lib/features/guard_shift/presentation/pages/handoff_page.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';
import '../../../../core/utils/qr_token_generator.dart';
import '../../../auth/domain/entities/app_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class HandoffPage extends ConsumerStatefulWidget {
  const HandoffPage({super.key});

  @override
  ConsumerState<HandoffPage> createState() => _HandoffPageState();
}

class _HandoffPageState extends ConsumerState<HandoffPage> {
  final MobileScannerController _cameraCtrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  bool _isProcessing = false;
  String _statusMessage = 'APUNTE AL QR DEL OFICIAL ENTRANTE';

  @override
  void dispose() {
    _cameraCtrl.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    final raw = barcode!.rawValue!;
    setState(() {
      _isProcessing = true;
      _statusMessage = 'PROCESANDO CÓDIGO...';
    });

    try {
      String? incomingUid;

      // 1. Validar si es QR personal dinámico o directo UID
      if (raw.startsWith('SP:')) {
        final parts = raw.substring(3).split(':');
        if (parts.length == 3) {
          final uid = parts[0];
          final window = int.tryParse(parts[1]);
          final token = parts[2];
          if (window != null) {
            final isValid = QrTokenGenerator.validate(uid: uid, window: window, token: token);
            if (isValid) {
              incomingUid = uid;
            }
          }
        }
      } else if (raw.length >= 20) {
        incomingUid = raw;
      }

      if (incomingUid == null) {
        setState(() {
          _isProcessing = false;
          _statusMessage = '✗ CÓDIGO INVÁLIDO — REINTENTE';
        });
        return;
      }

      final currentUser = ref.read(currentUserProvider).valueOrNull;
      if (currentUser != null && incomingUid == currentUser.uid) {
        setState(() {
          _isProcessing = false;
          _statusMessage = '✗ ERROR: NO PUEDE HACER RELEVO CONSIGO MISMO';
        });
        return;
      }

      // Fetch incoming user details
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(incomingUid)
          .get()
          .timeout(const Duration(seconds: 4));

      if (!userDoc.exists) {
        setState(() {
          _isProcessing = false;
          _statusMessage = '✗ ERROR: USUARIO NO ENCONTRADO EN Firestore';
        });
        return;
      }

      final incomingData = userDoc.data()!;
      final incomingName = incomingData['display_name'] ?? 'Oficial Entrante';
      final incomingRank = incomingData['rank'] ?? 'Grado Desconocido';

      if (mounted) {
        _showConfirmationDialog(incomingUid, incomingName, incomingRank);
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = '✗ ERROR AL ESCANEAR: $e';
      });
    }
  }

  void _showConfirmationDialog(String incomingUid, String incomingName, String incomingRank) {
    final outgoingUser = ref.read(currentUserProvider).valueOrNull;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.surfaceBorder),
          ),
          title: Row(
            children: [
              const Icon(Icons.swap_horiz_rounded, color: AppColors.accent, size: 24),
              const SizedBox(width: 10),
              Text(
                'CONFIRMAR TRASPASO',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.accent,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Confirmar relevo de guardia al oficial entrante?',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OFICIAL SALIENTE:',
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
                    ),
                    Text(
                      outgoingUser != null
                          ? '${outgoingUser.displayName} (${outgoingUser.rank})'
                          : 'Oficial Saliente',
                      style: AppTextStyles.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'OFICIAL ENTRANTE:',
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
                    ),
                    Text(
                      '$incomingName ($incomingRank)',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.accent, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Al confirmar, se guardará el log, se te removerán los privilegios de Oficial de Guardia, y se cerrará tu sesión automáticamente.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isProcessing = false;
                  _statusMessage = 'APUNTE AL QR DEL OFICIAL ENTRANTE';
                });
              },
              child: Text('Cancelar', style: AppTextStyles.buttonSecondary),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _executeHandoff(incomingUid, incomingName, incomingRank);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
              ),
              child: Text('CONFIRMAR RELEVO', style: AppTextStyles.buttonPrimary.copyWith(fontSize: 12)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _executeHandoff(String incomingUid, String incomingName, String incomingRank) async {
    setState(() => _statusMessage = 'EJECUTANDO TRASPASO EN LA NUBE...');
    final outgoingUser = ref.read(currentUserProvider).valueOrNull;
    if (outgoingUser == null) return;

    final batch = FirebaseFirestore.instance.batch();

    // 1. Degradación de saliente a su base_role original
    final outgoingRef = FirebaseFirestore.instance.collection('users').doc(outgoingUser.uid);
    batch.update(outgoingRef, {
      'current_role': outgoingUser.baseRole.toFirestoreString(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    // 2. Promoción de entrante a guard_officer
    final incomingRef = FirebaseFirestore.instance.collection('users').doc(incomingUid);
    batch.update(incomingRef, {
      'current_role': 'guard_officer',
      'updated_at': FieldValue.serverTimestamp(),
    });

    // 3. Crear log de relevo
    final handoffRef = FirebaseFirestore.instance.collection('shift_handoffs').doc();
    batch.set(handoffRef, {
      'handoff_id': handoffRef.id,
      'timestamp': FieldValue.serverTimestamp(),
      'gate_id': 'GARITA_PRINCIPAL',
      'outgoing_uid': outgoingUser.uid,
      'outgoing_name': outgoingUser.displayName,
      'outgoing_rank': outgoingUser.rank,
      'incoming_uid': incomingUid,
      'incoming_name': incomingName,
      'incoming_rank': incomingRank,
      'status': 'completed',
    });

    try {
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Relevo de Guardia completado con éxito. Cerrando sesión...'),
            backgroundColor: AppColors.statusGranted,
            duration: Duration(seconds: 3),
          ),
        );

        // Signout and route back to login cleanly
        await ref.read(signOutProvider)(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = '✗ ERROR AL EJECUTAR RELEVO: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error en transacción de relevo: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('TRASPASO DE MANDO', style: AppTextStyles.headlineMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // Mobile Scanner
          Positioned.fill(
            child: MobileScanner(
              controller: _cameraCtrl,
              onDetect: _onDetect,
            ),
          ),

          // Scan Frame overlay
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.accent, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      // Scanner Line
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: _ScannerLine(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Text(
                    _statusMessage,
                    style: AppTextStyles.labelMedium.copyWith(color: Colors.white, letterSpacing: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerLine extends StatefulWidget {
  @override
  State<_ScannerLine> createState() => _ScannerLineState();
}

class _ScannerLineState extends State<_ScannerLine> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0, end: 1).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Stack(
        children: [
          Positioned(
            top: _anim.value * 230,
            left: 0,
            right: 0,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.accent.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
