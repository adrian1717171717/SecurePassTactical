// lib/features/auth/domain/entities/user_entity.dart
import 'package:equatable/equatable.dart';
import 'app_role.dart';

class UserEntity extends Equatable {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final String cedula;
  final String rank;
  final String unit;
  final String? phone;
  final String? yearLevel; // Año o nivel para cadetes (1ro, 2do, 3ro, 4to)
  final String? serviceBranch; // Arma de servicio (Infantería, Caballería, etc.)
  final String? gender; // Masculino, Femenino, Sin especificar

  final AppRole currentRole;
  final AppRole baseRole;
  final DateTime? roleAssignedAt;
  final String? roleAssignedByUid;

  final List<String> fcmTokens;
  final bool isActive;
  final String? currentVehiclePlate;
  final String movementState;

  final DateTime createdAt;
  final DateTime updatedAt;

  const UserEntity({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    required this.cedula,
    required this.rank,
    required this.unit,
    this.phone,
    this.yearLevel,
    this.serviceBranch,
    this.gender = 'Sin especificar',
    required this.currentRole,
    required this.baseRole,
    this.roleAssignedAt,
    this.roleAssignedByUid,
    this.fcmTokens = const [],
    this.isActive = true,
    this.currentVehiclePlate,
    this.movementState = 'AFUERA',
    required this.createdAt,
    required this.updatedAt,
  });

  UserEntity copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? photoUrl,
    String? cedula,
    String? rank,
    String? unit,
    String? phone,
    String? yearLevel,
    String? serviceBranch,
    String? gender,
    AppRole? currentRole,
    AppRole? baseRole,
    DateTime? roleAssignedAt,
    String? roleAssignedByUid,
    List<String>? fcmTokens,
    bool? isActive,
    String? currentVehiclePlate,
    String? movementState,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      cedula: cedula ?? this.cedula,
      rank: rank ?? this.rank,
      unit: unit ?? this.unit,
      phone: phone ?? this.phone,
      yearLevel: yearLevel ?? this.yearLevel,
      serviceBranch: serviceBranch ?? this.serviceBranch,
      gender: gender ?? this.gender,
      currentRole: currentRole ?? this.currentRole,
      baseRole: baseRole ?? this.baseRole,
      roleAssignedAt: roleAssignedAt ?? this.roleAssignedAt,
      roleAssignedByUid: roleAssignedByUid ?? this.roleAssignedByUid,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      isActive: isActive ?? this.isActive,
      currentVehiclePlate: currentVehiclePlate ?? this.currentVehiclePlate,
      movementState: movementState ?? this.movementState,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [uid, currentRole, isActive, movementState, gender, serviceBranch, updatedAt];
}
