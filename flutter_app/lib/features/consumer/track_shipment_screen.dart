import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/shipment_provider.dart';
import '../../core/widgets/glassmorphic_card.dart';
import '../../core/widgets/funky_box.dart';
import '../../core/widgets/status_timeline.dart';
import '../../core/widgets/mode_icon.dart';
import '../../core/widgets/loading_shimmer.dart';
import '../../core/widgets/live_map_widget.dart';
import '../../core/models/shipment_model.dart';
import '../../core/models/intelligence_model.dart';
import 'dart:convert';
import 'package:flutter_client_sse/flutter_client_sse.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/shared_widgets.dart';
import '../shared/chat_screen.dart';

class TrackShipmentScreen extends ConsumerStatefulWidget {
  final String shipmentId;
  const TrackShipmentScreen({super.key, required this.shipmentId});

  @override
  ConsumerState<TrackShipmentScreen> createState() => _TrackShipmentScreenState();
}

class _TrackShipmentScreenState extends ConsumerState<TrackShipmentScreen> {
  List<TimelineEvent> _timelineEvents = [];
  bool _isLoadingTimeline = false;
  Map<String, dynamic>? _liveData; // Retained for SSE event access
  bool _isLive = false;
  LatLng? _driverLocation;
  int? _etaMinutes;
  double? _remainingKm;
  String? _riskAlertMessage;
  
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
    ApiService().getLiveTrackingStream(widget.shipmentId).listen(
      (event) {
        if (event.data != null && mounted) {
          try {
            final data = jsonDecode(event.data!);
            setState(() {
              _liveData = data as Map<String, dynamic>;
              // Extract driver location from SSE
              if (data['current_location'] != null) {
                _driverLocation = LatLng(
                  lat: (data['current_location']['lat'] as num).toDouble(),
                  lng: (data['current_location']['lng'] as num).toDouble(),
                );
              }
              // Extract ETA
              if (data['eta_minutes'] != null) {
                _etaMinutes = data['eta_minutes'] as int;
              }
              if (data['remaining_km'] != null) {
                _remainingKm = (data['remaining_km'] as num).toDouble();
              }
              // Check for risk alerts
              if (data['risk_alert'] != null) {
                _riskAlertMessage = data['risk_alert']['message'];
              }
            });
          } catch (_) {}
        }
      },
      onError: (_) {
        if (mounted) setState(() => _isLive = false);
      },
    );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? GarudaDarkColors.textPrimary : GarudaColors.textPrimary;
    final mutedColor = isDark ? GarudaDarkColors.textMuted : GarudaColors.textMuted;
    final state = ref.watch(shipmentProvider);
    final shipment = state.selectedShipment;
    final eta = state.currentEta;

    // Compute ETA display from SSE or provider
    String? etaDisplay;
    if (_etaMinutes != null) {
      etaDisplay = '${_etaMinutes! ~/ 60}h ${_etaMinutes! % 60}m';
      if (_remainingKm != null) etaDisplay += ' (~${_remainingKm!.toStringAsFixed(1)} km)';
    } else if (eta != null) {
      etaDisplay = '${eta.etaMinutes ~/ 60}h ${eta.etaMinutes % 60}m (~${eta.remainingKm.toStringAsFixed(1)} km)';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Track Package', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, size: 18), onPressed: () => Navigator.pop(context)),
        actions: [
          if (_isLive)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: GarudaColors.danger, shape: BoxShape.circle),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.5, 1.5), duration: 800.ms),
                  const SizedBox(width: 4),
                  Text('LIVE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: GarudaColors.danger)),
                ],
              ),
            ),
          IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: _load),
        ],
      ),
      body: state.isLoading && shipment == null
          ? const Padding(padding: EdgeInsets.all(24), child: LoadingShimmer(count: 4))
          : shipment == null
              ? const EmptyState(title: 'Not Found', subtitle: 'Check the ID and try again', icon: Icons.search_off)
              : RefreshIndicator(
                  onRefresh: () async => _load(),
                  color: GarudaColors.consumerColor,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // In-App Google Maps — Live driver tracking for consumer
                        LiveMapWidget(
                          origin: shipment.origin,
                          destination: shipment.destination,
                          driverLocation: _driverLocation ?? shipment.currentLocation,
                          height: 240,
                          etaDisplay: etaDisplay,
                        ).animate().fadeIn().slideY(begin: 0.1),

                        const SizedBox(height: 16),

                        // Risk alert from proactive monitoring
                        if (_riskAlertMessage != null)
                          FunkyBox.pill(
                            color: GarudaColors.warning.withValues(alpha: 0.15),
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, color: GarudaColors.warning, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Route Advisory', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: GarudaColors.warning)),
                                      const SizedBox(height: 2),
                                      Text(_riskAlertMessage!, style: GoogleFonts.inter(fontSize: 12, color: textColor)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(),

                        const SizedBox(height: 16),
                        const SectionHeader(title: 'Package Information'),

                        GlassmorphicCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isDark ? GarudaDarkColors.surfaceLight : GarudaColors.surfaceLight,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: GarudaColors.primaryDark, width: 2),
                                    ),
                                    child: modeIconFromString(shipment.routeMode, size: 24),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          shipment.packageDescription ?? 'Garuda Package',
                                          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: textColor),
                                        ),
                                        if (shipment.weightKg != null)
                                          Text('${shipment.weightKg} kg', style: GoogleFonts.inter(fontSize: 12, color: mutedColor)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 16),
                              InfoRow(label: 'Tracking ID', value: shipment.shipmentId),
                              InfoRow(label: 'From', value: shipment.origin.toDisplayString()),
                              InfoRow(label: 'To', value: shipment.destination.toDisplayString()),
                              if (_driverLocation != null)
                                InfoRow(label: 'Driver At', value: _driverLocation!.toDisplayString(), valueColor: GarudaColors.warning),
                            ],
                          ),
                        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

                        const SizedBox(height: 24),

                        const SectionHeader(title: 'Delivery Progress'),
                        GlassmorphicCard(child: StatusTimeline(currentStatus: shipment.status)).animate().fadeIn(delay: 200.ms),

                        const SizedBox(height: 24),
                        
                        const SectionHeader(title: 'Detailed Logs'),
                        GlassmorphicCard(
                          padding: const EdgeInsets.all(16),
                          child: _isLoadingTimeline
                            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                            : _timelineEvents.isEmpty
                              ? Center(child: Text('No timeline logs found.', style: GoogleFonts.inter(color: mutedColor)))
                              : Column(
                                  children: _timelineEvents.map((e) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.only(top: 4),
                                          width: 8, height: 8,
                                          decoration: const BoxDecoration(color: GarudaColors.primary, shape: BoxShape.circle),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(e.detail, style: GoogleFonts.inter(fontSize: 13, color: textColor)),
                                              const SizedBox(height: 2),
                                              Text(e.timestamp.substring(0, 16).replaceFirst('T', ' '), style: GoogleFonts.inter(fontSize: 11, color: mutedColor)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )).toList(),
                                ),
                        ).animate().fadeIn(delay: 300.ms),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
      floatingActionButton: shipment != null
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(shipmentId: shipment.shipmentId))),
              backgroundColor: GarudaColors.primary,
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
              label: Text("Secure Chat", style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white)),
            )
          : null,
    );
  }
}
