import 'package:flutter/material.dart';

class AppColors {

  // ── Backgrounds ─────────────────────────────────────────────
  static const bg              = Color(0xFFFFFFFF);
  static const bgCard          = Color(0xFFF8FAFF);
  static const bgInput         = Color(0xFFF2F5FB);
  static const bgAccent        = Color(0xFFDEEAFF);
  static const bgSplash        = Color(0xFF0A1628);

  // ── Primary brand ────────────────────────────────────────────
  static const primary         = Color(0xFF2563EB);
  static const primaryLight    = Color(0xFF3B82F6);
  static const primaryPale     = Color(0xFFEFF6FF);
  static const primaryDark     = Color(0xFF1E40AF);

  // ── Borders ───────────────────────────────────────────────────
  static const border          = Color(0xFFD1D9EE);
  static const borderFocus     = Color(0xFF2563EB);
  static const borderCard      = Color(0xFFE8EEF8);

  // ── Text ──────────────────────────────────────────────────────
  static const textPrimary     = Color(0xFF0F172A);
  static const textSecondary   = Color(0xFF475569);
  static const textMuted       = Color(0xFF94A3B8);
  static const textLink        = Color(0xFF2563EB);

  // ── Status ────────────────────────────────────────────────────
  static const success         = Color(0xFF16A34A);
  static const successLight    = Color(0xFFDCFCE7);
  static const danger          = Color(0xFFDC2626);
  static const dangerLight     = Color(0xFFFEE2E2);
  static const warning         = Color(0xFFD97706);
  static const warningLight    = Color(0xFFFEF3C7);
  static const info            = Color(0xFF0284C7);
  static const infoLight       = Color(0xFFE0F2FE);

  // ── Blockchain ────────────────────────────────────────────────
  static const blockchain      = Color(0xFF7C3AED);
  static const blockchainLight = Color(0xFFF5F3FF);

  // ── Character painter colors ──────────────────────────────────
  static const charSkin        = Color(0xFFF5C98A);
  static const charSkinDark    = Color(0xFFE8A85A);
  static const charOutfit      = Color(0xFF3B6FD4);
  static const charOutfitDark  = Color(0xFF2A52A8);
  static const charHair        = Color(0xFF1A0800);

  // ── Misc ──────────────────────────────────────────────────────
  static const shadow          = Color(0x1A2563EB);
  static const white           = Color(0xFFFFFFFF);
  static const black           = Color(0xFF0F172A);
  static const transparent     = Colors.transparent;

  // ── Theme ─────────────────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.light(
      primary:   primary,
      secondary: primaryLight,
      surface:   bgCard,
      error:     danger,
      onPrimary: white,
      onSurface: textPrimary,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
          color: textPrimary, fontWeight: FontWeight.w700,
          fontSize: 28, letterSpacing: -0.5),
      headlineMedium: TextStyle(
          color: textPrimary, fontWeight: FontWeight.w600, fontSize: 22),
      titleLarge: TextStyle(
          color: textPrimary, fontWeight: FontWeight.w600, fontSize: 18),
      titleMedium: TextStyle(
          color: textPrimary, fontWeight: FontWeight.w500, fontSize: 16),
      bodyLarge: TextStyle(
          color: textSecondary, fontWeight: FontWeight.w400, fontSize: 15),
      bodyMedium: TextStyle(
          color: textSecondary, fontWeight: FontWeight.w400, fontSize: 14),
      bodySmall: TextStyle(
          color: textMuted, fontWeight: FontWeight.w400, fontSize: 12),
      labelLarge: TextStyle(
          color: white, fontWeight: FontWeight.w600, fontSize: 15),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: bgInput,
      hintStyle: const TextStyle(color: textMuted, fontSize: 14),
      contentPadding:
      const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderFocus, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: danger)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: danger, width: 1.5)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: white,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        padding:
        const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        textStyle: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    // ✅ FIXED: CardThemeData instead of CardTheme
    cardTheme: CardThemeData(
      color: bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: borderCard),
      ),
    ),
    dividerColor: border,
    iconTheme: const IconThemeData(color: textSecondary, size: 20),
  );
}