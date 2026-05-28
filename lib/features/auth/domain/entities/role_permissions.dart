// lib/features/auth/domain/entities/role_permissions.dart
import 'app_role.dart';

/// Niveles de la jerarquía de seguridad e institucional de SecurPass Tactical.
/// Define una estructura de 5 niveles de privilegios y accesos.
enum SecurityLevel {
  /// Nivel 1: Director / Subdirector / Jefe de Escuela (Acceso total, gestión de roles, alertas VIP globales).
  level1Admin,

  /// Nivel 2: Jefe de Control (Estadísticas y reportes de solo lectura).
  level2ControlChief,

  /// Nivel 3: Oficial de Guardia (Gestión de Libro de Imaginaria, relevo y cierre de guardia).
  level3GuardOfficer,

  /// Nivel 4: Brigadier / Subbrigadier / Cadete de Guardia (Operadores de escáner en garita y alertas VIP).
  level4GateOperator,

  /// Nivel 5: Personal General (Visualización de QR propio, autogestión de perfil y vehículos).
  level5General,
}

/// Extensión para mapear cada miembro de [AppRole] a su nivel jerárquico e institucional.
extension AppRoleSecurity on AppRole {
  /// Obtiene el nivel de seguridad jerárquico asociado a este rol.
  SecurityLevel get securityLevel {
    return switch (this) {
      AppRole.director ||
      AppRole.subDirector ||
      AppRole.schoolChief =>
        SecurityLevel.level1Admin,
      AppRole.controlChief => SecurityLevel.level2ControlChief,
      AppRole.guardOfficer => SecurityLevel.level3GuardOfficer,
      AppRole.guardBrigadier ||
      AppRole.guardSubBrigadier ||
      AppRole.guardCadet =>
        SecurityLevel.level4GateOperator,
      AppRole.unknown => SecurityLevel.level5General,
    };
  }

  /// Obtiene el nivel jerárquico numérico (1 = más alto, 5 = más bajo).
  int get hierarchyValue {
    return switch (securityLevel) {
      SecurityLevel.level1Admin => 1,
      SecurityLevel.level2ControlChief => 2,
      SecurityLevel.level3GuardOfficer => 3,
      SecurityLevel.level4GateOperator => 4,
      SecurityLevel.level5General => 5,
    };
  }

  /// Indica si el rol tiene privilegios administrativos completos (e.g., asignar roles).
  bool get canManageRoles => securityLevel == SecurityLevel.level1Admin;

  /// Indica si tiene acceso de visualización y exportación de analíticas estadísticas.
  bool get canViewAnalytics => [
        SecurityLevel.level1Admin,
        SecurityLevel.level2ControlChief,
      ].contains(securityLevel);

  /// Indica si tiene acceso de lectura/escritura en el Libro de Imaginaria (Bitácora).
  bool get canManageBitacora => [
        SecurityLevel.level1Admin,
        SecurityLevel.level3GuardOfficer,
      ].contains(securityLevel);

  /// Indica si es operador activo en garita con permisos para escanear y registrar.
  bool get canScanAccessOperations => securityLevel == SecurityLevel.level4GateOperator;

  /// Indica si el rol pertenece al nivel más básico de autogestión (QR e identidad).
  bool get isBaseGeneralUser => securityLevel == SecurityLevel.level5General;

  /// Compara el nivel jerárquico. Retorna `true` si este rol es superior o igual en jerarquía a [other].
  bool isSuperiorOrEqual(AppRole other) {
    return hierarchyValue <= other.hierarchyValue;
  }
}
