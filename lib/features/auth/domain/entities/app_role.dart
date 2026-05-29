// lib/features/auth/domain/entities/app_role.dart

/// Roles del sistema SecurPass Tactical — Producción
/// Cubre la jerarquía institucional completa de la Escuela Militar.
enum AppRole {
  // ── Mando Superior (Nivel 1) ──────────────────────────────
  /// Director de la Escuela — Acceso total
  director,

  /// Subdirector de la Escuela — Acceso total
  subDirector,

  // ── Mando Intermedio (Nivel 2) ─────────────────────────────
  /// Comandante del Batallón de Cadetes
  battalionCommander,

  /// Comandante de Compañía (ICM, IICM, IIICM, IVCM)
  companyCommander,

  // ── Roles Operativos Rotativos (Nivel 3) ───────────────────
  /// Jefe de Escuela (rotación diaria)
  schoolChief,

  /// Jefe de Control (rotación diaria)
  controlChief,

  /// Oficial de Semana (rotación diaria)
  weekOfficer,

  /// Oficial de Guardia (rotación diaria) — Panel maestro
  guardOfficer,

  /// Oficial Ranchero (rotación mensual)
  kitchenOfficer,

  // ── Operadores de Garita (Nivel 4) ─────────────────────────
  /// Brigadier de Guardia (rotación diaria) — Escáner + Alertas
  guardBrigadier,

  /// Subbrigadier de Guardia (rotación diaria) — Escáner + Alertas
  guardSubBrigadier,

  /// Cadete de Guardia (rotación diaria) — Escáner básico
  guardCadet,

  // ── Dispositivo Especial (Nivel 4-R) ───────────────────────
  /// Dispositivo de prevención — Solo escáner y alertas
  preventionDevice,

  // ── Roles Base (Nivel 5) ───────────────────────────────────
  /// Cadete — QR, perfil, datos personales
  cadet,

  /// Voluntario — QR, perfil, datos personales
  volunteer,

  /// Servidor público — QR, perfil, datos personales
  civilServant,

  /// Oficial (rol base, no rotativo) — QR, perfil
  officer,

  /// Civil / Visitante externo — QR, perfil mínimo
  civilian,

  /// Rol no asignado / pendiente de aprobación
  unknown,
}

extension AppRoleExtension on AppRole {
  /// Convierte el string de Firestore al enum
  static AppRole fromString(String value) {
    return switch (value) {
      'director' => AppRole.director,
      'sub_director' => AppRole.subDirector,
      'battalion_commander' => AppRole.battalionCommander,
      'company_commander' => AppRole.companyCommander,
      'school_chief' => AppRole.schoolChief,
      'control_chief' => AppRole.controlChief,
      'week_officer' => AppRole.weekOfficer,
      'guard_officer' => AppRole.guardOfficer,
      'kitchen_officer' => AppRole.kitchenOfficer,
      'guard_brigadier' => AppRole.guardBrigadier,
      'guard_sub_brigadier' => AppRole.guardSubBrigadier,
      'guard_cadet' => AppRole.guardCadet,
      'prevention_device' => AppRole.preventionDevice,
      'cadet' => AppRole.cadet,
      'volunteer' => AppRole.volunteer,
      'civil_servant' => AppRole.civilServant,
      'officer' => AppRole.officer,
      'civilian' => AppRole.civilian,
      _ => AppRole.unknown,
    };
  }

  /// Convierte el enum a string para Firestore
  String toFirestoreString() {
    return switch (this) {
      AppRole.director => 'director',
      AppRole.subDirector => 'sub_director',
      AppRole.battalionCommander => 'battalion_commander',
      AppRole.companyCommander => 'company_commander',
      AppRole.schoolChief => 'school_chief',
      AppRole.controlChief => 'control_chief',
      AppRole.weekOfficer => 'week_officer',
      AppRole.guardOfficer => 'guard_officer',
      AppRole.kitchenOfficer => 'kitchen_officer',
      AppRole.guardBrigadier => 'guard_brigadier',
      AppRole.guardSubBrigadier => 'guard_sub_brigadier',
      AppRole.guardCadet => 'guard_cadet',
      AppRole.preventionDevice => 'prevention_device',
      AppRole.cadet => 'cadet',
      AppRole.volunteer => 'volunteer',
      AppRole.civilServant => 'civil_servant',
      AppRole.officer => 'officer',
      AppRole.civilian => 'civilian',
      AppRole.unknown => 'unknown',
    };
  }

  /// Nombre display en español
  String get displayName {
    return switch (this) {
      AppRole.director => 'Director',
      AppRole.subDirector => 'Subdirector',
      AppRole.battalionCommander => 'Comandante de Batallón',
      AppRole.companyCommander => 'Comandante de Compañía',
      AppRole.schoolChief => 'Jefe de Escuela',
      AppRole.controlChief => 'Jefe de Control',
      AppRole.weekOfficer => 'Oficial de Semana',
      AppRole.guardOfficer => 'Oficial de Guardia',
      AppRole.kitchenOfficer => 'Oficial Ranchero',
      AppRole.guardBrigadier => 'Brigadier de Guardia',
      AppRole.guardSubBrigadier => 'Subbrigadier de Guardia',
      AppRole.guardCadet => 'Cadete de Guardia',
      AppRole.preventionDevice => 'Dispositivo de Prevención',
      AppRole.cadet => 'Cadete',
      AppRole.volunteer => 'Voluntario',
      AppRole.civilServant => 'Servidor Público',
      AppRole.officer => 'Oficial',
      AppRole.civilian => 'Civil',
      AppRole.unknown => 'Sin Rol Asignado',
    };
  }

