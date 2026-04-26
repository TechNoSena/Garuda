import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shipment_model.dart';
import '../models/monitor_model.dart';
import '../services/api_service.dart';

class MonitorState {
  final RideMonitorResponse? lastResponse;
  final bool isMonitoring;
  final String? error;

  const MonitorState({this.lastResponse, this.isMonitoring = false, this.error});

  MonitorState copyWith({
    RideMonitorResponse? lastResponse,
    bool? isMonitoring,
    String? error,
    bool clearError = false,
  }) {
    return MonitorState(
      lastResponse: lastResponse ?? this.lastResponse,
      isMonitoring: isMonitoring ?? this.isMonitoring,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class MonitorNotifier extends StateNotifier<MonitorState> {
  final ApiService _api = ApiService();
  Timer? _timer;
  String? _sessionId;

  MonitorNotifier() : super(const MonitorState());

  Future<void> startMonitoring({
    required String sessionId,
    required LatLng currentLocation,
    required LatLng destination,
    String mode = 'ROAD_CAR',
    String? shipmentId,
    Duration interval = const Duration(seconds: 30),
  }) async {
    _sessionId = sessionId;
    state = state.copyWith(isMonitoring: true);

    // Initial check
    await _poll(currentLocation, destination, mode, shipmentId);

    // Periodic polling
    _timer = Timer.periodic(interval, (_) {
      _poll(currentLocation, destination, mode, shipmentId);
    });
  }

  Future<void> _poll(
    LatLng currentLocation,
    LatLng destination,
    String mode,
    String? shipmentId,
  ) async {
    if (_sessionId == null) return;
    try {
      final response = await _api.monitorRide(
        sessionId: _sessionId!,
        currentLocation: currentLocation,
        destination: destination,
        mode: mode,
        shipmentId: shipmentId,
      );
      if (mounted) {
        state = state.copyWith(lastResponse: response);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(error: e.toString());
      }
    }
  }

  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(isMonitoring: false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final monitorProvider = StateNotifierProvider<MonitorNotifier, MonitorState>((ref) {
  return MonitorNotifier();
});
