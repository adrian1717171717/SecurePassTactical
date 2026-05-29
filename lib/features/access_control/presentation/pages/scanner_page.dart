import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';
import '../../../../core/utils/qr_token_generator.dart';
import '../../../../core/services/audit_service.dart';
import '../../../auth/domain/entities/app_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Resultado visual del escaneo
enum _ScanResult { idle, granted, denied, pending }

class ScannerPage extends ConsumerStatefulWidget {
  const ScannerPage({super.key});

  @override
  ConsumerState<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends ConsumerState<ScannerPage> {
  final MobileScannerController _cameraCtrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  _ScanResult _result = _ScanResult.idle;
  String _lastScanned = '';
  String _statusMessage = 'APUNTE AL CÓDIGO QR O PLACA';
  bool _isProcessing = false;
  Timer? _resetTimer;

  // Modo: 'entry' | 'exit'
  String _mode = 'entry';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _mode = 'entry');
    });
  }

  @override
  void dispose() {
    _cameraCtrl.dispose();
    _resetTimer?.cancel();
    super.dispose();
  }

  // ── Procesa el código escaneado ───────────────────────────
  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    final raw = barcode!.rawValue!;
    if (raw == _lastScanned) return;

    setState(() {
      _isProcessing = true;
      _lastScanned = raw;
    });

    // Obtener datos del operador (quien escanea)
    final operator = ref.read(currentUserProvider).valueOrNull;
    final operatorUid = operator?.uid ?? '';
    final operatorName = operator?.displayName ?? 'Operador';
    final operatorRole = operator?.currentRole.toFirestoreString() ?? 'unknown';

    try {
      String personName = 'Usuario Desconocido';
      String personRank = 'Código QR';
      String eventType = _mode == 'entry' ? 'Ingreso Peatonal' : 'Salida Peatonal';
      String? vehiclePlate;
      String? scannedUid;
      String? scannedCedula;
      String? scannedUnit;
      bool isValid = false;
      bool isDuplicateState = false;
      String? errorMessage;
      String? matchedUid;

      // 1. Validar como QR dinámico personal
      if (raw.startsWith('SP:')) {
        final parts = raw.substring(3).split(':');
        if (parts.length == 3) {
          final uid = parts[0];
          final window = int.tryParse(parts[1]);
          final token = parts[2];
          if (window != null) {
            isValid = QrTokenGenerator.validate(uid: uid, window: window, token: token);
            if (isValid) {
              matchedUid = uid;
            }
          }
        }
      }
      // 2. Validar como QR de vehículo
      else if (raw.startsWith('VH:')) {
        final plate = raw.substring(3).trim().toUpperCase();
        isValid = true;
        personName = 'Vehículo Registrado';
        personRank = 'Sticker QR';
        eventType = _mode == 'entry' ? 'Ingreso Vehicular' : 'Salida Vehicular';
        vehiclePlate = plate;
      }
      // 3. Validar como cédula QR u otro
      else {
        isValid = raw.length >= 6;
        personName = 'Escaneo Manual/Barras';
        personRank = 'Documento';
        vehiclePlate = raw;
      }

      // Validar y aplicar lógica de estado de movimiento si es un usuario registrado
      if (matchedUid != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(matchedUid)
            .get()
            .timeout(const Duration(seconds: 4));
        if (userDoc.exists) {
          final d = userDoc.data()!;
          personName = d['display_name'] ?? 'Desconocido';
          personRank = d['rank'] ?? '—';
          scannedUid = matchedUid;
          scannedCedula = d['cedula'] as String?;
          scannedUnit = d['unit'] as String?;
          final movementState = d['movement_state'] ?? 'AFUERA';

          if (_mode == 'entry' && movementState == 'ADENTRO') {
            isValid = false;
            isDuplicateState = true;
            errorMessage = 'ERROR: Usuario ya se encuentra dentro de la instalación';
          } else if (_mode == 'exit' && movementState == 'AFUERA') {
            isValid = false;
            isDuplicateState = true;
            errorMessage = 'ERROR: Usuario ya se encuentra fuera de la instalación';
          } else {
            isValid = true;
            await FirebaseFirestore.instance
                .collection('users')
                .doc(matchedUid)
                .update({
              'movement_state': _mode == 'entry' ? 'ADENTRO' : 'AFUERA',
              'updated_at': FieldValue.serverTimestamp(),
            });
          }
        } else {
          isValid = false;
          errorMessage = 'ERROR: Usuario no registrado en la base de datos';
        }
      }

      final accessResult = isValid ? 'granted' : 'denied';

      setState(() {
        _result = isValid ? _ScanResult.granted : _ScanResult.denied;
        if (isValid) {
          _statusMessage = _mode == 'entry' ? '✓ INGRESO REGISTRADO' : '✓ SALIDA REGISTRADA';
        } else {
          _statusMessage = errorMessage ?? '✗ ACCESO DENEGADO — NO AUTORIZADO';
        }
      });

      // Guardar log en Firestore con datos completos de trazabilidad (solo si no es un escaneo duplicado)
      if (!isDuplicateState) {
        await _logAccess(
          personName: personName,
          rank: personRank,
          eventType: eventType,
          accessResult: accessResult,
          vehiclePlate: vehiclePlate,
          uid: scannedUid,
          cedula: scannedCedula,
          unit: scannedUnit,
          operatorUid: operatorUid,
          operatorName: operatorName,
          operatorRole: operatorRole,
          errorMessage: errorMessage,
        );

        // Registrar auditoría
        AuditService.logAccessScan(
          operatorUid: operatorUid,
          operatorName: operatorName,
          operatorRole: operatorRole,
          scannedUid: scannedUid ?? 'external',
          scannedName: personName,
          eventType: eventType,
          result: accessResult,
          vehiclePlate: vehiclePlate,
        );
      }

      // Auto-reset después de 2.5s
      _resetTimer = Timer(const Duration(milliseconds: 2500), () {
        if (mounted) {
          setState(() {
            _result = _ScanResult.idle;
            _statusMessage = 'APUNTE AL CÓDIGO QR O PLACA';
            _lastScanned = '';
            _isProcessing = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _result = _ScanResult.denied;
        _statusMessage = 'ERROR DE VALIDACIÓN';
        _isProcessing = false;
      });
    }
  }

  Future<void> _logAccess({
    required String personName,
    required String rank,
    required String eventType,
    required String accessResult,
    String? vehiclePlate,
    String? uid,
    String? cedula,
    String? unit,
    required String operatorUid,
    required String operatorName,
    required String operatorRole,
    String? errorMessage,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('access_logs').add({
        'person_name': personName,
        'rank': rank,
        'event_type': eventType,
        'timestamp': FieldValue.serverTimestamp(),
        'access_result': accessResult,
        if (vehiclePlate != null) 'vehicle_plate': vehiclePlate,
        if (uid != null) 'uid': uid,
        if (cedula != null) 'cedula': cedula,
        if (unit != null) 'unit': unit,
        'operator_uid': operatorUid,
        'operator_name': operatorName,
        'operator_role': operatorRole,
      });

      if (accessResult == 'denied') {
        await FirebaseFirestore.instance.collection('alerts').add({
          'type': 'security_incident',
          'sender': 'ESCÁNER AUTOMÁTICO',
          'message': 'Intento de acceso denegado. $personName ($rank). Razón: ${errorMessage ?? "Desconocida"}',
          'timestamp': FieldValue.serverTimestamp(),
          'is_read': false,
          'is_emergency': true,
        });
      }
    } catch (e) {
      debugPrint('Error al guardar log de acceso: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color statusColor = switch (_result) {
      _ScanResult.granted => AppColors.statusGranted,
      _ScanResult.denied => AppColors.statusDenied,
      _ScanResult.pending => AppColors.statusPending,
      _ScanResult.idle => AppColors.primary,
    };

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Cámara ─────────────────────────────────────
          Positioned.fill(
            child: MobileScanner(
              controller: _cameraCtrl,
              onDetect: _onDetect,
            ),
          ),

          // ── Overlay oscuro cuando hay resultado ─────────
          if (_result != _ScanResult.idle)
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.75))
                  .animate()
                  .fadeIn(duration: 150.ms),
            ),

          // ── Overlay UI ─────────────────────────────────
          Positioned.fill(
            child: Column(
              children: [
                // ── AppBar táctica ────────────────────────
                _buildTopBar(),

                Expanded(
                  child: Center(
                    child: _result == _ScanResult.idle
                        ? _buildScannerFrame()
                        : _buildResultDisplay(statusColor),
                  ),
                ),

                // ── Panel inferior ────────────────────────
                _buildBottomPanel(statusColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CONTROL DE ACCESO', style: AppTextStyles.headlineSmall),
              Text(
                _mode == 'entry' ? 'MODO: INGRESO' : 'MODO: SALIDA',
                style: AppTextStyles.labelSmall.copyWith(
                  color: _mode == 'entry'
                      ? AppColors.statusGranted
                      : AppColors.statusDenied,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Toggle modo ingreso/salida
          GestureDetector(
            onTap: () => setState(() {
              _mode = _mode == 'entry' ? 'exit' : 'entry';
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _mode == 'entry'
                    ? AppColors.statusGranted.withOpacity(0.2)
                    : AppColors.statusDenied.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _mode == 'entry'
                      ? AppColors.statusGranted
                      : AppColors.statusDenied,
                ),
              ),
              child: Text(
                _mode == 'entry' ? '↑ INGRESO' : '↓ SALIDA',
                style: AppTextStyles.labelMedium.copyWith(
                  color: _mode == 'entry'
                      ? AppColors.statusGranted
                      : AppColors.statusDenied,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Linterna
          IconButton(
            icon: const Icon(Icons.flashlight_on_rounded, color: Colors.white),
            onPressed: () => _cameraCtrl.toggleTorch(),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerFrame() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Marco de escaneo
        Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              // Esquinas iluminadas
              ..._buildCorners(),
              // Línea de escaneo animada
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _ScannerLine(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _statusMessage,
          style: AppTextStyles.labelMedium.copyWith(
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'QR personal · QR vehículo · Cédula QR',
          style: AppTextStyles.bodySmall,
        ),
      ],
    );
  }

  List<Widget> _buildCorners() {
    const corner = 24.0;
    const width = 3.0;
    const color = AppColors.primary;

    return [
      // Top-left
      Positioned(
          top: 0, left: 0,
          child: Container(width: corner, height: width, color: color)),
      Positioned(
          top: 0, left: 0,
          child: Container(width: width, height: corner, color: color)),
      // Top-right
      Positioned(
          top: 0, right: 0,
          child: Container(width: corner, height: width, color: color)),
      Positioned(
          top: 0, right: 0,
          child: Container(width: width, height: corner, color: color)),
      // Bottom-left
      Positioned(
          bottom: 0, left: 0,
          child: Container(width: corner, height: width, color: color)),
      Positioned(
          bottom: 0, left: 0,
          child: Container(width: width, height: corner, color: color)),
      // Bottom-right
      Positioned(
          bottom: 0, right: 0,
          child: Container(width: corner, height: width, color: color)),
      Positioned(
          bottom: 0, right: 0,
          child: Container(width: width, height: corner, color: color)),
    ];
  }

  Widget _buildResultDisplay(Color color) {
    final isGranted = _result == _ScanResult.granted;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.15),
            border: Border.all(color: color, width: 3),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.5), blurRadius: 40),
            ],
          ),
          child: Icon(
            isGranted ? Icons.check_rounded : Icons.close_rounded,
            size: 72,
            color: color,
          ),
        )
            .animate()
            .scale(begin: const Offset(0.5, 0.5), duration: 300.ms)
            .fadeIn(),
        const SizedBox(height: 24),
        Text(
          _statusMessage,
          style: AppTextStyles.headlineMedium.copyWith(color: color),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          _lastScanned.length > 30
              ? '${_lastScanned.substring(0, 30)}...'
              : _lastScanned,
          style: AppTextStyles.mono,
        ),
      ],
    );
  }

  Widget _buildBottomPanel(Color statusColor) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _BottomAction(
            icon: Icons.keyboard_rounded,
            label: 'MANUAL',
            onTap: () => _showManualEntry(),
          ),
          _BottomAction(
            icon: Icons.qr_code_rounded,
            label: 'MI QR',
            onTap: () {},
          ),
          _BottomAction(
            icon: Icons.history_rounded,
            label: 'HISTORIAL',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  void _showManualEntry() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ManualEntrySheet(
        mode: _mode,
        onVerify: (value) async {
          setState(() {
            _isProcessing = true;
            _lastScanned = value;
          });

          // Determinar si es placa (ej. 3 letras y 4 números o similar) o cédula
          final isPlate = RegExp(r'^[A-Z]{3}\d{3,4}$').hasMatch(value) || value.length <= 8;
          final eventType = isPlate 
              ? (_mode == 'entry' ? 'Ingreso Vehicular' : 'Salida Vehicular')
              : (_mode == 'entry' ? 'Ingreso Peatonal' : 'Salida Peatonal');
          
          String personName = isPlate ? 'Vehículo Externo' : 'Persona Externa';
          String rank = isPlate ? 'Placa Manual' : 'Cédula Manual';
          String? errorMessage;
          bool isManualValid = true;
          bool isDuplicateState = false;

          if (!isPlate) {
            // Es una cédula, buscar si existe un usuario registrado con esa cédula
            final userQuery = await FirebaseFirestore.instance
                .collection('users')
                .where('cedula', isEqualTo: value)
                .limit(1)
                .get();
            if (userQuery.docs.isNotEmpty) {
              final doc = userQuery.docs.first;
              final d = doc.data();
              personName = d['display_name'] ?? 'Desconocido';
              rank = d['rank'] ?? '—';
              final movementState = d['movement_state'] ?? 'AFUERA';

              if (_mode == 'entry' && movementState == 'ADENTRO') {
                isManualValid = false;
                isDuplicateState = true;
                errorMessage = 'ERROR: Usuario ya se encuentra dentro de la instalación';
              } else if (_mode == 'exit' && movementState == 'AFUERA') {
                isManualValid = false;
                isDuplicateState = true;
                errorMessage = 'ERROR: Usuario ya se encuentra fuera de la instalación';
              } else {
                isManualValid = true;
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(doc.id)
                    .update({
                  'movement_state': _mode == 'entry' ? 'ADENTRO' : 'AFUERA',
                  'updated_at': FieldValue.serverTimestamp(),
                });
              }
            }
          }

          final accessResult = isManualValid ? 'granted' : 'denied';

          setState(() {
            _result = isManualValid ? _ScanResult.granted : _ScanResult.denied;
            if (isManualValid) {
              _statusMessage = '✓ REGISTRADO MANUALMENTE';
            } else {
              _statusMessage = errorMessage ?? '✗ ACCESO DENEGADO';
            }
          });

          if (!isDuplicateState) {
            final op = ref.read(currentUserProvider).valueOrNull;
            await _logAccess(
              personName: personName,
              rank: rank,
              eventType: eventType,
              accessResult: accessResult,
              vehiclePlate: isPlate ? value : null,
              operatorUid: op?.uid ?? '',
              operatorName: op?.displayName ?? 'Operador',
              operatorRole: op?.currentRole.toFirestoreString() ?? 'unknown',
              errorMessage: errorMessage,
            );
          }

          _resetTimer = Timer(const Duration(milliseconds: 2500), () {
            if (mounted) {
              setState(() {
                _result = _ScanResult.idle;
                _statusMessage = 'APUNTE AL CÓDIGO QR O PLACA';
                _lastScanned = '';
                _isProcessing = false;
              });
            }
          });
        },
      ),
    );
  }
}

