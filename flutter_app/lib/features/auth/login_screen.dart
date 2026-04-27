import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/widgets/funky_box.dart';
import '../../core/widgets/floating_shapes.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;

  // Tagline cycling words
  static const _taglines = [
    'Autonomous',
    'Intelligent',
    'Predictive',
    'Real-time',
  ];
  int _taglineIndex = 0;

  @override
  void initState() {
    super.initState();
    // Cycle tagline word every 2.5 seconds
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 2500));
      if (!mounted) return false;
      setState(() => _taglineIndex = (_taglineIndex + 1) % _taglines.length);
      return true;
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authProvider.notifier).clearError();
    await ref.read(authProvider.notifier).login(
      _emailCtrl.text.trim(),
      _passCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: GarudaColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: FloatingShapes()),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Logo + Brand box ──
                      FunkyBox.diagonal(
                        color: GarudaColors.primaryLight,
                        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
                        child: Column(
                          children: [
                            // Logo with bounce
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: GarudaColors.primaryDark,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: GarudaColors.primaryDark, width: 3),
                              ),
                              child: const Center(
                                child: Text('🦅', style: TextStyle(fontSize: 36)),
                              ),
                            )
                                .animate(onPlay: (c) => c.repeat(reverse: true))
                                .moveY(begin: 0, end: -6, duration: 2.seconds, curve: Curves.easeInOut),
                            const SizedBox(height: 14),
                            Text(
                              'Project Garuda',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                color: GarudaColors.primaryDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Animated cycling tagline
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 500),
                                  transitionBuilder: (child, anim) {
                                    return FadeTransition(
                                      opacity: anim,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0, 0.3),
                                          end: Offset.zero,
                                        ).animate(anim),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Text(
                                    _taglines[_taglineIndex],
                                    key: ValueKey(_taglineIndex),
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: GarudaColors.primary,
                                    ),
                                  ),
                                ),
                                Text(
                                  ' Supply Chain',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: GarudaColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 500.ms).scale(
                            begin: const Offset(0.92, 0.92),
                            end: const Offset(1, 1),
                            curve: Curves.easeOut,
                          ),

                      const SizedBox(height: 16),

                      // ── "Welcome back" + form fields ──
                      FunkyBox.cornerAccent(
                        color: GarudaColors.surface,
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Welcome back',
                                  style: GoogleFonts.outfit(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: GarudaColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('👋', style: TextStyle(fontSize: 24))
                                    .animate(onPlay: (c) => c.repeat(reverse: true))
                                    .rotate(begin: -0.05, end: 0.05, duration: 600.ms)
                                    .then()
                                    .rotate(begin: 0.05, end: -0.05, duration: 600.ms),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sign in to your account',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: GarudaColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 24),

                            _buildFunkyTextField(
                              controller: _emailCtrl,
                              label: 'Email',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Email required';
                                if (!v.contains('@')) return 'Invalid email';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            _buildFunkyTextField(
                              controller: _passCtrl,
                              label: 'Password',
                              icon: Icons.lock_outline,
                              obscureText: _obscure,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: GarudaColors.primaryDark,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Password required';
                                if (v.length < 6) return 'Min 6 characters';
                                return null;
                              },
                              onFieldSubmitted: (_) => _login(),
                            ),

                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {},
                                child: Text(
                                  'Forgot Password?',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: GarudaColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.06),

                      // ── Error box ──
                      if (auth.error != null) ...[
                        const SizedBox(height: 12),
                        FunkyBox(
                          color: GarudaColors.danger,
                          borderRadius: BorderRadius.circular(14),
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.white, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  auth.error!,
                                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ).animate().shake(hz: 3, duration: 400.ms),
                      ],

                      const SizedBox(height: 20),

                      // ── Sign In button ──
                      _TappableBox(
                        onTap: auth.isLoading ? null : _login,
                        child: FunkyBox.pill(
                          color: GarudaColors.primaryDark,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Center(
                            child: auth.isLoading
                                ? const SizedBox(
                                    width: 22, height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.login_rounded, color: Colors.white, size: 20),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Sign In',
                                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 350.ms),

                      const SizedBox(height: 14),

                      // ── OR divider ──
                      Row(
                        children: [
                          Expanded(child: Container(height: 2, color: GarudaColors.glassBorder)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: FunkyBox(
                              color: GarudaColors.background,
                              borderRadius: BorderRadius.circular(20),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              borderWidth: 2,
                              child: Text(
                                'or',
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: GarudaColors.textMuted),
                              ),
                            ),
                          ),
                          Expanded(child: Container(height: 2, color: GarudaColors.glassBorder)),
                        ],
                      ).animate().fadeIn(delay: 380.ms),

                      const SizedBox(height: 14),

                      // ── Create Account button ──
                      _TappableBox(
                        onTap: () => Navigator.push(
                          context,
                          PageRouteBuilder(
                            transitionDuration: const Duration(milliseconds: 500),
                            reverseTransitionDuration: const Duration(milliseconds: 400),
                            pageBuilder: (_, __, ___) => const RegisterScreen(),
                            transitionsBuilder: (_, animation, __, child) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.08),
                                    end: Offset.zero,
                                  ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                                  child: child,
                                ),
                              );
                            },
                          ),
                        ),
                        child: FunkyBox.pill(
                          color: GarudaColors.accent,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.person_add_alt_1_rounded, color: GarudaColors.primaryDark, size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  'Create Account',
                                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: GarudaColors.primaryDark),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 420.ms),

                      const SizedBox(height: 24),

                      // ── Footer ──
                      Center(
                        child: Text(
                          'Google Solution Challenge 2026',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: GarudaColors.textMuted),
                        ),
                      ).animate().fadeIn(delay: 500.ms),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFunkyTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onFieldSubmitted: onFieldSubmitted,
      style: GoogleFonts.inter(color: GarudaColors.textPrimary, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, color: GarudaColors.primaryDark),
        prefixIcon: Icon(icon, color: GarudaColors.primaryDark, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: GarudaColors.primaryDark, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: GarudaColors.primaryDark, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: GarudaColors.primary, width: 3),
        ),
      ),
      validator: validator,
    );
  }
}

/// Adds a subtle scale-down effect when pressed, for tactile feel.
class _TappableBox extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _TappableBox({required this.child, this.onTap});

  @override
  State<_TappableBox> createState() => _TappableBoxState();
}

class _TappableBoxState extends State<_TappableBox> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
