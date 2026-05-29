// lib/features/alerts/presentation/pages/alerts_inbox_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';
import '../../../auth/domain/entities/app_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class AlertsInboxPage extends ConsumerStatefulWidget {
  const AlertsInboxPage({super.key});

  @override
  ConsumerState<AlertsInboxPage> createState() => _AlertsInboxPageState();
}

class _AlertsInboxPageState extends ConsumerState<AlertsInboxPage> {
  String _filter = 'all'; // all, unread, incident, novedad

  @override
  Widget build(BuildContext context) {
    final alertsStream = FirebaseFirestore.instance
        .collection('alerts')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.alertRed,
              ),
            )
                .animate(onPlay: (c) => c.repeat())
                .scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.2, 1.2),
                    duration: 800.ms)
                .then()
                .scale(
                    begin: const Offset(1.2, 1.2),
                    end: const Offset(0.8, 0.8),
                    duration: 800.ms),
            const SizedBox(width: 10),
            Text('ALERTAS VIP', style: AppTextStyles.headlineMedium),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: alertsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final allDocs = snapshot.data?.docs ?? [];
          
          final docs = allDocs.where((doc) {
            final d = doc.data();
            if (_filter == 'unread') return d['is_read'] == false;
            if (_filter == 'incident') return d['type'] == 'security_incident' || d['type'] == 'safarancho';
            if (_filter == 'novedad') return d['type'] == 'part_novedad';
            return true;
          }).toList();

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_off_rounded, size: 48, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  Text('No hay alertas activas', style: AppTextStyles.bodyMedium),
                ],
              ),
            );
          }
          
          return Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _FilterChip(label: 'TODAS', isSelected: _filter == 'all', onTap: () => setState(() => _filter = 'all')),
                    const SizedBox(width: 8),
                    _FilterChip(label: 'NO LEÍDAS', isSelected: _filter == 'unread', onTap: () => setState(() => _filter = 'unread')),
                    const SizedBox(width: 8),
                    _FilterChip(label: 'INCIDENTES', isSelected: _filter == 'incident', color: AppColors.alertRed, onTap: () => setState(() => _filter = 'incident')),
                    const SizedBox(width: 8),
                    _FilterChip(label: 'NOVEDADES', isSelected: _filter == 'novedad', color: AppColors.statusPending, onTap: () => setState(() => _filter = 'novedad')),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final d = doc.data();
                    final ts = (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                    return _AlertTile(
                      id: doc.id,
                      type: d['type'] ?? 'general_notice',
                      sender: d['sender'] ?? 'Anónimo',
                      message: d['message'] ?? '',
                      time: ts,
                      isRead: d['is_read'] ?? true,
                      status: d['status'] ?? 'active',
                    ).animate().fadeIn().slideX(begin: -0.05);
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewAlertDialog(context),
        backgroundColor: AppColors.alertRed,
        icon: const Icon(Icons.warning_amber_rounded),
        label: Text('DAR PARTE', style: AppTextStyles.buttonPrimary),
      ),
    );
  }

  void _showNewAlertDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _NewAlertSheet(),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.2) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? activeColor : AppColors.surfaceBorder),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: isSelected ? activeColor : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _AlertTile extends ConsumerWidget {
  final String id;
  final String type;
  final String sender;
  final String message;
  final DateTime time;
  final bool isRead;
  final String status;

  const _AlertTile({
    required this.id,
    required this.type,
    required this.sender,
    required this.message,
    required this.time,
    required this.isRead,
    required this.status,
  });

  Color get _typeColor {
    return switch (type) {
      'vip_entry_inbound' => AppColors.statusPending,
      'security_incident' => AppColors.alertRed,
      'part_novedad' => AppColors.statusDenied,
      'safarancho' => AppColors.alertRed,
      _ => AppColors.primary,
    };
  }

  IconData get _typeIcon {
    return switch (type) {
      'vip_entry_inbound' => Icons.star_rounded,
      'security_incident' => Icons.warning_rounded,
      'part_novedad' => Icons.report_problem_rounded,
      'safarancho' => Icons.campaign_rounded,
      _ => Icons.notifications_rounded,
    };
  }

  String get _timeStr {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    return '${time.day}/${time.month}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final canManage = user != null && user.currentRole.canApproveVehicles; // Admin, Director can archive/delete

    return Container(
      decoration: BoxDecoration(
        color: isRead ? AppColors.surface : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRead ? AppColors.surfaceBorder : _typeColor.withOpacity(0.4),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _typeColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(_typeIcon, color: _typeColor, size: 22),
        ),
        title: Text(sender, style: AppTextStyles.labelLarge),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(message,
                style: AppTextStyles.bodySmall.copyWith(height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_timeStr, style: AppTextStyles.labelSmall),
                if (!isRead) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _typeColor,
                    ),
                  ),
                ],
              ],
            ),
            if (canManage) ...[
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted),
                color: AppColors.surface,
                onSelected: (action) async {
                  if (action == 'read') {
                    await FirebaseFirestore.instance.collection('alerts').doc(id).update({'is_read': true});
                  } else if (action == 'archive') {
                    await FirebaseFirestore.instance.collection('alerts').doc(id).update({'status': 'archived'});
                  } else if (action == 'delete') {
                    await FirebaseFirestore.instance.collection('alerts').doc(id).delete();
                  }
                },
                itemBuilder: (_) => [
                  if (!isRead)
                    const PopupMenuItem(
                      value: 'read',
                      child: Row(
                        children: [
                          Icon(Icons.mark_email_read_rounded, size: 18, color: AppColors.statusGranted),
                          SizedBox(width: 8),
                          Text('Marcar leído'),
                        ],
                      ),
                    ),
                  if (status != 'archived')
                    const PopupMenuItem(
                      value: 'archive',
                      child: Row(
                        children: [
                          Icon(Icons.archive_rounded, size: 18, color: AppColors.statusPending),
                          SizedBox(width: 8),
                          Text('Archivar'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_forever_rounded, size: 18, color: AppColors.alertRed),
                        SizedBox(width: 8),
                        Text('Eliminar'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NewAlertSheet extends ConsumerStatefulWidget {
  const _NewAlertSheet();

  @override
  ConsumerState<_NewAlertSheet> createState() => _NewAlertSheetState();
}

class _NewAlertSheetState extends ConsumerState<_NewAlertSheet> {
  String _selectedType = 'part_novedad';
  final _msgCtrl = TextEditingController();
  bool _isSending = false;

  final _alertTypes = [
    {'value': 'vip_entry_inbound', 'label': 'VIP Entrante', 'icon': Icons.star_rounded},
    {'value': 'security_incident', 'label': 'Incidente de Seguridad', 'icon': Icons.warning_rounded},
    {'value': 'part_novedad', 'label': 'Novedad', 'icon': Icons.report_problem_rounded},
    {'value': 'safarancho', 'label': 'Safaranchos / Alarma General', 'icon': Icons.campaign_rounded},
    {'value': 'general_notice', 'label': 'Aviso General', 'icon': Icons.notifications_rounded},
  ];

  Future<void> _sendAlert() async {
    final msg = _msgCtrl.text.trim();
    if (msg.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escriba una descripción de la novedad')),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      final user = ref.read(currentUserProvider).valueOrNull;
      final senderName = user != null ? '${user.displayName} (${user.rank})' : 'Oficial de Guardia';

      await FirebaseFirestore.instance.collection('alerts').add({
        'type': _selectedType,
        'sender': senderName,
        'message': msg,
        'timestamp': FieldValue.serverTimestamp(),
        'is_read': false,
        'is_emergency': _selectedType == 'security_incident' || _selectedType == 'safarancho',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Alerta transmitida con éxito'),
            backgroundColor: AppColors.statusGranted,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar alerta: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.alertRedGlow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: AppColors.alertRed, size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DAR PARTE / ALERTA VIP',
                      style: AppTextStyles.headlineSmall),
                  Text('Notifica a todo el personal militar',
                      style: AppTextStyles.bodySmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('TIPO DE NOVEDAD', style: AppTextStyles.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _alertTypes.map((t) {
              final selected = _selectedType == t['value'];
              return ChoiceChip(
                label: Text(t['label'] as String),
                avatar: Icon(t['icon'] as IconData, size: 16),
                selected: selected,
                selectedColor: AppColors.alertRed.withOpacity(0.2),
                onSelected: (_) =>
                    setState(() => _selectedType = t['value'] as String),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _msgCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Descripción de la novedad',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _isSending ? null : _sendAlert,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.alertRed,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: _isSending 
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded),
            label: Text('ENVIAR ALERTA', style: AppTextStyles.buttonPrimary),
          ),
        ],
      ),
    );
  }
}
