import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/risk_model.dart';

class RiskBadge extends StatelessWidget {
  final RiskVerdict verdict;
  final double? score;
  final bool showScore;
  final bool compact;

  const RiskBadge({
    super.key,
    required this.verdict,
    this.score,
    this.showScore = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: verdict.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: verdict.color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(verdict.icon, size: compact ? 14 : 18, color: verdict.color),
          const SizedBox(width: 6),
          Text(
            verdict.label,
            style: GoogleFonts.inter(
              fontSize: compact ? 11 : 13,
              fontWeight: FontWeight.w600,
              color: verdict.color,
            ),
          ),
          if (showScore && score != null) ...[
            const SizedBox(width: 6),
            Text(
              '${score!.toStringAsFixed(0)}%',
              style: GoogleFonts.inter(
                fontSize: compact ? 10 : 12,
                fontWeight: FontWeight.w500,
                color: verdict.color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
