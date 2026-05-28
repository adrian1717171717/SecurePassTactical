// lib/core/config/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Fondos ───────────────────────────────────────────────
  static const Color background = Color(0xFF0A0E14);
  static const Color surface = Color(0xFF111827);
  static const Color surfaceElevated = Color(0xFF1A2332);
  static const Color surfaceBorder = Color(0xFF1E3A5F);

  // ── Primario (Azul táctico) ──────────────────────────────
  static const Color primary = Color(0xFF1A6BFF);
  static const Color primaryDark = Color(0xFF0F4FCC);
  static const Color primaryLight = Color(0xFF4D91FF);
  static const Color primaryGlow = Color(0x331A6BFF);

  // ── Acento (Verde militar) ───────────────────────────────
  static const Color accent = Color(0xFF00D084);
  static const Color accentDark = Color(0xFF009E63);
  static const Color accentGlow = Color(0x3300D084);

  // ── Semafórico ───────────────────────────────────────────
  static const Color statusGranted = Color(0xFF00D084);   // Verde — acceso permitido
  static const Color statusDenied = Color(0xFFFF3B3B);    // Rojo  — acceso denegado
  static const Color statusPending = Color(0xFFFFB800);   // Ámbar — pendiente verificación
  static const Color statusInside = Color(0xFF1A6BFF);    // Azul  — dentro del perímetro
  static const Color statusOverstay = Color(0xFFFF6B00);  // Naranja — excedió tiempo

  // ── Alerta ───────────────────────────────────────────────
  static const Color alertRed = Color(0xFFFF1744);
  static const Color alertRedGlow = Color(0x66FF1744);
  static const Color alertAmber = Color(0xFFFFAB00);

  // ── Texto ────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFE8EDF5);
  static const Color textSecondary = Color(0xFF8B9AB2);
  static const Color textMuted = Color(0xFF4A5568);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Roles — Colores de insignia ──────────────────────────
  static const Color roleDirector = Color(0xFFFFD700);      // Oro
  static const Color roleSubDirector = Color(0xFFC0C0C0);   // Plata
  static const Color roleSchoolChief = Color(0xFFCD7F32);   // Bronce
  static const Color roleControlChief = Color(0xFF4D91FF);  // Azul claro
  static const Color roleGuardOfficer = Color(0xFF00D084);  // Verde
  static const Color roleBrigadier = Color(0xFF8B9AB2);     // Gris azulado
  static const Color roleSubBrigadier = Color(0xFF6B7A8D);  // Gris
  static const Color roleCadet = Color(0xFF4A5568);         // Gris oscuro

  // ── Gradientes ───────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0F4FCC), Color(0xFF1A6BFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient scannerGradient = LinearGradient(
    colors: [Color(0xFF0A0E14), Color(0xFF111827)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF111827), Color(0xFF1A2332)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
