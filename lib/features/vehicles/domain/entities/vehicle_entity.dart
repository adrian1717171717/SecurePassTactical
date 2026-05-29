// lib/features/vehicles/domain/entities/vehicle_entity.dart

/// Estados posibles de un vehículo en el sistema.
enum VehicleStatus {
  /// Registrado, pendiente de aprobación por Director/Subdirector
  pending,

  /// Aprobado para ingreso
  approved,

  /// Rechazado por Director/Subdirector
  rejected,

  /// Bloqueado (suspensión temporal o permanente)
  blocked,
}

extension VehicleStatusExtension on VehicleStatus {
  String get displayName {
    return switch (this) {
      VehicleStatus.pending => 'Pendiente',
      VehicleStatus.approved => 'Aprobado',
      VehicleStatus.rejected => 'Rechazado',
      VehicleStatus.blocked => 'Bloqueado',
    };
  }

  String toFirestoreString() {
    return switch (this) {
      VehicleStatus.pending => 'pending',
      VehicleStatus.approved => 'approved',
      VehicleStatus.rejected => 'rejected',
      VehicleStatus.blocked => 'blocked',
    };
  }

  static VehicleStatus fromString(String value) {
    return switch (value) {
      'approved' => VehicleStatus.approved,
      'rejected' => VehicleStatus.rejected,
      'blocked' => VehicleStatus.blocked,
      _ => VehicleStatus.pending,
    };
  }
}

/// Entidad de vehículo registrado en el sistema.
class VehicleEntity {
  final String id;
  final String plate;
  final String brand;
  final String model;
  final String color;
  final String ownerUid;
  final String ownerName;
  final String ownerRank;
  final VehicleStatus status;
  final String? rejectionReason;
  final String? approvedByUid;
  final String? approvedByName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? approvedAt;

  const VehicleEntity({
    required this.id,
    required this.plate,
    required this.brand,
    required this.model,
    required this.color,
    required this.ownerUid,
    required this.ownerName,
    required this.ownerRank,
    required this.status,
    this.rejectionReason,
    this.approvedByUid,
    this.approvedByName,
    required this.createdAt,
    required this.updatedAt,
    this.approvedAt,
  });
}
