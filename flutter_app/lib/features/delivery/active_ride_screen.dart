import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:convert';
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
import '../../core/widgets/funky_box.dart';
import '../../core/widgets/live_map_widget.dart';
import '../../core/models/shipment_model.dart';
import '../../core/models/risk_model.dart';
import '../../core/services/api_service.dart';
import '../shared/chat_screen.dart';

class ActiveRideScreen extends ConsumerStatefulWidget {
  final String shipmentId;
  const ActiveRideScreen({super.key, required this.shipmentId});

  @override
  ConsumerState<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends ConsumerState<ActiveRideScreen> {
  Timer? _locationTimer;
  Timer? _monitorTimer;
  Map<String, dynamic>? _lastLiveData;
  bool _isStreamingLocation = false;
  LatLng? _driverGpsLocation;
  String? _riskAlertMessage;

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

    // Start live location streaming + real GPS capture
    _startLiveTracking();
    _startRealGps();
    _startProactiveMonitor();
  }

  /// Capture real GPS from device every 2 minutes and push to backend
  Future<void> _startRealGps() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return; // Fall back to SSE data
      }

      // Capture initial position
      await _captureAndPushGps();

      // Periodic GPS capture every 2 minutes
      _locationTimer = Timer.periodic(const Duration(minutes: 2), (_) {
        _captureAndPushGps();
      });
    } catch (_) {
      // GPS not available — fall back to SSE-only tracking
    }
  }

  Future<void> _captureAndPushGps() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 10)),
      );
      final loc = LatLng(lat: position.latitude, lng: position.longitude);
      setState(() => _driverGpsLocation = loc);

      // Push to backend
      await ApiService().updateShipmentLocation(widget.shipmentId, loc);
    } catch (_) {}
  }

  /// Proactive monitor: every 10 minutes check for 1-2 hour window risks
  void _startProactiveMonitor() {
    _monitorTimer = Timer.periodic(const Duration(minutes: 10), (_) async {
      final shipment = ref.read(shipmentProvider).selectedShipment;
      if (shipment == null) return;
      try {
        final sessionId = await ref.read(routingProvider.notifier).ensureSession();
        final response = await ApiService().monitorRide(
          sessionId: sessionId,
          currentLocation: _driverGpsLocation ?? shipment.currentLocation ?? shipment.origin,
          destination: shipment.destination,
          mode: shipment.routeMode,
          shipmentId: widget.shipmentId,
        );
        if (mounted && response.isRerouteNeeded) {
          setState(() => _riskAlertMessage = response.displayMessage);
        }
      } catch (_) {}
    });
  }

  void _startLiveTracking() {
    setState(() => _isStreamingLocation = true);
    
    // Listen to SSE live stream
    try {
      ApiService().getLiveTrackingStream(widget.shipmentId).listen(
        (event) {
          if (event.data != null && mounted) {
            try {
              final data = jsonDecode(event.data!);
              setState(() {
                _lastLiveData = data as Map<String, dynamic>;
                // Update driver location from SSE if no real GPS
                if (_driverGpsLocation == null && data['current_location'] != null) {
                  _driverGpsLocation = LatLng(
                    lat: (data['current_location']['lat'] as num).toDouble(),
                    lng: (data['current_location']['lng'] as num).toDouble(),
                  );
                }
                // Check for risk alerts from SSE
                if (data['risk_alert'] != null) {
                  _riskAlertMessage = data['risk_alert']['message'];
                }
              });
            } catch (_) {}
          }
        },
        onError: (_) {
          if (mounted) setState(() => _isStreamingLocation = false);
        },
      );
    } catch (_) {
      setState(() => _isStreamingLocation = false);
    }
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _monitorTimer?.cancel();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? GarudaDarkColors.textPrimary : GarudaColors.textPrimary;
    final shipState = ref.watch(shipmentProvider);
    final monState = ref.watch(monitorProvider);
    final shipment = shipState.selectedShipment;

    // Compute ETA display from SSE data
    String? etaDisplay;
    if (_lastLiveData != null && _lastLiveData!['eta_minutes'] != null) {
      final mins = _lastLiveData!['eta_minutes'] as int;
      etaDisplay = '${mins ~/ 60}h ${mins % 60}m (~${_lastLiveData!['remaining_km']} km)';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Active Ride', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () {
            ref.read(monitorProvider.notifier).stopMonitoring();
            _locationTimer?.cancel();
            _monitorTimer?.cancel();
            Navigator.pop(context);
          },
        ),
        actions: [
          // Live indicator
          if (_isStreamingLocation)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: GarudaColors.danger, shape: BoxShape.circle),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                    begin: const Offset(1, 1), end: const Offset(1.5, 1.5), duration: 800.ms,
                  ),
                  const SizedBox(width: 4),
                  Text('LIVE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: GarudaColors.danger)),
                ],
              ),
            ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: GarudaColors.primary),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(shipmentId: widget.shipmentId, driverName: "Consumer")));
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
                  // In-App Google Maps — Live Tracking
                  LiveMapWidget(
                    origin: shipment.origin,
                    destination: shipment.destination,
                    driverLocation: _driverGpsLocation ?? shipment.currentLocation,
                    height: 260,
                    etaDisplay: etaDisplay,
                  ).animate().fadeIn().slideY(begin: 0.1),

                  const SizedBox(height: 16),

                  // Header
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
                                color: GarudaColors.deliveryColor,
                                borderRadius: BorderRadius.circular(14),
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
                                    shipment.packageDescription ?? 'Delivery',
                                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: textColor),
                                  ),
                                  const SizedBox(height: 4),
                                  StatusBadge(label: shipment.status.label, color: GarudaColors.primary),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _openNavigation,
                              style: IconButton.styleFrom(backgroundColor: GarudaColors.primary.withValues(alpha: 0.15)),
                              icon: const Icon(Icons.navigation, color: GarudaColors.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        InfoRow(label: 'Origin', value: shipment.origin.toDisplayString()),
                        InfoRow(label: 'Destination', value: shipment.destination.toDisplayString()),
                      ],
                    ),
                  ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.1),

                  const SizedBox(height: 16),

                  // Proactive Risk Alert
                  if (_riskAlertMessage != null)
                    FunkyBox.pill(
                      color: GarudaColors.danger.withValues(alpha: 0.15),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber, color: GarudaColors.danger, size: 32),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('⚠️ UPCOMING RISK (1-2hr)', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: GarudaColors.danger)),
                                const SizedBox(height: 4),
                                Text(_riskAlertMessage!, style: GoogleFonts.inter(fontSize: 13, color: textColor)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn().shakeX(amount: 2),

                  // Monitor alerts
                  if (monState.lastResponse?.isRerouteNeeded == true)
                    FunkyBox.pill(
                      color: GarudaColors.danger.withValues(alpha: 0.15),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber, color: GarudaColors.danger, size: 32),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('REROUTE SUGGESTED', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: GarudaColors.danger)),
                                const SizedBox(height: 4),
                                Text(monState.lastResponse!.displayMessage, style: GoogleFonts.inter(fontSize: 13, color: textColor)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn().slideX()
                  else if (monState.lastResponse?.isOnTrack == true)
                    GlassmorphicCard(
                      borderColor: GarudaColors.success,
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: GarudaColors.success, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(monState.lastResponse!.displayMessage, style: GoogleFonts.inter(fontSize: 13, color: textColor)),
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
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final driverId = ref.read(authProvider).user?.uid ?? 'unknown-driver';
                              final loc = _driverGpsLocation ?? shipment.currentLocation ?? shipment.origin;
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
                                    backgroundColor: isDark ? GarudaDarkColors.surface : GarudaColors.surface,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(color: GarudaColors.primaryDark, width: 2),
                                    ),
                                    title: Text('Fatigue Assessment', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: textColor)),
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
                                              Icon(Icons.info_outline, size: 16, color: GarudaColors.textMuted),
                                              const SizedBox(width: 8),
                                              Expanded(child: Text(r, style: GoogleFonts.inter(fontSize: 13, color: isDark ? GarudaDarkColors.textSecondary : GarudaColors.textSecondary))),
                                            ],
                                          ),
                                        )),
                                      ],
                                    ),
                                    actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
                                  ),
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(foregroundColor: GarudaColors.info, side: const BorderSide(color: GarudaColors.info, width: 2)),
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
        label: Text('Report Incident', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _showReportIncidentDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? GarudaDarkColors.textPrimary : GarudaColors.textPrimary;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? GarudaDarkColors.surface : GarudaColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: GarudaColors.primaryDark, width: 2)),
          title: Row(
            children: [
              const Icon(Icons.warning, color: GarudaColors.danger),
              const SizedBox(width: 8),
              Text('Report Incident', style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.w800)),
            ],
          ),
          content: Text('Report a roadblock, accident, or hazard to the logistics team.', style: GoogleFonts.inter(color: GarudaColors.textMuted, height: 1.5)),
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
                    widget.shipmentId, 'ROAD_BLOCK', 'Driver reported sudden roadblock',
                    _driverGpsLocation ?? shipment.currentLocation ?? shipment.origin, 0.8, driverId,
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
        side: BorderSide(color: color, width: 2),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
