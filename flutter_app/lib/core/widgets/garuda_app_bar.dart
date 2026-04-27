import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';

class GarudaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final UserRole? role;
  final List<Widget>? actions;
  final bool showBack;

  const GarudaAppBar({
    super.key,
    required this.title,
    this.role,
    this.actions,
    this.showBack = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  Color _roleColor(UserRole r) {
    switch (r) {
      case UserRole.supplier: return GarudaColors.supplierColor;
      case UserRole.logistics: return GarudaColors.logisticsColor;
      case UserRole.deliveryMan: return GarudaColors.deliveryColor;
      case UserRole.consumer: return GarudaColors.consumerColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? GarudaDarkColors.textPrimary : GarudaColors.textPrimary;

    return AppBar(
      automaticallyImplyLeading: showBack,
      title: Row(
        children: [
          Text('🦅 ', style: GoogleFonts.inter(fontSize: 22)),
          Text(title, style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, color: textColor)),
          if (role != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _roleColor(role!).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _roleColor(role!), width: 2),
              ),
              child: Text(
                role!.label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _roleColor(role!),
                ),
              ),
            ),
          ],
        ],
      ),
      actions: actions,
    );
  }
}
