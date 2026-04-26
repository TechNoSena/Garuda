import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/shipment_provider.dart';
import '../../core/providers/routing_provider.dart';
import '../../core/providers/monitor_provider.dart';
import '../../core/widgets/glassmorphic_card.dart';
import '../../core/widgets/loading_shimmer.dart';
import '../../core/widgets/mode_icon.dart';

class ActiveRideScreen extends ConsumerStatefulWidget {
  final String shipmentId;
  const ActiveRideScreen({super.key, required this.shipmentId});

  @override
  ConsumerState<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends ConsumerState<ActiveRideScreen> {
  @override
  void initState() {
    super.initState();
    _initRide();
  }

  Future<void> _initRide() async {
    await ref.read(shipmentProvider.notifier).selectShipment(widget.shipmentId);
    final shipment = ref.read(shipmentProvider).selectedShipment;
    if (shipment == null) return;

    // Start monitoring
    final sessionId = await ref.read(routingProvider.notifier).ensureSession();
    ref.read(monitorProvider.notifier).startMonitoring(
      sessionId: sessionId,
      currentLocation: shipment.currentLocation ?? shipment.origin,
      destination: shipment.destination,
      mode: shipment.routeMode,
      shipmentId: widget.shipmentId,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _updateStatus(String status) async {
    await ref.read(shipmentProvider.notifier).updateStatus(widget.shipmentId, status);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to $status')),
      );
    }
  }

  Future<void> _openNavigation() async {
    final shipment = ref.read(shipmentProvider).selectedShipment;
    if (shipment == null) return;

    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${shipment.currentLocation?.lat ?? shipment.origin.lat},${shipment.currentLocation?.lng ?? shipment.origin.lng}'
      '&destination=${shipment.destination.lat},${shipment.destination.lng}'
      '&travelmode=driving'
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shipState = ref.watch(shipmentProvider);
    final monState = ref.watch(monitorProvider);
    final shipment = shipState.selectedShipment;

    return Scaffold(
      appBar: AppBar(
        title: Text('Active Ride', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () {
            ref.read(monitorProvider.notifier).stopMonitoring();
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.navigation, size: 20),
            onPressed: _openNavigation,
            tooltip: 'Open in Google Maps',
          ),
        ],
      ),
      body: shipment == null
          ? const Center(child: LoadingShimmer(count: 3))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Reroute alert
                  if (monState.lastResponse?.isRerouteNeeded == true)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: GarudaColors.danger.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: GarudaColors.danger.withValues(alpha: 0.5), width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber, color: GarudaColors.danger, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '⚠️ REROUTE SUGGESTED',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: GarudaColors.danger,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  monState.lastResponse!.displayMessage,
                                  style: GoogleFonts.inter(fontSize: 12, color: GarudaColors.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (monState.lastResponse?.isOnTrack == true)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: GarudaColors.success.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: GarudaColors.success.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: GarudaColors.success, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              monState.lastResponse!.displayMessage,
                              style: GoogleFonts.inter(fontSize: 13, color: GarudaColors.textPrimary),
                            ),
                          ),
                          if (monState.isMonitoring)
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: GarudaColors.success,
                                boxShadow: [BoxShadow(color: GarudaColors.success.withValues(alpha: 0.5), blurRadius: 6)],
                              ),
                            ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Route info
                  GlassmorphicCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            modeIconFromString(shipment.routeMode, size: 38),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    shipment.packageDescription ?? 'Delivery',
                                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: GarudaColors.textPrimary),
                                  ),
                                  Text(
                                    shipment.status.label,
                                    style: GoogleFonts.inter(fontSize: 12, color: GarudaColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _routeInfo('From', shipment.origin.toDisplayString(), Icons.trip_origin, GarudaColors.primary),
                        const SizedBox(height: 6),
                        _routeInfo('To', shipment.destination.toDisplayString(), Icons.location_on, GarudaColors.danger),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Navigation button
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _openNavigation,
                      style: ElevatedButton.styleFrom(backgroundColor: GarudaColors.info),
                      icon: const Icon(Icons.navigation),
                      label: const Text('Open in Google Maps'),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Status controls
                  Text(
                    'Update Status',
                    style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: GarudaColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _statusButton('DISPATCHED', 'Dispatched', Icons.send, GarudaColors.modeBike),
                      _statusButton('IN_TRANSIT', 'In Transit', Icons.local_shipping, GarudaColors.warning),
                      _statusButton('OUT_FOR_DELIVERY', 'Out for Delivery', Icons.delivery_dining, GarudaColors.modeFlight),
                      _statusButton('DELIVERED', 'Delivered', Icons.check_circle, GarudaColors.success),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Monitor info
                  GlassmorphicCard(
                    child: Row(
                      children: [
                        Icon(
                          monState.isMonitoring ? Icons.radar : Icons.radar,
                          color: monState.isMonitoring ? GarudaColors.accent : GarudaColors.textMuted,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            monState.isMonitoring
                                ? 'AI monitoring active — checking route every 30s'
                                : 'AI monitoring inactive',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: monState.isMonitoring ? GarudaColors.accent : GarudaColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _statusButton(String status, String label, IconData icon, Color color) {
    return OutlinedButton.icon(
      onPressed: () => _updateStatus(status),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _routeInfo(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text('$label: ', style: GoogleFonts.inter(fontSize: 12, color: GarudaColors.textMuted)),
        Expanded(
          child: Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: GarudaColors.textPrimary)),
        ),
      ],
    );
  }
}
