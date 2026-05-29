// lib/features/vehicles/presentation/pages/vehicles_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';
import '../../../auth/domain/entities/app_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/widgets/tactical_app_bar.dart';
import '../../data/services/vehicle_service.dart';
import '../../domain/entities/vehicle_entity.dart';

// ── Providers ──────────────────────────────────────────────────

final _allVehiclesProvider = StreamProvider.autoDispose<List<VehicleEntity>>((ref) {
  return VehicleService.watchAll();
});

final _pendingVehiclesProvider = StreamProvider.autoDispose<List<VehicleEntity>>((ref) {
  return VehicleService.watchPending();
});

// ── Page ───────────────────────────────────────────────────────

class VehiclesPage extends ConsumerStatefulWidget {
  const VehiclesPage({super.key});

  @override
  ConsumerState<VehiclesPage> createState() => _VehiclesPageState();
}

class _VehiclesPageState extends ConsumerState<VehiclesPage> with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final canApprove = user?.currentRole.canApproveVehicles ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: TacticalAppBar(
        title: 'CONTROL VEHICULAR',
        subtitle: canApprove ? 'PANEL DE APROBACIÓN' : 'MIS VEHÍCULOS',
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRegisterDialog(context, user),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('REGISTRAR', style: AppTextStyles.buttonPrimary.copyWith(fontSize: 12)),
      ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.8, 0.8)),
      body: Column(
        children: [
          if (canApprove) ...[
            Container(
              color: AppColors.surface,
              child: TabBar(
                controller: _tabCtrl,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textMuted,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: 'TODOS'),
                  Tab(text: 'PENDIENTES'),
                  Tab(text: 'MIS VEHÍCULOS'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _VehicleList(
                    provider: _allVehiclesProvider,
                    canApprove: true,
                    userUid: user?.uid ?? '',
                  ),
                  _VehicleList(
                    provider: _pendingVehiclesProvider,
                    canApprove: true,
                    userUid: user?.uid ?? '',
                  ),
                  _MyVehiclesList(uid: user?.uid ?? ''),
                ],
              ),
            ),
          ] else ...[
            Expanded(child: _MyVehiclesList(uid: user?.uid ?? '')),
          ],
        ],
      ),
    );
  }

  void _showRegisterDialog(BuildContext context, dynamic user) {
    final plateCtrl = TextEditingController();
    final brandCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    final colorCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.surfaceBorder),
        ),
        title: Text('REGISTRAR VEHÍCULO', style: AppTextStyles.headlineSmall.copyWith(
          color: AppColors.primary,
          letterSpacing: 2,
        )),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: plateCtrl,
                  textCapitalization: TextCapitalization.characters,
                  style: AppTextStyles.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: 'Placa del vehículo',
                    prefixIcon: Icon(Icons.confirmation_num_rounded, color: AppColors.textMuted),
                    hintText: 'Ej: ABC1234',
                  ),
                  validator: (v) => (v == null || v.trim().length < 4) ? 'Placa inválida' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: brandCtrl,
                  style: AppTextStyles.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: 'Marca',
                    prefixIcon: Icon(Icons.directions_car_rounded, color: AppColors.textMuted),
                    hintText: 'Ej: Toyota',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: modelCtrl,
                  style: AppTextStyles.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: 'Modelo',
                    prefixIcon: Icon(Icons.car_repair_rounded, color: AppColors.textMuted),
                    hintText: 'Ej: Hilux 2024',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: colorCtrl,
                  style: AppTextStyles.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: 'Color',
                    prefixIcon: Icon(Icons.palette_rounded, color: AppColors.textMuted),
                    hintText: 'Ej: Blanco',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await VehicleService.register(
                  plate: plateCtrl.text,
                  brand: brandCtrl.text,
                  model: modelCtrl.text,
                  color: colorCtrl.text,
                  ownerUid: user?.uid ?? '',
                  ownerName: user?.displayName ?? '',
                  ownerRank: user?.rank ?? '',
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ Vehículo registrado — pendiente de aprobación'),
                      backgroundColor: AppColors.statusGranted,
                    ),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.alertRed),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('REGISTRAR'),
          ),
        ],
      ),
    );
  }
}

// ── My Vehicles List ───────────────────────────────────────────

