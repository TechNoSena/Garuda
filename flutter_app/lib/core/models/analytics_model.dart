class ShipmentAnalytics {
  final String shipmentId;
  final double distanceKm;
  final double estimatedCo2EmissionG;
  final double fuelOrTransitCostInr;
  final double tollEstimateInr;
  final double efficiencyScore;

  ShipmentAnalytics({
    required this.shipmentId,
    required this.distanceKm,
    required this.estimatedCo2EmissionG,
    required this.fuelOrTransitCostInr,
    required this.tollEstimateInr,
    required this.efficiencyScore,
  });

  factory ShipmentAnalytics.fromJson(Map<String, dynamic> json) => ShipmentAnalytics(
    shipmentId: json['shipment_id'] ?? '',
    distanceKm: (json['distance_km'] ?? 0).toDouble(),
    estimatedCo2EmissionG: (json['estimated_co2_emission_g'] ?? 0).toDouble(),
    fuelOrTransitCostInr: (json['fuel_or_transit_cost_inr'] ?? 0).toDouble(),
    tollEstimateInr: (json['toll_estimate_inr'] ?? 0).toDouble(),
    efficiencyScore: (json['efficiency_score'] ?? 0).toDouble(),
  );
}

class PackageIntegrity {
  final int integrityScore;
  final String riskLevel;
  final Map<String, dynamic> factors;
  final List<String> recommendations;

  PackageIntegrity({
    required this.integrityScore,
    required this.riskLevel,
    required this.factors,
    required this.recommendations,
  });

  factory PackageIntegrity.fromJson(Map<String, dynamic> json) => PackageIntegrity(
    integrityScore: json['integrity_score'] ?? 0,
    riskLevel: json['risk_level'] ?? 'UNKNOWN',
    factors: json['factors'] ?? {},
    recommendations: List<String>.from(json['recommendations'] ?? []),
  );
}

class BillingEstimate {
  final double totalEstimatedCostInr;
  final Map<String, dynamic> breakdown;
  final double distanceKm;
  final String mode;

  BillingEstimate({
    required this.totalEstimatedCostInr,
    required this.breakdown,
    required this.distanceKm,
    required this.mode,
  });

  factory BillingEstimate.fromJson(Map<String, dynamic> json) {
    final breakdown = json['cost_breakdown'] ?? {};
    final route = json['route'] ?? {};
    return BillingEstimate(
      totalEstimatedCostInr: (breakdown['total_inr'] ?? 0).toDouble(),
      breakdown: breakdown,
      distanceKm: (route['distance_km'] ?? 0).toDouble(),
      mode: route['mode'] ?? 'UNKNOWN',
    );
  }
}
