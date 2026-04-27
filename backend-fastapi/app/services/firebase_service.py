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
        from google.cloud.firestore_v1.base_query import FieldFilter
        
        # Resolve logistics email to UID if possible
        logistics_id = req.logistics_id
        if "@" in logistics_id:
            users_ref = db.collection("users").where(filter=FieldFilter("email", "==", logistics_id)).stream()
            for u in users_ref:
                logistics_id = u.id
                break
                
        doc_ref = db.collection("shipments").document()
        shipment_data = {
            "shipment_id": doc_ref.id,
            "supplier_id": req.supplier_id,
            "logistics_id": logistics_id,
            "delivery_man_id": None,
            "consumer_email": req.consumer_email,
            "origin": req.origin.to_dict(),
            "destination": req.destination.to_dict(),
            "current_location": req.origin.to_dict(),
            "status": ShipmentStatus.PENDING.value,
            "route_mode": req.route_mode.value,
            "package_description": req.package_description,
            "weight_kg": req.weight_kg,
            "delivery_type": req.delivery_type.value if hasattr(req, 'delivery_type') else "LAST_MILE",
            "coupled_shipment_ids": req.coupled_shipment_ids if hasattr(req, 'coupled_shipment_ids') else [],
            "timestamps": {
                "created_at": datetime.now(timezone.utc).isoformat()
            },
            "location_history": []
        }
        doc_ref.set(shipment_data)
        
        # Auto-link shipment to consumer user doc (so consumer sees it on login)
        try:
            consumer_ref = db.collection("users").where(
                filter=FieldFilter("email", "==", req.consumer_email)
            ).stream()
            for consumer_doc in consumer_ref:
                from google.cloud.firestore_v1 import ArrayUnion
                db.collection("users").document(consumer_doc.id).update({
                    "linked_shipments": ArrayUnion([doc_ref.id])
                })
                break
        except Exception:
            pass  # Consumer may not be registered yet — shipment still queryable by email
        
        return shipment_data
    except Exception as e:
        raise Exception(f"Failed to create shipment: {str(e)}")

def update_shipment_status(shipment_id: str, status: ShipmentStatus, delivery_man_id: Optional[str] = None, delivery_type: Optional[str] = None) -> dict:
    if not db:
        return {"shipment_id": shipment_id, "status": status.value, "mock": True}
        
    doc_ref = db.collection("shipments").document(shipment_id)
    doc = doc_ref.get()
    if not doc.exists:
        raise Exception("Shipment not found")
        
    updates: Dict[str, Any] = {"status": status.value}
    now = datetime.now(timezone.utc).isoformat()
    
    if delivery_man_id:
        if "@" in delivery_man_id:
            from google.cloud.firestore_v1.base_query import FieldFilter
            users_ref = db.collection("users").where(filter=FieldFilter("email", "==", delivery_man_id)).stream()
            for u in users_ref:
                delivery_man_id = u.id
                break
        updates["delivery_man_id"] = delivery_man_id
    
    if delivery_type:
        updates["delivery_type"] = delivery_type
    
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
    
    from google.cloud.firestore_v1.base_query import FieldFilter
    
    # Consumer queries by email, others by UID
    if role.upper() == "CONSUMER":
        docs = db.collection("shipments").where(
            filter=FieldFilter("consumer_email", "==", user_id)
        ).stream()
        return [doc.to_dict() for doc in docs]
    
    field_map = {
        "SUPPLIER": "supplier_id",
        "LOGISTICS": "logistics_id",
        "DELIVERY_MAN": "delivery_man_id",
    }
    field = field_map.get(role.upper())
    if not field:
        raise Exception(f"Invalid role for listing: {role}")
    
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


# ──────────────────────────── NEW: TIMELINE ────────────────────────────

