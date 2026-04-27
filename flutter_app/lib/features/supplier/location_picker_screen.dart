import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../core/theme/app_theme.dart';
import '../../core/models/shipment_model.dart' as models;
import '../../core/widgets/glassmorphic_card.dart';

class LocationPickerScreen extends StatefulWidget {
  final models.LatLng? initialLocation;
  
  const LocationPickerScreen({super.key, this.initialLocation});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;
  LatLng _selectedLocation = const LatLng(28.6139, 77.2090); // Default: New Delhi
  final String _googleMapsApiKey = "AIzaSyCGJyIbpXwOMG_vLlBilIWP0zzkNSysdWM";
  
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _placeSuggestions = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _selectedLocation = LatLng(widget.initialLocation!.lat, widget.initialLocation!.lng);
    } else {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _selectedLocation = LatLng(position.latitude, position.longitude);
    });

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _selectedLocation, zoom: 15),
      ),
    );
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() => _placeSuggestions = []);
      return;
    }

    setState(() => _isSearching = true);
    final url = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$_googleMapsApiKey";
    
    try {
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);
      if (data['status'] == 'OK') {
        setState(() {
          _placeSuggestions = data['predictions'];
        });
      } else {
        setState(() => _placeSuggestions = []);
      }
    } catch (_) {}
    setState(() => _isSearching = false);
  }

  Future<void> _getPlaceDetails(String placeId) async {
    final url = "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_googleMapsApiKey";
    try {
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);
      if (data['status'] == 'OK') {
        final location = data['result']['geometry']['location'];
        final latLng = LatLng(location['lat'], location['lng']);
        
        setState(() {
          _selectedLocation = latLng;
          _placeSuggestions = [];
          _searchController.clear();
          FocusScope.of(context).unfocus();
        });
        
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: _selectedLocation, zoom: 15),
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _selectedLocation, zoom: 12),
            onMapCreated: (controller) {
              _mapController = controller;
              // Set dark map style
              _mapController?.setMapStyle(_darkMapStyle);
            },
            onTap: (latLng) {
              setState(() => _selectedLocation = latLng);
            },
            markers: {
              Marker(
                markerId: const MarkerId('selected'),
                position: _selectedLocation,
                draggable: true,
                onDragEnd: (latLng) {
                  setState(() => _selectedLocation = latLng);
                },
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
              )
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          
          // Search Bar Overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: GarudaColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: GarudaColors.glassBorder),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.inter(color: GarudaColors.textPrimary),
                      onChanged: (v) {
                        if (v.length > 2) _searchPlaces(v);
                      },
                      decoration: InputDecoration(
                        hintText: 'Search location...',
                        hintStyle: GoogleFonts.inter(color: GarudaColors.textMuted),
                        prefixIcon: IconButton(
                          icon: const Icon(Icons.arrow_back, color: GarudaColors.textPrimary),
                          onPressed: () => Navigator.pop(context),
                        ),
                        suffixIcon: _isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: GarudaColors.primary)),
                              )
                            : IconButton(
                                icon: const Icon(Icons.clear, color: GarudaColors.textMuted),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _placeSuggestions = []);
                                },
                              ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        filled: false,
                      ),
                    ),
                  ),
                  if (_placeSuggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: GarudaColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: GarudaColors.glassBorder),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 15)
                        ],
                      ),
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _placeSuggestions.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: GarudaColors.glassBorder),
                        itemBuilder: (context, index) {
                          final place = _placeSuggestions[index];
                          return ListTile(
                            leading: const Icon(Icons.location_on_outlined, color: GarudaColors.textMuted),
                            title: Text(place['description'], style: GoogleFonts.inter(fontSize: 13, color: GarudaColors.textPrimary)),
                            onTap: () => _getPlaceDetails(place['place_id']),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Bottom Controls
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: 'myLocation',
                  backgroundColor: GarudaColors.surfaceLight,
                  onPressed: _getCurrentLocation,
                  child: const Icon(Icons.my_location, color: GarudaColors.primaryLight),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GradientButton(
                    label: 'Confirm Location',
                    icon: Icons.check,
                    onPressed: () {
                      Navigator.pop(context, models.LatLng(lat: _selectedLocation.latitude, lng: _selectedLocation.longitude));
                    },
                    height: 56,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Google Maps Dark Mode Style
  static const String _darkMapStyle = '''
  [
    {
      "elementType": "geometry",
      "stylers": [{"color": "#242f3e"}]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#746855"}]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#242f3e"}]
    },
    {
      "featureType": "administrative.locality",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#d59563"}]
    },
    {
      "featureType": "poi",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#d59563"}]
    },
    {
      "featureType": "poi.park",
      "elementType": "geometry",
      "stylers": [{"color": "#263c3f"}]
    },
    {
      "featureType": "poi.park",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#6b9a76"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [{"color": "#38414e"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry.stroke",
      "stylers": [{"color": "#212a37"}]
    },
    {
      "featureType": "road",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#9ca5b3"}]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry",
      "stylers": [{"color": "#746855"}]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry.stroke",
      "stylers": [{"color": "#1f2835"}]
    },
    {
      "featureType": "road.highway",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#f3d19c"}]
    },
    {
      "featureType": "transit",
      "elementType": "geometry",
      "stylers": [{"color": "#2f3948"}]
    },
    {
      "featureType": "transit.station",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#d59563"}]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [{"color": "#17263c"}]
    },
    {
      "featureType": "water",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#515c6d"}]
    },
    {
      "featureType": "water",
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#17263c"}]
    }
  ]
  ''';
}
