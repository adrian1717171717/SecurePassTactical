// lib/features/auth/data/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/app_role.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.displayName,
    required super.email,
    super.photoUrl,
    required super.cedula,
    required super.rank,
    required super.unit,
    super.phone,
    super.yearLevel,
    super.serviceBranch,
    super.gender,
    required super.currentRole,
    required super.baseRole,
    super.roleAssignedAt,
    super.roleAssignedByUid,
    super.fcmTokens,
    super.isActive,
    super.currentVehiclePlate,
    super.movementState,
    required super.createdAt,
    required super.updatedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      displayName: data['display_name'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photo_url'],
      cedula: data['cedula'] ?? '',
      rank: data['rank'] ?? '',
      unit: data['unit'] ?? '',
      phone: data['phone'],
      yearLevel: data['year_level'],
      serviceBranch: data['service_branch'],
      gender: data['gender'] ?? 'Sin especificar',
      currentRole: AppRoleExtension.fromString(data['current_role'] ?? ''),
      baseRole: AppRoleExtension.fromString(data['base_role'] ?? ''),
      roleAssignedAt: (data['role_assigned_at'] as Timestamp?)?.toDate(),
      roleAssignedByUid: data['role_assigned_by_uid'],
      fcmTokens: List<String>.from(data['fcm_tokens'] ?? []),
      isActive: data['is_active'] ?? true,
      currentVehiclePlate: data['current_vehicle_plate'],
      movementState: data['movement_state'] ?? 'AFUERA',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'display_name': displayName,
      'email': email,
      'photo_url': photoUrl,
      'cedula': cedula,
      'rank': rank,
      'unit': unit,
      'phone': phone,
      'year_level': yearLevel,
      'service_branch': serviceBranch,
      'gender': gender,
      'current_role': currentRole.toFirestoreString(),
      'base_role': baseRole.toFirestoreString(),
      'role_assigned_at':
          roleAssignedAt != null ? Timestamp.fromDate(roleAssignedAt!) : null,
      'role_assigned_by_uid': roleAssignedByUid,
      'fcm_tokens': fcmTokens,
      'is_active': isActive,
      'current_vehicle_plate': currentVehiclePlate,
      'movement_state': movementState,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }
}
