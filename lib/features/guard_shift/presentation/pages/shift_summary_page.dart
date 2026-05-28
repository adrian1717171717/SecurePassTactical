// lib/features/guard_shift/presentation/pages/shift_summary_page.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ShiftSummaryPage extends ConsumerStatefulWidget {
  const ShiftSummaryPage({super.key});

  @override
  ConsumerState<ShiftSummaryPage> createState() => _ShiftSummaryPageState();
}

class _ShiftSummaryPageState extends ConsumerState<ShiftSummaryPage> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _logs = [];
  List<Map<String, dynamic>> _bitacora = [];
  List<Map<String, dynamic>> _pendingVisitors = [];

  @override
  void initState() {
    super.initState();
    _fetchGuardData();
  }

  Future<void> _fetchGuardData() async {
    setState(() => _isLoading = true);
    try {
      // Fetch Access Logs
      final logsSnap = await FirebaseFirestore.instance
          .collection('access_logs')
          .orderBy('timestamp', descending: true)
          .limit(200)
          .get();

      // Fetch Bitacora
      final bitacoraSnap = await FirebaseFirestore.instance
          .collection('novedades_bitacora')
          .orderBy('timestamp', descending: false)
          .limit(200)
          .get();

      // Fetch Pending Visitors
      final visitorsSnap = await FirebaseFirestore.instance
          .collection('visitors')
          .where('status', isEqualTo: 'inside')
          .get();

      setState(() {
        _logs = logsSnap.docs.map((doc) => doc.data()).toList();
        _bitacora = bitacoraSnap.docs.map((doc) => doc.data()).toList();
        _pendingVisitors = visitorsSnap.docs.map((doc) => doc.data()).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos del turno: $e')),
        );
      }
    }
  }

  Future<void> _generatePdfReport() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    final officerName = user?.displayName ?? 'Oficial de Guardia';
    final officerRank = user?.rank ?? '—';
    final dateStr = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final shiftId = 'GRD-${DateFormat('yyyyMMdd').format(DateTime.now())}-001';

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          // ── MEMBRETE MILITAR ──────────────────────────────────────
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  'ESCUELA MILITAR',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'COMPAÑÍA DE CONTROL DE ACCESOS Y GARITAS',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'PARTE DIARIO DE PREVENCIÓN Y SEGURIDAD',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'ID TURNO: $shiftId  |  FECHA: $dateStr',
                  style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // ── PLANA MAYOR DE GUARDIA ────────────────────────────────
          pw.Text('1. PLANA DE GUARDIA Y PREVENCIÓN', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.Divider(thickness: 1),
          pw.SizedBox(height: 4),
          pw.Text('Oficial de Guardia: $officerName ($officerRank)', style: pw.TextStyle(fontSize: 10)),
          pw.Text('Lugar de Servicio: Prevención y Garita Principal Norte', style: pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 20),

          // ── ESTADÍSTICAS DEL TURNO ───────────────────────────────
          pw.Text('2. RESUMEN ESTADÍSTICO DE ACCESOS', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.Divider(thickness: 1),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headers: ['Categoría de Acceso', 'Ingresos Registrados', 'Salidas Registradas'],
            data: [
              ['Peatonales Militar', _countLogs('Peatonal', 'Ingreso').toString(), _countLogs('Peatonal', 'Salida').toString()],
              ['Vehiculares Autorizados', _countLogs('Vehicular', 'Ingreso').toString(), _countLogs('Vehicular', 'Salida').toString()],
              ['Invitados / Civiles', _pendingVisitors.length.toString(), '—'],
            ],
          ),
          pw.SizedBox(height: 20),

          // ── LIBRO DE IMAGINARIA (NOVEDADES CRONOLÓGICAS) ──────────
          pw.Text('3. NOVEDADES REGISTRADAS EN BITÁCORA (IMAGINARIA)', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.Divider(thickness: 1),
          pw.SizedBox(height: 6),
          if (_bitacora.isEmpty)
            pw.Text('Sin novedades registradas durante el turno del servicio.', style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic))
          else
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headers: ['Hora', 'Autor/Grado', 'Descripción de la Novedad/Suceso'],
              data: _bitacora.map((item) {
                final ts = (item['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                final time = DateFormat('HH:mm').format(ts);
                final author = item['author_name'] ?? 'Guardia';
                final desc = item['description'] ?? '';
                return [time, author, desc];
              }).toList(),
            ),
          pw.SizedBox(height: 20),

          // ── VISITANTES PENDIENTES (ALERTA DE SEGURIDAD) ───────────
          pw.Text('4. ADVERTENCIA: VISITANTES PENDIENTES DE SALIDA', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.Divider(thickness: 1),
          pw.SizedBox(height: 6),
          if (_pendingVisitors.isEmpty)
            pw.Text('Ninguno. Todos los invitados y personal civil registraron salida correctamente.', style: pw.TextStyle(fontSize: 10, color: PdfColors.green))
          else
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headers: ['Nombre de Invitado', 'Cédula', 'Vehículo / Placa', 'Anfitrión / Motivo', 'Hora de Entrada'],
              data: _pendingVisitors.map((item) {
                final name = item['full_name'] ?? '—';
                final ci = item['cedula'] ?? '—';
                final plate = item['vehicle_plate'] ?? 'Peatón';
                final host = item['host_name'] ?? '—';
                final ts = (item['entry_timestamp'] as Timestamp?)?.toDate();
                final entryTime = ts != null ? DateFormat('HH:mm').format(ts) : '—';
                return [name, ci, plate, host, entryTime];
              }).toList(),
            ),
          pw.SizedBox(height: 35),

          // ── BLOQUE DE FIRMAS ──────────────────────────────────────
          pw.Center(
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: [
                pw.Column(
                  children: [
                    pw.Container(width: 140, height: 1, color: PdfColors.black),
                    pw.SizedBox(height: 4),
                    pw.Text('OFICIAL SALIENTE', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.Text('$officerName', style: pw.TextStyle(fontSize: 9)),
                    pw.Text('$officerRank', style: pw.TextStyle(fontSize: 8)),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Container(width: 140, height: 1, color: PdfColors.black),
                    pw.SizedBox(height: 4),
                    pw.Text('OFICIAL ENTRANTE', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.Text('FIRMA Y GRADO', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'PARTE_DIARIO_PREVENCION_$shiftId.pdf',
    );
  }

  int _countLogs(String type, String event) {
    return _logs.where((l) {
      final et = (l['event_type'] as String? ?? '').toLowerCase();
      return et.contains(type.toLowerCase()) && et.contains(event.toLowerCase());
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final shiftId = 'GRD-${DateFormat('yyyyMMdd').format(DateTime.now())}-001';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('PARTE DE GUARDIA', style: AppTextStyles.headlineMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cabecera militar de confirmación
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.verified_user_rounded, color: AppColors.statusGranted, size: 44),
                        const SizedBox(height: 12),
                        Text(
                          'SERVICIO DE GUARDIA CERRADO',
                          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.statusGranted, letterSpacing: 1.5),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Turno: $shiftId',
                          style: AppTextStyles.mono.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Resumen de Estadísticas
                  Text('RESUMEN DE AUDITORÍA', style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryStatCard(
                          label: 'Ingresos Peatonales',
                          value: _countLogs('Peatonal', 'Ingreso').toString(),
                          color: AppColors.statusGranted,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SummaryStatCard(
                          label: 'Salidas Peatonales',
                          value: _countLogs('Peatonal', 'Salida').toString(),
                          color: AppColors.statusDenied,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryStatCard(
                          label: 'Vehículos Dentro',
                          value: _countLogs('Vehicular', 'Ingreso').toString(),
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SummaryStatCard(
                          label: 'Visitas Pendientes',
                          value: _pendingVisitors.length.toString(),
                          color: AppColors.statusPending,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Alerta de Visitantes
                  if (_pendingVisitors.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.statusPending.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.statusPending.withOpacity(0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: AppColors.statusPending, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'ALERTA DE SEGURIDAD',
                                style: AppTextStyles.labelMedium.copyWith(color: AppColors.statusPending, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Existen ${_pendingVisitors.length} visitantes que no han registrado salida al cierre. Quedarán auditados en el reporte.',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // Botón de Generación PDF
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
                      label: Text('GENERAR & IMPRIMIR PARTE PDF', style: AppTextStyles.buttonPrimary),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.statusPending,
                      ),
                      onPressed: _generatePdfReport,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SummaryStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryStatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.headlineMedium.copyWith(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
