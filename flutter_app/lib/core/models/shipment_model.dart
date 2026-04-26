enum ShipmentStatus {
  pending('PENDING', 'Pending', '⏳'),
  assigned('ASSIGNED', 'Assigned', '👤'),
  dispatched('DISPATCHED', 'Dispatched', '📦'),
  inTransit('IN_TRANSIT', 'In Transit', '🚚'),
  outForDelivery('OUT_FOR_DELIVERY', 'Out for Delivery', '🏃'),
  delivered('DELIVERED', 'Delivered', '✅'),
  cancelled('CANCELLED', 'Cancelled', '❌'),
  exception('EXCEPTION', 'Exception', '⚠️');

  final String value;
  final String label;
  final String emoji;
  const ShipmentStatus(this.value, this.label, this.emoji);

  static ShipmentStatus fromString(String val) {
    return ShipmentStatus.values.firstWhere(
      (e) => e.value == val,
      orElse: () => ShipmentStatus.pending,
    );
  }

  /// Returns ordered list for timeline display
  static List<ShipmentStatus> get lifecycle => [
    pending, assigned, dispatched, inTransit, outForDelivery, delivered,
  ];

  int get lifecycleIndex => lifecycle.indexOf(this);
  bool get isActive => lifecycle.contains(this);
}

class LatLng {
  final double lat;
  final double lng;

  const LatLng({required this.lat, required this.lng});

  factory LatLng.fromJson(Map<String, dynamic> json) {
    return LatLng(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};

  String toDisplayString() => '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';

  @override
  String toString() => '$lat,$lng';
}

class Shipment {
  final String shipmentId;
  final String supplierId;
  final String? logisticsId;
  final String? deliveryManId;
  final String? consumerEmail;
  final LatLng origin;
  final LatLng destination;
  final LatLng? currentLocation;
  final ShipmentStatus status;
  final String routeMode;
  final String? packageDescription;
  final double? weightKg;
  final Map<String, dynamic>? timestamps;
  final bool isMock;

  Shipment({
    required this.shipmentId,
    required this.supplierId,
    this.logisticsId,
    this.deliveryManId,
    this.consumerEmail,
    required this.origin,
    required this.destination,
    this.currentLocation,
    required this.status,
    required this.routeMode,
    this.packageDescription,
    this.weightKg,
    this.timestamps,
    this.isMock = false,
  });

  factory Shipment.fromJson(Map<String, dynamic> json) {
    return Shipment(
      shipmentId: json['shipment_id'] ?? '',
      supplierId: json['supplier_id'] ?? '',
      logisticsId: json['logistics_id'],
      deliveryManId: json['delivery_man_id'],
      consumerEmail: json['consumer_email'],
      origin: LatLng.fromJson(json['origin'] ?? {'lat': 0, 'lng': 0}),
      destination: LatLng.fromJson(json['destination'] ?? {'lat': 0, 'lng': 0}),
      currentLocation: json['current_location'] != null
          ? LatLng.fromJson(json['current_location'])
          : null,
      status: ShipmentStatus.fromString(json['status'] ?? 'PENDING'),
      routeMode: json['route_mode'] ?? 'ROAD_CAR',
      packageDescription: json['package_description'],
      weightKg: json['weight_kg']?.toDouble(),
      timestamps: json['timestamps'],
      isMock: json['mock'] == true,
    );
  }
}

class ShipmentEta {
  final String shipmentId;
  final String status;
  final double remainingKm;
  final int etaMinutes;
  final String? routeMode;

  ShipmentEta({
    required this.shipmentId,
    required this.status,
    required this.remainingKm,
    required this.etaMinutes,
    this.routeMode,
  });

  factory ShipmentEta.fromJson(Map<String, dynamic> json) {
    return ShipmentEta(
      shipmentId: json['shipment_id'] ?? '',
      status: json['status'] ?? 'PENDING',
      remainingKm: (json['remaining_km'] ?? 0).toDouble(),
      etaMinutes: json['eta_minutes'] ?? 0,
      routeMode: json['route_mode'],
    );
  }
}
