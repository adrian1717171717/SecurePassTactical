// lib/core/config/theme/app_text_styles.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // ── Display ──────────────────────────────────────────────
  static TextStyle get displayLarge => GoogleFonts.rajdhani(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 1.2,
      );

  static TextStyle get displayMedium => GoogleFonts.rajdhani(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 1.0,
      );

  // ── Títulos ──────────────────────────────────────────────
  static TextStyle get headlineLarge => GoogleFonts.rajdhani(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.8,
      );

  static TextStyle get headlineMedium => GoogleFonts.rajdhani(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.5,
      );

  static TextStyle get headlineSmall => GoogleFonts.rajdhani(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  // ── Cuerpo ───────────────────────────────────────────────
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
      );

  // ── Labels ───────────────────────────────────────────────
  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.5,
      );

  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.8,
      );

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
        letterSpacing: 1.0,
      );

  // ── Monoespaciado (placas, cédulas, IDs) ─────────────────
  static TextStyle get mono => GoogleFonts.jetBrainsMono(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.accent,
        letterSpacing: 1.5,
      );

  static TextStyle get monoLarge => GoogleFonts.jetBrainsMono(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 3.0,
      );

  // ── Contador / Número grande (dashboard) ─────────────────
  static TextStyle get counterDisplay => GoogleFonts.rajdhani(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get counterSmall => GoogleFonts.rajdhani(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  // ── Botones ──────────────────────────────────────────────
  static TextStyle get buttonPrimary => GoogleFonts.rajdhani(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textOnPrimary,
        letterSpacing: 1.0,
      );

  static TextStyle get buttonSecondary => GoogleFonts.rajdhani(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
        letterSpacing: 0.8,
      );

  // ── Status / Badge ───────────────────────────────────────
  static TextStyle get statusGranted => GoogleFonts.rajdhani(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.statusGranted,
        letterSpacing: 2.0,
      );

  static TextStyle get statusDenied => GoogleFonts.rajdhani(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.statusDenied,
        letterSpacing: 2.0,
      );
}
