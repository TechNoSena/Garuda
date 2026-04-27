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
import '../../core/models/shipment_model.dart';

class AssignDriverScreen extends ConsumerStatefulWidget {
  final String shipmentId;
  const AssignDriverScreen({super.key, required this.shipmentId});

  @override
  ConsumerState<AssignDriverScreen> createState() => _AssignDriverScreenState();
}

class _AssignDriverScreenState extends ConsumerState<AssignDriverScreen> {
  final _driverIdCtrl = TextEditingController();
  DeliveryType _selectedDeliveryType = DeliveryType.lastMile;
  List<Shipment> _coupleCandidates = [];
  final List<String> _selectedCoupleIds = [];
  bool _isLoadingCandidates = false;

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

  /// When relay type is selected, load other pending shipments to the same destination for coupling
  Future<void> _loadCoupleCandidates() async {
    final shipment = ref.read(shipmentProvider).selectedShipment;
    if (shipment == null) return;

    setState(() => _isLoadingCandidates = true);
    try {
      // Load all pending shipments for this logistics partner
      final allShipments = ref.read(shipmentProvider).shipments;
      final candidates = allShipments.where((s) =>
          s.shipmentId != widget.shipmentId &&
          s.status == ShipmentStatus.pending &&
          s.destination.lat == shipment.destination.lat &&
          s.destination.lng == shipment.destination.lng).toList();
      setState(() => _coupleCandidates = candidates);
    } catch (_) {}
    setState(() => _isLoadingCandidates = false);
  }

  Future<void> _assignDriver() async {
    if (_driverIdCtrl.text.trim().isEmpty) return;

    // For last mile, destination is auto-set from shipment
    // For relay, ask driver for warehouse destination (already set from shipment destination)

    await ref.read(shipmentProvider.notifier).assignDriver(widget.shipmentId, _driverIdCtrl.text.trim());

    // If relay with coupled shipments, assign same driver to all coupled
    if (_selectedDeliveryType == DeliveryType.relay && _selectedCoupleIds.isNotEmpty) {
      for (final coupleId in _selectedCoupleIds) {
        try {
          await ref.read(shipmentProvider.notifier).assignDriver(coupleId, _driverIdCtrl.text.trim());
        } catch (_) {}
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                _selectedCoupleIds.isNotEmpty
                    ? 'Driver assigned to ${_selectedCoupleIds.length + 1} coupled shipments!'
                    : 'Driver assigned successfully!',
                style: GoogleFonts.inter(color: Colors.white),
              ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? GarudaDarkColors.textPrimary : GarudaColors.textPrimary;
    final mutedColor = isDark ? GarudaDarkColors.textMuted : GarudaColors.textMuted;
    final state = ref.watch(shipmentProvider);
    final routeState = ref.watch(routingProvider);
    final shipment = state.selectedShipment;

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Shipment', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, size: 18), onPressed: () => Navigator.pop(context)),
      ),
      body: shipment == null
          ? const Padding(padding: EdgeInsets.all(24), child: LoadingShimmer(count: 3))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                                color: GarudaColors.logisticsColor,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: GarudaColors.primaryDark, width: 2),
                              ),
                              child: const Icon(Icons.inventory_2, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(shipment.packageDescription ?? 'Shipment', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: textColor)),
                                  const SizedBox(height: 4),
                                  Text('ID: ${shipment.shipmentId}', style: GoogleFonts.inter(fontSize: 11, color: mutedColor)),
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

