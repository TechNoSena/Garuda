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

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: showBack,
      title: Row(
        children: [
          Text('🦅 ', style: GoogleFonts.inter(fontSize: 22)),
          Text(title),
          if (role != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: GarudaColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: GarudaColors.primary.withValues(alpha: 0.4)),
              ),
              child: Text(
                role!.label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: GarudaColors.primaryLight,
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
