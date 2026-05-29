// lib/features/guard_shift/presentation/pages/bitacora_filter_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';
import '../../../../core/services/audit_service.dart';
import '../../../../core/services/pdf_report_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/widgets/tactical_app_bar.dart';

// ── Filter state ─────────────────────────────────────────────────────────────

enum _NovedadFilter { all, soloNovedad, sinNovedad }

class _FilterState {
  final DateTime startDate;
  final DateTime endDate;
  final _NovedadFilter novedadFilter;
  final String searchText;

  const _FilterState({
    required this.startDate,
    required this.endDate,
    required this.novedadFilter,
    required this.searchText,
  });

  _FilterState copyWith({
    DateTime? startDate,
    DateTime? endDate,
    _NovedadFilter? novedadFilter,
    String? searchText,
  }) {
    return _FilterState(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      novedadFilter: novedadFilter ?? this.novedadFilter,
      searchText: searchText ?? this.searchText,
    );
  }
}

// ── Page ─────────────────────────────────────────────────────────────────────

/// Página avanzada de bitácora con filtros completos:
/// - Rango de fecha (inicio y fin)
/// - Tipo de novedad (todos / novedad / sin novedad)
/// - Búsqueda por texto (autor o descripción)
/// - Exportación PDF
class BitacoraFilterPage extends ConsumerStatefulWidget {
  const BitacoraFilterPage({super.key});

  @override
  ConsumerState<BitacoraFilterPage> createState() => _BitacoraFilterPageState();
}