                  // Delivery Type Selector
                  const SectionHeader(title: 'Delivery Type'),
                  GlassmorphicCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Select how this shipment will be delivered:', style: GoogleFonts.inter(fontSize: 13, color: isDark ? GarudaDarkColors.textSecondary : GarudaColors.textSecondary)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _deliveryTypeChip(
                              DeliveryType.lastMile,
                              '🏃 Last Mile',
                              'City delivery to consumer addresses',
                              Icons.delivery_dining,
                              isDark, textColor, mutedColor,
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: _deliveryTypeChip(
                              DeliveryType.relay,
                              '🏭 Relay',
                              'Warehouse → Warehouse bulk',
                              Icons.local_shipping,
                              isDark, textColor, mutedColor,
                            )),
                          ],
                        ),
                        // Auto-info based on type
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: GarudaColors.info.withValues(alpha: isDark ? 0.1 : 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: GarudaColors.info.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline, size: 16, color: GarudaColors.info),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedDeliveryType == DeliveryType.lastMile
                                      ? 'Last Mile: Driver picks up from city warehouse and delivers to multiple consumer addresses in ${shipment.destination.toDisplayString()}.'
                                      : 'Relay: Driver takes all coupled orders from origin warehouse to destination warehouse at ${shipment.destination.toDisplayString()}.',
                                  style: GoogleFonts.inter(fontSize: 12, color: textColor, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.1),

                  // Couple Orders (for Relay type)
                  if (_selectedDeliveryType == DeliveryType.relay) ...[
                    const SizedBox(height: 16),
                    const SectionHeader(title: 'Couple Orders (Same Destination)'),
                    GlassmorphicCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Batch shipments going to the same warehouse for this driver.', style: GoogleFonts.inter(fontSize: 13, color: mutedColor)),
                          const SizedBox(height: 12),
                          if (_coupleCandidates.isEmpty && !_isLoadingCandidates)
                            OutlinedButton.icon(
                              onPressed: _loadCoupleCandidates,
                              icon: const Icon(Icons.search, size: 16),
                              label: const Text('Find Similar Shipments'),
                            ),
                          if (_isLoadingCandidates)
                            const Center(child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )),
                          if (_coupleCandidates.isNotEmpty)
                            ..._coupleCandidates.map((s) {
                              final isSelected = _selectedCoupleIds.contains(s.shipmentId);
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedCoupleIds.remove(s.shipmentId);
                                    } else {
                                      _selectedCoupleIds.add(s.shipmentId);
                                    }
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected ? GarudaColors.success.withValues(alpha: 0.1) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected ? GarudaColors.success : (isDark ? GarudaDarkColors.glassBorder : GarudaColors.glassBorder),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                                        size: 20,
                                        color: isSelected ? GarudaColors.success : mutedColor,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(s.packageDescription ?? 'Shipment', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                                            Text('ID: ${s.shipmentId}', style: GoogleFonts.inter(fontSize: 10, color: mutedColor)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          if (_coupleCandidates.isEmpty && !_isLoadingCandidates)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text('No matching shipments found for same destination.', style: GoogleFonts.inter(fontSize: 12, color: mutedColor)),
                            ),
                          if (_selectedCoupleIds.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: GarudaColors.success.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: GarudaColors.success, width: 1.5),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.link, size: 16, color: GarudaColors.success),
                                    const SizedBox(width: 8),
                                    Text('${_selectedCoupleIds.length} orders coupled', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: GarudaColors.success)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 100.ms),
                  ],

                  const SizedBox(height: 24),
                  const SectionHeader(title: 'Assign Driver'),
                  
                  GlassmorphicCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedDeliveryType == DeliveryType.lastMile
                              ? 'Assign a last-mile driver for city deliveries.'
                              : 'Assign a relay driver for warehouse-to-warehouse transport.',
                          style: GoogleFonts.inter(fontSize: 13, color: isDark ? GarudaDarkColors.textSecondary : GarudaColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _driverIdCtrl,
                                style: GoogleFonts.inter(color: textColor, fontSize: 14),
                                decoration: const InputDecoration(hintText: 'Enter Driver UID or Email', prefixIcon: Icon(Icons.person_search, size: 20)),
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
                              border: Border.all(color: GarudaColors.success, width: 2),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, size: 16, color: GarudaColors.success),
                                const SizedBox(width: 8),
                                Text('Assigned to: ${shipment.deliveryManId}', style: GoogleFonts.inter(fontSize: 13, color: GarudaColors.success, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),

                  const SizedBox(height: 24),
                  
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
                      borderColor: routeState.riskAnalysis!.verdict.color,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [RiskBadge(verdict: routeState.riskAnalysis!.verdict, score: routeState.riskAnalysis!.riskScore)]),
                          if (routeState.riskAnalysis!.headsUp != null) ...[
                            const SizedBox(height: 12),
                            Text(routeState.riskAnalysis!.headsUp!, style: GoogleFonts.inter(fontSize: 13, color: textColor, height: 1.5)),
                          ],
                        ],
                      ),
                    ).animate().fadeIn(),

                  const SizedBox(height: 24),
                  const SectionHeader(title: 'Shipment Status'),
                  GlassmorphicCard(child: StatusTimeline(currentStatus: shipment.status)).animate().fadeIn(delay: 300.ms),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _deliveryTypeChip(DeliveryType type, String label, String subtitle, IconData icon, bool isDark, Color textColor, Color mutedColor) {
    final isSelected = _selectedDeliveryType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDeliveryType = type;
          _selectedCoupleIds.clear();
          _coupleCandidates.clear();
        });
        if (type == DeliveryType.relay) {
          _loadCoupleCandidates();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? GarudaColors.primary.withValues(alpha: 0.12) : (isDark ? GarudaDarkColors.surfaceLight : GarudaColors.surface),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? GarudaColors.primary : (isDark ? GarudaDarkColors.glassBorder : GarudaColors.glassBorder),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: isSelected ? GarudaColors.primary : mutedColor),
                const Spacer(),
                if (isSelected)
                  const Icon(Icons.check_circle, size: 18, color: GarudaColors.primary),
              ],
            ),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: isSelected ? textColor : mutedColor)),
            const SizedBox(height: 2),
            Text(subtitle, style: GoogleFonts.inter(fontSize: 10, color: mutedColor), maxLines: 2),
          ],
        ),
      ),
    );
  }
}
