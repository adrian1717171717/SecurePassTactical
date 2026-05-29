// lib/features/profile/presentation/pages/profile_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';
import '../../../../core/services/audit_service.dart';
import '../../../auth/domain/entities/app_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/widgets/tactical_app_bar.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cedulaCtrl = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user != null) {
        _nameCtrl.text = user.displayName;
        _phoneCtrl.text = user.phone ?? '';
        _cedulaCtrl.text = user.cedula;
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _cedulaCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      final changes = <String, dynamic>{
        'updated_at': FieldValue.serverTimestamp(),
      };
      final changedFields = <String>[];

      if (_nameCtrl.text.trim().toUpperCase() != user.displayName) {
        changes['display_name'] = _nameCtrl.text.trim().toUpperCase();
        changedFields.add('display_name');
      }
      if (_phoneCtrl.text.trim() != (user.phone ?? '')) {
        changes['phone'] = _phoneCtrl.text.trim();
        changedFields.add('phone');
      }
      if (_cedulaCtrl.text.trim() != user.cedula) {
        changes['cedula'] = _cedulaCtrl.text.trim();
        changedFields.add('cedula');
      }

      if (changedFields.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update(changes);

        AuditService.logProfileUpdate(
          actorUid: user.uid,
          actorName: user.displayName,
          actorRole: user.currentRole.toFirestoreString(),
          fieldsChanged: changedFields,
        );
      }

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Perfil actualizado correctamente'),
            backgroundColor: AppColors.statusGranted,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.alertRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: TacticalAppBar(
        title: 'MI PERFIL',
        showBackButton: true,
        actions: [
          if (!_isEditing)
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 20),
              tooltip: 'Editar perfil',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ── Avatar ─────────────────────────────────
              CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.surfaceElevated,
                child: Text(
                  user.displayName.isNotEmpty ? user.displayName[0] : '?',
                  style: AppTextStyles.displayLarge.copyWith(
                    color: AppColors.primary,
                    fontSize: 36,
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGlow,
                  borderRadius: BorderRadius.circular(6),
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
              const SizedBox(height: 8),
              // Movement state badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: user.movementState == 'ADENTRO'
                      ? AppColors.statusGranted.withOpacity(0.1)
                      : AppColors.textMuted.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: user.movementState == 'ADENTRO'
                        ? AppColors.statusGranted.withOpacity(0.4)
                        : AppColors.surfaceBorder,
                  ),
                ),
                child: Text(
                  user.movementState == 'ADENTRO' ? '● DENTRO DE INSTALACIÓN' : '○ FUERA DE INSTALACIÓN',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: user.movementState == 'ADENTRO'
                        ? AppColors.statusGranted
                        : AppColors.textMuted,
                    letterSpacing: 1.5,
                    fontSize: 10,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Datos ─────────────────────────────────
              _buildField(
                label: 'Nombres completos',
                controller: _nameCtrl,
                icon: Icons.person_rounded,
                enabled: _isEditing,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              _buildField(
                label: 'Correo institucional',
                icon: Icons.email_rounded,
                value: user.email,
                enabled: false,
              ),
              const SizedBox(height: 12),
              _buildField(
                label: 'Número de cédula',
                controller: _cedulaCtrl,
                icon: Icons.badge_rounded,
                enabled: _isEditing,
              ),
              const SizedBox(height: 12),
              _buildField(
                label: 'Teléfono',
                controller: _phoneCtrl,
                icon: Icons.phone_rounded,
                enabled: _isEditing,
              ),
              const SizedBox(height: 12),
              _buildField(
                label: 'Cargo / Jerarquía',
                icon: Icons.grade_rounded,
                value: user.rank,
                enabled: false,
              ),
              const SizedBox(height: 12),
              _buildField(
                label: 'Unidad / Compañía',
                icon: Icons.group_work_rounded,
                value: user.unit.isNotEmpty ? user.unit : '—',
                enabled: false,
              ),
              if (user.yearLevel != null && user.yearLevel!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildField(
                  label: 'Año / Nivel',
                  icon: Icons.school_rounded,
                  value: user.yearLevel!,
                  enabled: false,
                ),
              ],

              const SizedBox(height: 24),

              if (_isEditing) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() => _isEditing = false);
                          _nameCtrl.text = user.displayName;
                          _phoneCtrl.text = user.phone ?? '';
                          _cedulaCtrl.text = user.cedula;
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: AppColors.surfaceBorder),
                        ),
                        child: const Text('CANCELAR'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('GUARDAR'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required IconData icon,
    TextEditingController? controller,
    String? value,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? value : null,
      enabled: enabled,
      style: AppTextStyles.bodyLarge.copyWith(
        color: enabled ? Colors.white : AppColors.textSecondary,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        filled: true,
        fillColor: enabled ? AppColors.surface : AppColors.surfaceElevated,
      ),
      validator: validator,
    );
  }
}
