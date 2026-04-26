import 'routing_model.dart';

class DisruptionEvent {
  final String type;
  final double severity;
  final Location location;
  final String description;
  final List<String> affectedModes;
  final int estimatedDelayMins;

  DisruptionEvent({
    required this.type,
    required this.severity,
    required this.location,
    required this.description,
    required this.affectedModes,
    required this.estimatedDelayMins,
  });

  factory DisruptionEvent.fromJson(Map<String, dynamic> json) => DisruptionEvent(
    type: json['type'] ?? '',
    severity: (json['severity'] ?? 0).toDouble(),
    location: Location.fromJson(json['location'] ?? {}),
    description: json['description'] ?? '',
    affectedModes: List<String>.from(json['affected_modes'] ?? []),
    estimatedDelayMins: json['estimated_delay_mins'] ?? 0,
  );
}

class TimelineEvent {
  final String type; // STATUS_CHANGE, LOCATION_UPDATE, EVENT
  final String detail;
  final String timestamp;
  final String? status;
  final Location? location;

  TimelineEvent({
    required this.type,
    required this.detail,
    required this.timestamp,
    this.status,
    this.location,
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> json) => TimelineEvent(
    type: json['type'] ?? 'EVENT',
    detail: json['detail'] ?? '',
    timestamp: json['timestamp'] ?? '',
    status: json['status'],
    location: json['location'] != null ? Location.fromJson(json['location']) : null,
  );
}

class ExplainableRiskDetails {
  final String shipmentId;
  final int riskScore;
  final String riskLevel;
  final String explanation;
  final List<RiskFactorDetail> factors;
  final List<String> mitigationActions;

  ExplainableRiskDetails({
    required this.shipmentId,
    required this.riskScore,
    required this.riskLevel,
    required this.explanation,
    required this.factors,
    required this.mitigationActions,
  });

  factory ExplainableRiskDetails.fromJson(Map<String, dynamic> json) => ExplainableRiskDetails(
    shipmentId: json['shipment_id'] ?? '',
    riskScore: json['risk_score'] ?? 0,
    riskLevel: json['risk_level'] ?? 'UNKNOWN',
    explanation: json['explanation'] ?? '',
    factors: (json['factors'] as List? ?? []).map((f) => RiskFactorDetail.fromJson(f)).toList(),
    mitigationActions: List<String>.from(json['mitigation_actions'] ?? []),
  );
}

class RiskFactorDetail {
  final String name;
  final double weight;
  final double score;
  final String detail;

  RiskFactorDetail({required this.name, required this.weight, required this.score, required this.detail});

  factory RiskFactorDetail.fromJson(Map<String, dynamic> json) => RiskFactorDetail(
    name: json['name'] ?? '',
    weight: (json['weight'] ?? 0).toDouble(),
    score: (json['score'] ?? 0).toDouble(),
    detail: json['detail'] ?? '',
  );
}

class FatigueAssessment {
  final String driverId;
  final double fatigueScore;
  final String riskLevel;
  final String action;
  final double hoursDriven;
  final double totalKmDriven;
  final int breaksTaken;
  final List<String> recommendations;

  FatigueAssessment({
    required this.driverId,
    required this.fatigueScore,
    required this.riskLevel,
    required this.action,
    required this.hoursDriven,
    required this.totalKmDriven,
    required this.breaksTaken,
    required this.recommendations,
  });

  factory FatigueAssessment.fromJson(Map<String, dynamic> json) => FatigueAssessment(
    driverId: json['driver_id'] ?? '',
    fatigueScore: (json['fatigue_score'] ?? 0).toDouble(),
    riskLevel: json['risk_level'] ?? 'UNKNOWN',
    action: json['action'] ?? '',
    hoursDriven: (json['hours_driven'] ?? 0).toDouble(),
    totalKmDriven: (json['total_km_driven'] ?? 0).toDouble(),
    breaksTaken: json['breaks_taken'] ?? 0,
    recommendations: List<String>.from(json['recommendations'] ?? []),
  );
}

class DemandSurgePrediction {
  final bool surgePredicted;
  final double surgeProbability;
  final List<String> peakDays;
  final List<Map<String, dynamic>> triggers;
  final int recommendedFleetIncreasePct;

  DemandSurgePrediction({
    required this.surgePredicted,
    required this.surgeProbability,
    required this.peakDays,
    required this.triggers,
    required this.recommendedFleetIncreasePct,
  });

  factory DemandSurgePrediction.fromJson(Map<String, dynamic> json) => DemandSurgePrediction(
    surgePredicted: json['surge_predicted'] ?? false,
    surgeProbability: (json['surge_probability'] ?? 0).toDouble(),
    peakDays: List<String>.from(json['peak_days'] ?? []),
    triggers: List<Map<String, dynamic>>.from(json['triggers'] ?? []),
    recommendedFleetIncreasePct: json['recommended_fleet_increase_pct'] ?? 0,
  );
}