// ── Línea de escaneo animada ──────────────────────────────
class _ScannerLine extends StatefulWidget {
  @override
  State<_ScannerLine> createState() => _ScannerLineState();
}

class _ScannerLineState extends State<_ScannerLine>
    with SingleTickerProviderStateMixin {
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
            top: _anim.value * 240,
            left: 0,
            right: 0,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.primary.withOpacity(0.8),
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

// ── Acción del panel inferior ────────────────────────────
class _BottomAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BottomAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 28),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.labelSmall),
          ],
        ),
      ),
    );
  }
}

// ── Sheet de entrada manual ───────────────────────────────
class _ManualEntrySheet extends StatefulWidget {
  final String mode;
  final Function(String val) onVerify;
  const _ManualEntrySheet({required this.mode, required this.onVerify});

  @override
  State<_ManualEntrySheet> createState() => _ManualEntrySheetState();
}

class _ManualEntrySheetState extends State<_ManualEntrySheet> {
  final _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('REGISTRO MANUAL', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 4),
          Text(
            widget.mode == 'entry' 
                ? 'Ingrese cédula o placa para registrar ENTRADA'
                : 'Ingrese cédula o placa para registrar SALIDA',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _ctrl,
            style: AppTextStyles.mono.copyWith(
              color: AppColors.textPrimary,
              fontSize: 18,
            ),
            decoration: const InputDecoration(
              labelText: 'Cédula / Placa',
              prefixIcon: Icon(Icons.badge_rounded, color: AppColors.textMuted),
            ),
            textCapitalization: TextCapitalization.characters,
            autofocus: true,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final text = _ctrl.text.trim().toUpperCase();
              if (text.isNotEmpty) {
                widget.onVerify(text);
              }
              Navigator.pop(context);
            },
            child: const Text('REGISTRAR PERMITIDO'),
          ),
        ],
      ),
    );
  }
}
