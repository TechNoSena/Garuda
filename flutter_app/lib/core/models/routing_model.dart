import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum TransportMode {
  roadCar('ROAD_CAR', 'Road (Car/Truck)', Icons.local_shipping, GarudaColors.modeCar),
  roadBike('ROAD_BIKE', 'Road (Bike)', Icons.two_wheeler, GarudaColors.modeBike),
  rail('RAIL', 'Rail', Icons.train, GarudaColors.modeRail),
  flight('FLIGHT', 'Air Freight', Icons.flight, GarudaColors.modeFlight),
  ship('SHIP', 'Maritime', Icons.directions_boat, GarudaColors.modeShip);

  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const TransportMode(this.value, this.label, this.icon, this.color);

  static TransportMode fromString(String val) {
    return TransportMode.values.firstWhere(
      (e) => e.value == val,
      orElse: () => TransportMode.roadCar,
    );
  }
}

class RouteData {
  final String? description;
  final int? distanceMeters;
  final String? duration;
  final String? info;
  final Map<String, dynamic>? polyline;

  RouteData({
    this.description,
    this.distanceMeters,
    this.duration,
    this.info,
    this.polyline,
  });

  factory RouteData.fromJson(Map<String, dynamic> json) {
    return RouteData(
      description: json['description'],
      distanceMeters: json['distanceMeters'],
      duration: json['duration'],
      info: json['info'],
      polyline: json['polyline'],
    );
  }

  String get distanceDisplay {
    if (distanceMeters == null) return 'Unknown';
    final km = distanceMeters! / 1000;
    return '${km.toStringAsFixed(1)} km';
  }

  String get durationDisplay {
    if (duration == null) return 'Unknown';
    final raw = duration!.replaceAll('s', '');
    final seconds = int.tryParse(raw) ?? 0;
    final hours = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${mins}m';
    return '${mins}m';
  }
}
