import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/theme/app_theme.dart';
import '../../core/providers/shipment_provider.dart';
import '../../core/providers/routing_provider.dart';
import '../../core/providers/monitor_provider.dart';
import '../../core/widgets/funky_box.dart';
import '../../core/models/shipment_model.dart';
import '../../core/models/monitor_model.dart';
import '../../core/services/api_service.dart';

class ActiveRideScreen extends ConsumerStatefulWidget {
  final String shipmentId;
  const ActiveRideScreen({super.key, required this.shipmentId});
  @override
  ConsumerState<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends ConsumerState<ActiveRideScreen> {
  Timer? _locationTimer;
  Timer? _monitorTimer;
  bool _isStreaming = false;
  LatLng? _driverGps;
  double? _speedKmh;
  String? _destName;
  String _eta = '--';
  String _dist = '--';
  final List<RideMonitorResponse> _alerts = [];
  final Set<String> _dismissed = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
    
    FlutterOverlayWindow.overlayListener.listen((event) {
      if (event != null && event is Map) {
        if (event['action'] == 'REROUTE_ACCEPTED') {
          _acceptReroute(_alerts.isNotEmpty ? _alerts.last : null);
        } else if (event['action'] == 'EXIT_NAVIGATION') {
          if (mounted) Navigator.pop(context); // Go back to Home
        }
      }
    });
  }

  Future<void> _init() async {
    await _requestPerms();
    await ref.read(shipmentProvider.notifier).selectShipment(widget.shipmentId);
    final s = ref.read(shipmentProvider).selectedShipment;
    if (s == null) return;
    final sid = await ref.read(routingProvider.notifier).ensureSession();
    ref.read(monitorProvider.notifier).startMonitoring(
      sessionId: sid, currentLocation: s.currentLocation ?? s.origin,
      destination: s.destination, mode: s.routeMode, shipmentId: widget.shipmentId,
    );
    _reverseGeocode(s.destination);
    _startGps();
    _startMonitor();
    _startPolling();
  }

  Future<void> _requestPerms() async {
    bool svc = await Geolocator.isLocationServiceEnabled();
    if (!svc) return;
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
    try { await Permission.notification.request(); } catch (_) {}
  }

  Future<void> _reverseGeocode(LatLng loc) async {
    try {
      const key = 'AIzaSyCGJyIbpXwOMG_vLlBilIWP0zzkNSysdWM';
      final r = await http.get(Uri.parse('https://maps.googleapis.com/maps/api/geocode/json?latlng=${loc.lat},${loc.lng}&key=$key'));
      if (r.statusCode == 200) {
        final d = jsonDecode(r.body);
        if (d['results'] != null && (d['results'] as List).isNotEmpty) {
          final results = d['results'] as List;
          String? name;
          for (final x in results) {
            final t = x['types'] as List;
            if (t.contains('locality') || t.contains('administrative_area_level_2')) { name = x['formatted_address']; break; }
          }
          name ??= results[0]['formatted_address'];
          if (mounted) setState(() => _destName = name);
        }
      }
    } catch (_) {}
  }

