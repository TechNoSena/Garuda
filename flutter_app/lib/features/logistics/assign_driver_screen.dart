import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/shipment_provider.dart';
import '../../core/providers/routing_provider.dart';
import '../../core/widgets/glassmorphic_card.dart';
import '../../core/widgets/risk_badge.dart';
import '../../core/widgets/loading_shimmer.dart';
import '../../core/widgets/mode_icon.dart';
import '../../core/widgets/status_timeline.dart';

class AssignDriverScreen extends ConsumerStatefulWidget {
  final String shipmentId;
  const AssignDriverScreen({super.key, required this.shipmentId});

  @override
  ConsumerState<AssignDriverScreen> createState() => _AssignDriverScreenState();
}

class _AssignDriverScreenState extends ConsumerState<AssignDriverScreen> {
  final _driverIdCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    ref.read(shipmentProvider.notifier).selectShipment(widget.shipmentId);
  }

  @override
  void dispose() {
    _driverIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _assignDriver() async {
    if (_driverIdCtrl.text.trim().isEmpty) return;
    await ref.read(shipmentProvider.notifier).assignDriver(
      widget.shipmentId,
      _driverIdCtrl.text.trim(),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Driver assigned!')),
      );
    }
  }

  void _analyzeRisk() {
    final shipment = ref.read(shipmentProvider).selectedShipment;
    if (shipment == null) return;
    ref.read(routingProvider.notifier).analyzeRisk(
      origin: shipment.origin,
      destination: shipment.destination,
      mode: shipment.routeMode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shipmentProvider);
    final routeState = ref.watch(routingProvider);
    final shipment = state.selectedShipment;

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Shipment', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: shipment == null
          ? const Center(child: LoadingShimmer(count: 3))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Shipment info
                  GlassmorphicCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            modeIconFromString(shipment.routeMode, size: 40),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    shipment.packageDescription ?? 'Shipment',
                                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: GarudaColors.textPrimary),
                                  ),
                                  StatusChip(status: shipment.status),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _infoRow('From', shipment.origin.toDisplayString()),
                        _infoRow('To', shipment.destination.toDisplayString()),
                      ],
                    ),
                  ),

                  // Assign driver
                  GlassmorphicCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🛵 Assign Delivery Person',
                          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: GarudaColors.textPrimary),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _driverIdCtrl,
                                style: GoogleFonts.inter(color: GarudaColors.textPrimary, fontSize: 13),
                                decoration: const InputDecoration(
                                  hintText: 'Driver UID',
                                  prefixIcon: Icon(Icons.person_search, size: 20),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: _assignDriver,
                              child: const Text('Assign'),
                            ),
                          ],
                        ),
                        if (shipment.deliveryManId != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Currently assigned: ${shipment.deliveryManId}',
                            style: GoogleFonts.inter(fontSize: 11, color: GarudaColors.success),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Risk analysis
                  OutlinedButton.icon(
                    onPressed: routeState.isLoading ? null : _analyzeRisk,
                    icon: const Icon(Icons.shield_outlined, size: 18),
                    label: const Text('Run Risk Analysis'),
                  ),
                  if (routeState.riskAnalysis != null) ...[
                    const SizedBox(height: 8),
                    GlassmorphicCard(
                      borderColor: routeState.riskAnalysis!.verdict.color.withValues(alpha: 0.4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RiskBadge(
                            verdict: routeState.riskAnalysis!.verdict,
                            score: routeState.riskAnalysis!.riskScore,
                          ),
                          if (routeState.riskAnalysis!.headsUp != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              routeState.riskAnalysis!.headsUp!,
                              style: GoogleFonts.inter(fontSize: 13, color: GarudaColors.textPrimary),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Status timeline
                  GlassmorphicCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Status', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: GarudaColors.textPrimary)),
                        const SizedBox(height: 12),
                        StatusTimeline(currentStatus: shipment.status),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('$label: ', style: GoogleFonts.inter(fontSize: 12, color: GarudaColors.textMuted)),
          Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: GarudaColors.textPrimary)),
        ],
      ),
    );
  }
}