class _BitacoraFilterPageState extends ConsumerState<BitacoraFilterPage> {
  final _searchController = TextEditingController();
  late _FilterState _filter;
  bool _isLoading = false;
  bool _isExporting = false;
  List<Map<String, dynamic>> _entries = [];

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _filter = _FilterState(
      startDate: DateTime(today.year, today.month, today.day),
      endDate: DateTime(today.year, today.month, today.day, 23, 59, 59),
      novedadFilter: _NovedadFilter.all,
      searchText: '',
    );
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('novedades_bitacora')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(_filter.startDate))
          .where('timestamp',
              isLessThanOrEqualTo: Timestamp.fromDate(_filter.endDate))
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
          SnackBar(
            content: Text('Error al cargar: $e'),
            backgroundColor: AppColors.alertRed,
          ),
        );
      }
    }
  }

  Future<void> _selectDate({required bool isStart}) async {
    final initial = isStart ? _filter.startDate : _filter.endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2025),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.surfaceElevated,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (picked == null || !mounted) return;

    setState(() {
      if (isStart) {
        _filter = _filter.copyWith(
          startDate: DateTime(picked.year, picked.month, picked.day),
        );
      } else {
        _filter = _filter.copyWith(
          endDate: DateTime(picked.year, picked.month, picked.day, 23, 59, 59),
        );
      }
    });
    _fetchData();
  }

  List<Map<String, dynamic>> get _filtered {
    return _entries.where((e) {
      // Novedad filter
      final isNov = e['is_novedad'] as bool? ?? false;
      if (_filter.novedadFilter == _NovedadFilter.soloNovedad && !isNov) {
        return false;
      }
      if (_filter.novedadFilter == _NovedadFilter.sinNovedad && isNov) {
        return false;
      }

      // Text search (author or description)
      if (_filter.searchText.isNotEmpty) {
        final q = _filter.searchText.toLowerCase();
        final desc = (e['description'] as String? ?? '').toLowerCase();
        final author = (e['author_name'] as String? ?? '').toLowerCase();
        if (!desc.contains(q) && !author.contains(q)) return false;
      }

      return true;
    }).toList();
  }

  Future<void> _exportPdf() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isExporting = true);

    try {
      final df = DateFormat('dd/MM/yyyy');
      final entries = _filtered;

      final rows = entries.map((e) {
        final ts = (e['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        return {
          'timestamp': DateFormat('HH:mm').format(ts),
          'dateGroup': DateFormat('dd/MM/yyyy').format(ts),
          'type': (e['is_novedad'] as bool? ?? false) ? 'NOVEDAD' : 'SIN NOV.',
          'author': '${e['author_name'] ?? ''} (${e['author_rank'] ?? ''})',
          'description': e['description'] as String? ?? '',
        };
      }).toList();

      await PdfReportService.generateBitacoraReport(
        title: 'HISTORIAL DE BITÁCORA — ${df.format(_filter.startDate)} al ${df.format(_filter.endDate)}',
        rows: rows,
        generatedBy: user.displayName,
        generatedByRank: user.rank,
      );

      // Audit
      await AuditService.log(
        action: 'bitacora_export',
        module: 'bitacora',
        actorUid: user.uid,
        actorName: user.displayName,
        actorRole: user.currentRole.name,
        description: 'Exportación PDF: ${entries.length} entradas, '
            '${df.format(_filter.startDate)} - ${df.format(_filter.endDate)}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'PDF generado — ${entries.length} entradas exportadas',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textPrimary),
            ),
            backgroundColor: AppColors.statusGranted.withOpacity(0.8),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar: $e'),
            backgroundColor: AppColors.alertRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: TacticalAppBar(
        title: 'BITÁCORA AVANZADA',
        showBackButton: true,
        actions: [
          // Export PDF button
          _isExporting
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  ),
                )
              : IconButton(
                  onPressed: filtered.isNotEmpty ? _exportPdf : null,
                  icon: Icon(
                    Icons.picture_as_pdf_rounded,
                    color: filtered.isNotEmpty
                        ? AppColors.primary
                        : AppColors.textMuted,
                    size: 22,
                  ),
                  tooltip: 'Exportar PDF',
                ),
        ],
      ),
      body: Column(
        children: [
          // ── Filter bar ──────────────────────────────────────────
          _FilterBar(
            filter: _filter,
            onStartDateTap: () => _selectDate(isStart: true),
            onEndDateTap: () => _selectDate(isStart: false),
            onNovedadFilterChanged: (val) {
              setState(() => _filter = _filter.copyWith(novedadFilter: val));
            },
            onSearchChanged: (val) {
              setState(
                  () => _filter = _filter.copyWith(searchText: val));
            },
            searchController: _searchController,
          ),

          // ── Summary bar ─────────────────────────────────────────
          _SummaryBar(
            totalEntries: filtered.length,
            novedadCount:
                filtered.where((e) => e['is_novedad'] == true).length,
            sinNovedadCount:
                filtered.where((e) => !(e['is_novedad'] as bool? ?? false)).length,
          ),

          // ── List ────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? _EmptyState(
                        hasFilters: _filter.searchText.isNotEmpty ||
                            _filter.novedadFilter != _NovedadFilter.all,
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        children: _buildGroupedList(filtered),
                      ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGroupedList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return [];
    
    final List<Widget> widgets = [];
    String? currentDate;
    
    for (int i = 0; i < items.length; i++) {
      final data = items[i];
      final ts = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
      final dateStr = DateFormat('dd/MM/yyyy').format(ts);
      
      if (currentDate != dateStr) {
        currentDate = dateStr;
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            ' FECHA: $currentDate',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.primary,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ));
      }
      
      widgets.add(_BitacoraEntryCard(data: data, index: i));
    }
    
    return widgets;
  }
}

