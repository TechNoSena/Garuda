import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shipment_model.dart';
import '../models/routing_model.dart';
import '../models/risk_model.dart';
import '../models/compare_model.dart';
import '../services/api_service.dart';

class RoutingState {
  final String? sessionId;
  final List<RouteData> routes;
  final RiskAnalysis? riskAnalysis;
  final CompareModesResponse? comparison;
  final Map<String, dynamic>? optimizationResult;
  final bool isLoading;
  final String? error;

  const RoutingState({
    this.sessionId,
    this.routes = const [],
    this.riskAnalysis,
    this.comparison,
    this.optimizationResult,
    this.isLoading = false,
    this.error,
  });

  RoutingState copyWith({
    String? sessionId,
    List<RouteData>? routes,
    RiskAnalysis? riskAnalysis,
    CompareModesResponse? comparison,
    Map<String, dynamic>? optimizationResult,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearRisk = false,
    bool clearComparison = false,
  }) {
    return RoutingState(
      sessionId: sessionId ?? this.sessionId,
      routes: routes ?? this.routes,
      riskAnalysis: clearRisk ? null : (riskAnalysis ?? this.riskAnalysis),
      comparison: clearComparison ? null : (comparison ?? this.comparison),
      optimizationResult: optimizationResult ?? this.optimizationResult,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class RoutingNotifier extends StateNotifier<RoutingState> {
  final ApiService _api = ApiService();

  RoutingNotifier() : super(const RoutingState());

  Future<String> ensureSession() async {
    if (state.sessionId != null) return state.sessionId!;
    final sid = await _api.startSession();
    state = state.copyWith(sessionId: sid);
    return sid;
  }

  Future<void> fetchRoutes({
    required LatLng origin,
    required LatLng destination,
    String mode = 'ROAD_CAR',
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final sid = await ensureSession();
      final routes = await _api.fetchRoutes(
        sessionId: sid,
        origin: origin,
        destination: destination,
        mode: mode,
      );
      state = state.copyWith(routes: routes, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> analyzeRisk({
    required LatLng origin,
    required LatLng destination,
    String mode = 'ROAD_CAR',
    Map<String, dynamic>? routeData,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearRisk: true);
    try {
      final sid = await ensureSession();
      final risk = await _api.analyzeRoute(
        sessionId: sid,
        origin: origin,
        destination: destination,
        mode: mode,
        routeData: routeData,
      );
      state = state.copyWith(riskAnalysis: risk, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> compareModes({
    required LatLng origin,
    required LatLng destination,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearComparison: true);
    try {
      final sid = await ensureSession();
      final comparison = await _api.compareModes(
        sessionId: sid,
        origin: origin,
        destination: destination,
      );
      state = state.copyWith(comparison: comparison, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> optimizeMulti({
    required List<LatLng> points,
    String mode = 'ROAD_CAR',
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final sid = await ensureSession();
      final result = await _api.optimizeMulti(
        sessionId: sid,
        points: points,
        mode: mode,
      );
      state = state.copyWith(optimizationResult: result, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void clearRisk() {
    state = state.copyWith(clearRisk: true);
  }
}

final routingProvider = StateNotifierProvider<RoutingNotifier, RoutingState>((ref) {
  return RoutingNotifier();
});
