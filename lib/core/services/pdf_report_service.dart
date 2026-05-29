// lib/core/services/pdf_report_service.dart
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

class PdfReportService {
  static final _df = DateFormat('dd/MM/yyyy HH:mm');
  static final _sfDate = DateFormat('dd/MM/yyyy');

  // ── Download / Print ──────────────────────────────────────────────────────

  /// Genera bytes PDF y lanza la descarga o pantalla de impresión según la plataforma.
  static Future<void> _saveOrPrint(Uint8List bytes, String filename) async {
    if (kIsWeb) {
      await Printing.sharePdf(bytes: bytes, filename: filename);
    } else {
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    }
  }

  // ── Access report ─────────────────────────────────────────────────────────

  /// Genera y descarga un reporte de accesos.
  static Future<void> generateAccessReport({
    required String title,
    required List<Map<String, dynamic>> logs,
    required String operatorName,
    required String operatorRole,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final bytes = await _buildAccessReportBytes(
      title: title,
      logs: logs,
      operatorName: operatorName,
      operatorRole: operatorRole,
      startDate: startDate,
      endDate: endDate,
    );
    final filename =
        'reporte_accesos_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';
    await _saveOrPrint(bytes, filename);
  }

  static Future<Uint8List> buildAccessReportBytes({
    required String title,
    required List<Map<String, dynamic>> logs,
    required String operatorName,
    required String operatorRole,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return _buildAccessReportBytes(
      title: title,
      logs: logs,
      operatorName: operatorName,
      operatorRole: operatorRole,
      startDate: startDate,
      endDate: endDate,
    );
  }

  static Future<Uint8List> _buildAccessReportBytes({
    required String title,
    required List<Map<String, dynamic>> logs,
    required String operatorName,
    required String operatorRole,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _pdfHeader('REPORTE OFICIAL DE ACCESOS'),
          pw.SizedBox(height: 16),
          pw.Text(title,
              style:
                  pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(
              'Período: ${_sfDate.format(startDate)} al ${_sfDate.format(endDate)}',
              style: const pw.TextStyle(fontSize: 11)),
          pw.Text('Operador: $operatorName ($operatorRole)',
              style: const pw.TextStyle(fontSize: 11)),
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            context: context,
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.blueGrey800),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: const pw.TextStyle(fontSize: 10),
            data: <List<String>>[
              ['FECHA/HORA', 'TIPO', 'NOMBRES', 'JERARQUÍA', 'PLACA', 'ESTADO'],
              ...logs.map((l) {
                final ts = l['timestamp'] is DateTime
                    ? l['timestamp'] as DateTime
                    : DateTime.now();
                final name = l['person_name'] as String? ?? '—';
                final cedula = l['cedula'] as String? ?? '';
                final personDisplay =
                    cedula.isNotEmpty ? '$name\nC.I. $cedula' : name;
                final rank = l['rank'] as String? ?? '—';
                final unit = l['unit'] as String? ?? '';
                final rankDisplay =
                    unit.isNotEmpty ? '$rank\n$unit' : rank;
                final plate = l['vehicle_plate'] as String? ?? '—';
                final type = l['event_type'] as String? ?? '—';
                final result = l['access_result'] == 'granted'
                    ? 'APROBADO'
                    : 'DENEGADO';
                return [_df.format(ts), type, personDisplay, rankDisplay, plate, result];
              }),
            ],
          ),
        ],
        footer: _pageFooter,
      ),
    );

    return pdf.save();
  }

  // ── Bitacora report ───────────────────────────────────────────────────────

  /// Genera y descarga un PDF de bitácora con filtros aplicados.
  static Future<void> generateBitacoraReport({
    required String title,
    required List<Map<String, dynamic>> rows,
    required String generatedBy,
    required String generatedByRank,
  }) async {
    final bytes = await _buildBitacoraBytes(
      title: title,
      rows: rows,
      generatedBy: generatedBy,
      generatedByRank: generatedByRank,
    );
    final filename =
        'bitacora_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';
    await _saveOrPrint(bytes, filename);
  }

  static Future<Uint8List> _buildBitacoraBytes({
    required String title,
    required List<Map<String, dynamic>> rows,
    required String generatedBy,
    required String generatedByRank,
  }) async {
    final pdf = pw.Document();

    // Count totals
    final novedadCount = rows.where((r) => r['type'] == 'NOVEDAD').length;
    final sinNovedadCount = rows.length - novedadCount;

    // Group rows by dateGroup
    final Map<String, List<Map<String, dynamic>>> groupedRows = {};
    for (var r in rows) {
      final dateGroup = r['dateGroup'] as String? ?? 'Desconocida';
      if (!groupedRows.containsKey(dateGroup)) {
        groupedRows[dateGroup] = [];
      }
      groupedRows[dateGroup]!.add(r);
    }

    final List<pw.Widget> contentWidgets = [
      _pdfHeader('HISTORIAL DE BITÁCORA'),
      pw.SizedBox(height: 16),
      pw.Text(title, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 4),
      pw.Text('Generado por: $generatedBy — $generatedByRank', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
      pw.Text('Total registros: ${rows.length}   |   Novedades: $novedadCount   |   Sin novedad: $sinNovedadCount', style: const pw.TextStyle(fontSize: 11)),
      pw.SizedBox(height: 18),
    ];

    groupedRows.forEach((date, dailyRows) {
      contentWidgets.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(top: 12, bottom: 6),
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          color: PdfColors.grey200,
          child: pw.Text('FECHA: $date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
        ),
      );
      
      contentWidgets.add(
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
          cellAlignment: pw.Alignment.centerLeft,
          cellStyle: const pw.TextStyle(fontSize: 9),
          columnWidths: {
            0: const pw.FixedColumnWidth(60),
            1: const pw.FixedColumnWidth(55),
            2: const pw.FixedColumnWidth(90),
            3: const pw.FlexColumnWidth(),
          },
          data: <List<String>>[
            ['HORA', 'TIPO', 'AUTOR', 'DESCRIPCIÓN'],
            ...dailyRows.map((r) => [
                  r['timestamp'] as String? ?? '',
                  r['type'] as String? ?? '',
                  r['author'] as String? ?? '',
                  r['description'] as String? ?? '',
                ]),
          ],
        ),
      );
    });

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => contentWidgets,
        footer: _pageFooter,
      ),
    );

    return pdf.save();
  }

  // ── Shared builders ───────────────────────────────────────────────────────

  static pw.Widget _pdfHeader(String subtitle) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('SECURPASS TACTICAL',
                style: pw.TextStyle(
                    fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Text(subtitle,
                style: const pw.TextStyle(
                    fontSize: 11, color: PdfColors.grey700)),
          ],
        ),
        pw.Text(
          'Generado: ${_df.format(DateTime.now())}',
          style:
              const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
      ],
    );
  }

  static pw.Widget Function(pw.Context) get _pageFooter =>
      (context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Página ${context.pageNumber} de ${context.pagesCount}',
              style:
                  const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
            ),
          );
}
