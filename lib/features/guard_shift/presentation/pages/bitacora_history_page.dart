// lib/features/guard_shift/presentation/pages/bitacora_history_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';
import '../../../dashboard/presentation/widgets/tactical_app_bar.dart';

class BitacoraHistoryPage extends ConsumerStatefulWidget {
  const BitacoraHistoryPage({super.key});

  @override
  ConsumerState<BitacoraHistoryPage> createState() => _BitacoraHistoryPageState();
}

class _BitacoraHistoryPageState extends ConsumerState<BitacoraHistoryPage> {
  DateTime _selectedDate = DateTime.now();
  String _filterType = 'all'; // 'all', 'novedad', 'sin_novedad'
  bool _isLoading = false;
  List<Map<String, dynamic>> _entries = [];

  @override
  void initState() {
    super.initState();
    _fetchBitacora();
  }

  Future<void> _fetchBitacora() async {
    setState(() => _isLoading = true);
    try {
      final start = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final end = start.add(const Duration(days: 1));

      final snap = await FirebaseFirestore.instance
          .collection('novedades_bitacora')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('timestamp', isLessThan: Timestamp.fromDate(end))
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        _entries = snap.docs.map((d) => d.data()).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar historial: $e'), backgroundColor: AppColors.alertRed),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surfaceElevated,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
      _fetchBitacora();
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy');

    final filtered = _entries.where((e) {
      final isNov = e['is_novedad'] as bool? ?? false;
      if (_filterType == 'novedad') return isNov;
      if (_filterType == 'sin_novedad') return !isNov;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: TacticalAppBar(
        title: 'HISTORIAL DE BITÁCORA',
        showBackButton: true,
      ),
      body: Column(
        children: [
          // ── Filtros y Selectores ──────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.surfaceBorder)),
            ),
            child: Row(
              children: [
                // Selector de Fecha
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.surfaceBorder),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Text(df.format(_selectedDate), style: AppTextStyles.bodyMedium),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Selector de Filtro de Novedad
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.surfaceBorder),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _filterType,
                    dropdownColor: AppColors.surface,
                    underline: const SizedBox(),
                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('TODOS')),
                      DropdownMenuItem(value: 'novedad', child: Text('SÓLO NOVEDADES')),
                      DropdownMenuItem(value: 'sin_novedad', child: Text('SÓLO SIN NOVEDAD')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _filterType = val);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── Lista de Novedades ───────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_outlined, size: 48, color: AppColors.textMuted.withOpacity(0.3)),
                            const SizedBox(height: 16),
                            Text('Sin registros para esta fecha y filtro', style: AppTextStyles.bodyMedium),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final data = filtered[index];
                          final ts = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                          final timeStr = DateFormat('HH:mm').format(ts);
                          final desc = data['description'] as String? ?? '';
                          final isNov = data['is_novedad'] as bool? ?? false;
                          final author = data['author_name'] as String? ?? '—';
                          final rank = data['author_rank'] as String? ?? '—';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            color: AppColors.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isNov ? AppColors.alertRed.withOpacity(0.4) : AppColors.surfaceBorder,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isNov 
                                              ? AppColors.alertRed.withOpacity(0.1) 
                                              : AppColors.statusGranted.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          isNov ? 'NOVEDAD' : 'SIN NOVEDAD',
                                          style: AppTextStyles.labelSmall.copyWith(
                                            color: isNov ? AppColors.alertRed : AppColors.statusGranted,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 9,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '[$timeStr]',
                                        style: AppTextStyles.mono.copyWith(color: AppColors.textMuted),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '$author ($rank)',
                                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    desc,
                                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.white, height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                          ).animate(delay: (index * 30).ms).fadeIn().slideX(begin: 0.03);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
