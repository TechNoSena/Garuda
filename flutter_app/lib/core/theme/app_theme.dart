import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════════
//  GARUDA COLOR SYSTEM
// ═══════════════════════════════════════════════════════════
class GarudaColors {
  // Core backgrounds (light)
  static const Color background = Color(0xFFF0F4EF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFB4CDED);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardHover = Color(0xFFE8ECEB);

  // Brand colors
  static const Color primary = Color(0xFF344966);
  static const Color primaryDark = Color(0xFF0D1821);
  static const Color primaryLight = Color(0xFFB4CDED);
  static const Color accent = Color(0xFFBFCC94);
  static const Color accentLight = Color(0xFFD4E0B3);

  // Role colors
  static const Color supplierColor = Color(0xFFBFCC94);
  static const Color logisticsColor = Color(0xFF344966);
  static const Color deliveryColor = Color(0xFFE5A93A);
  static const Color consumerColor = Color(0xFF7A6B9E);

  // Text
  static const Color textPrimary = Color(0xFF0D1821);
  static const Color textSecondary = Color(0xFF344966);
  static const Color textMuted = Color(0xFF788D96);

  // Semantic
  static const Color success = Color(0xFFBFCC94);
  static const Color warning = Color(0xFFE5A93A);
  static const Color danger = Color(0xFFE65C5C);
  static const Color info = Color(0xFFB4CDED);

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
  static const Color glass = Color(0x33B4CDED);
  static const Color glassBorder = Color(0xFFB4CDED);
  static const Color glassBorderStrong = Color(0xFF344966);
}

// ═══════════════════════════════════════════════════════════
//  DARK MODE COLORS
// ═══════════════════════════════════════════════════════════
class GarudaDarkColors {
  static const Color background = Color(0xFF0D1821);
  static const Color surface = Color(0xFF162029);
  static const Color surfaceLight = Color(0xFF1E2D3A);
  static const Color card = Color(0xFF162029);
  static const Color cardHover = Color(0xFF1E2D3A);
  static const Color primaryDark = Color(0xFFE8ECEB);
  static const Color textPrimary = Color(0xFFF0F4EF);
  static const Color textSecondary = Color(0xFFB4CDED);
  static const Color textMuted = Color(0xFF788D96);
  static const Color glassBorder = Color(0xFF2A3A47);
  static const Color glassBorderStrong = Color(0xFF4A6070);
}

// ═══════════════════════════════════════════════════════════
//  SOLID GRADIENTS (kept for backward compat)
// ═══════════════════════════════════════════════════════════
class GarudaGradients {
  static const LinearGradient primary = LinearGradient(
    colors: [GarudaColors.primary, GarudaColors.primary],
  );
  static const LinearGradient supplier = LinearGradient(
    colors: [GarudaColors.supplierColor, GarudaColors.supplierColor],
  );
  static const LinearGradient logistics = LinearGradient(
    colors: [GarudaColors.logisticsColor, GarudaColors.logisticsColor],
  );
  static const LinearGradient delivery = LinearGradient(
    colors: [GarudaColors.deliveryColor, GarudaColors.deliveryColor],
  );
  static const LinearGradient consumer = LinearGradient(
    colors: [GarudaColors.consumerColor, GarudaColors.consumerColor],
  );
  static const LinearGradient danger = LinearGradient(
    colors: [GarudaColors.danger, GarudaColors.danger],
  );
  static const LinearGradient success = LinearGradient(
    colors: [GarudaColors.success, GarudaColors.success],
  );
}

// ═══════════════════════════════════════════════════════════
//  THEME PROVIDER (dark/light toggle)
// ═══════════════════════════════════════════════════════════
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('dark_mode') ?? false;
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggle() async {
    final prefs = await SharedPreferences.getInstance();
    if (state == ThemeMode.dark) {
      state = ThemeMode.light;
      await prefs.setBool('dark_mode', false);
    } else {
      state = ThemeMode.dark;
      await prefs.setBool('dark_mode', true);
    }
  }

  bool get isDark => state == ThemeMode.dark;
}

// ═══════════════════════════════════════════════════════════
//  THEME
// ═══════════════════════════════════════════════════════════
class GarudaTheme {
  static ThemeData get lightTheme {
    return _buildTheme(
      brightness: Brightness.light,
      background: GarudaColors.background,
      surface: GarudaColors.surface,
      card: GarudaColors.card,
      onSurface: GarudaColors.textPrimary,
      overlay: SystemUiOverlayStyle.dark,
    );
  }

  static ThemeData get darkTheme {
    return _buildTheme(
      brightness: Brightness.dark,
      background: GarudaDarkColors.background,
      surface: GarudaDarkColors.surface,
      card: GarudaDarkColors.card,
      onSurface: GarudaDarkColors.textPrimary,
      overlay: SystemUiOverlayStyle.light,
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color card,
    required Color onSurface,
    required SystemUiOverlayStyle overlay,
  }) {
    final isDark = brightness == Brightness.dark;
    final textMuted = isDark ? GarudaDarkColors.textMuted : GarudaColors.textMuted;
    final textSecondary = isDark ? GarudaDarkColors.textSecondary : GarudaColors.textSecondary;
    final border = isDark ? GarudaDarkColors.glassBorder : GarudaColors.glassBorder;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: GarudaColors.primary,
        secondary: GarudaColors.accent,
        surface: surface,
        error: GarudaColors.danger,
        onPrimary: Colors.white,
        onSecondary: GarudaColors.primaryDark,
        onSurface: onSurface,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.spaceGrotesk(fontSize: 36, fontWeight: FontWeight.w800, color: onSurface),
        headlineLarge: GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.w700, color: onSurface),
        headlineMedium: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w600, color: onSurface),
        titleLarge: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w600, color: onSurface),
        titleMedium: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: onSurface),
        bodyLarge: GoogleFonts.inter(fontSize: 15, color: onSurface),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: textSecondary),
        bodySmall: GoogleFonts.inter(fontSize: 12, color: textMuted),
        labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: onSurface),
        labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.8, color: textMuted),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: overlay,
        titleTextStyle: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w700, color: onSurface),
        iconTheme: IconThemeData(color: onSurface),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: GarudaColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: GarudaColors.primary,
          side: BorderSide(color: isDark ? GarudaDarkColors.glassBorderStrong : GarudaColors.glassBorderStrong),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: GarudaColors.primary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: GarudaColors.danger)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: GarudaColors.danger, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.inter(color: textMuted, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: textSecondary, fontSize: 14),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: GarudaColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        extendedPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: GarudaColors.primary,
        unselectedItemColor: textMuted,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: GarudaColors.primaryDark,
        contentTextStyle: GoogleFonts.inter(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? GarudaDarkColors.surfaceLight : GarudaColors.surfaceLight,
        labelStyle: GoogleFonts.inter(fontSize: 12, color: onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: border),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: GarudaColors.primary),
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
    border: Border.all(color: borderColor ?? GarudaColors.glassBorder, width: borderWidth),
    gradient: gradient,
  );
}

BoxDecoration gradientCardDecoration(Gradient gradient, {double radius = 16}) {
  return BoxDecoration(
    gradient: gradient,
    borderRadius: BorderRadius.circular(radius),
  );
}
