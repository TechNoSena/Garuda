import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../theme/app_theme.dart';
import '../models/shipment_model.dart' as app;

/// Reusable in-app Google Maps widget for live driver tracking.
/// Used by ActiveRideScreen (driver), TrackShipmentScreen (consumer),
/// and ShipmentDetailScreen (supplier).
class LiveMapWidget extends StatefulWidget {
  final app.LatLng origin;
  final app.LatLng destination;
  final app.LatLng? driverLocation;
  final double height;
  final String? etaDisplay;
  final bool showRecenterButton;
  final bool fullScreen;
  final bool followDriver;
  final double? driverBearing;

  /// Called when Directions API returns ETA/distance info
  final void Function(String etaText, String distanceText, int etaMinutes)? onDirectionsInfo;

  const LiveMapWidget({
    super.key,
    required this.origin,
    required this.destination,
    this.driverLocation,
    this.height = 280,
    this.etaDisplay,
    this.showRecenterButton = true,
    this.fullScreen = false,
    this.followDriver = false,
    this.driverBearing,
    this.onDirectionsInfo,
  });

  @override
  State<LiveMapWidget> createState() => LiveMapWidgetState();
}

class LiveMapWidgetState extends State<LiveMapWidget> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  // Google Directions API
  static const String _mapsApiKey = 'AIzaSyCGJyIbpXwOMG_vLlBilIWP0zzkNSysdWM';
  List<LatLng>? _cachedRoutePoints;
  String? _lastFetchedKey;

  // Night mode style for navigation
  static const String _nightStyle = '''[
    {"elementType":"geometry","stylers":[{"color":"#212121"}]},
    {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
    {"elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
    {"elementType":"labels.text.stroke","stylers":[{"color":"#212121"}]},
    {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#757575"}]},
    {"featureType":"administrative.country","elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]},
    {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#bdbdbd"}]},
    {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
    {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#181818"}]},
    {"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},
    {"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#2c2c2c"}]},
    {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#8a8a8a"}]},
    {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#373737"}]},
    {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3c3c3c"}]},
    {"featureType":"road.highway.controlled_access","elementType":"geometry","stylers":[{"color":"#4e4e4e"}]},
    {"featureType":"road.local","elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},
    {"featureType":"transit","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
    {"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]},
    {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#3d3d3d"}]}
  ]''';

  @override
  void initState() {
    super.initState();
    _buildMapData();
    _fetchDirectionsPolyline();
  }

  @override
  void didUpdateWidget(covariant LiveMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.driverLocation != oldWidget.driverLocation ||
        widget.origin != oldWidget.origin ||
        widget.destination != oldWidget.destination) {
      _buildMarkers();
      if (widget.followDriver && widget.driverLocation != null) {
        _followDriverCamera();
      } else if (!widget.followDriver) {
        _animateCameraToDriver();
      }
      
      // Update directions if driver moved significantly (or origin/dest changed)
      // Since polling is every 15-30s, we can afford to fetch here.
      _fetchDirectionsPolyline();
    }
  }

  /// Fetch actual road polyline from Google Directions API
  Future<void> _fetchDirectionsPolyline() async {
    // Use driver location (current pos) as origin if available
    final dirOrigin = widget.driverLocation ?? widget.origin;
    final key = '${dirOrigin.lat},${dirOrigin.lng}->${widget.destination.lat},${widget.destination.lng}';
    if (key == _lastFetchedKey && _cachedRoutePoints != null) return;

    try {
      final url = 'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=${dirOrigin.lat},${dirOrigin.lng}'
          '&destination=${widget.destination.lat},${widget.destination.lng}'
          '&key=$_mapsApiKey';
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final encodedPolyline = route['overview_polyline']['points'] as String;
          final decoded = _decodePolyline(encodedPolyline);
          _lastFetchedKey = key;
          _cachedRoutePoints = decoded;
          _buildPolylines();
          if (mounted) setState(() {});

          // Extract ETA + distance from first leg
          if (route['legs'] != null && (route['legs'] as List).isNotEmpty) {
            final leg = route['legs'][0];
            final durationText = leg['duration']['text'] ?? '';
            final distanceText = leg['distance']['text'] ?? '';
            final durationSecs = leg['duration']['value'] ?? 0;
            final etaMinutes = (durationSecs / 60).round();
            widget.onDirectionsInfo?.call(durationText, distanceText, etaMinutes);
          }
        } else {
          print('LiveMapWidget: Directions API returned no routes. Response: ${resp.body}');
        }
      } else {
        print('LiveMapWidget: Directions API failed with status ${resp.statusCode}: ${resp.body}');
      }
    } catch (e) {
      print('LiveMapWidget: Error fetching directions: $e');
      // Fallback: straight line already drawn
    }
  }

  /// Re-fetch directions (called on reroute)
  Future<void> refetchDirections() async {
    _lastFetchedKey = null;
    _cachedRoutePoints = null;
    await _fetchDirectionsPolyline();
  }

  /// Decode Google's encoded polyline format using flutter_polyline_points
  List<LatLng> _decodePolyline(String encoded) {
    final result = PolylinePoints.decodePolyline(encoded);
    return result.map((p) => LatLng(p.latitude, p.longitude)).toList();
  }

  void _buildMapData() {
    _buildMarkers();
    _buildPolylines();
  }

  void _buildMarkers() {
    _markers.clear();

    // Origin marker
    _markers.add(Marker(
      markerId: const MarkerId('origin'),
      position: LatLng(widget.origin.lat, widget.origin.lng),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: const InfoWindow(title: 'Origin'),
    ));

    // Destination marker
    _markers.add(Marker(
      markerId: const MarkerId('destination'),
      position: LatLng(widget.destination.lat, widget.destination.lng),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: const InfoWindow(title: 'Destination'),
    ));

    // Driver marker (blue dot)
    if (widget.driverLocation != null) {
      _markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: LatLng(widget.driverLocation!.lat, widget.driverLocation!.lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'You'),
        flat: true,
        rotation: widget.driverBearing ?? 0,
      ));
    }

    if (mounted) setState(() {});
  }

  void _buildPolylines() {
    _polylines.clear();

    if (_cachedRoutePoints != null && _cachedRoutePoints!.isNotEmpty) {
      // Real road polyline from Google Directions
      _polylines.add(Polyline(
        polylineId: const PolylineId('route'),
        points: _cachedRoutePoints!,
        color: const Color(0xFF4FC3F7), // Bright cyan-blue, visible on dark map
        width: 8,
      ));
    } else {
      // Fallback: straight-line polyline
      final List<LatLng> routePoints = [
        LatLng(widget.origin.lat, widget.origin.lng),
      ];
      if (widget.driverLocation != null) {
        routePoints.add(LatLng(widget.driverLocation!.lat, widget.driverLocation!.lng));
      }
      routePoints.add(LatLng(widget.destination.lat, widget.destination.lng));

      _polylines.add(Polyline(
        polylineId: const PolylineId('route'),
        points: routePoints,
        color: const Color(0xFF4285F4),
        width: 5,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ));
    }

    if (mounted) setState(() {});
  }

  void _animateCameraToDriver() {
    if (_mapController == null) return;
    final target = widget.driverLocation ?? widget.origin;
    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(target.lat, target.lng),
        12,
      ),
    );
  }

  /// Follow driver at street-level zoom with tilt + bearing (navigation mode)
  void _followDriverCamera() {
    if (_mapController == null || widget.driverLocation == null) return;
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(widget.driverLocation!.lat, widget.driverLocation!.lng),
          zoom: 17,
          tilt: 60, // 3D perspective like Google Maps nav
          bearing: widget.driverBearing ?? 0,
        ),
      ),
    );
  }

  /// Public: update route polyline when reroute is accepted
  void updateRoutePoints(List<app.LatLng> newRoutePoints) {
    _polylines.removeWhere((p) => p.polylineId.value == 'remaining' || p.polylineId.value == 'route');
    if (newRoutePoints.length >= 2) {
      _polylines.add(Polyline(
        polylineId: const PolylineId('route'),
        points: newRoutePoints.map((p) => LatLng(p.lat, p.lng)).toList(),
        color: const Color(0xFF4285F4),
        width: 6,
      ));
    }
    if (mounted) setState(() {});
  }

  void fitBounds() {
    if (_mapController == null) return;
    final points = <LatLng>[
      LatLng(widget.origin.lat, widget.origin.lng),
      LatLng(widget.destination.lat, widget.destination.lng),
    ];
    if (widget.driverLocation != null) {
      points.add(LatLng(widget.driverLocation!.lat, widget.driverLocation!.lng));
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - 0.01, minLng - 0.01),
          northeast: LatLng(maxLat + 0.01, maxLng + 0.01),
        ),
        60,
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? GarudaDarkColors.textPrimary : GarudaColors.textPrimary;
    final mutedColor = isDark ? GarudaDarkColors.textMuted : GarudaColors.textMuted;
    final centerLat = widget.driverLocation?.lat ??
        (widget.origin.lat + widget.destination.lat) / 2;
    final centerLng = widget.driverLocation?.lng ??
        (widget.origin.lng + widget.destination.lng) / 2;

    final mapContent = Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(centerLat, centerLng),
            zoom: widget.followDriver ? 17 : 11,
            tilt: widget.followDriver ? 60 : 0,
            bearing: widget.followDriver ? (widget.driverBearing ?? 0) : 0,
          ),
          markers: _markers,
          polylines: _polylines,
          myLocationEnabled: widget.followDriver,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
          // Removed aggressive custom style to restore standard Google Maps look with roads visible
          onMapCreated: (controller) {
            _mapController = controller;
            // Longer delay to ensure map is fully loaded before camera animation
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (widget.followDriver && widget.driverLocation != null) {
                _followDriverCamera();
              } else {
                fitBounds();
              }
            });
          },
        ),
        if (widget.driverLocation != null && !widget.fullScreen)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (isDark ? GarudaDarkColors.surface : GarudaColors.surface).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: GarudaColors.danger, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: GarudaColors.danger, shape: BoxShape.circle),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                    begin: const Offset(1, 1), end: const Offset(1.5, 1.5), duration: 800.ms,
                  ),
                  const SizedBox(width: 6),
                  Text('LIVE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: GarudaColors.danger)),
                ],
              ),
            ),
          ),
        if (widget.showRecenterButton)
          Positioned(
            bottom: widget.fullScreen ? 20 : 12,
            right: 12,
            child: GestureDetector(
              onTap: fitBounds,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isDark ? GarudaDarkColors.surface : GarudaColors.surface).withValues(alpha: 0.95),
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? GarudaDarkColors.glassBorderStrong : GarudaColors.glassBorderStrong, width: 1.5),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
                ),
                child: const Icon(Icons.my_location, size: 20, color: GarudaColors.primary),
              ),
            ),
          ),
      ],
    );

    if (widget.fullScreen) {
      return mapContent;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? GarudaDarkColors.glassBorderStrong : GarudaColors.glassBorderStrong,
              width: 2,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: mapContent,
        ),
        // ETA display below map
        if (widget.etaDisplay != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: GarudaColors.primary.withValues(alpha: isDark ? 0.2 : 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: GarudaColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, size: 18, color: GarudaColors.primary),
                const SizedBox(width: 8),
                Text('ETA: ', style: GoogleFonts.inter(fontSize: 13, color: mutedColor, fontWeight: FontWeight.w500)),
                Expanded(
                  child: Text(
                    widget.etaDisplay!,
                    style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w700, color: textColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
