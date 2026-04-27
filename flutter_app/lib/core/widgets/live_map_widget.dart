import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

  const LiveMapWidget({
    super.key,
    required this.origin,
    required this.destination,
    this.driverLocation,
    this.height = 280,
    this.etaDisplay,
    this.showRecenterButton = true,
  });

  @override
  State<LiveMapWidget> createState() => _LiveMapWidgetState();
}

class _LiveMapWidgetState extends State<LiveMapWidget> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _buildMapData();
  }

  @override
  void didUpdateWidget(covariant LiveMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.driverLocation != oldWidget.driverLocation ||
        widget.origin != oldWidget.origin ||
        widget.destination != oldWidget.destination) {
      _buildMapData();
      _animateCameraToDriver();
    }
  }

  void _buildMapData() {
    _markers.clear();
    _polylines.clear();

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

    // Driver marker (if available)
    if (widget.driverLocation != null) {
      _markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: LatLng(widget.driverLocation!.lat, widget.driverLocation!.lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Driver'),
      ));
    }

    // Route polyline (origin → driver → destination)
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
      color: GarudaColors.primary,
      width: 4,
      patterns: [PatternItem.dash(20), PatternItem.gap(10)],
    ));

    // Remaining route polyline (driver → destination) in bold
    if (widget.driverLocation != null) {
      _polylines.add(Polyline(
        polylineId: const PolylineId('remaining'),
        points: [
          LatLng(widget.driverLocation!.lat, widget.driverLocation!.lng),
          LatLng(widget.destination.lat, widget.destination.lng),
        ],
        color: GarudaColors.warning,
        width: 5,
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

  void _fitBounds() {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Map container
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
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(centerLat, centerLng),
                  zoom: 11,
                ),
                markers: _markers,
                polylines: _polylines,
                myLocationEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
                onMapCreated: (controller) {
                  _mapController = controller;
                  // Fit bounds after map is created
                  Future.delayed(const Duration(milliseconds: 500), _fitBounds);
                },
              ),
              // Live pulsing indicator
              if (widget.driverLocation != null)
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
              // Recenter button
              if (widget.showRecenterButton)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: _fitBounds,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isDark ? GarudaDarkColors.surface : GarudaColors.surface).withValues(alpha: 0.95),
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? GarudaDarkColors.glassBorderStrong : GarudaColors.glassBorderStrong, width: 1.5),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
                      ),
                      child: Icon(Icons.my_location, size: 20, color: GarudaColors.primary),
                    ),
                  ),
                ),
            ],
          ),
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