def get_shipment_timeline(shipment_id: str) -> dict:
    """Return full timeline of status transitions with timestamps."""
    if not db:
        return {
            "shipment_id": shipment_id,
            "timeline": [
                {"event": "CREATED", "timestamp": "2026-04-26T06:00:00Z", "detail": "Shipment created by supplier"},
                {"event": "ASSIGNED", "timestamp": "2026-04-26T06:15:00Z", "detail": "Delivery man assigned"},
                {"event": "DISPATCHED", "timestamp": "2026-04-26T06:30:00Z", "detail": "Package dispatched from origin"},
                {"event": "IN_TRANSIT", "timestamp": "2026-04-26T07:00:00Z", "detail": "Package in transit"},
                {"event": "LOCATION_UPDATE", "timestamp": "2026-04-26T08:00:00Z", "detail": "Location ping received"},
            ],
            "mock": True
        }
    
    doc = db.collection("shipments").document(shipment_id).get()
    if not doc.exists:
        raise Exception("Shipment not found")
    
    data = doc.to_dict()
    timestamps = data.get("timestamps", {})
    timeline = []
    
    for key, value in sorted(timestamps.items(), key=lambda x: x[1] if x[1] else ""):
        event_name = key.replace("_at", "").upper()
        timeline.append({"event": event_name, "timestamp": value, "detail": f"Status changed to {event_name}"})
    
    # Add location history events
    for loc_entry in data.get("location_history", []):
        timeline.append({
            "event": "LOCATION_UPDATE",
            "timestamp": loc_entry.get("timestamp"),
            "detail": f"Location: ({loc_entry['location']['lat']}, {loc_entry['location']['lng']})"
        })
    
    timeline.sort(key=lambda x: x["timestamp"] if x["timestamp"] else "")
    return {"shipment_id": shipment_id, "total_events": len(timeline), "timeline": timeline}


# ──────────────────────────── NEW: EXCEPTIONS ────────────────────────────

def log_exception(shipment_id: str, exception_type: str, description: str, severity: float, reported_by: str) -> dict:
    """Log an exception event on a shipment."""
    import uuid
    exception_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc).isoformat()
    
    exception_data = {
        "exception_id": exception_id,
        "shipment_id": shipment_id,
        "exception_type": exception_type,
        "description": description,
        "severity": severity,
        "reported_by": reported_by,
        "status": "OPEN",
        "created_at": now
    }
    
    if not db:
        return {"status": "logged", "exception": exception_data, "mock": True}
    
    try:
        doc = db.collection("shipments").document(shipment_id).get()
        if not doc.exists:
            raise Exception("Shipment not found")
        
        db.collection("exceptions").document(exception_id).set(exception_data)
        db.collection("shipments").document(shipment_id).update({
            "status": "EXCEPTION",
            f"timestamps.exception_at": now
        })
        return {"status": "logged", "exception": exception_data}
    except Exception as e:
        raise Exception(f"Failed to log exception: {str(e)}")


# ──────────────────────────── NEW: INCIDENTS ────────────────────────────

def log_incident(shipment_id: str, incident_type: str, description: str, location: dict, severity: float, driver_id: str) -> dict:
    """Store a driver-reported incident."""
    import uuid
    incident_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc).isoformat()
    
    incident_data = {
        "incident_id": incident_id,
        "shipment_id": shipment_id,
        "incident_type": incident_type,
        "description": description,
        "location": location,
        "severity": severity,
        "driver_id": driver_id,
        "verified": False,
        "created_at": now
    }
    
    if not db:
        return {"status": "reported", "incident": incident_data, "mock": True}
    
    try:
        db.collection("incidents").document(incident_id).set(incident_data)
        return {"status": "reported", "incident": incident_data}
    except Exception as e:
        raise Exception(f"Failed to log incident: {str(e)}")


# ──────────────────────────── NEW: FLEET STATUS ────────────────────────────

