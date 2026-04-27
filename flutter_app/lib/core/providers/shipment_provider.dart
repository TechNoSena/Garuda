import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shipment_model.dart';
import '../services/api_service.dart';
import '../models/intelligence_model.dart';

class ShipmentState {
  final List<Shipment> shipments;
  final Shipment? selectedShipment;
  final ShipmentEta? currentEta;
  final bool isLoading;
  final String? error;

  const ShipmentState({
    this.shipments = const [],
    this.selectedShipment,
    this.currentEta,
    this.isLoading = false,
    this.error,
  });

  ShipmentState copyWith({
    List<Shipment>? shipments,
    Shipment? selectedShipment,
    ShipmentEta? currentEta,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearSelected = false,
    bool clearEta = false,
  }) {
    return ShipmentState(
      shipments: shipments ?? this.shipments,
      selectedShipment: clearSelected ? null : (selectedShipment ?? this.selectedShipment),
      currentEta: clearEta ? null : (currentEta ?? this.currentEta),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  int get pendingCount => shipments.where((s) => s.status == ShipmentStatus.pending).length;
  int get inTransitCount => shipments.where((s) => 
    s.status == ShipmentStatus.inTransit || 
    s.status == ShipmentStatus.dispatched ||
    s.status == ShipmentStatus.outForDelivery
  ).length;
  int get deliveredCount => shipments.where((s) => s.status == ShipmentStatus.delivered).length;
}

class ShipmentNotifier extends StateNotifier<ShipmentState> {
  final ApiService _api = ApiService();

  ShipmentNotifier() : super(const ShipmentState());

  Future<void> loadShipments(String uid, String role) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final shipments = await _api.listShipmentsByUser(uid, role);
      state = state.copyWith(shipments: shipments, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Consumer-specific: load all shipments by consumer email
  Future<void> loadConsumerShipments(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final shipments = await _api.listShipmentsByUser(email, 'CONSUMER');
      state = state.copyWith(shipments: shipments, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<Shipment?> createShipment({
    required String supplierId,
    required String logisticsId,
    required String consumerEmail,
    required LatLng origin,
    required LatLng destination,
    String routeMode = 'ROAD_CAR',
    String? packageDescription,
    double? weightKg,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final json = await _api.createShipment(
        supplierId: supplierId,
        logisticsId: logisticsId,
        consumerEmail: consumerEmail,
        origin: origin,
        destination: destination,
        routeMode: routeMode,
        packageDescription: packageDescription,
        weightKg: weightKg,
      );
      final shipment = Shipment.fromJson(json['shipment'] ?? json);
      state = state.copyWith(
        shipments: [shipment, ...state.shipments],
        isLoading: false,
      );
      return shipment;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return null;
    }
  }

  Future<void> selectShipment(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      final shipment = await _api.getShipment(id);
      state = state.copyWith(selectedShipment: shipment, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> loadEta(String id) async {
    try {
      final eta = await _api.getShipmentEta(id);
      state = state.copyWith(currentEta: eta);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateStatus(String id, String status) async {
    try {
      await _api.updateShipmentStatus(id, status);
      // Refresh the shipment
      await selectShipment(id);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> assignDriver(String shipmentId, String driverId) async {
    try {
      await _api.assignShipment(shipmentId, driverId);
      await selectShipment(shipmentId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateLocation(String shipmentId, LatLng location) async {
    try {
      await _api.updateShipmentLocation(shipmentId, location);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<List<TimelineEvent>> getTimeline(String id) async {
    try {
      return await _api.getShipmentTimeline(id);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  Future<void> logException(String id, String type, String description, double severity, String driverId) async {
    try {
      await _api.logException(id, type, description, severity, driverId);
      await selectShipment(id); // refresh
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> reportIncident(String id, String type, String description, LatLng location, double severity, String driverId) async {
    try {
      await _api.reportIncident(id, type, description, location, severity, driverId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<ExplainableRiskDetails?> getRiskDetails(String id) async {
    try {
      return await _api.getRiskDetails(id);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  void clearSelection() {
    state = state.copyWith(clearSelected: true, clearEta: true);
  }
}

final shipmentProvider = StateNotifierProvider<ShipmentNotifier, ShipmentState>((ref) {
  return ShipmentNotifier();
});
