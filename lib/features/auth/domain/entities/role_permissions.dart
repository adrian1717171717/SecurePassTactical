// lib/features/auth/domain/entities/role_permissions.dart
import 'app_role.dart';

/// Niveles jerárquicos de seguridad del sistema SecurPass Tactical.
/// Define una estructura de 6 niveles de privilegios y accesos.
enum SecurityLevel {
  /// Nivel 1: Director / Subdirector — Acceso total, gestión de roles, alertas, aprobación vehículos.
  level1HighCommand,

  /// Nivel 2: Comandante de Batallón / Compañía — Alertas, vistas filtradas por ámbito.
  level2MidCommand,

  /// Nivel 3: Roles operativos rotativos con panel — Jefe de Escuela, Jefe de Control, Oficial de Semana, Oficial de Guardia, Oficial Ranchero.
  level3OperationalCommand,

  /// Nivel 4: Operadores de garita — Brigadier, Subbrigadier, Cadete de Guardia, Dispositivo de Prevención.
  level4GateOperator,

  /// Nivel 5: Personal base — Cadete, Voluntario, Servidor Público, Oficial base, Civil.
  level5BaseUser,

  /// Nivel 6: Sin rol asignado — Pendiente de aprobación.
  level6Unassigned,
}

/// Extensión para mapear cada miembro de [AppRole] a su nivel jerárquico.
extension AppRoleSecurity on AppRole {
  /// Obtiene el nivel de seguridad jerárquico asociado a este rol.
  SecurityLevel get securityLevel {
    return switch (this) {
      AppRole.director ||
      AppRole.subDirector =>
        SecurityLevel.level1HighCommand,
      AppRole.battalionCommander ||
      AppRole.companyCommander =>
        SecurityLevel.level2MidCommand,
      AppRole.schoolChief ||
      AppRole.controlChief ||
      AppRole.weekOfficer ||
      AppRole.guardOfficer ||
      AppRole.kitchenOfficer =>
        SecurityLevel.level3OperationalCommand,
      AppRole.guardBrigadier ||
      AppRole.guardSubBrigadier ||
      AppRole.guardCadet ||
      AppRole.preventionDevice =>
        SecurityLevel.level4GateOperator,
      AppRole.cadet ||
      AppRole.volunteer ||
      AppRole.civilServant ||
      AppRole.officer ||
      AppRole.civilian =>
        SecurityLevel.level5BaseUser,
      AppRole.unknown => SecurityLevel.level6Unassigned,
    };
  }

  /// Obtiene el nivel jerárquico numérico (1 = más alto, 6 = más bajo).
  int get hierarchyValue {
    return switch (securityLevel) {
      SecurityLevel.level1HighCommand => 1,
      SecurityLevel.level2MidCommand => 2,
      SecurityLevel.level3OperationalCommand => 3,
      SecurityLevel.level4GateOperator => 4,
      SecurityLevel.level5BaseUser => 5,
      SecurityLevel.level6Unassigned => 6,
    };
  }

  /// Indica si tiene acceso de visualización y exportación de analíticas.
  bool get canViewAnalytics => [
        SecurityLevel.level1HighCommand,
        SecurityLevel.level2MidCommand,
        SecurityLevel.level3OperationalCommand,
      ].contains(securityLevel);

  /// Indica si tiene acceso de lectura/escritura en el Libro de Imaginaria (Bitácora).
  bool get canManageBitacora => [
        SecurityLevel.level1HighCommand,
        SecurityLevel.level3OperationalCommand,
      ].contains(securityLevel);

  /// Indica si es operador activo en garita con permisos para escanear.
  bool get canScanAccessOperations =>
      securityLevel == SecurityLevel.level4GateOperator ||
      this == AppRole.guardOfficer ||
      this == AppRole.schoolChief ||
      this == AppRole.weekOfficer;

  /// Indica si el rol pertenece al nivel más básico de autogestión (QR e identidad).
  bool get isBaseGeneralUser =>
      securityLevel == SecurityLevel.level5BaseUser ||
      securityLevel == SecurityLevel.level6Unassigned;

  /// Compara el nivel jerárquico. Retorna `true` si este rol es superior o igual en jerarquía a [other].
  bool isSuperiorOrEqual(AppRole other) {
    return hierarchyValue <= other.hierarchyValue;
  }

  /// Qué tipo de dashboard debe ver este rol.
  DashboardType get dashboardType {
    return switch (this) {
      AppRole.director ||
      AppRole.subDirector =>
        DashboardType.admin,
      AppRole.battalionCommander ||
      AppRole.companyCommander =>
        DashboardType.admin,
      AppRole.schoolChief ||
      AppRole.weekOfficer =>
        DashboardType.guardOfficer,
      AppRole.controlChief => DashboardType.controlChief,
      AppRole.guardOfficer => DashboardType.guardOfficer,
      AppRole.kitchenOfficer => DashboardType.baseUser,
      AppRole.guardBrigadier ||
      AppRole.guardSubBrigadier ||
      AppRole.guardCadet =>
        DashboardType.gateOps,
      AppRole.preventionDevice => DashboardType.preventionDevice,
      AppRole.cadet ||
      AppRole.volunteer ||
      AppRole.civilServant ||
      AppRole.officer ||
      AppRole.civilian =>
        DashboardType.baseUser,
      AppRole.unknown => DashboardType.unassigned,
    };
  }
}

/// Tipos de dashboard disponibles en el sistema.
enum DashboardType {
  admin,
  controlChief,
  guardOfficer,
  gateOps,
  preventionDevice,
  baseUser,
  unassigned,
}
