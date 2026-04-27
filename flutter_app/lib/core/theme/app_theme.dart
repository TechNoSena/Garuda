import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════
//  GARUDA COLOR SYSTEM — Custom Light Palette
// ═══════════════════════════════════════════════════════════
class GarudaColors {
  // Core backgrounds
  static const Color background = Color(0xFFF0F4EF); // Porcelain
  static const Color surface = Color(0xFFFFFFFF); // Clean White for cards
  static const Color surfaceLight = Color(0xFFB4CDED); // Powder Blue
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardHover = Color(0xFFE8ECEB);

  // Brand colors
  static const Color primary = Color(0xFF344966);      // Yale Blue
  static const Color primaryDark = Color(0xFF0D1821);  // Ink Black
  static const Color primaryLight = Color(0xFFB4CDED); // Powder Blue
  static const Color accent = Color(0xFFBFCC94);       // Dry Sage
  static const Color accentLight = Color(0xFFD4E0B3);

  // Role colors
  static const Color supplierColor = Color(0xFFBFCC94);   // Dry Sage
  static const Color logisticsColor = Color(0xFF344966);  // Yale Blue
  static const Color deliveryColor = Color(0xFFE5A93A);   // Vibrant Orange-Yellow (adjusted for contrast)
  static const Color consumerColor = Color(0xFF7A6B9E);   // Purple-ish

  // Text
  static const Color textPrimary = Color(0xFF0D1821); // Ink Black
  static const Color textSecondary = Color(0xFF344966); // Yale Blue
  static const Color textMuted = Color(0xFF788D96);

  // Semantic
  static const Color success = Color(0xFFBFCC94); // Dry Sage
  static const Color warning = Color(0xFFE5A93A); 
  static const Color danger = Color(0xFFE65C5C);
  static const Color info = Color(0xFFB4CDED); // Powder Blue

  // Risk
  static const Color riskSafe = Color(0xFFBFCC94);
  static const Color riskCaution = Color(0xFFE5A93A);
  static const Color riskHigh = Color(0xFFE65C5C);

  // Transport mode colors
  static const Color modeCar = Color(0xFF344966);
  static const Color modeBike = Color(0xFF7A6B9E);
  static const Color modeRail = Color(0xFFE5A93A);
  static const Color modeFlight = Color(0xFFBFCC94);
  static const Color modeShip = Color(0xFF5ABCB9);

  // Glass/Borders
  static const Color glass = Color(0x33B4CDED); // Powder Blue with opacity
  static const Color glassBorder = Color(0xFFB4CDED); // Powder Blue
  static const Color glassBorderStrong = Color(0xFF344966); // Yale Blue
}

// ═══════════════════════════════════════════════════════════
//  SOLID COLORS (Previously Gradients)
// ═══════════════════════════════════════════════════════════
class GarudaGradients {
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [GarudaColors.primary, GarudaColors.primary],
  );

  static const LinearGradient supplier = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [GarudaColors.supplierColor, GarudaColors.supplierColor],
  );

  static const LinearGradient logistics = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [GarudaColors.logisticsColor, GarudaColors.logisticsColor],
  );

  static const LinearGradient delivery = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [GarudaColors.deliveryColor, GarudaColors.deliveryColor],
  );

  static const LinearGradient consumer = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [GarudaColors.consumerColor, GarudaColors.consumerColor],
  );

  static const LinearGradient danger = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [GarudaColors.danger, GarudaColors.danger],
  );

  static const LinearGradient success = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [GarudaColors.success, GarudaColors.success],
  );
}

// ═══════════════════════════════════════════════════════════
//  THEME
// ═══════════════════════════════════════════════════════════
class GarudaTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: GarudaColors.background,
      colorScheme: const ColorScheme.light(
        primary: GarudaColors.primary,
        secondary: GarudaColors.accent,
        surface: GarudaColors.surface,
        error: GarudaColors.danger,
        onPrimary: Colors.white,
        onSurface: GarudaColors.textPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
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
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 20, fontWeight: FontWeight.w700, color: GarudaColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: GarudaColors.textPrimary),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: GarudaColors.card,
        elevation: 2,
        shadowColor: GarudaColors.primaryDark.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: GarudaColors.glassBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: GarudaColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: GarudaColors.primary.withValues(alpha: 0.3),
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
        fillColor: GarudaColors.surface,
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
          borderSide: const BorderSide(color: GarudaColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: GarudaColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: GarudaColors.danger, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.inter(color: GarudaColors.textMuted, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: GarudaColors.textSecondary, fontSize: 14),
        prefixIconColor: GarudaColors.textSecondary,
        suffixIconColor: GarudaColors.textSecondary,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: GarudaColors.primary,
        foregroundColor: Colors.white,
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
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: GarudaColors.glassBorder,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: GarudaColors.primaryDark,
        contentTextStyle: GoogleFonts.inter(color: Colors.white),
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
    boxShadow: [
      BoxShadow(
        color: GarudaColors.primaryDark.withValues(alpha: 0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
      )
    ],
  );
}

BoxDecoration gradientCardDecoration(Gradient gradient, {double radius = 16}) {
  return BoxDecoration(
    gradient: gradient,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(
        color: GarudaColors.primaryDark.withValues(alpha: 0.1),
        blurRadius: 12,
        offset: const Offset(0, 6),
      )
    ],
  );
}
