import os
import requests
from datetime import datetime, timezone
from typing import Dict, Any, Optional, List
from firebase_admin import auth
from app.config import db
from app.models import (
    RegisterRequest, LoginRequest, UserRole, 
    CreateShipmentRequest, ShipmentStatus, LatLng
)

# Web API Key for REST-based sign-in
FIREBASE_API_KEY = os.getenv("FIREBASE_WEB_API_KEY", "")

# ──────────────────────────── AUTH ────────────────────────────

def create_user(req: RegisterRequest) -> dict:
    if not db:
        return {"uid": "mock-uid", "email": req.email, "role": req.role.value}
        
    try:
        user = auth.create_user(
            email=req.email,
            password=req.password,
            display_name=req.name
        )
        user_data = {
            "uid": user.uid,
            "email": req.email,
            "role": req.role.value,
            "name": req.name,
            "company_name": req.company_name,
            "phone": req.phone,
            "created_at": datetime.now(timezone.utc).isoformat()
        }
        db.collection("users").document(user.uid).set(user_data)
        return user_data
    except auth.EmailAlreadyExistsError:
        raise Exception("Email already registered")
    except Exception as e:
        raise Exception(f"Registration failed: {str(e)}")

def login_user(req: LoginRequest) -> dict:
    if not db or not FIREBASE_API_KEY:
        return {"idToken": "mock-token", "email": req.email, "localId": "mock-uid"}
        
    url = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={FIREBASE_API_KEY}"
    payload = {"email": req.email, "password": req.password, "returnSecureToken": True}
    resp = requests.post(url, json=payload, timeout=10)
    if resp.status_code == 200:
        data = resp.json()
        # Fetch user profile from Firestore to include the role
        user_doc = db.collection("users").document(data["localId"]).get()
        if user_doc.exists:
            data["profile"] = user_doc.to_dict()
        return data
    else:
        error_msg = resp.json().get("error", {}).get("message", "Invalid credentials")
        raise Exception(error_msg)

def reset_password(email: str) -> dict:
    if not FIREBASE_API_KEY:
        return {"status": "mock", "message": "Password reset email sent (mock)"}
    url = f"https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key={FIREBASE_API_KEY}"
    payload = {"requestType": "PASSWORD_RESET", "email": email}
    resp = requests.post(url, json=payload, timeout=10)
    if resp.status_code == 200:
        return {"status": "success", "message": "Password reset email sent"}
    raise Exception("Failed to send reset email")

def get_user_profile(uid: str) -> dict:
    if not db:
        return {"uid": uid, "mock": True}
    doc = db.collection("users").document(uid).get()
    if doc.exists:
        return doc.to_dict()
    raise Exception("User not found")

# ──────────────────────────── SHIPMENTS ────────────────────────────

def create_shipment(req: CreateShipmentRequest) -> dict:
    if not db:
        return {"shipment_id": "mock-shipment-id", "status": ShipmentStatus.PENDING.value}
        
    try:
        doc_ref = db.collection("shipments").document()
        shipment_data = {
            "shipment_id": doc_ref.id,
            "supplier_id": req.supplier_id,
            "logistics_id": req.logistics_id,
            "delivery_man_id": None,
            "consumer_email": req.consumer_email,
            "origin": req.origin.to_dict(),
            "destination": req.destination.to_dict(),
            "current_location": req.origin.to_dict(),
            "status": ShipmentStatus.PENDING.value,
            "route_mode": req.route_mode.value,
            "package_description": req.package_description,
            "weight_kg": req.weight_kg,
            "timestamps": {
                "created_at": datetime.now(timezone.utc).isoformat()
            },
            "location_history": []
        }
        doc_ref.set(shipment_data)
        return shipment_data
    except Exception as e:
        raise Exception(f"Failed to create shipment: {str(e)}")

def update_shipment_status(shipment_id: str, status: ShipmentStatus, delivery_man_id: Optional[str] = None) -> dict:
    if not db:
        return {"shipment_id": shipment_id, "status": status.value, "mock": True}
        
    doc_ref = db.collection("shipments").document(shipment_id)
    doc = doc_ref.get()
    if not doc.exists:
        raise Exception("Shipment not found")
        
    updates: Dict[str, Any] = {"status": status.value}
    now = datetime.now(timezone.utc).isoformat()
    
    if delivery_man_id:
        updates["delivery_man_id"] = delivery_man_id
    
    # Automatic timestamp tracking
    ts_key = f"timestamps.{status.value.lower()}_at"
    updates[ts_key] = now
        
    doc_ref.update(updates)
    return {"shipment_id": shipment_id, "updated_fields": updates}

def update_shipment_location(shipment_id: str, location: LatLng) -> dict:
    if not db:
        return {"shipment_id": shipment_id, "current_location": location.to_dict(), "mock": True}
        
    from google.cloud.firestore_v1 import ArrayUnion
    doc_ref = db.collection("shipments").document(shipment_id)
    now = datetime.now(timezone.utc).isoformat()
    
    doc_ref.update({
        "current_location": location.to_dict(),
        "timestamps.last_location_update": now,
        "location_history": ArrayUnion([{
            "location": location.to_dict(),
            "timestamp": now
        }])
    })
    return {"shipment_id": shipment_id, "current_location": location.to_dict()}

def get_shipment(shipment_id: str) -> dict:
    if not db:
        return {"shipment_id": shipment_id, "status": ShipmentStatus.IN_TRANSIT.value, "mock": True}
        
    doc = db.collection("shipments").document(shipment_id).get()
    if doc.exists:
        return doc.to_dict()
    raise Exception("Shipment not found")

def list_shipments_by_user(user_id: str, role: str) -> List[dict]:
    if not db:
        return [{"shipment_id": "mock-1", "status": "PENDING", "mock": True}]
    
    field_map = {
        "SUPPLIER": "supplier_id",
        "LOGISTICS": "logistics_id",
        "DELIVERY_MAN": "delivery_man_id",
    }
    field = field_map.get(role.upper())
    if not field:
        raise Exception(f"Invalid role for listing: {role}")
    
    from google.cloud.firestore_v1.base_query import FieldFilter
    docs = db.collection("shipments").where(filter=FieldFilter(field, "==", user_id)).stream()
    return [doc.to_dict() for doc in docs]

def get_shipment_eta(shipment_id: str) -> dict:
    """Calculate ETA based on current location, destination, and route mode."""
    if not db:
        return {"shipment_id": shipment_id, "eta_minutes": 45, "mock": True}
    
    doc = db.collection("shipments").document(shipment_id).get()
    if not doc.exists:
        raise Exception("Shipment not found")
    
    data = doc.to_dict()
    current = LatLng(**data["current_location"])
    dest = LatLng(**data["destination"])
    
    from app.services.routing_strategy import calculate_haversine
    dist_km = calculate_haversine(current, dest)
    
    # Estimate speed by mode (km/h)
    speed_map = {"ROAD_CAR": 50, "ROAD_BIKE": 35, "RAIL": 80, "FLIGHT": 800, "SHIP": 40}
    speed = speed_map.get(data.get("route_mode", "ROAD_CAR"), 50)
    eta_minutes = round((dist_km / speed) * 60)
    
    return {
        "shipment_id": shipment_id,
        "status": data["status"],
        "remaining_km": round(dist_km, 2),
        "eta_minutes": eta_minutes,
        "route_mode": data.get("route_mode")
    }
