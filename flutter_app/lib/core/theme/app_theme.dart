import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════
//  GARUDA COLOR SYSTEM — Premium Dark Navy + Cyan Accent
// ═══════════════════════════════════════════════════════════
class GarudaColors {
  // Core backgrounds
  static const Color background = Color(0xFF050C1A);
  static const Color surface = Color(0xFF0A1628);
  static const Color surfaceLight = Color(0xFF0F1F3A);
  static const Color card = Color(0xFF0D1B33);
  static const Color cardHover = Color(0xFF122140);

  // Brand gradient colors
  static const Color primary = Color(0xFF00B8FF);      // Cyan blue
  static const Color primaryDark = Color(0xFF0077CC);
  static const Color primaryLight = Color(0xFF4DD7FF);
  static const Color accent = Color(0xFF7B2FFF);       // Electric purple
  static const Color accentLight = Color(0xFFAA78FF);

  // Role colors
  static const Color supplierColor = Color(0xFF00E5A0);   // Emerald green
  static const Color logisticsColor = Color(0xFF00B8FF);  // Cyan blue
  static const Color deliveryColor = Color(0xFFFF8C00);   // Amber orange
  static const Color consumerColor = Color(0xFF7B2FFF);   // Purple

  // Text
  static const Color textPrimary = Color(0xFFEAF4FF);
  static const Color textSecondary = Color(0xFF7BA3CC);
  static const Color textMuted = Color(0xFF3D6080);

  // Semantic
  static const Color success = Color(0xFF00E5A0);
  static const Color warning = Color(0xFFFFB800);
  static const Color danger = Color(0xFFFF3B5C);
  static const Color info = Color(0xFF00B8FF);

  // Risk
  static const Color riskSafe = Color(0xFF00E5A0);
  static const Color riskCaution = Color(0xFFFFB800);
  static const Color riskHigh = Color(0xFFFF3B5C);

  // Transport mode colors
  static const Color modeCar = Color(0xFF00B8FF);
  static const Color modeBike = Color(0xFF7B2FFF);
  static const Color modeRail = Color(0xFFFFB800);
  static const Color modeFlight = Color(0xFF00E5A0);
  static const Color modeShip = Color(0xFF14B8A6);

  // Glass
  static const Color glass = Color(0x0AFFFFFF);
  static const Color glassBorder = Color(0x1A00B8FF);
  static const Color glassBorderStrong = Color(0x3300B8FF);
}

// ═══════════════════════════════════════════════════════════
//  GRADIENTS
// ═══════════════════════════════════════════════════════════
class GarudaGradients {
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00B8FF), Color(0xFF7B2FFF)],
  );

  static const LinearGradient supplier = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00E5A0), Color(0xFF00B8FF)],
  );

  static const LinearGradient logistics = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00B8FF), Color(0xFF0077CC)],
  );

  static const LinearGradient delivery = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF8C00), Color(0xFFFF3B5C)],
  );

  static const LinearGradient consumer = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7B2FFF), Color(0xFF00B8FF)],
  );

  static const LinearGradient danger = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF3B5C), Color(0xFFFF8C00)],
  );

  static const LinearGradient success = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00E5A0), Color(0xFF00B8FF)],
  );
}

// ═══════════════════════════════════════════════════════════
//  THEME
// ═══════════════════════════════════════════════════════════
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
        displayLarge: GoogleFonts.spaceGrotesk(
          fontSize: 36, fontWeight: FontWeight.w800, color: GarudaColors.textPrimary,
        ),
        headlineLarge: GoogleFonts.spaceGrotesk(
          fontSize: 28, fontWeight: FontWeight.w700, color: GarudaColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.spaceGrotesk(
          fontSize: 22, fontWeight: FontWeight.w600, color: GarudaColors.textPrimary,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          fontSize: 18, fontWeight: FontWeight.w600, color: GarudaColors.textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.w500, color: GarudaColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15, color: GarudaColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14, color: GarudaColors.textSecondary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12, color: GarudaColors.textMuted,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w600, color: GarudaColors.textPrimary,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.8, color: GarudaColors.textMuted,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: GarudaColors.surface,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 20, fontWeight: FontWeight.w700, color: GarudaColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: GarudaColors.textPrimary),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: GarudaColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: GarudaColors.glassBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: GarudaColors.primary,
          foregroundColor: GarudaColors.background,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: GarudaColors.primary,
          side: const BorderSide(color: GarudaColors.glassBorderStrong),
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
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: GarudaColors.danger, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.inter(color: GarudaColors.textMuted, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: GarudaColors.textSecondary, fontSize: 14),
        prefixIconColor: GarudaColors.textMuted,
        suffixIconColor: GarudaColors.textMuted,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: GarudaColors.primary,
        foregroundColor: GarudaColors.background,
        elevation: 8,
        extendedPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: GarudaColors.surface,
        selectedItemColor: GarudaColors.primary,
        unselectedItemColor: GarudaColors.textMuted,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: GarudaColors.glassBorder,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: GarudaColors.surfaceLight,
        contentTextStyle: GoogleFonts.inter(color: GarudaColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: GarudaColors.surfaceLight,
        labelStyle: GoogleFonts.inter(fontSize: 12, color: GarudaColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: GarudaColors.glassBorder),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: GarudaColors.primary,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  HELPER DECORATIONS
// ═══════════════════════════════════════════════════════════
BoxDecoration glassDecoration({
  double borderRadius = 16,
  Color? borderColor,
  Gradient? gradient,
  double borderWidth = 1,
}) {
  return BoxDecoration(
    color: GarudaColors.card,
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(
      color: borderColor ?? GarudaColors.glassBorder,
      width: borderWidth,
    ),
    gradient: gradient,
  );
}

BoxDecoration gradientCardDecoration(Gradient gradient, {double radius = 16}) {
  return BoxDecoration(
    gradient: gradient,
    borderRadius: BorderRadius.circular(radius),
  );
}
