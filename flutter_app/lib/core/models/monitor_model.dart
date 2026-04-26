class RideMonitorResponse {
  final String status;
  final double severity;
  final String? reason;
  final String? message;
  final Map<String, dynamic>? newRoute;
  final dynamic remainingDistance;
  final dynamic remainingDuration;

  RideMonitorResponse({
    required this.status,
    required this.severity,
    this.reason,
    this.message,
    this.newRoute,
    this.remainingDistance,
    this.remainingDuration,
  });

  factory RideMonitorResponse.fromJson(Map<String, dynamic> json) {
    return RideMonitorResponse(
      status: json['status'] ?? 'ON_TRACK',
      severity: (json['severity'] ?? 0).toDouble(),
      reason: json['reason'],
      message: json['message'],
      newRoute: json['new_route'],
      remainingDistance: json['remaining_distance'],
      remainingDuration: json['remaining_duration'],
    );
  }

  bool get isRerouteNeeded => status == 'REROUTE_SUGGESTED';
  bool get isOnTrack => status == 'ON_TRACK';
  bool get isNoRoute => status == 'NO_ROUTE';

  String get displayMessage {
    if (isRerouteNeeded) {
      return reason ?? 'Hazard detected — reroute suggested';
    }
    return message ?? 'Path looks clear';
  }
}
