from enum import Enum
from pydantic import BaseModel, Field
from typing import List, Optional

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
    DELIVERED = "DELIVERED"
    EXCEPTION = "EXCEPTION"

# --- CORE MODELS ---
class LatLng(BaseModel):
    lat: float
    lng: float
    
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

class LoginRequest(BaseModel):
    email: str
    password: str

# --- SHIPMENT MODELS ---
class CreateShipmentRequest(BaseModel):
    supplier_id: str
    logistics_id: str
    consumer_email: str
    origin: LatLng
    destination: LatLng
    route_mode: str = "ROAD_CAR"

class AssignShipmentRequest(BaseModel):
    delivery_man_id: str

class UpdateLocationRequest(BaseModel):
    current_location: LatLng

# --- ROUTING MODELS (Existing) ---
class FetchRoutesRequest(BaseModel):
    session_id: str
    origin: LatLng = Field(default_factory=lambda: LatLng(lat=22.543610, lng=85.796856))
    destination: LatLng = Field(default_factory=lambda: LatLng(lat=22.768116, lng=86.200684))
    mode: str = "ROAD_CAR"

class OptimizeMultiRequest(BaseModel):
    session_id: str
    points: List[LatLng] = Field(default_factory=lambda: [
        LatLng(lat=22.543610, lng=85.796856),
        LatLng(lat=22.650000, lng=85.900000),
        LatLng(lat=22.700000, lng=85.950000),
        LatLng(lat=22.768116, lng=86.200684)
    ])
    mode: str = "ROAD_CAR"

class AnalyzeRouteRequest(BaseModel):
    session_id: str
    origin: LatLng = Field(default_factory=lambda: LatLng(lat=22.543610, lng=85.796856))
    destination: LatLng = Field(default_factory=lambda: LatLng(lat=22.768116, lng=86.200684))
    mode: str = "ROAD_CAR"
    route_data: dict = Field(default_factory=lambda: {"duration": "1200s", "distanceMeters": 45000})

class MonitorRideRequest(BaseModel):
    session_id: str
    shipment_id: Optional[str] = None
    current_location: LatLng = Field(default_factory=lambda: LatLng(lat=22.543610, lng=85.796856))
    destination: LatLng = Field(default_factory=lambda: LatLng(lat=22.768116, lng=86.200684))
    mode: str = "ROAD_CAR"
    current_route_id: Optional[str] = None