  // ── Permisos por rol ─────────────────────────────────────

  /// ¿Es un rol de mando superior (Director/Subdirector)?
  bool get isHighCommand => [
        AppRole.director,
        AppRole.subDirector,
      ].contains(this);

  /// ¿Es un rol de mando intermedio (Batallón/Compañía)?
  bool get isMidCommand => [
        AppRole.battalionCommander,
        AppRole.companyCommander,
      ].contains(this);

  /// ¿Puede ver el dashboard en tiempo real?
  bool get canViewLiveDashboard => [
        AppRole.director,
        AppRole.subDirector,
        AppRole.battalionCommander,
        AppRole.companyCommander,
        AppRole.schoolChief,
        AppRole.controlChief,
        AppRole.weekOfficer,
        AppRole.guardOfficer,
      ].contains(this);

  /// ¿Puede escanear y registrar accesos?
  bool get canScanAccess => [
        AppRole.guardBrigadier,
        AppRole.guardSubBrigadier,
        AppRole.guardCadet,
        AppRole.guardOfficer,
        AppRole.schoolChief,
        AppRole.weekOfficer,
        AppRole.preventionDevice,
      ].contains(this);

  /// ¿Puede registrar visitantes?
  bool get canRegisterVisitors => [
        AppRole.guardBrigadier,
        AppRole.guardSubBrigadier,
        AppRole.guardCadet,
      ].contains(this);

  /// ¿Puede enviar Alertas?
  bool get canSendAlert => [
        AppRole.director,
        AppRole.subDirector,
        AppRole.battalionCommander,
        AppRole.companyCommander,
        AppRole.schoolChief,
        AppRole.controlChief,
        AppRole.weekOfficer,
        AppRole.guardOfficer,
        AppRole.guardBrigadier,
        AppRole.guardSubBrigadier,
        AppRole.guardCadet,
        AppRole.preventionDevice,
      ].contains(this);

  /// ¿Recibe alertas?
  bool get receivesAlerts => [
        AppRole.director,
        AppRole.subDirector,
        AppRole.battalionCommander,
        AppRole.companyCommander,
        AppRole.schoolChief,
        AppRole.controlChief,
        AppRole.weekOfficer,
        AppRole.guardOfficer,
        AppRole.kitchenOfficer,
        AppRole.guardBrigadier,
        AppRole.guardSubBrigadier,
      ].contains(this);

  /// ¿Puede cerrar guardia y generar PDF?
  bool get canCloseShift => this == AppRole.guardOfficer;

  /// ¿Puede ejecutar relevos de guardia?
  bool get canHandoffRole => [
        AppRole.guardOfficer,
        AppRole.guardBrigadier,
        AppRole.guardSubBrigadier,
        AppRole.guardCadet,
      ].contains(this);

  /// ¿Es un rol operativo de garita?
  bool get isGateOperator => [
        AppRole.guardBrigadier,
        AppRole.guardSubBrigadier,
        AppRole.guardCadet,
        AppRole.preventionDevice,
      ].contains(this);

  /// ¿Puede gestionar roles de otros usuarios?
  bool get canManageRoles => isHighCommand;

  /// ¿Puede ver y gestionar usuarios?
  bool get canManageUsers => [
        AppRole.director,
        AppRole.subDirector,
        AppRole.battalionCommander,
      ].contains(this);

  /// ¿Puede aprobar/rechazar vehículos?
  bool get canApproveVehicles => [
        AppRole.director,
        AppRole.subDirector,
      ].contains(this);

  /// ¿Puede ver reportes y estadísticas?
  bool get canViewReports => [
        AppRole.director,
        AppRole.subDirector,
        AppRole.battalionCommander,
        AppRole.companyCommander,
        AppRole.schoolChief,
        AppRole.controlChief,
        AppRole.weekOfficer,
        AppRole.guardOfficer,
      ].contains(this);

  /// ¿Puede generar reportes PDF?
  bool get canGenerateReports => [
        AppRole.director,
        AppRole.subDirector,
        AppRole.controlChief,
        AppRole.guardOfficer,
      ].contains(this);

  /// ¿Puede eliminar alertas?
  bool get canDeleteAlerts => [
        AppRole.director,
        AppRole.subDirector,
      ].contains(this);

  /// ¿Puede escribir en la bitácora?
  bool get canWriteBitacora => [
        AppRole.guardOfficer,
        AppRole.schoolChief,
        AppRole.weekOfficer,
      ].contains(this);

  /// ¿Es un rol base (sin permisos operativos)?
  bool get isBaseRole => [
        AppRole.cadet,
        AppRole.volunteer,
        AppRole.civilServant,
        AppRole.officer,
        AppRole.civilian,
        AppRole.unknown,
      ].contains(this);

  /// ¿Es un dispositivo de prevención?
  bool get isPreventionDevice => this == AppRole.preventionDevice;
}