def get_fleet_status(region: str = "all") -> dict:
    """Aggregate shipment statuses for admin dashboard."""
    if not db:
        return {
            "region": region,
            "total_vehicles": 48,
            "status_breakdown": {
                "IN_TRANSIT": 18,
                "IDLE": 12,
                "OUT_FOR_DELIVERY": 8,
                "RETURNING": 4,
                "MAINTENANCE": 3,
                "BREAKDOWN": 2,
                "OFFLINE": 1
            },
            "utilization_rate": 62.5,
            "active_shipments": 26,
            "alerts": [
                {"vehicle_id": "TRK-042", "alert": "Maintenance overdue by 3 days"},
                {"vehicle_id": "BK-017", "alert": "Low fuel warning"}
            ],
            "mock": True
        }
    
    try:
        status_counts = {}
        docs = db.collection("shipments").stream()
        total = 0
        for doc in docs:
            data = doc.to_dict()
            status = data.get("status", "UNKNOWN")
            status_counts[status] = status_counts.get(status, 0) + 1
            total += 1
        
        active = sum(v for k, v in status_counts.items() if k in ["IN_TRANSIT", "OUT_FOR_DELIVERY", "DISPATCHED"])
        utilization = round((active / max(total, 1)) * 100, 1)
        
        return {
            "region": region,
            "total_vehicles": total,
            "status_breakdown": status_counts,
            "utilization_rate": utilization,
            "active_shipments": active,
            "alerts": []
        }
    except Exception as e:
        return {"error": str(e)}


# ──────────────────────────── NEW: ANALYTICS ────────────────────────────

def get_shipment_analytics(shipment_id: str) -> dict:
    """Carbon footprint, fuel cost, toll estimate, efficiency score."""
    from app.services.routing_strategy import calculate_haversine, get_strategy
    
    if not db:
        dist_km = 42.5
        mode = "ROAD_CAR"
    else:
        doc = db.collection("shipments").document(shipment_id).get()
        if not doc.exists:
            raise Exception("Shipment not found")
        data = doc.to_dict()
        origin = LatLng(**data["origin"])
        dest = LatLng(**data["destination"])
        dist_km = calculate_haversine(origin, dest)
        mode = data.get("route_mode", "ROAD_CAR")
    
    strategy = get_strategy(mode)
    cost_data = strategy.estimate_cost(dist_km)
    
    # Toll estimation (simulated — ₹1.5/km for highways)
    toll_estimate = round(dist_km * 1.5, 2) if mode in ["ROAD_CAR", "ROAD_BIKE"] else 0
    
    # Fuel cost (diesel ₹90/L, avg 8km/L for trucks)
    fuel_map = {"ROAD_CAR": 8, "ROAD_BIKE": 40, "RAIL": 0, "FLIGHT": 0, "SHIP": 0}
    km_per_litre = fuel_map.get(mode, 8)
    fuel_litres = round(dist_km / max(km_per_litre, 1), 2) if km_per_litre > 0 else 0
    fuel_cost = round(fuel_litres * 90, 2)
    
    # Efficiency score (lower CO2 + lower cost = higher efficiency)
    co2_per_km = strategy.co2_per_km_g
    max_co2 = 250  # Flight baseline
    efficiency = round(max(0, (1 - (co2_per_km / max_co2)) * 100), 1)
    
    return {
        "shipment_id": shipment_id,
        "distance_km": round(dist_km, 2),
        "route_mode": mode,
        "carbon_footprint": {
            "co2_grams": cost_data["estimated_co2_g"],
            "co2_kg": round(cost_data["estimated_co2_g"] / 1000, 3),
            "trees_to_offset": max(1, round(cost_data["estimated_co2_g"] / 21000)),
            "carbon_rating": "A" if co2_per_km < 50 else "B" if co2_per_km < 150 else "C"
        },
        "cost_breakdown": {
            "transport_cost_inr": cost_data["estimated_cost_inr"],
            "toll_charges_inr": toll_estimate,
            "fuel_cost_inr": fuel_cost,
            "fuel_litres": fuel_litres,
            "total_cost_inr": round(cost_data["estimated_cost_inr"] + toll_estimate, 2)
        },
        "efficiency_score": efficiency,
        "duration_mins": cost_data["estimated_duration_mins"]
    }
