import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:convert';
import '../../core/theme/app_theme.dart';
import '../../core/providers/shipment_provider.dart';
import '../../core/widgets/glassmorphic_card.dart';
import '../../core/widgets/status_timeline.dart';
import '../../core/widgets/loading_shimmer.dart';
import '../../core/widgets/live_map_widget.dart';
import '../../core/providers/analytics_provider.dart';
import '../../core/models/analytics_model.dart';
import '../../core/models/intelligence_model.dart';
import '../../core/models/shipment_model.dart';
import '../../core/services/api_service.dart';

class ShipmentDetailScreen extends ConsumerStatefulWidget {
  final String shipmentId;
  const ShipmentDetailScreen({super.key, required this.shipmentId});

  @override
  ConsumerState<ShipmentDetailScreen> createState() => _ShipmentDetailScreenState();
}

class _ShipmentDetailScreenState extends ConsumerState<ShipmentDetailScreen> {
  ExplainableRiskDetails? _riskDetails;
  PackageIntegrity? _integrity;
  bool _isLoadingExtra = false;
  LatLng? _driverLocation;
  int? _etaMinutes;
  double? _remainingKm;
  bool _isLive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      _startSSE();
    });
  }

  void _startSSE() {
    setState(() => _isLive = true);
    try {
      ApiService().getLiveTrackingStream(widget.shipmentId).listen(
        (event) {
          if (event.data != null && mounted) {
            try {
              final data = jsonDecode(event.data!);
              setState(() {
                if (data['current_location'] != null) {
                  _driverLocation = LatLng(
                    lat: (data['current_location']['lat'] as num).toDouble(),
                    lng: (data['current_location']['lng'] as num).toDouble(),
                  );
                }
                if (data['eta_minutes'] != null) _etaMinutes = data['eta_minutes'] as int;
                if (data['remaining_km'] != null) _remainingKm = (data['remaining_km'] as num).toDouble();
              });
            } catch (_) {}
          }
        },
        onError: (_) { if (mounted) setState(() => _isLive = false); },
      );
    } catch (_) { setState(() => _isLive = false); }
  }

  Future<void> _load() async {
    ref.read(shipmentProvider.notifier).selectShipment(widget.shipmentId);
    ref.read(shipmentProvider.notifier).loadEta(widget.shipmentId);
  }

  Future<void> _fetchExtraDetails() async {
    setState(() => _isLoadingExtra = true);
    final shipment = ref.read(shipmentProvider).selectedShipment;
    if (shipment != null) {
      final risk = await ref.read(shipmentProvider.notifier).getRiskDetails(widget.shipmentId);
      final integrity = await ref.read(analyticsProvider).getPackageIntegrity(
        widget.shipmentId, 
        'general', 
        shipment.weightKg ?? 5.0, 
        shipment.routeMode,
      );
      if (mounted) {
        setState(() {
          _riskDetails = risk;
          _integrity = integrity;
        });
      }
    }
    if (mounted) setState(() => _isLoadingExtra = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? GarudaDarkColors.textPrimary : GarudaColors.textPrimary;
    final mutedColor = isDark ? GarudaDarkColors.textMuted : GarudaColors.textMuted;
    final state = ref.watch(shipmentProvider);
    final shipment = state.selectedShipment;
    final eta = state.currentEta;

    return Scaffold(
      appBar: AppBar(
        title: Text('Shipment Track', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _load,
          ),
        ],
      ),
      body: state.isLoading && shipment == null
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: LoadingShimmer(count: 5),
            )
          : shipment == null
              ? const EmptyState(title: 'Not Found', subtitle: 'Shipment details could not be loaded.', icon: Icons.error_outline)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Live Map for active shipments
                      if (shipment.status != ShipmentStatus.pending && shipment.status != ShipmentStatus.delivered && shipment.status != ShipmentStatus.cancelled) ...[
                        LiveMapWidget(
                          origin: shipment.origin,
                          destination: shipment.destination,
                          driverLocation: _driverLocation ?? shipment.currentLocation,
                          height: 220,
                          etaDisplay: _etaMinutes != null
                              ? '${_etaMinutes! ~/ 60}h ${_etaMinutes! % 60}m (~${_remainingKm?.toStringAsFixed(1) ?? '?'} km)'
                              : (eta != null ? '${eta.etaMinutes ~/ 60}h ${eta.etaMinutes % 60}m' : null),
                          onDirectionsInfo: (etaText, dist, mins) {
                            if (mounted && _etaMinutes == null) {
                              setState(() {
                                _etaMinutes = mins;
                                _remainingKm = double.tryParse(dist.replaceAll(RegExp(r'[^0-9.]'), ''));
                              });
                            }
                          },
                        ).animate().fadeIn().slideY(begin: 0.1),
                        const SizedBox(height: 16),
                      ],
                      // Header Card
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
                                    gradient: GarudaGradients.primary,
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
                                        shipment.packageDescription ?? 'Garuda Shipment',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'ID: ${shipment.shipmentId}',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: mutedColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Route visual
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  children: [
                                    const Icon(Icons.trip_origin, size: 14, color: GarudaColors.primary),
                                    Container(width: 2, height: 30, color: GarudaColors.glassBorderStrong),
                                    const Icon(Icons.location_on, size: 14, color: GarudaColors.accentLight),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Origin', style: GoogleFonts.inter(fontSize: 11, color: mutedColor)),
                                      Text(shipment.origin.toDisplayString(), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                                      const SizedBox(height: 14),
                                      Text('Destination', style: GoogleFonts.inter(fontSize: 11, color: mutedColor)),
                                      Text(shipment.destination.toDisplayString(), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                                    ],
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1),

                      const SizedBox(height: 16),

                      // ETA Card
                      if (eta != null)
                        GlassmorphicCard(
                          gradient: LinearGradient(
                            colors: [isDark ? GarudaDarkColors.card : GarudaColors.card, isDark ? GarudaDarkColors.cardHover : GarudaColors.cardHover],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderColor: GarudaColors.primary.withValues(alpha: 0.3),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: GarudaColors.primary.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.timer_outlined, color: GarudaColors.primaryLight, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Time to Destination', style: GoogleFonts.inter(fontSize: 12, color: mutedColor)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${eta.etaMinutes ~/ 60}h ${eta.etaMinutes % 60}m',
                                      style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.w700, color: GarudaColors.primaryLight),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('${eta.remainingKm.toStringAsFixed(1)} km', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w600, color: textColor)),
                                  Text('remaining', style: GoogleFonts.inter(fontSize: 11, color: mutedColor)),
                                ],
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

                      const SizedBox(height: 16),
                      const SectionHeader(title: 'Timeline'),
                      GlassmorphicCard(
                        child: StatusTimeline(currentStatus: shipment.status),
                      ).animate().fadeIn(delay: 200.ms),

                      const SizedBox(height: 16),

                      if (_riskDetails == null && _integrity == null)
                        GradientButton(
                          label: 'AI Risk & Integrity Analysis',
                          icon: Icons.auto_awesome,
                          isLoading: _isLoadingExtra,
                          onPressed: _fetchExtraDetails,
                          gradient: GarudaGradients.consumer,
                        ).animate().fadeIn(delay: 300.ms),

                      if (_riskDetails != null) ...[
                        const SectionHeader(title: 'AI Risk Analysis'),
                        GlassmorphicCard(
                          borderColor: _riskColor(_riskDetails!.riskLevel).withValues(alpha: 0.5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.shield, color: _riskColor(_riskDetails!.riskLevel)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Risk Level: ${_riskDetails!.riskLevel}', 
                                    style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700, color: _riskColor(_riskDetails!.riskLevel)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(_riskDetails!.explanation, style: GoogleFonts.inter(fontSize: 14, color: textColor)),
                              const SizedBox(height: 16),
                              ..._riskDetails!.factors.map((f) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.circle, size: 6, color: mutedColor),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: RichText(
                                        text: TextSpan(
                                          style: GoogleFonts.inter(fontSize: 13, color: isDark ? GarudaDarkColors.textSecondary : GarudaColors.textSecondary),
                                          children: [
                                            TextSpan(text: '${f.name}: ', style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                                            TextSpan(text: f.detail),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                            ],
                          ),
                        ).animate().fadeIn().slideY(),
                      ],

                      if (_integrity != null) ...[
                        const SizedBox(height: 16),
                        const SectionHeader(title: 'Package Integrity'),
                        GlassmorphicCard(
                          borderColor: GarudaColors.primary.withValues(alpha: 0.5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.health_and_safety, color: GarudaColors.primaryLight),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Integrity Score: ${_integrity!.integrityScore.toStringAsFixed(1)}/100', 
                                    style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700, color: GarudaColors.primaryLight),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ..._integrity!.recommendations.map((r) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.check, size: 16, color: GarudaColors.success),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(r, style: GoogleFonts.inter(fontSize: 13, color: GarudaColors.textSecondary))),
                                  ],
                                ),
                              )),
                            ],
                          ),
                        ).animate().fadeIn().slideY(),
                      ],
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  Color _riskColor(String level) {
    if (level.toUpperCase() == 'HIGH') return GarudaColors.danger;
    if (level.toUpperCase() == 'MEDIUM') return GarudaColors.warning;
    return GarudaColors.success;
  }
}
