import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
import '../../core/models/analytics_model.dart';
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
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      _startSSE();
    });
  }

  void _startSSE() {
    ApiService().getLiveTrackingStream(widget.shipmentId).listen((event) {
      if (event.data != null && mounted) {
        try {
          final data = jsonDecode(event.data!);
          // Update live map
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
        title: Text('Track Package', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
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
              ? const EmptyState(title: 'Not Found', subtitle: 'Check the ID and try again', icon: Icons.search_off)
              : RefreshIndicator(
                  onRefresh: () async => _load(),
                  color: GarudaColors.consumerColor,
                  backgroundColor: GarudaColors.card,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ETA hero
                        if (eta != null)
                          GlassmorphicCard(
                            gradient: LinearGradient(
                              colors: [GarudaColors.card, GarudaColors.cardHover],
                            ),
                            borderColor: GarudaColors.consumerColor.withValues(alpha: 0.5),
                            child: Column(
                              children: [
                                Text(
                                  'Estimated Arrival',
                                  style: GoogleFonts.inter(fontSize: 13, color: GarudaColors.textSecondary),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${eta.etaMinutes ~/ 60}h ${eta.etaMinutes % 60}m',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 42,
                                    fontWeight: FontWeight.w700,
                                    color: GarudaColors.primaryLight,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${eta.remainingKm.toStringAsFixed(1)} km remaining',
                                  style: GoogleFonts.inter(fontSize: 13, color: GarudaColors.textMuted),
                                ),
                              ],
                            ),
                          ).animate().fadeIn().slideY(begin: 0.1),

                        const SizedBox(height: 24),
                        const SectionHeader(title: 'Package Information'),

                        // Shipment info
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
                                      color: GarudaColors.surfaceLight,
                                      borderRadius: BorderRadius.circular(12),
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
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
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
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 16),
                              InfoRow(label: 'Tracking ID', value: shipment.shipmentId),
                              InfoRow(label: 'From', value: shipment.origin.toDisplayString()),
                              InfoRow(label: 'To', value: shipment.destination.toDisplayString()),
                              if (shipment.currentLocation != null)
                                InfoRow(label: 'Current', value: shipment.currentLocation!.toDisplayString(), valueColor: GarudaColors.warning),
                            ],
                          ),
                        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

                        const SizedBox(height: 24),

                        // Timeline
                        const SectionHeader(title: 'Delivery Progress'),
                        GlassmorphicCard(
                          child: StatusTimeline(currentStatus: shipment.status),
                        ).animate().fadeIn(delay: 200.ms),

                        const SizedBox(height: 24),
                        
                        const SectionHeader(title: 'Detailed Logs'),
                        GlassmorphicCard(
                          padding: const EdgeInsets.all(16),
                          child: _isLoadingTimeline
                            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                            : _timelineEvents.isEmpty
                              ? Center(child: Text('No timeline logs found.', style: GoogleFonts.inter(color: GarudaColors.textMuted)))
                              : Column(
                                  children: _timelineEvents.map((e) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.only(top: 4),
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: GarudaColors.primaryLight,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(e.detail, style: GoogleFonts.inter(fontSize: 13, color: GarudaColors.textPrimary)),
                                              const SizedBox(height: 2),
                                              Text(e.timestamp.substring(0, 16).replaceFirst('T', ' '), style: GoogleFonts.inter(fontSize: 11, color: GarudaColors.textMuted)),
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ChatScreen(shipmentId: shipment.shipmentId)),
                );
              },
              backgroundColor: GarudaColors.primary,
              icon: const Icon(Icons.chat_bubble_outline, color: GarudaColors.background),
              label: Text("Secure Chat", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: GarudaColors.background)),
            )
          : null,
    );
  }
}
