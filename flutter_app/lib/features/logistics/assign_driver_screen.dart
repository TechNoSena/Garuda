import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/shipment_provider.dart';
import '../../core/providers/routing_provider.dart';
import '../../core/widgets/glassmorphic_card.dart';
import '../../core/widgets/risk_badge.dart';
import '../../core/widgets/loading_shimmer.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shipmentProvider.notifier).selectShipment(widget.shipmentId);
    });
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
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: GarudaColors.background),
              const SizedBox(width: 8),
              Text('Driver assigned successfully!', style: GoogleFonts.inter(color: GarudaColors.background)),
            ],
          ),
          backgroundColor: GarudaColors.success,
        ),
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
        title: Text('Manage Shipment', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: shipment == null
          ? const Padding(padding: EdgeInsets.all(24), child: LoadingShimmer(count: 3))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Shipment info
                  GlassmorphicCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: GarudaGradients.logistics,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.inventory_2, color: GarudaColors.background, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    shipment.packageDescription ?? 'Shipment',
                                    style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w700, color: GarudaColors.textPrimary),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'ID: ${shipment.shipmentId}',
                                    style: GoogleFonts.inter(fontSize: 11, color: GarudaColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        InfoRow(label: 'Origin', value: shipment.origin.toDisplayString()),
                        InfoRow(label: 'Destination', value: shipment.destination.toDisplayString()),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: 0.1),

                  const SizedBox(height: 24),
                  const SectionHeader(title: 'Assign Driver'),
                  
                  // Assign driver
                  GlassmorphicCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select the delivery personnel for this route.',
                          style: GoogleFonts.inter(fontSize: 13, color: GarudaColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _driverIdCtrl,
                                style: GoogleFonts.inter(color: GarudaColors.textPrimary, fontSize: 14),
                                decoration: const InputDecoration(
                                  hintText: 'Enter Driver UID',
                                  prefixIcon: Icon(Icons.person_search, size: 20),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _assignDriver,
                                style: ElevatedButton.styleFrom(backgroundColor: GarudaColors.logisticsColor),
                                child: const Text('Assign'),
                              ),
                            ),
                          ],
                        ),
                        if (shipment.deliveryManId != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: GarudaColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: GarudaColors.success.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, size: 16, color: GarudaColors.success),
                                const SizedBox(width: 8),
                                Text(
                                  'Assigned to: ${shipment.deliveryManId}',
                                  style: GoogleFonts.inter(fontSize: 13, color: GarudaColors.success, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

                  const SizedBox(height: 24),
                  
                  // Risk analysis
                  const SectionHeader(title: 'Route Risk Analysis'),
                  if (routeState.riskAnalysis == null)
                    GradientButton(
                      label: 'Analyze Risk Factors',
                      icon: Icons.shield_outlined,
                      isLoading: routeState.isLoading,
                      onPressed: _analyzeRisk,
                      gradient: GarudaGradients.consumer,
                    ).animate().fadeIn(delay: 200.ms)
                  else
                    GlassmorphicCard(
                      borderColor: routeState.riskAnalysis!.verdict.color.withValues(alpha: 0.4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              RiskBadge(
                                verdict: routeState.riskAnalysis!.verdict,
                                score: routeState.riskAnalysis!.riskScore,
                              ),
                            ],
                          ),
                          if (routeState.riskAnalysis!.headsUp != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              routeState.riskAnalysis!.headsUp!,
                              style: GoogleFonts.inter(fontSize: 13, color: GarudaColors.textPrimary, height: 1.5),
                            ),
                          ],
                        ],
                      ),
                    ).animate().fadeIn(),

                  const SizedBox(height: 24),

                  // Status timeline
                  const SectionHeader(title: 'Shipment Status'),
                  GlassmorphicCard(
                    child: StatusTimeline(currentStatus: shipment.status),
                  ).animate().fadeIn(delay: 300.ms),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}
