import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/shipment_provider.dart';
import '../../core/providers/routing_provider.dart';
import '../../core/providers/monitor_provider.dart';
import '../../core/providers/intelligence_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/widgets/glassmorphic_card.dart';
import '../../core/widgets/loading_shimmer.dart';
import '../../core/widgets/mode_icon.dart';
import '../../core/widgets/risk_badge.dart';
import '../../core/models/risk_model.dart';
import '../../core/models/routing_model.dart';
import '../../core/models/intelligence_model.dart';
import '../shared/chat_screen.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _initRide());
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
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('Status updated to $status', style: GoogleFonts.inter(color: Colors.white)),
            ],
          ),
          backgroundColor: GarudaColors.success,
        ),
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
        title: Text('Active Ride', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () {
            ref.read(monitorProvider.notifier).stopMonitoring();
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: GarudaColors.primaryLight),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChatScreen(shipmentId: widget.shipmentId, driverName: "Consumer")),
              );
            },
          ),
        ],
      ),
      body: shipment == null
          ? const Padding(padding: EdgeInsets.all(24), child: LoadingShimmer(count: 3))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  GlassmorphicCard(
                    padding: const EdgeInsets.all(20),
                    gradient: LinearGradient(
                      colors: [GarudaColors.card, GarudaColors.cardHover],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: GarudaGradients.delivery,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: modeIconFromString(shipment.routeMode, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    shipment.packageDescription ?? 'Delivery',
                                    style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w700, color: GarudaColors.textPrimary),
                                  ),
                                  const SizedBox(height: 4),
                                  StatusBadge(label: shipment.status.label, color: GarudaColors.primaryLight),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _openNavigation,
                              style: IconButton.styleFrom(
                                backgroundColor: GarudaColors.primary.withValues(alpha: 0.15),
                              ),
                              icon: const Icon(Icons.navigation, color: GarudaColors.primaryLight),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        InfoRow(label: 'Origin', value: shipment.origin.toDisplayString()),
                        InfoRow(label: 'Destination', value: shipment.destination.toDisplayString()),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: 0.1),

                  const SizedBox(height: 20),

                  // Monitor alerts
                  if (monState.lastResponse?.isRerouteNeeded == true)
                    GlassmorphicCard(
                      borderColor: GarudaColors.danger.withValues(alpha: 0.5),
                      gradient: LinearGradient(
                        colors: [GarudaColors.danger.withValues(alpha: 0.15), GarudaColors.card],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber, color: GarudaColors.danger, size: 32),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'REROUTE SUGGESTED',
                                  style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700, color: GarudaColors.danger),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  monState.lastResponse!.displayMessage,
                                  style: GoogleFonts.inter(fontSize: 13, color: GarudaColors.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn().slideX()
                  else if (monState.lastResponse?.isOnTrack == true)
                    GlassmorphicCard(
                      borderColor: GarudaColors.success.withValues(alpha: 0.3),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: GarudaColors.success, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              monState.lastResponse!.displayMessage,
                              style: GoogleFonts.inter(fontSize: 13, color: GarudaColors.textPrimary),
                            ),
                          ),
                          if (monState.isMonitoring)
                            Container(
                              width: 10, height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: GarudaColors.success,
                                boxShadow: [BoxShadow(color: GarudaColors.success.withValues(alpha: 0.5), blurRadius: 8)],
                              ),
                            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.5,1.5), duration: 1.seconds),
                        ],
                      ),
                    ).animate().fadeIn(),

                  const SizedBox(height: 24),
                  const SectionHeader(title: 'Update Status'),
                  
                  // Status grid
                  GlassmorphicCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _statusButton('DISPATCHED', 'Dispatched', Icons.send, GarudaColors.modeBike)),
                            const SizedBox(width: 12),
                            Expanded(child: _statusButton('IN_TRANSIT', 'In Transit', Icons.local_shipping, GarudaColors.warning)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _statusButton('OUT_FOR_DELIVERY', 'Out for Delivery', Icons.delivery_dining, GarudaColors.modeFlight)),
                            const SizedBox(width: 12),
                            Expanded(child: _statusButton('DELIVERED', 'Delivered', Icons.check_circle, GarudaColors.success)),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 100.ms),

                  const SizedBox(height: 24),
                  const SectionHeader(title: 'Driver Tools'),

                  GlassmorphicCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Fatigue Check
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final driverId = ref.read(authProvider).user?.uid ?? 'unknown-driver';
                              final loc = shipment.currentLocation ?? shipment.origin;
                              final res = await ref.read(intelligenceProvider).checkDriverFatigue(
                                driverId: driverId,
                                driveStartTime: DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
                                currentLocation: loc,
                                totalKmDriven: 180,
                                breaksTaken: 1,
                              );
                              if (mounted) {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: GarudaColors.surface,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: GarudaColors.glassBorder)),
                                    title: Text('Fatigue Assessment', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, color: GarudaColors.textPrimary)),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        RiskBadge(
                                          verdict: res.riskLevel == 'High' ? RiskVerdict.highRisk : res.riskLevel == 'Medium' ? RiskVerdict.caution : RiskVerdict.safe,
                                          showScore: false,
                                        ),
                                        const SizedBox(height: 16),
                                        ...res.recommendations.map((r) => Padding(
                                          padding: const EdgeInsets.only(bottom: 8),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Icon(Icons.info_outline, size: 16, color: GarudaColors.textMuted),
                                              const SizedBox(width: 8),
                                              Expanded(child: Text(r, style: GoogleFonts.inter(fontSize: 13, color: GarudaColors.textSecondary))),
                                            ],
                                          ),
                                        )),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))
                                    ],
                                  ),
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(foregroundColor: GarudaColors.info, side: BorderSide(color: GarudaColors.info.withValues(alpha: 0.5))),
                            icon: const Icon(Icons.health_and_safety),
                            label: const Text('Check Fatigue Level'),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 100),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showReportIncidentDialog(context),
        backgroundColor: GarudaColors.danger,
        icon: const Icon(Icons.report_problem),
        label: Text('Report Incident', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _showReportIncidentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: GarudaColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: GarudaColors.glassBorder)),
          title: Row(
            children: [
              const Icon(Icons.warning, color: GarudaColors.danger),
              const SizedBox(width: 8),
              Text('Report Incident', style: GoogleFonts.spaceGrotesk(color: GarudaColors.textPrimary, fontWeight: FontWeight.w700)),
            ],
          ),
          content: Text('Report a roadblock, accident, or hazard to the logistics team.', style: GoogleFonts.inter(color: GarudaColors.textSecondary, height: 1.5)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.inter(color: GarudaColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final shipment = ref.read(shipmentProvider).selectedShipment;
                final driverId = ref.read(authProvider).user?.uid ?? 'unknown-driver';
                if (shipment != null) {
                  await ref.read(shipmentProvider.notifier).reportIncident(
                    widget.shipmentId,
                    'ROAD_BLOCK',
                    'Driver reported sudden roadblock',
                    shipment.currentLocation ?? shipment.origin,
                    0.8,
                    driverId,
                  );
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incident reported')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: GarudaColors.danger),
              child: const Text('Report'),
            ),
          ],
        );
      },
    );
  }

  Widget _statusButton(String status, String label, IconData icon, Color color) {
    return OutlinedButton.icon(
      onPressed: () => _updateStatus(status),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
