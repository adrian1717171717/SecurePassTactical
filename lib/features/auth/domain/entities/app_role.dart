// lib/features/auth/domain/entities/app_role.dart

/// Roles del sistema SecurPass Tactical — Fase 1
enum AppRole {
  /// Director de la Escuela — Acceso total + Alertas VIP
  director,

  /// Subdirector de la Escuela — Acceso total + Alertas VIP
  subDirector,

  /// Jefe de Escuela — Acceso total + Alertas VIP
  schoolChief,

  /// Jefe de Control — Dashboard + Reportes (solo lectura)
  controlChief,

  /// Oficial de Guardia (rotativo) — Panel maestro + Parte PDF + Relevo
  guardOfficer,

  /// Brigadier de Guardia (rotativo) — Escáner + Registro + Dar Parte
  guardBrigadier,

  /// Subbrigadier de Guardia (rotativo) — Escáner + Registro + Dar Parte
  guardSubBrigadier,

  /// Cadete de Guardia (rotativo) — Escáner + Registro básico
  guardCadet,

  /// Rol desconocido / no asignado
  unknown,
}

extension AppRoleExtension on AppRole {
  /// Convierte el string de Firestore al enum
  static AppRole fromString(String value) {
    return switch (value) {
      'director' => AppRole.director,
      'sub_director' => AppRole.subDirector,
      'school_chief' => AppRole.schoolChief,
      'control_chief' => AppRole.controlChief,
      'guard_officer' => AppRole.guardOfficer,
      'guard_brigadier' => AppRole.guardBrigadier,
      'guard_sub_brigadier' => AppRole.guardSubBrigadier,
      'guard_cadet' => AppRole.guardCadet,
      _ => AppRole.unknown,
    };
  }

  /// Convierte el enum a string para Firestore
  String toFirestoreString() {
    return switch (this) {
      AppRole.director => 'director',
      AppRole.subDirector => 'sub_director',
      AppRole.schoolChief => 'school_chief',
      AppRole.controlChief => 'control_chief',
      AppRole.guardOfficer => 'guard_officer',
      AppRole.guardBrigadier => 'guard_brigadier',
      AppRole.guardSubBrigadier => 'guard_sub_brigadier',
      AppRole.guardCadet => 'guard_cadet',
      AppRole.unknown => 'unknown',
    };
  }

  /// Nombre display en español
  String get displayName {
    return switch (this) {
      AppRole.director => 'Director',
      AppRole.subDirector => 'Subdirector',
      AppRole.schoolChief => 'Jefe de Escuela',
      AppRole.controlChief => 'Jefe de Control',
      AppRole.guardOfficer => 'Oficial de Guardia',
      AppRole.guardBrigadier => 'Brigadier de Guardia',
      AppRole.guardSubBrigadier => 'Subbrigadier de Guardia',
      AppRole.guardCadet => 'Cadete de Guardia',
      AppRole.unknown => 'Sin Rol',
    };
  }

  // ── Permisos por rol ─────────────────────────────────────

  /// ¿Puede ver el dashboard en tiempo real?
  bool get canViewLiveDashboard => [
        AppRole.director,
        AppRole.subDirector,
        AppRole.schoolChief,
        AppRole.controlChief,
        AppRole.guardOfficer,
      ].contains(this);

  /// ¿Puede escanear y registrar accesos?
  bool get canScanAccess => [
        AppRole.guardBrigadier,
        AppRole.guardSubBrigadier,
        AppRole.guardCadet,
      ].contains(this);

  /// ¿Puede registrar visitantes?
  bool get canRegisterVisitors => [
        AppRole.guardBrigadier,
        AppRole.guardSubBrigadier,
        AppRole.guardCadet,
      ].contains(this);

  /// ¿Puede enviar Alertas VIP?
  bool get canSendVipAlert => [
        AppRole.guardBrigadier,
        AppRole.guardSubBrigadier,
        AppRole.guardCadet,
        AppRole.guardOfficer,
      ].contains(this);

  /// ¿Recibe notificaciones VIP?
  bool get receivesVipAlerts => [
        AppRole.director,
        AppRole.subDirector,
        AppRole.schoolChief,
        AppRole.guardOfficer,
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

  /// ¿Es un rol de mando superior (acceso total)?
  bool get isHighCommand => [
        AppRole.director,
        AppRole.subDirector,
        AppRole.schoolChief,
      ].contains(this);

  /// ¿Es un rol operativo de garita?
  bool get isGateOperator => [
        AppRole.guardBrigadier,
        AppRole.guardSubBrigadier,
        AppRole.guardCadet,
      ].contains(this);
}
