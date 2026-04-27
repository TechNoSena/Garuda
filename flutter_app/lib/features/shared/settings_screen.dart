import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/widgets/funky_box.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final auth = ref.watch(authProvider);
    final textColor = isDark ? GarudaDarkColors.textPrimary : GarudaColors.textPrimary;
    final bgColor = isDark ? GarudaDarkColors.surface : GarudaColors.surface;

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile card
            FunkyBox.diagonal(
              color: isDark ? GarudaDarkColors.surfaceLight : GarudaColors.primaryLight,
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: GarudaColors.primaryDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: GarudaColors.primaryDark, width: 3),
                    ),
                    child: Center(
                      child: Text(
                        auth.user?.name.isNotEmpty == true ? auth.user!.name[0].toUpperCase() : '?',
                        style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.user?.name ?? 'User',
                          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: textColor),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          auth.user?.email ?? '',
                          style: GoogleFonts.inter(fontSize: 13, color: GarudaColors.textMuted),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: GarudaColors.accent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: GarudaColors.accent, width: 2),
                          ),
                          child: Text(
                            auth.user?.role.label ?? '',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: GarudaColors.accent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.08),

            const SizedBox(height: 24),

            // Appearance section
            Text(
              'Appearance',
              style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700, color: textColor),
            ),
            const SizedBox(height: 12),

            GestureDetector(
              onTap: () => ref.read(themeProvider.notifier).toggle(),
              child: FunkyBox.leftRound(
                color: bgColor,
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark ? GarudaColors.warning.withValues(alpha: 0.15) : GarudaColors.primaryDark.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: GarudaColors.primaryDark, width: 2),
                      ),
                      child: Icon(
                        isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        color: isDark ? GarudaColors.warning : GarudaColors.primaryDark,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isDark ? 'Dark Mode' : 'Light Mode',
                            style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w800, color: textColor),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isDark ? 'Switch to light mode' : 'Switch to dark mode',
                            style: GoogleFonts.inter(fontSize: 13, color: GarudaColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 52,
                      height: 30,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: isDark ? GarudaColors.accent : GarudaColors.glassBorder,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: GarudaColors.primaryDark, width: 2),
                      ),
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: isDark ? GarudaColors.primaryDark : Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.06),

            const SizedBox(height: 24),

            // About section
            Text(
              'About',
              style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700, color: textColor),
            ),
            const SizedBox(height: 12),

            FunkyBox.cornerAccent(
              color: bgColor,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset('garuda_logo.png', width: 28, height: 28),
                      const SizedBox(width: 10),
                      Text('Project Garuda', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w800, color: textColor)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Autonomous Supply Chain Intelligence Engine\nGoogle Solution Challenge 2026',
                    style: GoogleFonts.inter(fontSize: 13, color: GarudaColors.textMuted, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Text('v1.0.0', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: GarudaColors.primary)),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.06),

            const SizedBox(height: 24),

            // Logout button
            GestureDetector(
              onTap: () {
                ref.read(authProvider.notifier).logout();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: FunkyBox.pill(
                color: GarudaColors.danger,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text('Logout', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
