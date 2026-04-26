import 'routing_model.dart';

class ModeComparison {
  final String mode;
  final double distanceKm;
  final double estimatedCostInr;
  final double estimatedCo2G;
  final double estimatedDurationMins;

  ModeComparison({
    required this.mode,
    required this.distanceKm,
    required this.estimatedCostInr,
    required this.estimatedCo2G,
    required this.estimatedDurationMins,
  });

  factory ModeComparison.fromJson(Map<String, dynamic> json) {
    return ModeComparison(
      mode: json['mode'] ?? '',
      distanceKm: (json['distance_km'] ?? 0).toDouble(),
      estimatedCostInr: (json['estimated_cost_inr'] ?? 0).toDouble(),
      estimatedCo2G: (json['estimated_co2_g'] ?? 0).toDouble(),
      estimatedDurationMins: (json['estimated_duration_mins'] ?? 0).toDouble(),
    );
  }

  TransportMode get transportMode {
    // Map backend mode labels to enum
    if (mode.contains('Bike')) return TransportMode.roadBike;
    if (mode.contains('Car') || mode.contains('Truck')) return TransportMode.roadCar;
    if (mode.contains('Rail')) return TransportMode.rail;
    if (mode.contains('Air') || mode.contains('Flight')) return TransportMode.flight;
    if (mode.contains('Maritime') || mode.contains('Sea')) return TransportMode.ship;
    return TransportMode.roadCar;
  }

  String get durationDisplay {
    final hours = estimatedDurationMins ~/ 60;
    final mins = (estimatedDurationMins % 60).round();
    if (hours > 0) return '${hours}h ${mins}m';
    return '${mins}m';
  }

  String get costDisplay => '₹${estimatedCostInr.toStringAsFixed(0)}';

  String get co2Display {
    if (estimatedCo2G >= 1000) {
      return '${(estimatedCo2G / 1000).toStringAsFixed(1)} kg';
    }
    return '${estimatedCo2G.toStringAsFixed(0)} g';
  }
}

class CompareModesResponse {
  final Map<String, dynamic> origin;
  final Map<String, dynamic> destination;
  final double straightLineKm;
  final List<ModeComparison> comparisons;
  final String? recommendation;

  CompareModesResponse({
    required this.origin,
    required this.destination,
    required this.straightLineKm,
    required this.comparisons,
    this.recommendation,
  });

  factory CompareModesResponse.fromJson(Map<String, dynamic> json) {
    return CompareModesResponse(
      origin: json['origin'] ?? {},
      destination: json['destination'] ?? {},
      straightLineKm: (json['straight_line_km'] ?? 0).toDouble(),
      comparisons: (json['comparisons'] as List? ?? [])
          .map((c) => ModeComparison.fromJson(c))
          .toList(),
      recommendation: json['recommendation'],
    );
  }
}
