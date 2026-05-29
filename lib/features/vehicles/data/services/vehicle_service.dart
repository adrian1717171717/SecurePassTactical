// lib/features/vehicles/data/services/vehicle_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/audit_service.dart';
import '../../domain/entities/vehicle_entity.dart';

class VehicleService {
  static final _firestore = FirebaseFirestore.instance;
  static const _collection = 'vehicles';

  /// Registra un vehículo nuevo (pendiente de aprobación).
  static Future<void> register({
    required String plate,
    required String brand,
    required String model,
    required String color,
    required String ownerUid,
    required String ownerName,
    required String ownerRank,
  }) async {
    final normalizedPlate = plate.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

    // Verificar si ya existe un vehículo con esta placa
    final existing = await _firestore
        .collection(_collection)
        .where('plate', isEqualTo: normalizedPlate)
        .get();
    if (existing.docs.isNotEmpty) {
      throw Exception('Ya existe un vehículo registrado con la placa $normalizedPlate');
    }

    await _firestore.collection(_collection).add({
      'plate': normalizedPlate,
      'brand': brand.trim(),
      'model': model.trim(),
      'color': color.trim(),
      'owner_uid': ownerUid,
      'owner_name': ownerName,
      'owner_rank': ownerRank,
      'status': VehicleStatus.pending.toFirestoreString(),
      'rejection_reason': null,
      'approved_by_uid': null,
      'approved_by_name': null,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'approved_at': null,
    });
  }

  /// Aprueba un vehículo (solo Director/Subdirector).
  static Future<void> approve({
    required String vehicleId,
    required String approverUid,
    required String approverName,
    required String approverRole,
  }) async {
    final doc = await _firestore.collection(_collection).doc(vehicleId).get();
    if (!doc.exists) throw Exception('Vehículo no encontrado');

    await _firestore.collection(_collection).doc(vehicleId).update({
      'status': VehicleStatus.approved.toFirestoreString(),
      'approved_by_uid': approverUid,
      'approved_by_name': approverName,
      'approved_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'rejection_reason': null,
    });

    final plate = doc.data()?['plate'] ?? '';
    final ownerUid = doc.data()?['owner_uid'] as String?;
    AuditService.logVehicle(
      actorUid: approverUid,
      actorName: approverName,
      actorRole: approverRole,
      action: 'approve',
      vehiclePlate: plate,
      ownerUid: ownerUid,
    );
  }

  /// Rechaza un vehículo.
  static Future<void> reject({
    required String vehicleId,
    required String rejectorUid,
    required String rejectorName,
    required String rejectorRole,
    required String reason,
  }) async {
    final doc = await _firestore.collection(_collection).doc(vehicleId).get();
    if (!doc.exists) throw Exception('Vehículo no encontrado');

    await _firestore.collection(_collection).doc(vehicleId).update({
      'status': VehicleStatus.rejected.toFirestoreString(),
      'rejection_reason': reason,
      'updated_at': FieldValue.serverTimestamp(),
    });

    final plate = doc.data()?['plate'] ?? '';
    final ownerUid = doc.data()?['owner_uid'] as String?;
    AuditService.logVehicle(
      actorUid: rejectorUid,
      actorName: rejectorName,
      actorRole: rejectorRole,
      action: 'reject',
      vehiclePlate: plate,
      ownerUid: ownerUid,
    );
  }

  /// Bloquea un vehículo (temporal o permanente).
  static Future<void> block({
    required String vehicleId,
    required String blockerUid,
    required String blockerName,
    required String blockerRole,
    required String reason,
  }) async {
    final doc = await _firestore.collection(_collection).doc(vehicleId).get();
    if (!doc.exists) throw Exception('Vehículo no encontrado');

    await _firestore.collection(_collection).doc(vehicleId).update({
      'status': VehicleStatus.blocked.toFirestoreString(),
      'rejection_reason': reason,
      'updated_at': FieldValue.serverTimestamp(),
    });

    final plate = doc.data()?['plate'] ?? '';
    final ownerUid = doc.data()?['owner_uid'] as String?;
    AuditService.logVehicle(
      actorUid: blockerUid,
      actorName: blockerName,
      actorRole: blockerRole,
      action: 'block',
      vehiclePlate: plate,
      ownerUid: ownerUid,
    );
  }

  /// Stream de todos los vehículos (para panel admin).
  static Stream<List<VehicleEntity>> watchAll() {
    return _firestore
        .collection(_collection)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_docToEntity).toList());
  }

  /// Stream de vehículos pendientes de aprobación.
  static Stream<List<VehicleEntity>> watchPending() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'pending')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_docToEntity).toList());
  }

  /// Stream de vehículos de un usuario específico.
  static Stream<List<VehicleEntity>> watchByOwner(String ownerUid) {
    return _firestore
        .collection(_collection)
        .where('owner_uid', isEqualTo: ownerUid)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_docToEntity).toList());
  }

  static VehicleEntity _docToEntity(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return VehicleEntity(
      id: doc.id,
      plate: d['plate'] ?? '',
      brand: d['brand'] ?? '',
      model: d['model'] ?? '',
      color: d['color'] ?? '',
      ownerUid: d['owner_uid'] ?? '',
      ownerName: d['owner_name'] ?? '',
      ownerRank: d['owner_rank'] ?? '',
      status: VehicleStatusExtension.fromString(d['status'] ?? ''),
      rejectionReason: d['rejection_reason'],
      approvedByUid: d['approved_by_uid'],
      approvedByName: d['approved_by_name'],
      createdAt: (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approvedAt: (d['approved_at'] as Timestamp?)?.toDate(),
    );
  }
}
