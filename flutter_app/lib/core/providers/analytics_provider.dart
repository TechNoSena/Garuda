import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/analytics_model.dart';
import '../models/routing_model.dart';
import '../models/shipment_model.dart';

final analyticsProvider = Provider((ref) => AnalyticsNotifier(ApiService()));

class AnalyticsNotifier {
  final ApiService _api;
  AnalyticsNotifier(this._api);

  Future<ShipmentAnalytics> getShipmentAnalytics(String id) async {
    return await _api.getShipmentAnalytics(id);
  }

  Future<PackageIntegrity> getPackageIntegrity(String id, String cargoType, double weightKg, String mode) async {
    return await _api.getPackageIntegrity(id, cargoType, weightKg, mode);
  }

  Future<BillingEstimate> getBillingEstimate({
    required LatLng origin,
    required LatLng destination,
    required String mode,
    required double weightKg,
    bool isExpress = false,
    bool isFragile = false,
  }) async {
    return await _api.getBillingEstimate(
      origin: origin,
      destination: destination,
      mode: mode,
      weightKg: weightKg,
      isExpress: isExpress,
      isFragile: isFragile,
    );
  }
}
