import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/user_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/widgets/funky_box.dart';
import '../../core/widgets/floating_shapes.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _companyController = TextEditingController();
  final _phoneController = TextEditingController();
  UserRole _selectedRole = UserRole.supplier;
  bool _obscurePassword = true;

  // Step emojis & accent colors
  static const _stepEmojis = ['🎭', '✍️', '🔐'];
  static const _stepAccentColors = [
    GarudaColors.warning,
    GarudaColors.supplierColor,
    GarudaColors.primaryLight,
  ];

  // Role descriptions
  static const _roleDescriptions = {
    UserRole.supplier: 'Ship goods & manage inventory',
    UserRole.logistics: 'Optimize routes & fleet management',
    UserRole.deliveryMan: 'Deliver packages on the ground',
    UserRole.consumer: 'Track & receive your orders',
  };

  // Role accent colors
  static const _roleColors = {
    UserRole.supplier: GarudaColors.supplierColor,
    UserRole.logistics: GarudaColors.logisticsColor,
    UserRole.deliveryMan: GarudaColors.deliveryColor,
    UserRole.consumer: GarudaColors.consumerColor,
  };

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
    setState(() => _currentPage = page);
  }

  void _nextPage() {
    if (_currentPage == 1 && !_formKey1.currentState!.validate()) return;
    if (_currentPage < 2) _goTo(_currentPage + 1);
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _goTo(_currentPage - 1);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _register() async {
    if (!_formKey2.currentState!.validate()) return;
    ref.read(authProvider.notifier).clearError();

    final success = await ref.read(authProvider.notifier).register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      role: _selectedRole.value,
      companyName: _companyController.text.isNotEmpty ? _companyController.text.trim() : null,
      phone: _phoneController.text.isNotEmpty ? _phoneController.text.trim() : null,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Registration successful!', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
          backgroundColor: GarudaColors.primaryDark,
        ),
      );
      Navigator.pop(context);
    }
  }

  bool get _showCompanyField =>
      _selectedRole == UserRole.supplier || _selectedRole == UserRole.logistics;

  // Staggered border-radii for each role card
  static const _roleRadii = [
    BorderRadius.only(
      topLeft: Radius.circular(30), topRight: Radius.circular(8),
      bottomLeft: Radius.circular(8), bottomRight: Radius.circular(30),
    ),
    BorderRadius.only(
      topLeft: Radius.circular(8), topRight: Radius.circular(30),
      bottomLeft: Radius.circular(30), bottomRight: Radius.circular(8),
    ),
    BorderRadius.only(
      topLeft: Radius.circular(8), topRight: Radius.circular(8),
      bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30),
    ),
    BorderRadius.only(
      topLeft: Radius.circular(30), topRight: Radius.circular(30),
      bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: GarudaColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: FloatingShapes()),

          SafeArea(
            child: Column(
              children: [
                // ── Header ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      _TappableBox(
                        onTap: _prevPage,
                        child: FunkyBox(
                          color: GarudaColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          padding: const EdgeInsets.all(8),
                          borderWidth: 2,
                          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: GarudaColors.primaryDark),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _buildProgressBar()),
                      const SizedBox(width: 12),
                      // Animated step emoji
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                        child: Text(
                          _stepEmojis[_currentPage],
                          key: ValueKey(_currentPage),
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStep1Role(),
                      _buildStep2BasicInfo(),
                      _buildStep3AccountInfo(authState),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Progress bar with checkmarks ──
  Widget _buildProgressBar() {
    return FunkyBox(
      color: GarudaColors.surface,
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(6),
      borderWidth: 2,
      child: Row(
        children: List.generate(3, (i) {
          final isActive = _currentPage >= i;
          final isDone = _currentPage > i;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              height: 10,
              margin: EdgeInsets.only(left: i > 0 ? 4 : 0),
              decoration: BoxDecoration(
                color: isActive ? _stepAccentColors[i] : GarudaColors.glassBorder,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: isActive ? GarudaColors.primaryDark : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: isDone
                  ? const Center(child: Icon(Icons.check_rounded, size: 8, color: GarudaColors.primaryDark))
                  : null,
            ),
          );
        }),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  STEP 1 — Role Selection
  // ════════════════════════════════════════════════════════
  Widget _buildStep1Role() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          FunkyBox.diagonal(
            color: GarudaColors.warning,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Who are you?',
                      style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900, color: GarudaColors.textPrimary, height: 1.2),
                    ),
                    const SizedBox(width: 8),
                    const Text('🤔', style: TextStyle(fontSize: 28))
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .rotate(begin: -0.05, end: 0.05, duration: 800.ms),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap your role — we\'ll customize everything for you.',
                  style: GoogleFonts.inter(fontSize: 14, color: GarudaColors.textPrimary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.1),

          const SizedBox(height: 20),

          ...UserRole.values.map((role) {
            final i = role.index;
            final isSelected = _selectedRole == role;
            final br = _roleRadii[i % _roleRadii.length];
            final roleColor = _roleColors[role] ?? GarudaColors.surface;

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _TappableBox(
                onTap: () {
                  setState(() => _selectedRole = role);
                  Future.delayed(const Duration(milliseconds: 300), _nextPage);
                },
                child: FunkyBox(
                  color: isSelected ? roleColor.withValues(alpha: 0.3) : GarudaColors.surface,
                  borderRadius: br,
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      // Emoji in a small circle
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                          border: Border.all(color: GarudaColors.primaryDark, width: 2),
                        ),
                        child: Center(child: Text(role.emoji, style: const TextStyle(fontSize: 24))),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              role.label,
                              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: GarudaColors.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _roleDescriptions[role] ?? '',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: GarudaColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: isSelected ? GarudaColors.primaryDark : GarudaColors.primaryDark.withValues(alpha: 0.2),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: 150 + (i * 80))).slideX(begin: 0.04);
          }),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  STEP 2 — Basic Info
  // ════════════════════════════════════════════════════════
  Widget _buildStep2BasicInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Form(
        key: _formKey1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            FunkyBox.leftRound(
              color: GarudaColors.supplierColor,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Nice to meet you!',
                        style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900, color: GarudaColors.textPrimary, height: 1.2),
                      ),
                      const SizedBox(width: 8),
                      const Text('😊', style: TextStyle(fontSize: 26)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'What should we call you?',
                    style: GoogleFonts.inter(fontSize: 15, color: GarudaColors.textPrimary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ).animate().fadeIn().slideX(begin: 0.08),

            const SizedBox(height: 16),

            // Selected role chip
            FunkyBox(
              color: (_roleColors[_selectedRole] ?? GarudaColors.surface).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(30),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              borderWidth: 2,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_selectedRole.emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    'Joining as ${_selectedRole.label}',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: GarudaColors.textPrimary),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 16),

            FunkyBox.bottomRound(
              color: GarudaColors.surface,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildFunkyTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    icon: Icons.person_outline,
                    validator: (v) => v == null || v.isEmpty ? 'Name required' : null,
                  ),
                  if (_showCompanyField) ...[
                    const SizedBox(height: 20),
                    _buildFunkyTextField(
                      controller: _companyController,
                      label: 'Company Name',
                      icon: Icons.business_outlined,
                      validator: (v) => v == null || v.isEmpty ? 'Company required' : null,
                    ),
                  ],
                ],
              ),
            ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.05),

            const SizedBox(height: 20),

            _TappableBox(
              onTap: _nextPage,
              child: FunkyBox.pill(
                color: GarudaColors.primaryDark,
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Continue',
                        style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 250.ms),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  STEP 3 — Account Security
  // ════════════════════════════════════════════════════════
  Widget _buildStep3AccountInfo(AuthState authState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Form(
        key: _formKey2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            FunkyBox.topRound(
              color: GarudaColors.primaryLight,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Almost there!',
                        style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900, color: GarudaColors.textPrimary, height: 1.2),
                      ),
                      const SizedBox(width: 8),
                      const Text('🔒', style: TextStyle(fontSize: 26)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Secure your account with a password.',
                    style: GoogleFonts.inter(fontSize: 15, color: GarudaColors.textPrimary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ).animate().fadeIn().slideX(begin: 0.08),

            const SizedBox(height: 16),

            // Summary chip row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _infoChip(_selectedRole.emoji, _selectedRole.label),
                if (_nameController.text.isNotEmpty)
                  _infoChip('👤', _nameController.text),
              ],
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 16),

            FunkyBox.cornerAccent(
              color: GarudaColors.surface,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildFunkyTextField(
                    controller: _emailController,
                    label: 'Email Address',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Email required';
                      if (!v.contains('@')) return 'Invalid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildFunkyTextField(
                    controller: _passwordController,
                    label: 'Password',
                    icon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: GarudaColors.primaryDark, size: 20),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password required';
                      if (v.length < 6) return 'Min 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildFunkyTextField(
                    controller: _phoneController,
                    label: 'Phone Number (optional)',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.05),

            const SizedBox(height: 14),
            if (authState.error != null)
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
                        authState.error!,
                        style: GoogleFonts.inter(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ).animate().shake(hz: 3, duration: 400.ms),

            const SizedBox(height: 20),

            _TappableBox(
              onTap: authState.isLoading ? null : _register,
              child: FunkyBox.pill(
                color: GarudaColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: authState.isLoading
                      ? const SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(strokeWidth: 3, color: GarudaColors.primaryDark),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.rocket_launch_rounded, color: GarudaColors.primaryDark, size: 22),
                            const SizedBox(width: 10),
                            Text(
                              'Launch Account',
                              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900, color: GarudaColors.primaryDark),
                            ),
                          ],
                        ),
                ),
              ),
            ).animate().fadeIn(delay: 250.ms),
          ],
        ),
      ),
    );
  }

  // ── Helper: info chip ──
  Widget _infoChip(String emoji, String text) {
    return FunkyBox(
      color: GarudaColors.background,
      borderRadius: BorderRadius.circular(30),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      borderWidth: 2,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(text, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: GarudaColors.textPrimary)),
        ],
      ),
    );
  }

  // ── Shared text field builder ──
  Widget _buildFunkyTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
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
