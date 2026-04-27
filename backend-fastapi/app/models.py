from enum import Enum
from pydantic import BaseModel, Field, field_validator
from typing import List, Optional, Dict, Any
from datetime import datetime

# --- ENUMS ---
class UserRole(str, Enum):
    SUPPLIER = "SUPPLIER"
    LOGISTICS = "LOGISTICS"
    DELIVERY_MAN = "DELIVERY_MAN"
    CONSUMER = "CONSUMER"

class ShipmentStatus(str, Enum):
    PENDING = "PENDING"
    ASSIGNED = "ASSIGNED"
    DISPATCHED = "DISPATCHED"
    IN_TRANSIT = "IN_TRANSIT"
    OUT_FOR_DELIVERY = "OUT_FOR_DELIVERY"
    DELIVERED = "DELIVERED"
    CANCELLED = "CANCELLED"
    EXCEPTION = "EXCEPTION"

class TransportMode(str, Enum):
    ROAD_CAR = "ROAD_CAR"
    ROAD_BIKE = "ROAD_BIKE"
    RAIL = "RAIL"
    FLIGHT = "FLIGHT"
    SHIP = "SHIP"

class DeliveryType(str, Enum):
    RELAY = "RELAY"
    LAST_MILE = "LAST_MILE"

class ExceptionType(str, Enum):
    DAMAGED = "DAMAGED"
    DELAYED = "DELAYED"
    LOST = "LOST"
    ADDRESS_WRONG = "ADDRESS_WRONG"
    CUSTOMER_UNAVAILABLE = "CUSTOMER_UNAVAILABLE"
    CUSTOMS_HOLD = "CUSTOMS_HOLD"
    OTHER = "OTHER"

class IncidentType(str, Enum):
    ROAD_BLOCK = "ROAD_BLOCK"
    ACCIDENT = "ACCIDENT"
    VEHICLE_BREAKDOWN = "VEHICLE_BREAKDOWN"
    FLOODING = "FLOODING"
    PROTEST = "PROTEST"
    LANDSLIDE = "LANDSLIDE"
    CONSTRUCTION = "CONSTRUCTION"
    OTHER = "OTHER"

class NotificationType(str, Enum):
    REROUTE_ALERT = "REROUTE_ALERT"
    RISK_WARNING = "RISK_WARNING"
    DELIVERY_UPDATE = "DELIVERY_UPDATE"
    EXCEPTION_ALERT = "EXCEPTION_ALERT"
    SYSTEM_BROADCAST = "SYSTEM_BROADCAST"
    INCIDENT_REPORT = "INCIDENT_REPORT"
    ETA_UPDATE = "ETA_UPDATE"

class NotificationPriority(str, Enum):
    LOW = "LOW"
    MEDIUM = "MEDIUM"
    HIGH = "HIGH"
    CRITICAL = "CRITICAL"

# --- CORE MODELS ---
class LatLng(BaseModel):
    lat: float
    lng: float
    
    @field_validator('lat')
    @classmethod
    def validate_lat(cls, v):
        if not -90 <= v <= 90:
            raise ValueError('Latitude must be between -90 and 90')
        return v
    
    @field_validator('lng')
    @classmethod
    def validate_lng(cls, v):
        if not -180 <= v <= 180:
            raise ValueError('Longitude must be between -180 and 180')
        return v
    
    def to_string(self) -> str:
        return f"{self.lat},{self.lng}"
    
    def to_dict(self) -> dict:
        return {"lat": self.lat, "lng": self.lng}

# --- AUTH MODELS ---
class RegisterRequest(BaseModel):
    email: str
    password: str
    name: str
    role: UserRole
    company_name: Optional[str] = None
    phone: Optional[str] = None

class LoginRequest(BaseModel):
    email: str
    password: str

class ResetPasswordRequest(BaseModel):
    email: str

# --- SHIPMENT MODELS ---
class CreateShipmentRequest(BaseModel):
    supplier_id: str
    logistics_id: str
    consumer_email: str
    origin: LatLng
    destination: LatLng
    route_mode: TransportMode = TransportMode.ROAD_CAR
    package_description: Optional[str] = None
    weight_kg: Optional[float] = None
    delivery_type: DeliveryType = DeliveryType.LAST_MILE
    coupled_shipment_ids: List[str] = Field(default_factory=list, description="IDs of shipments coupled for relay batching")

class AssignShipmentRequest(BaseModel):
    delivery_man_id: str
    delivery_type: DeliveryType = DeliveryType.LAST_MILE

class UpdateLocationRequest(BaseModel):
    current_location: LatLng

