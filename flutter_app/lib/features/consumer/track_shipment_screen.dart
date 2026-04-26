import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/shipment_provider.dart';
import '../../core/widgets/glassmorphic_card.dart';
import '../../core/widgets/status_timeline.dart';
import '../../core/widgets/mode_icon.dart';
import '../../core/widgets/loading_shimmer.dart';
import '../../core/models/intelligence_model.dart';
import 'dart:convert';
import 'package:flutter_client_sse/flutter_client_sse.dart';
import '../../core/services/api_service.dart';

class TrackShipmentScreen extends ConsumerStatefulWidget {
  final String shipmentId;
  const TrackShipmentScreen({super.key, required this.shipmentId});

  @override
  ConsumerState<TrackShipmentScreen> createState() => _TrackShipmentScreenState();
}

class _TrackShipmentScreenState extends ConsumerState<TrackShipmentScreen> {
  List<TimelineEvent> _timelineEvents = [];
  bool _isLoadingTimeline = false;
  
  @override
  void initState() {
    super.initState();
    _load();
    _startSSE();
  }

  void _startSSE() {
    ApiService().getLiveTrackingStream(widget.shipmentId).listen((event) {
      if (event.data != null && mounted) {
        try {
          final data = jsonDecode(event.data!);
          // Real app would update a live map here with data['lat'], data['lng']
          // For now, we just refresh the whole view occasionally
        } catch (_) {}
      }
    });
  }

  @override
  void dispose() {
    SSEClient.unsubscribeFromSSE();
    super.dispose();
  }

  Future<void> _load() async {
    ref.read(shipmentProvider.notifier).selectShipment(widget.shipmentId);
    ref.read(shipmentProvider.notifier).loadEta(widget.shipmentId);
    
    setState(() => _isLoadingTimeline = true);
    final events = await ref.read(shipmentProvider.notifier).getTimeline(widget.shipmentId);
    if (mounted) {
      setState(() {
        _timelineEvents = events;
        _isLoadingTimeline = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shipmentProvider);
    final shipment = state.selectedShipment;
    final eta = state.currentEta;

    return Scaffold(
      appBar: AppBar(
        title: Text('Track Package', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: _load),
        ],
      ),
      body: state.isLoading && shipment == null
          ? const Padding(padding: EdgeInsets.all(24), child: LoadingShimmer(count: 4))
          : shipment == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.search_off, size: 48, color: GarudaColors.textMuted),
                      const SizedBox(height: 12),
                      Text(
                        'Shipment not found',
                        style: GoogleFonts.outfit(fontSize: 16, color: GarudaColors.textSecondary),
                      ),
                      Text(
                        'Check the ID and try again',
                        style: GoogleFonts.inter(fontSize: 12, color: GarudaColors.textMuted),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => _load(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ETA hero
                        if (eta != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  GarudaColors.primary.withValues(alpha: 0.15),
                                  GarudaColors.primaryDark.withValues(alpha: 0.08),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: GarudaColors.primary.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Estimated Arrival',
                                  style: GoogleFonts.inter(fontSize: 13, color: GarudaColors.textSecondary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${eta.etaMinutes} min',
                                  style: GoogleFonts.outfit(
                                    fontSize: 42,
                                    fontWeight: FontWeight.w700,
                                    color: GarudaColors.accent,
                                  ),
                                ),
                                Text(
                                  '${eta.remainingKm.toStringAsFixed(1)} km remaining',
                                  style: GoogleFonts.inter(fontSize: 12, color: GarudaColors.textMuted),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Route info
                        GlassmorphicCard(
                          child: Column(
                            children: [
                              _routePoint(
                                Icons.trip_origin,
                                'From',
                                shipment.origin.toDisplayString(),
                                GarudaColors.primary,
                              ),
                              Container(
                                width: 2,
                                height: 20,
                                margin: const EdgeInsets.only(left: 11),
                                color: GarudaColors.glassBorder,
                              ),
                              if (shipment.currentLocation != null)
                                _routePoint(
                                  Icons.my_location,
                                  'Current Location',
                                  shipment.currentLocation!.toDisplayString(),
                                  GarudaColors.warning,
                                ),
                              if (shipment.currentLocation != null)
                                Container(
                                  width: 2,
                                  height: 20,
                                  margin: const EdgeInsets.only(left: 11),
                                  color: GarudaColors.glassBorder,
                                ),
                              _routePoint(
                                Icons.location_on,
                                'To',
                                shipment.destination.toDisplayString(),
                                GarudaColors.danger,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Shipment info
                        GlassmorphicCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  modeIconFromString(shipment.routeMode, size: 36),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          shipment.packageDescription ?? 'Package',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: GarudaColors.textPrimary,
                                          ),
                                        ),
                                        if (shipment.weightKg != null)
                                          Text(
                                            '${shipment.weightKg} kg',
                                            style: GoogleFonts.inter(fontSize: 12, color: GarudaColors.textMuted),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Timeline
                        GlassmorphicCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Delivery Progress',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: GarudaColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              StatusTimeline(currentStatus: shipment.status),
                              const SizedBox(height: 24),
                              Text(
                                'Detailed Logs',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: GarudaColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (_isLoadingTimeline)
                                const Center(child: CircularProgressIndicator(strokeWidth: 2))
                              else if (_timelineEvents.isEmpty)
                                Text('No timeline logs found.', style: GoogleFonts.inter(color: GarudaColors.textMuted))
                              else
                                ..._timelineEvents.map((e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.circle, size: 8, color: GarudaColors.primary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(e.detail, style: GoogleFonts.inter(fontSize: 13, color: GarudaColors.textPrimary)),
                                            Text(e.timestamp.substring(0, 16).replaceFirst('T', ' '), style: GoogleFonts.inter(fontSize: 11, color: GarudaColors.textMuted)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _routePoint(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 11, color: GarudaColors.textMuted)),
              Text(
                value,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: GarudaColors.textPrimary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
