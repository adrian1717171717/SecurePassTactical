// lib/core/services/audit_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio centralizado de auditoría.
/// Registra cada acción crítica en la colección `audit_logs` de Firestore.
class AuditService {
  static final _firestore = FirebaseFirestore.instance;
  static const _collection = 'audit_logs';

  /// Registra un evento de auditoría.
  static Future<void> log({
    required String action,
    required String module,
    required String actorUid,
    required String actorName,
    required String actorRole,
    String? targetUid,
    String? targetEntity,
    String? description,
    String? result,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _firestore.collection(_collection).add({
        'action': action,
        'module': module,
        'actor_uid': actorUid,
        'actor_name': actorName,
        'actor_role': actorRole,
        'target_uid': targetUid,
        'target_entity': targetEntity,
        'description': description,
        'result': result ?? 'success',
        'metadata': metadata,
        'timestamp': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silently fail — audit should never block operations
    }
  }

  // ── Convenience methods for common actions ─────────────────

  /// Registra un escaneo de acceso (entrada/salida).
  static Future<void> logAccessScan({
    required String operatorUid,
    required String operatorName,
    required String operatorRole,
    required String scannedUid,
    required String scannedName,
    required String eventType,
    required String result,
    String? vehiclePlate,
  }) => log(
    action: 'access_scan',
    module: 'access_control',
    actorUid: operatorUid,
    actorName: operatorName,
    actorRole: operatorRole,
    targetUid: scannedUid,
    targetEntity: scannedName,
    description: eventType,
    result: result,
    metadata: {
      if (vehiclePlate != null) 'vehicle_plate': vehiclePlate,
    },
  );

  /// Registra creación o eliminación de alerta.
  static Future<void> logAlert({
    required String actorUid,
    required String actorName,
    required String actorRole,
    required String action, // 'create', 'delete', 'archive', 'read'
    required String alertType,
    String? alertId,
    String? description,
  }) => log(
    action: 'alert_$action',
    module: 'alerts',
    actorUid: actorUid,
    actorName: actorName,
    actorRole: actorRole,
    targetEntity: alertId,
    description: description ?? alertType,
  );

  /// Registra acción sobre vehículo (registro, aprobación, rechazo).
  static Future<void> logVehicle({
    required String actorUid,
    required String actorName,
    required String actorRole,
    required String action, // 'register', 'approve', 'reject', 'block'
    required String vehiclePlate,
    String? ownerUid,
  }) => log(
    action: 'vehicle_$action',
    module: 'vehicles',
    actorUid: actorUid,
    actorName: actorName,
    actorRole: actorRole,
    targetUid: ownerUid,
    targetEntity: vehiclePlate,
  );

  /// Registra cambio de rol.
  static Future<void> logRoleChange({
    required String actorUid,
    required String actorName,
    required String actorRole,
    required String targetUid,
    required String targetName,
    required String previousRole,
    required String newRole,
  }) => log(
    action: 'role_change',
    module: 'roles',
    actorUid: actorUid,
    actorName: actorName,
    actorRole: actorRole,
    targetUid: targetUid,
    targetEntity: targetName,
    description: '$previousRole → $newRole',
    metadata: {
      'previous_role': previousRole,
      'new_role': newRole,
    },
  );

  /// Registra generación de PDF.
  static Future<void> logPdfGeneration({
    required String actorUid,
    required String actorName,
    required String actorRole,
    required String reportType,
    String? shiftId,
  }) => log(
    action: 'pdf_generation',
    module: 'reports',
    actorUid: actorUid,
    actorName: actorName,
    actorRole: actorRole,
    description: reportType,
    metadata: {
      if (shiftId != null) 'shift_id': shiftId,
    },
  );

  /// Registra actualización de perfil.
  static Future<void> logProfileUpdate({
    required String actorUid,
    required String actorName,
    required String actorRole,
    required List<String> fieldsChanged,
  }) => log(
    action: 'profile_update',
    module: 'profile',
    actorUid: actorUid,
    actorName: actorName,
    actorRole: actorRole,
    targetUid: actorUid,
    description: 'Campos: ${fieldsChanged.join(', ')}',
  );
}
