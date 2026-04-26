import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/shipment_provider.dart';
import '../../core/widgets/glassmorphic_card.dart';
import '../../core/widgets/status_timeline.dart';
import '../../core/widgets/mode_icon.dart';
import '../../core/widgets/loading_shimmer.dart';

class ShipmentDetailScreen extends ConsumerStatefulWidget {
  final String shipmentId;
  const ShipmentDetailScreen({super.key, required this.shipmentId});

  @override
  ConsumerState<ShipmentDetailScreen> createState() => _ShipmentDetailScreenState();
}

class _ShipmentDetailScreenState extends ConsumerState<ShipmentDetailScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(shipmentProvider.notifier).selectShipment(widget.shipmentId);
    ref.read(shipmentProvider.notifier).loadEta(widget.shipmentId);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shipmentProvider);
    final shipment = state.selectedShipment;
    final eta = state.currentEta;

    return Scaffold(
      appBar: AppBar(
        title: Text('Shipment Details', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () {
              ref.read(shipmentProvider.notifier).selectShipment(widget.shipmentId);
              ref.read(shipmentProvider.notifier).loadEta(widget.shipmentId);
            },
          ),
        ],
      ),
      body: state.isLoading && shipment == null
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: LoadingShimmer(count: 5),
            )
          : shipment == null
              ? Center(
                  child: Text(
                    'Shipment not found',
                    style: GoogleFonts.inter(color: GarudaColors.textMuted),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header card
                      GlassmorphicCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                modeIconFromString(shipment.routeMode, size: 42),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        shipment.packageDescription ?? 'Shipment',
                                        style: GoogleFonts.outfit(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: GarudaColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'ID: ${shipment.shipmentId.substring(0, shipment.shipmentId.length.clamp(0, 12))}...',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: GarudaColors.textMuted,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Route
                            _infoRow(Icons.trip_origin, 'Origin', shipment.origin.toDisplayString()),
                            const SizedBox(height: 8),
                            _infoRow(Icons.location_on, 'Destination', shipment.destination.toDisplayString()),
                            if (shipment.currentLocation != null) ...[
                              const SizedBox(height: 8),
                              _infoRow(Icons.my_location, 'Current', shipment.currentLocation!.toDisplayString()),
                            ],
                            if (shipment.weightKg != null) ...[
                              const SizedBox(height: 8),
                              _infoRow(Icons.scale, 'Weight', '${shipment.weightKg} kg'),
                            ],
                          ],
                        ),
                      ),

                      // ETA card
                      if (eta != null)
                        GlassmorphicCard(
                          borderColor: GarudaColors.primary.withValues(alpha: 0.4),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: GarudaColors.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.timer, color: GarudaColors.primaryLight, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Estimated Arrival',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: GarudaColors.textMuted,
                                      ),
                                    ),
                                    Text(
                                      '${eta.etaMinutes} minutes',
                                      style: GoogleFonts.outfit(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: GarudaColors.primaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${eta.remainingKm.toStringAsFixed(1)} km',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: GarudaColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'remaining',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: GarudaColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 8),

                      // Status timeline
                      GlassmorphicCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status Timeline',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: GarudaColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            StatusTimeline(currentStatus: shipment.status),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: GarudaColors.textMuted),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.inter(fontSize: 12, color: GarudaColors.textMuted),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: GarudaColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