  void _startGps() {
    _captureGps();
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (_) => _captureGps());
  }

  Future<void> _captureGps() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 10)),
      );
      setState(() { _driverGps = LatLng(lat: pos.latitude, lng: pos.longitude); _speedKmh = pos.speed * 3.6; });
      await ApiService().updateShipmentLocation(widget.shipmentId, _driverGps!);
    } catch (_) {}
  }

  void _startMonitor() {
    _runMonitor();
    _monitorTimer = Timer.periodic(const Duration(seconds: 30), (_) => _runMonitor());
  }

  Future<void> _runMonitor() async {
    final s = ref.read(shipmentProvider).selectedShipment;
    if (s == null) return;
    try {
      final sid = await ref.read(routingProvider.notifier).ensureSession();
      final r = await ApiService().monitorRide(
        sessionId: sid, currentLocation: _driverGps ?? s.currentLocation ?? s.origin,
        destination: s.destination, mode: s.routeMode, shipmentId: widget.shipmentId,
      );
      if (mounted && r.isRerouteNeeded && !_alerts.any((a) => a.displayMessage == r.displayMessage)) {
        setState(() => _alerts.add(r));
        FlutterOverlayWindow.shareData({
          "message": r.displayMessage,
          "severity": r.severity,
        });
      }
    } catch (_) {}
  }

  Timer? _pollingTimer;

  void _startPolling() {
    setState(() => _isStreaming = true);
    // Poll ETA and location via standard HTTP every 10 seconds (No SSE)
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (!mounted) return;
      try {
        final etaObj = await ApiService().getShipmentEta(widget.shipmentId);
        setState(() {
          _eta = '${etaObj.etaMinutes} min';
          _dist = '${etaObj.remainingKm.toStringAsFixed(1)} km';
        });
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _monitorTimer?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _launchGoogleMaps() async {
    final s = ref.read(shipmentProvider).selectedShipment;
    if (s == null) return;
    
    // Removing origin forces Google Maps to use the device's live location!
    final url = 'google.navigation:q=${s.destination.lat},${s.destination.lng}&mode=d';
    final fallback = 'https://www.google.com/maps/dir/?api=1&destination=${s.destination.lat},${s.destination.lng}&travelmode=driving';
    try {
      if (await canLaunchUrl(Uri.parse(url))) { await launchUrl(Uri.parse(url)); }
      else { await launchUrl(Uri.parse(fallback), mode: LaunchMode.externalApplication); }
    } catch (_) { await launchUrl(Uri.parse(fallback), mode: LaunchMode.externalApplication); }

    // Show Garuda AI Overlay on top of Google Maps
    try {
      if (await FlutterOverlayWindow.isPermissionGranted() == false) {
        await FlutterOverlayWindow.requestPermission();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please grant "Display over other apps" permission, then try again.')),
          );
        }
        return; // Don't launch overlay if permission isn't guaranteed
      }
      
      if (await FlutterOverlayWindow.isActive() == false) {
        await FlutterOverlayWindow.showOverlay(
          enableDrag: true,
          overlayTitle: "Garuda AI",
          overlayContent: "Monitoring Route...",
          flag: OverlayFlag.defaultFlag,
          alignment: OverlayAlignment.topCenter,
          visibility: NotificationVisibility.visibilityPublic,
          positionGravity: PositionGravity.auto,
          height: 1000, // Large enough to hold expanded UI without shrinking logical bounds
          width: 1000,
        );
      }
    } catch (_) {}
  }

  Future<void> _acceptReroute([RideMonitorResponse? alert]) async {
    final s = ref.read(shipmentProvider).selectedShipment;
    if (s == null) return;
    if (alert != null) setState(() => _dismissed.add(alert.displayMessage));
    try {
      final sid = await ref.read(routingProvider.notifier).ensureSession();
      await ApiService().reroute(sessionId: sid, shipmentId: widget.shipmentId,
        origin: _driverGps ?? s.currentLocation ?? s.origin, destination: s.destination,
        mode: s.routeMode, avoidZones: [], reason: alert?.displayMessage ?? 'Driver manually requested reroute');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Route updated successfully!'), backgroundColor: GarudaColors.success));
    } catch (_) {}
  }

  Future<void> _updateStatus(String status) async {
    await ref.read(shipmentProvider.notifier).updateStatus(widget.shipmentId, status);
    if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status → $status'), backgroundColor: GarudaColors.success)); }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? GarudaDarkColors.background : GarudaColors.background;
    final surface = isDark ? GarudaDarkColors.surface : GarudaColors.surface;
    final text = isDark ? GarudaDarkColors.textPrimary : GarudaColors.textPrimary;
    final muted = isDark ? GarudaDarkColors.textMuted : GarudaColors.textMuted;
    final shipment = ref.watch(shipmentProvider).selectedShipment;
    if (shipment == null) return Scaffold(backgroundColor: bg, body: const Center(child: CircularProgressIndicator()));

    final active = _alerts.where((a) => !_dismissed.contains(a.displayMessage)).toList();

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              GestureDetector(onTap: () => Navigator.pop(context),
                child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: surface, shape: BoxShape.circle, border: Border.all(color: muted.withValues(alpha: 0.2))),
                  child: Icon(Icons.arrow_back, color: text, size: 20))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Active Ride', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: text)),
                Text(shipment.shipmentId.substring(0, 8).toUpperCase(), style: GoogleFonts.robotoMono(fontSize: 12, color: muted)),
              ])),
              if (_isStreaming) Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: GarudaColors.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: GarudaColors.success, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text('LIVE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: GarudaColors.success)),
                ]),
              ),
            ]),
          ),

          Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
            // Destination Card
            FunkyBox.diagonal(color: GarudaColors.primaryDark, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.location_on, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('DESTINATION', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white70, letterSpacing: 1)),
              ]),
              const SizedBox(height: 8),
              Text(_destName ?? shipment.destination.toDisplayString(), style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 16),
              Row(children: [
                _infoChip(Icons.timer, _eta, Colors.white),
                const SizedBox(width: 12),
                _infoChip(Icons.straighten, _dist, Colors.white),
                const SizedBox(width: 12),
                _infoChip(Icons.speed, _speedKmh != null ? '${_speedKmh!.toStringAsFixed(0)} km/h' : '-- km/h', Colors.white),
              ]),
            ])).animate().fadeIn().slideY(begin: -0.1),

            const SizedBox(height: 16),

            // Navigate Button
            GestureDetector(
              onTap: _launchGoogleMaps,
              child: FunkyBox.pill(color: const Color(0xFF1A73E8), padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.navigation, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Text('Start Google Maps Navigation', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                ]),
              ),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

            const SizedBox(height: 24),

            // Garuda AI Alerts Section
            Row(children: [
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: GarudaColors.warning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.psychology, size: 18, color: GarudaColors.warning)),
              const SizedBox(width: 8),
              Text('Garuda AI Alerts', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: text)),
              const Spacer(),
              if (active.isNotEmpty) Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: GarudaColors.danger, borderRadius: BorderRadius.circular(10)),
                child: Text('${active.length}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ]),
            const SizedBox(height: 12),

            if (active.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: muted.withValues(alpha: 0.1))),
                child: Column(children: [
                  Icon(Icons.check_circle_outline, size: 40, color: GarudaColors.success.withValues(alpha: 0.6)),
                  const SizedBox(height: 8),
                  Text('Route is clear', style: GoogleFonts.inter(fontSize: 14, color: muted)),
                  Text('Garuda AI is monitoring your path', style: GoogleFonts.inter(fontSize: 12, color: muted.withValues(alpha: 0.6))),
                ]),
              ),

            ...active.map((alert) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FunkyBox.topRound(color: GarudaColors.warning.withValues(alpha: 0.95), padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.alt_route, color: Colors.black87, size: 22),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('REROUTE', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black87)),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(6)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.warning_amber_rounded, size: 11, color: Colors.black87),
                            const SizedBox(width: 3),
                            Text('${(alert.severity * 100).toInt()}/100', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.black87)),
                          ])),
                      ]),
                      const SizedBox(height: 4),
                      Text(alert.displayMessage, style: GoogleFonts.inter(fontSize: 13, color: Colors.black87)),
                    ])),
                  ]),
                  const SizedBox(height: 10),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    TextButton(onPressed: () => setState(() => _dismissed.add(alert.displayMessage)),
                      style: TextButton.styleFrom(foregroundColor: Colors.black54), child: const Text('Dismiss')),
                    const SizedBox(width: 8),
                    ElevatedButton(onPressed: () => _acceptReroute(alert),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black87, foregroundColor: Colors.white),
                      child: const Text('Accept & Reroute')),
                  ]),
                ]),
              ),
            )),

            // Alert history (dismissed)
            if (_dismissed.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Resolved (${_dismissed.length})', style: GoogleFonts.inter(fontSize: 13, color: muted, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ..._alerts.where((a) => _dismissed.contains(a.displayMessage)).map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: muted.withValues(alpha: 0.1))),
                  child: Row(children: [
                    const Icon(Icons.check, size: 16, color: GarudaColors.success),
                    const SizedBox(width: 8),
                    Expanded(child: Text(a.displayMessage, style: GoogleFonts.inter(fontSize: 12, color: muted), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ])),
              )),
            ],

            const SizedBox(height: 24),

            // Quick Actions
            Row(children: [
              Expanded(child: _actionBtn('Dispatched', Icons.send, GarudaColors.modeBike, () => _updateStatus('DISPATCHED'))),
              const SizedBox(width: 8),
              Expanded(child: _actionBtn('In Transit', Icons.local_shipping, GarudaColors.warning, () => _updateStatus('IN_TRANSIT'))),
              const SizedBox(width: 8),
              Expanded(child: _actionBtn('Delivered', Icons.check_circle, GarudaColors.success, () => _updateStatus('DELIVERED'))),
            ]),
            const SizedBox(height: 40),
          ])),
        ]),
      ),
    );
  }

  Widget _infoChip(IconData icon, String val, Color c) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: c.withValues(alpha: 0.7)),
      const SizedBox(width: 4),
      Text(val, style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w700, color: c)),
    ]);
  }

  Widget _actionBtn(String label, IconData icon, Color c, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: c.withValues(alpha: 0.3))),
      child: Column(children: [
        Icon(icon, size: 20, color: c),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: c), textAlign: TextAlign.center),
      ]),
    ));
  }
}
