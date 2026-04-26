import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/shipment_model.dart';
import '../theme/app_theme.dart';

/// Stat card used on dashboards
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: GarudaColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shipment list tile with status chip
class ShipmentTile extends StatelessWidget {
  final Shipment shipment;
  final VoidCallback? onTap;

  const ShipmentTile({super.key, required this.shipment, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: GarudaColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: GarudaColors.glassBorder, width: 0.5),
        ),
        child: Row(
          children: [
            // Mode icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _modeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_modeIcon, size: 20, color: _modeColor),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shipment.packageDescription ?? 'Shipment',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: GarudaColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${shipment.origin.toDisplayString()} → ${shipment.destination.toDisplayString()}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: GarudaColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Status
            _buildStatusChip(),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: GarudaColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  Color get _modeColor {
    switch (shipment.routeMode) {
      case 'ROAD_CAR': return GarudaColors.modeCar;
      case 'ROAD_BIKE': return GarudaColors.modeBike;
      case 'RAIL': return GarudaColors.modeRail;
      case 'FLIGHT': return GarudaColors.modeFlight;
      case 'SHIP': return GarudaColors.modeShip;
      default: return GarudaColors.modeCar;
    }
  }

  IconData get _modeIcon {
    switch (shipment.routeMode) {
      case 'ROAD_CAR': return Icons.local_shipping;
      case 'ROAD_BIKE': return Icons.two_wheeler;
      case 'RAIL': return Icons.train;
      case 'FLIGHT': return Icons.flight;
      case 'SHIP': return Icons.directions_boat;
      default: return Icons.local_shipping;
    }
  }

  Widget _buildStatusChip() {
    final color = _statusColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        shipment.status.label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color get _statusColor {
    switch (shipment.status) {
      case ShipmentStatus.pending: return GarudaColors.textMuted;
      case ShipmentStatus.assigned: return GarudaColors.info;
      case ShipmentStatus.dispatched: return GarudaColors.modeBike;
      case ShipmentStatus.inTransit: return GarudaColors.warning;
      case ShipmentStatus.outForDelivery: return GarudaColors.modeFlight;
      case ShipmentStatus.delivered: return GarudaColors.success;
      case ShipmentStatus.cancelled: return GarudaColors.danger;
      case ShipmentStatus.exception: return GarudaColors.danger;
    }
  }
}

/// Empty state placeholder
class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: GarudaColors.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: GarudaColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: GarudaColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