# --- ROUTING MODELS ---
class FetchRoutesRequest(BaseModel):
    session_id: str
    origin: LatLng = Field(default_factory=lambda: LatLng(lat=22.543610, lng=85.796856))
    destination: LatLng = Field(default_factory=lambda: LatLng(lat=22.768116, lng=86.200684))
    mode: TransportMode = TransportMode.ROAD_CAR

class OptimizeMultiRequest(BaseModel):
    session_id: str
    points: List[LatLng] = Field(default_factory=lambda: [
        LatLng(lat=22.543610, lng=85.796856),
        LatLng(lat=22.650000, lng=85.900000),
        LatLng(lat=22.700000, lng=85.950000),
        LatLng(lat=22.768116, lng=86.200684)
    ])
    mode: TransportMode = TransportMode.ROAD_CAR

class AnalyzeRouteRequest(BaseModel):
    session_id: str
    origin: LatLng = Field(default_factory=lambda: LatLng(lat=22.543610, lng=85.796856))
    destination: LatLng = Field(default_factory=lambda: LatLng(lat=22.768116, lng=86.200684))
    mode: TransportMode = TransportMode.ROAD_CAR
    route_data: dict = Field(default_factory=lambda: {"duration": "1200s", "distanceMeters": 45000})

class MonitorRideRequest(BaseModel):
    session_id: str
    shipment_id: Optional[str] = None
    current_location: LatLng = Field(default_factory=lambda: LatLng(lat=22.543610, lng=85.796856))
    destination: LatLng = Field(default_factory=lambda: LatLng(lat=22.768116, lng=86.200684))
    mode: TransportMode = TransportMode.ROAD_CAR
    current_route_id: Optional[str] = None

class CompareModesRequest(BaseModel):
    session_id: str
    origin: LatLng = Field(default_factory=lambda: LatLng(lat=22.543610, lng=85.796856))
    destination: LatLng = Field(default_factory=lambda: LatLng(lat=22.768116, lng=86.200684))

class EtaRequest(BaseModel):
    shipment_id: str

# ═══════════════════════════════════════════════════════════════
# NEW MODELS — API Expansion
# ═══════════════════════════════════════════════════════════════

# --- REROUTE ---
class RerouteRequest(BaseModel):
    session_id: str
    shipment_id: Optional[str] = None
    origin: LatLng = Field(default_factory=lambda: LatLng(lat=22.543610, lng=85.796856))
    destination: LatLng = Field(default_factory=lambda: LatLng(lat=22.768116, lng=86.200684))
    mode: TransportMode = TransportMode.ROAD_CAR
    avoid_zones: List[LatLng] = Field(default_factory=list, description="Coordinates to avoid during rerouting")
    reason: str = Field(default="traffic_congestion", description="Reason for reroute: accident, weather, traffic_congestion, road_closure")

# --- RISK EVALUATION ---
class RiskEvaluateRequest(BaseModel):
    origin: LatLng = Field(default_factory=lambda: LatLng(lat=22.543610, lng=85.796856))
    destination: LatLng = Field(default_factory=lambda: LatLng(lat=22.768116, lng=86.200684))
    mode: TransportMode = TransportMode.ROAD_CAR
    cargo_type: str = Field(default="general", description="Type: general, fragile, perishable, hazardous, high_value")
    weight_kg: Optional[float] = None

# --- DISRUPTION DETECTION ---
class DisruptionDetectRequest(BaseModel):
    center: LatLng = Field(default_factory=lambda: LatLng(lat=22.650000, lng=85.900000))
    radius_km: float = Field(default=50.0, ge=1.0, le=500.0, description="Scan radius in km")
    modes_to_check: List[TransportMode] = Field(default_factory=lambda: [TransportMode.ROAD_CAR])

# --- NOTIFICATIONS ---
class PushNotificationRequest(BaseModel):
    user_id: str = Field(default="mock-uid", description="Target user UID or 'broadcast' for all")
    title: str = Field(default="Garuda Alert", description="Notification title")
    body: str = Field(default="Your shipment status has been updated.", description="Notification body text")
    notification_type: NotificationType = NotificationType.DELIVERY_UPDATE
    priority: NotificationPriority = NotificationPriority.MEDIUM
    shipment_id: Optional[str] = None
    data: Optional[Dict[str, Any]] = None

# --- PRE-CHECK (Predictive Alert) ---
class PrecheckRequest(BaseModel):
    session_id: str
    origin: LatLng = Field(default_factory=lambda: LatLng(lat=22.543610, lng=85.796856))
    destination: LatLng = Field(default_factory=lambda: LatLng(lat=22.768116, lng=86.200684))
    mode: TransportMode = TransportMode.ROAD_CAR
    dispatch_time: Optional[str] = Field(default=None, description="ISO format dispatch time, e.g., '2026-04-27T06:00:00+05:30'")
    cargo_type: str = Field(default="general", description="Cargo type for risk weighting")

