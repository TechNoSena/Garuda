import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/shipment_model.dart';
import '../theme/app_theme.dart';

class StatusTimeline extends StatelessWidget {
  final ShipmentStatus currentStatus;

  const StatusTimeline({super.key, required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final lifecycle = ShipmentStatus.lifecycle;
    final currentIndex = currentStatus.lifecycleIndex;

    return Column(
      children: List.generate(lifecycle.length, (i) {
        final status = lifecycle[i];
        final isCompleted = i <= currentIndex && currentStatus.isActive;
        final isCurrent = i == currentIndex;
        final isLast = i == lifecycle.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline dot and line
            SizedBox(
              width: 24,
              child: Column(
                children: [
                  Container(
                    width: isCurrent ? 16 : 12,
                    height: isCurrent ? 16 : 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? GarudaColors.primary
                          : GarudaColors.surfaceLight,
                      border: isCurrent
                          ? Border.all(color: GarudaColors.accent, width: 2)
                          : null,
                      boxShadow: isCurrent
                          ? [BoxShadow(
                              color: GarudaColors.accent.withValues(alpha: 0.4),
                              blurRadius: 8,
                            )]
                          : null,
                    ),
                    child: isCompleted && !isCurrent
                        ? const Icon(Icons.check, size: 8, color: GarudaColors.background)
                        : null,
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 32,
                      color: isCompleted
                          ? GarudaColors.primary.withValues(alpha: 0.6)
                          : GarudaColors.surfaceLight,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Label
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${status.emoji} ${status.label}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                        color: isCompleted
                            ? GarudaColors.textPrimary
                            : GarudaColors.textMuted,
                      ),
                    ),
                    if (isCurrent)
                      Text(
                        'Current Status',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: GarudaColors.accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class StatusChip extends StatelessWidget {
  final ShipmentStatus status;

  const StatusChip({super.key, required this.status});

  Color get _color {
    switch (status) {
      case ShipmentStatus.pending:
        return GarudaColors.textMuted;
      case ShipmentStatus.assigned:
        return GarudaColors.info;
      case ShipmentStatus.dispatched:
        return GarudaColors.modeBike;
      case ShipmentStatus.inTransit:
        return GarudaColors.warning;
      case ShipmentStatus.outForDelivery:
        return GarudaColors.modeFlight;
      case ShipmentStatus.delivered:
        return GarudaColors.success;
      case ShipmentStatus.cancelled:
        return GarudaColors.danger;
      case ShipmentStatus.exception:
        return GarudaColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }
}