class _MyVehiclesList extends ConsumerWidget {
  final String uid;
  const _MyVehiclesList({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder(
      stream: VehicleService.watchByOwner(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final vehicles = snapshot.data ?? [];
        if (vehicles.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions_car_outlined, size: 64, color: AppColors.textMuted.withOpacity(0.3)),
                const SizedBox(height: 16),
                Text('No tiene vehículos registrados', style: AppTextStyles.bodyMedium),
                const SizedBox(height: 8),
                Text('Presione el botón + para registrar', style: AppTextStyles.bodySmall),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: vehicles.length,
          itemBuilder: (context, index) {
            return _VehicleCard(vehicle: vehicles[index], canApprove: false, userUid: uid)
                .animate(delay: (index * 60).ms)
                .fadeIn(duration: 300.ms)
                .slideX(begin: 0.05);
          },
        );
      },
    );
  }
}

// ── Vehicle List (for admin) ───────────────────────────────────

class _VehicleList extends ConsumerWidget {
  final AutoDisposeStreamProvider<List<VehicleEntity>> provider;
  final bool canApprove;
  final String userUid;

  const _VehicleList({
    required this.provider,
    required this.canApprove,
    required this.userUid,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(provider);

    return vehiclesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e', style: AppTextStyles.bodyMedium)),
      data: (vehicles) {
        if (vehicles.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 64, color: AppColors.textMuted.withOpacity(0.3)),
                const SizedBox(height: 16),
                Text('Sin vehículos en esta categoría', style: AppTextStyles.bodyMedium),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: vehicles.length,
          itemBuilder: (context, index) {
            return _VehicleCard(vehicle: vehicles[index], canApprove: canApprove, userUid: userUid)
                .animate(delay: (index * 60).ms)
                .fadeIn(duration: 300.ms)
                .slideX(begin: 0.05);
          },
        );
      },
    );
  }
}

// ── Vehicle Card ───────────────────────────────────────────────

class _VehicleCard extends ConsumerWidget {
  final VehicleEntity vehicle;
  final bool canApprove;
  final String userUid;

  const _VehicleCard({
    required this.vehicle,
    required this.canApprove,
    required this.userUid,
  });

  Color get _statusColor {
    return switch (vehicle.status) {
      VehicleStatus.pending => AppColors.statusPending,
      VehicleStatus.approved => AppColors.statusGranted,
      VehicleStatus.rejected => AppColors.statusDenied,
      VehicleStatus.blocked => AppColors.alertRed,
    };
  }

  IconData get _statusIcon {
    return switch (vehicle.status) {
      VehicleStatus.pending => Icons.hourglass_top_rounded,
      VehicleStatus.approved => Icons.check_circle_rounded,
      VehicleStatus.rejected => Icons.cancel_rounded,
      VehicleStatus.blocked => Icons.block_rounded,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.directions_car_rounded, color: _statusColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.plate,
                      style: AppTextStyles.headlineSmall.copyWith(
                        fontFamily: 'monospace',
                        letterSpacing: 3,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      '${vehicle.brand} ${vehicle.model} · ${vehicle.color}',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _statusColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_statusIcon, size: 14, color: _statusColor),
                    const SizedBox(width: 4),
                    Text(
                      vehicle.status.displayName.toUpperCase(),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: _statusColor,
                        letterSpacing: 1,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                '${vehicle.ownerName} · ${vehicle.ownerRank}',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
          if (vehicle.rejectionReason != null && vehicle.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.alertRed.withOpacity(0.05),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.alertRed),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      vehicle.rejectionReason!,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.alertRed),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (canApprove && vehicle.status == VehicleStatus.pending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectDialog(context, user),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('RECHAZAR'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.alertRed,
                      side: const BorderSide(color: AppColors.alertRed),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await VehicleService.approve(
                          vehicleId: vehicle.id,
                          approverUid: user?.uid ?? '',
                          approverName: user?.displayName ?? '',
                          approverRole: user?.currentRole.toFirestoreString() ?? '',
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✓ Vehículo aprobado'),
                              backgroundColor: AppColors.statusGranted,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('APROBAR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusGranted,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, dynamic user) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('RECHAZAR VEHÍCULO', style: AppTextStyles.headlineSmall.copyWith(color: AppColors.alertRed)),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 3,
          style: AppTextStyles.bodyLarge,
          decoration: const InputDecoration(
            labelText: 'Motivo del rechazo',
            hintText: 'Describa el motivo...',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () async {
              if (reasonCtrl.text.trim().isEmpty) return;
              try {
                await VehicleService.reject(
                  vehicleId: vehicle.id,
                  rejectorUid: user?.uid ?? '',
                  rejectorName: user?.displayName ?? '',
                  rejectorRole: user?.currentRole.toFirestoreString() ?? '',
                  reason: reasonCtrl.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.alertRed),
            child: const Text('RECHAZAR'),
          ),
        ],
      ),
    );
  }
}
