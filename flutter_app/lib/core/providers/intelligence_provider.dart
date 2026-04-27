import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/intelligence_model.dart';
import '../models/shipment_model.dart';

final intelligenceProvider = Provider((ref) => IntelligenceNotifier(ApiService()));

class IntelligenceNotifier {
  final ApiService _api;
  IntelligenceNotifier(this._api);

  Future<FatigueAssessment> checkDriverFatigue({
    required String driverId,
    required String driveStartTime,
    required LatLng currentLocation,
    required double totalKmDriven,
    required int breaksTaken,
  }) async {
    return await _api.checkDriverFatigue(
      driverId: driverId,
      driveStartTime: driveStartTime,
      currentLocation: currentLocation,
      totalKmDriven: totalKmDriven,
      breaksTaken: breaksTaken,
    );
  }

  Future<DemandSurgePrediction> predictDemandSurge({
    required LatLng regionCenter,
    required double radiusKm,
    required int predictionWindowDays,
    required String category,
  }) async {
    return await _api.predictDemandSurge(
      regionCenter: regionCenter,
      radiusKm: radiusKm,
      predictionWindowDays: predictionWindowDays,
      category: category,
    );
  }
}
