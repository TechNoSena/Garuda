import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GarudaColors {
  // Brand
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryDark = Color(0xFF0B3D2E);
  static const Color primaryLight = Color(0xFF66BB6A);
  static const Color accent = Color(0xFF00E676);

  // Background
  static const Color background = Color(0xFF0A0E17);
  static const Color surface = Color(0xFF111827);
  static const Color surfaceLight = Color(0xFF1E293B);
  static const Color card = Color(0xFF162032);

  // Text
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Semantic
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Risk
  static const Color riskSafe = Color(0xFF22C55E);
  static const Color riskCaution = Color(0xFFF59E0B);
  static const Color riskHigh = Color(0xFFEF4444);

  // Transport modes
  static const Color modeCar = Color(0xFF3B82F6);
  static const Color modeBike = Color(0xFF8B5CF6);
  static const Color modeRail = Color(0xFFF59E0B);
  static const Color modeFlight = Color(0xFF06B6D4);
  static const Color modeShip = Color(0xFF14B8A6);

  // Glass
  static const Color glass = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
}

class GarudaTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: GarudaColors.background,
      colorScheme: const ColorScheme.dark(
        primary: GarudaColors.primary,
        secondary: GarudaColors.accent,
        surface: GarudaColors.surface,
        error: GarudaColors.danger,
        onPrimary: Colors.white,
        onSurface: GarudaColors.textPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        headlineLarge: GoogleFonts.outfit(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: GarudaColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: GarudaColors.textPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: GarudaColors.textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: GarudaColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          color: GarudaColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: GarudaColors.textSecondary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          color: GarudaColors.textMuted,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: GarudaColors.textPrimary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: GarudaColors.surface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: GarudaColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: GarudaColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: GarudaColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: GarudaColors.glassBorder, width: 0.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: GarudaColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: GarudaColors.primaryLight,
          side: const BorderSide(color: GarudaColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: GarudaColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: GarudaColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: GarudaColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: GarudaColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: GarudaColors.danger),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.inter(color: GarudaColors.textMuted, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: GarudaColors.textSecondary, fontSize: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: GarudaColors.surfaceLight,
        labelStyle: GoogleFonts.inter(fontSize: 12, color: GarudaColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: GarudaColors.glassBorder),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: GarudaColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: GarudaColors.surface,
        selectedItemColor: GarudaColors.accent,
        unselectedItemColor: GarudaColors.textMuted,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: const DividerThemeData(
        color: GarudaColors.glassBorder,
        thickness: 0.5,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: GarudaColors.surfaceLight,
        contentTextStyle: GoogleFonts.inter(color: GarudaColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Glassmorphic decoration builder
BoxDecoration glassDecoration({
  double borderRadius = 16,
  Color? color,
  double opacity = 0.06,
}) {
  return BoxDecoration(
    color: color ?? Colors.white.withValues(alpha: opacity),
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(color: GarudaColors.glassBorder, width: 0.5),
  );
}