// ── Filter bar ───────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final _FilterState filter;
  final VoidCallback onStartDateTap;
  final VoidCallback onEndDateTap;
  final ValueChanged<_NovedadFilter> onNovedadFilterChanged;
  final ValueChanged<String> onSearchChanged;
  final TextEditingController searchController;

  const _FilterBar({
    required this.filter,
    required this.onStartDateTap,
    required this.onEndDateTap,
    required this.onNovedadFilterChanged,
    required this.onSearchChanged,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yy');

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border:
            Border(bottom: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Date range row ───────────────────────────────────
          Row(
            children: [
              _DateChip(
                icon: Icons.calendar_today_rounded,
                label: 'Desde: ${df.format(filter.startDate)}',
                onTap: onStartDateTap,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward_rounded,
                    size: 16, color: AppColors.textMuted),
              ),
              _DateChip(
                icon: Icons.event_rounded,
                label: 'Hasta: ${df.format(filter.endDate)}',
                onTap: onEndDateTap,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Type filter chips ────────────────────────────────
          Row(
            children: [
              _FilterChip(
                label: 'TODOS',
                selected:
                    filter.novedadFilter == _NovedadFilter.all,
                onTap: () => onNovedadFilterChanged(_NovedadFilter.all),
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'NOVEDAD',
                selected:
                    filter.novedadFilter == _NovedadFilter.soloNovedad,
                onTap: () =>
                    onNovedadFilterChanged(_NovedadFilter.soloNovedad),
                color: AppColors.alertRed,
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'SIN NOVEDAD',
                selected:
                    filter.novedadFilter == _NovedadFilter.sinNovedad,
                onTap: () =>
                    onNovedadFilterChanged(_NovedadFilter.sinNovedad),
                color: AppColors.statusGranted,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Search field ─────────────────────────────────────
          SizedBox(
            height: 40,
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Buscar por autor o descripción…',
                hintStyle: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 18, color: AppColors.textMuted),
                suffixIcon: searchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          searchController.clear();
                          onSearchChanged('');
                        },
                        child: const Icon(Icons.close_rounded,
                            size: 16, color: AppColors.textMuted),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceElevated,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                      color: AppColors.surfaceBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                      color: AppColors.surfaceBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Summary bar ──────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  final int totalEntries;
  final int novedadCount;
  final int sinNovedadCount;

  const _SummaryBar({
    required this.totalEntries,
    required this.novedadCount,
    required this.sinNovedadCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surfaceElevated,
      child: Row(
        children: [
          _SummaryChip(
            label: '$totalEntries registros',
            color: AppColors.textSecondary,
          ),
          const Spacer(),
          _SummaryChip(
            label: '🔴 $novedadCount novedades',
            color: AppColors.alertRed,
          ),
          const SizedBox(width: 12),
          _SummaryChip(
            label: '🟢 $sinNovedadCount sin novedad',
            color: AppColors.statusGranted,
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final Color color;

  const _SummaryChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.labelSmall.copyWith(
        color: color,
        fontSize: 11,
        letterSpacing: 0.5,
      ),
    );
  }
}

// ── Entry card ───────────────────────────────────────────────────────────────

class _BitacoraEntryCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final int index;

  const _BitacoraEntryCard({required this.data, required this.index});

  @override
  Widget build(BuildContext context) {
    final ts = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    final timeStr = DateFormat('HH:mm').format(ts);
    final dateStr = DateFormat('dd/MM/yy').format(ts);
    final isNovedad = data['is_novedad'] as bool? ?? false;
    final description = data['description'] as String? ?? '';
    final authorName = data['author_name'] as String? ?? '—';
    final authorRank = data['author_rank'] as String? ?? '—';

    final chipColor =
        isNovedad ? AppColors.alertRed : AppColors.statusGranted;
    final chipLabel = isNovedad ? 'NOVEDAD' : 'SIN NOVEDAD';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isNovedad
              ? AppColors.alertRed.withOpacity(0.35)
              : AppColors.surfaceBorder,
          width: isNovedad ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ───────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: chipColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                    border:
                        Border.all(color: chipColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    chipLabel,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: chipColor,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Timestamp
                Text(
                  '[$dateStr $timeStr]',
                  style: AppTextStyles.mono
                      .copyWith(color: AppColors.textMuted, fontSize: 11),
                ),

                const Spacer(),

                // Author
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      authorName,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      authorRank,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Description ──────────────────────────────────
            Text(
              description,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                height: 1.5,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: (index * 25).ms)
        .fadeIn(duration: 250.ms)
        .slideX(begin: 0.03, end: 0);
  }
}

// ── Helper widgets ───────────────────────────────────────────────────────────

class _DateChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DateChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.surfaceBorder),
            borderRadius: BorderRadius.circular(8),
            color: AppColors.surfaceElevated,
          ),
          child: Row(
            children: [
              Icon(icon, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : AppColors.surfaceBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            fontSize: 10,
            color: selected ? color : AppColors.textMuted,
            fontWeight:
                selected ? FontWeight.bold : FontWeight.normal,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasFilters;

  const _EmptyState({required this.hasFilters});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilters
                ? Icons.filter_alt_off_rounded
                : Icons.assignment_outlined,
            size: 56,
            color: AppColors.textMuted.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters
                ? 'Ningún registro coincide con los filtros'
                : 'Sin registros en este rango de fechas',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          if (hasFilters) ...[
            const SizedBox(height: 8),
            Text(
              'Modifica los filtros para ver más resultados',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textMuted.withOpacity(0.6)),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