# --- MODE SWITCHING ---
class SwitchModeRequest(BaseModel):
    session_id: str
    shipment_id: Optional[str] = None
    origin: LatLng = Field(default_factory=lambda: LatLng(lat=22.543610, lng=85.796856))
    destination: LatLng = Field(default_factory=lambda: LatLng(lat=22.768116, lng=86.200684))
    current_mode: TransportMode = TransportMode.ROAD_CAR
    new_mode: TransportMode = TransportMode.RAIL
    reason: str = Field(default="vehicle_breakdown", description="Why switching: vehicle_breakdown, cost_optimization, weather, time_critical")

# --- EXCEPTION HANDLING ---
class ExceptionRequest(BaseModel):
    exception_type: ExceptionType = ExceptionType.DELAYED
    description: str = Field(default="Package delayed due to weather conditions", description="Detailed exception description")
    severity: float = Field(default=0.5, ge=0.0, le=1.0, description="Severity 0.0-1.0")
    reported_by: str = Field(default="driver-uid", description="UID of the person reporting")

# --- INCIDENT REPORTING (Driver) ---
class ReportIncidentRequest(BaseModel):
    incident_type: IncidentType = IncidentType.ROAD_BLOCK
    description: str = Field(default="Major roadblock near NH-33 junction due to fallen tree", description="Incident details")
    location: LatLng = Field(default_factory=lambda: LatLng(lat=22.650000, lng=85.900000))
    severity: float = Field(default=0.7, ge=0.0, le=1.0, description="Severity 0.0-1.0")
    driver_id: str = Field(default="driver-uid", description="Reporting driver UID")

# --- CHAT BRIDGE ---
class ChatBridgeRequest(BaseModel):
    shipment_id: str = Field(default="mock-shipment-id", description="Shipment being discussed")
    requester_id: str = Field(default="consumer-uid", description="Who initiated the chat")
    requester_role: UserRole = UserRole.CONSUMER
    message: Optional[str] = Field(default="Where is my package?", description="Initial message")

# --- GEOFENCE ---
class GeofenceCheckRequest(BaseModel):
    shipment_id: str = Field(default="mock-shipment-id")
    current_location: LatLng = Field(default_factory=lambda: LatLng(lat=22.650000, lng=85.900000))
    zone_center: LatLng = Field(default_factory=lambda: LatLng(lat=22.768116, lng=86.200684))
    zone_radius_km: float = Field(default=5.0, ge=0.1, le=100.0, description="Geofence radius in km")
    zone_name: str = Field(default="Destination Warehouse", description="Name of the geofence zone")

# --- DRIVER FATIGUE ---
class FatigueCheckRequest(BaseModel):
    driver_id: str = Field(default="driver-uid")
    drive_start_time: str = Field(default="2026-04-26T06:00:00+05:30", description="ISO format drive start")
    current_location: LatLng = Field(default_factory=lambda: LatLng(lat=22.650000, lng=85.900000))
    total_km_driven: float = Field(default=180.0, ge=0.0, description="Total km driven in this shift")
    breaks_taken: int = Field(default=1, ge=0, description="Number of rest breaks taken")

# --- DEMAND SURGE ---
class DemandSurgeRequest(BaseModel):
    region_center: LatLng = Field(default_factory=lambda: LatLng(lat=22.650000, lng=85.900000))
    radius_km: float = Field(default=100.0, ge=1.0, le=1000.0)
    prediction_window_days: int = Field(default=7, ge=1, le=30, description="Days ahead to predict")
    category: str = Field(default="all", description="Category: all, electronics, perishable, industrial, ecommerce")

# --- BILLING ESTIMATE ---
class BillingEstimateParams(BaseModel):
    origin: LatLng = Field(default_factory=lambda: LatLng(lat=22.543610, lng=85.796856))
    destination: LatLng = Field(default_factory=lambda: LatLng(lat=22.768116, lng=86.200684))
    mode: TransportMode = TransportMode.ROAD_CAR
    weight_kg: float = Field(default=10.0, ge=0.1, description="Package weight in kg")
    is_express: bool = Field(default=False, description="Express delivery surcharge")
    is_fragile: bool = Field(default=False, description="Fragile handling surcharge")

# --- ADMIN: BROADCAST ---
class AdminBroadcastRequest(BaseModel):
    title: str = Field(default="System Alert", description="Broadcast title")
    body: str = Field(default="Scheduled maintenance at 2AM IST tonight.", description="Broadcast message")
    target_role: Optional[UserRole] = Field(default=None, description="Target role or None for all")
    region_center: Optional[LatLng] = Field(default=None, description="Optional region filter")
    region_radius_km: Optional[float] = Field(default=None, description="Radius if region filter active")
    priority: NotificationPriority = NotificationPriority.HIGH
