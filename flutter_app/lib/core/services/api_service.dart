import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/shipment_model.dart';
import '../models/routing_model.dart';
import '../models/risk_model.dart';
import '../models/compare_model.dart';
import '../models/monitor_model.dart';
import '../models/analytics_model.dart';
import '../models/intelligence_model.dart';
import '../models/notification_model.dart';
import 'package:flutter_client_sse/constants/sse_request_type_enum.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String get baseUrl {
    // Return live production backend URL
    return 'https://garuda-backend-437904093333.asia-south1.run.app';
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
  };

  Future<Map<String, dynamic>> _get(String path) async {
    final resp = await http.get(Uri.parse('$baseUrl$path'), headers: _headers);
    return _handleResponse(resp);
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final resp = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(resp);
  }

  Future<Map<String, dynamic>> _patch(String path, {Map<String, dynamic>? body}) async {
    final resp = await http.patch(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(resp);
  }

  Map<String, dynamic> _handleResponse(http.Response resp) {
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final decoded = jsonDecode(resp.body);
      if (decoded is List) return {'data': decoded};
      return decoded as Map<String, dynamic>;
    }
    String message;
    try {
      final err = jsonDecode(resp.body);
      message = err['detail'] ?? err['message'] ?? 'Request failed';
    } catch (_) {
      message = resp.body;
    }
    throw ApiException(resp.statusCode, message);
  }

  // ─────────────── HEALTH ───────────────
  Future<Map<String, dynamic>> healthCheck() => _get('/v1/health');

  // ─────────────── AUTH ───────────────
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String role,
    String? companyName,
    String? phone,
  }) => _post('/v1/auth/register', {
    'email': email,
    'password': password,
    'name': name,
    'role': role,
    if (companyName != null) 'company_name': companyName,
    if (phone != null) 'phone': phone,
  });

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) => _post('/v1/auth/login', {
    'email': email,
    'password': password,
  });

  Future<Map<String, dynamic>> resetPassword(String email) =>
      _post('/v1/auth/reset-password', {'email': email});

  Future<Map<String, dynamic>> getProfile(String uid) =>
      _get('/v1/auth/profile/$uid');

  // ─────────────── SHIPMENTS ───────────────
  Future<Map<String, dynamic>> createShipment({
    required String supplierId,
    required String logisticsId,
    required String consumerEmail,
    required LatLng origin,
    required LatLng destination,
    String routeMode = 'ROAD_CAR',
    String? packageDescription,
    double? weightKg,
  }) => _post('/v1/shipments/', {
    'supplier_id': supplierId,
    'logistics_id': logisticsId,
    'consumer_email': consumerEmail,
    'origin': origin.toJson(),
    'destination': destination.toJson(),
    'route_mode': routeMode,
    if (packageDescription != null) 'package_description': packageDescription,
    if (weightKg != null) 'weight_kg': weightKg,
  });

  Future<Shipment> getShipment(String id) async {
    final json = await _get('/v1/shipments/$id');
    return Shipment.fromJson(json);
  }

  Future<ShipmentEta> getShipmentEta(String id) async {
    final json = await _get('/v1/shipments/$id/eta');
    return ShipmentEta.fromJson(json);
  }

  Future<List<Shipment>> listShipmentsByUser(String uid, String role) async {
    final json = await _get('/v1/shipments/user/$uid?role=$role');
    final list = json['data'] as List? ?? [json];
    return list.map((s) => Shipment.fromJson(s as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> assignShipment(String id, String deliveryManId) =>
      _patch('/v1/shipments/$id/assign', body: {'delivery_man_id': deliveryManId});

  Future<Map<String, dynamic>> updateShipmentStatus(String id, String status) =>
      _patch('/v1/shipments/$id/status?status=$status');

  Future<Map<String, dynamic>> updateShipmentLocation(String id, LatLng location) =>
      _patch('/v1/shipments/$id/location', body: {
        'current_location': location.toJson(),
      });

  Stream<SSEModel> getLiveTrackingStream(String id) {
    return SSEClient.subscribeToSSE(
      method: SSERequestType.GET,
      url: '$baseUrl/v1/shipments/$id/live',
      header: _headers,
    );
  }

  Future<List<TimelineEvent>> getShipmentTimeline(String id) async {
    final json = await _get('/v1/shipments/$id/timeline');
    final list = json['timeline'] as List? ?? [];
    return list.map((e) => TimelineEvent.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> logException(String id, String type, String description, double severity, String driverId) =>
      _post('/v1/shipments/$id/exception', {
        'exception_type': type,
        'description': description,
        'severity': severity,
        'reported_by': driverId,
      });

  Future<Map<String, dynamic>> reportIncident(String id, String type, String description, LatLng location, double severity, String driverId) =>
      _post('/v1/shipments/$id/report-incident', {
        'incident_type': type,
        'description': description,
        'location': location.toJson(),
        'severity': severity,
        'driver_id': driverId,
      });

  Future<ExplainableRiskDetails> getRiskDetails(String id) async {
    final json = await _get('/v1/shipments/$id/risk-details');
    return ExplainableRiskDetails.fromJson(json);
  }

  // ─────────────── ROUTING ───────────────
  Future<String> startSession() async {
    final json = await _post('/v1/session/start', {});
    return json['session_id'] as String;
  }

  Future<List<RouteData>> fetchRoutes({
    required String sessionId,
    required LatLng origin,
    required LatLng destination,
    String mode = 'ROAD_CAR',
  }) async {
    final json = await _post('/v1/routes/fetch', {
      'session_id': sessionId,
      'origin': origin.toJson(),
      'destination': destination.toJson(),
      'mode': mode,
    });
    return (json['routes'] as List? ?? [])
        .map((r) => RouteData.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> optimizeMulti({
    required String sessionId,
    required List<LatLng> points,
    String mode = 'ROAD_CAR',
  }) => _post('/v1/routes/optimize-multi', {
    'session_id': sessionId,
    'points': points.map((p) => p.toJson()).toList(),
    'mode': mode,
  });

  Future<RiskAnalysis> analyzeRoute({
    required String sessionId,
    required LatLng origin,
    required LatLng destination,
    String mode = 'ROAD_CAR',
    Map<String, dynamic>? routeData,
  }) async {
    final json = await _post('/v1/routes/analyze', {
      'session_id': sessionId,
      'origin': origin.toJson(),
      'destination': destination.toJson(),
      'mode': mode,
      if (routeData != null) 'route_data': routeData,
    });
    return RiskAnalysis.fromJson(json);
  }

  Future<CompareModesResponse> compareModes({
    required String sessionId,
    required LatLng origin,
    required LatLng destination,
  }) async {
    final json = await _post('/v1/routes/compare-modes', {
      'session_id': sessionId,
      'origin': origin.toJson(),
      'destination': destination.toJson(),
    });
    return CompareModesResponse.fromJson(json);
  }

  Future<RideMonitorResponse> monitorRide({
    required String sessionId,
    required LatLng currentLocation,
    required LatLng destination,
    String mode = 'ROAD_CAR',
    String? shipmentId,
  }) async {
    final json = await _post('/v1/ride/monitor', {
      'session_id': sessionId,
      'current_location': currentLocation.toJson(),
      'destination': destination.toJson(),
      'mode': mode,
      if (shipmentId != null) 'shipment_id': shipmentId,
    });
    return RideMonitorResponse.fromJson(json);
  }

  Future<Map<String, dynamic>> reroute({
    required String sessionId,
    required String shipmentId,
    required LatLng origin,
    required LatLng destination,
    required String mode,
    required List<LatLng> avoidZones,
    required String reason,
  }) => _post('/v1/routes/reroute', {
    'session_id': sessionId,
    'shipment_id': shipmentId,
    'origin': origin.toJson(),
    'destination': destination.toJson(),
    'mode': mode,
    'avoid_zones': avoidZones.map((z) => z.toJson()).toList(),
    'reason': reason,
  });

  Future<Map<String, dynamic>> precheckRoute({
    required String sessionId,
    required LatLng origin,
    required LatLng destination,
    required String mode,
    String? dispatchTime,
    String cargoType = 'general',
  }) => _post('/v1/routes/precheck', {
    'session_id': sessionId,
    'origin': origin.toJson(),
    'destination': destination.toJson(),
    'mode': mode,
    if (dispatchTime != null) 'dispatch_time': dispatchTime,
    'cargo_type': cargoType,
  });

  // ─────────────── RISK & ANALYTICS ───────────────
  Future<Map<String, dynamic>> evaluateRisk({
    required LatLng origin,
    required LatLng destination,
    required String mode,
    String cargoType = 'general',
    double? weightKg,
  }) => _post('/v1/risk/evaluate', {
    'origin': origin.toJson(),
    'destination': destination.toJson(),
    'mode': mode,
    'cargo_type': cargoType,
    if (weightKg != null) 'weight_kg': weightKg,
  });

  Future<Map<String, dynamic>> detectDisruptions({
    required LatLng center,
    required double radiusKm,
    required List<String> modesToCheck,
  }) => _post('/v1/disruptions/detect', {
    'center': center.toJson(),
    'radius_km': radiusKm,
    'modes_to_check': modesToCheck,
  });

  Future<ShipmentAnalytics> getShipmentAnalytics(String id) async {
    final json = await _get('/v1/analytics/shipment/$id');
    return ShipmentAnalytics.fromJson(json);
  }

  Future<PackageIntegrity> getPackageIntegrity(String id, String cargoType, double weightKg, String mode) async {
    final json = await _get('/v1/analytics/package-integrity/$id?cargo_type=$cargoType&weight_kg=$weightKg&mode=$mode');
    return PackageIntegrity.fromJson(json);
  }

  Future<BillingEstimate> getBillingEstimate({
    required LatLng origin,
    required LatLng destination,
    required String mode,
    required double weightKg,
    bool isExpress = false,
    bool isFragile = false,
  }) async {
    final q = '?origin_lat=${origin.lat}&origin_lng=${origin.lng}&dest_lat=${destination.lat}&dest_lng=${destination.lng}&mode=$mode&weight_kg=$weightKg&is_express=$isExpress&is_fragile=$isFragile';
    final json = await _get('/v1/billing/estimate$q');
    return BillingEstimate.fromJson(json);
  }

  // ─────────────── INTELLIGENCE ───────────────
  Future<FatigueAssessment> checkDriverFatigue({
    required String driverId,
    required String driveStartTime,
    required LatLng currentLocation,
    required double totalKmDriven,
    required int breaksTaken,
  }) async {
    final json = await _post('/v1/driver/fatigue-check', {
      'driver_id': driverId,
      'drive_start_time': driveStartTime,
      'current_location': currentLocation.toJson(),
      'total_km_driven': totalKmDriven,
      'breaks_taken': breaksTaken,
    });
    return FatigueAssessment.fromJson(json);
  }

  Future<DemandSurgePrediction> predictDemandSurge({
    required LatLng regionCenter,
    required double radiusKm,
    required int predictionWindowDays,
    required String category,
  }) async {
    final json = await _post('/v1/predictions/demand-surge', {
      'region_center': regionCenter.toJson(),
      'radius_km': radiusKm,
      'prediction_window_days': predictionWindowDays,
      'category': category,
    });
    return DemandSurgePrediction.fromJson(json);
  }

  // --- Support & Chat ---
  Future<Map<String, dynamic>> createChatBridge({
    required String shipmentId,
    required String requesterId,
    required String requesterRole,
    required String message,
  }) async {
    final json = await _post('/v1/support/chat-bridge', {
      'shipment_id': shipmentId,
      'requester_id': requesterId,
      'requester_role': requesterRole,
      'message': message,
    });
    return json;
  }
}
