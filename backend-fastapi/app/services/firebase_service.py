import os
import requests
from datetime import datetime
from typing import Dict, Any, Optional
from firebase_admin import auth
from app.config import db
from app.models import RegisterRequest, LoginRequest, UserRole, CreateShipmentRequest, ShipmentStatus, LatLng

# You need the Web API Key for login REST API
FIREBASE_API_KEY = os.getenv("FIREBASE_WEB_API_KEY", "")

def create_user(req: RegisterRequest) -> dict:
    if not db:
        return {"uid": "mock-uid", "email": req.email, "role": req.role.value}
        
    try:
        user = auth.create_user(
            email=req.email,
            password=req.password,
            display_name=req.name
        )
        
        # Save to Firestore
        user_data = {
            "uid": user.uid,
            "email": req.email,
            "role": req.role.value,
            "name": req.name,
            "company_name": req.company_name,
            "created_at": datetime.utcnow().isoformat()
        }
        db.collection("users").document(user.uid).set(user_data)
        return user_data
    except Exception as e:
        raise Exception(f"Failed to create user: {str(e)}")

def login_user(req: LoginRequest) -> dict:
    if not db or not FIREBASE_API_KEY:
        # Mock login
        return {"idToken": "mock-token", "email": req.email, "localId": "mock-uid"}
        
    url = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={FIREBASE_API_KEY}"
    payload = {
        "email": req.email,
        "password": req.password,
        "returnSecureToken": True
    }
    resp = requests.post(url, json=payload)
    if resp.status_code == 200:
        return resp.json()
    else:
        raise Exception("Invalid credentials")

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
            "route_mode": req.route_mode,
            "timestamps": {
                "created_at": datetime.utcnow().isoformat()
            }
        }
        doc_ref.set(shipment_data)
        return shipment_data
    except Exception as e:
        raise Exception(f"Failed to create shipment: {str(e)}")

def update_shipment_status(shipment_id: str, status: ShipmentStatus, delivery_man_id: Optional[str] = None) -> dict:
    if not db:
        return {"status": "success", "mock": True}
        
    doc_ref = db.collection("shipments").document(shipment_id)
    updates = {"status": status.value}
    
    if delivery_man_id:
        updates["delivery_man_id"] = delivery_man_id
    if status == ShipmentStatus.DISPATCHED:
        updates["timestamps.dispatched_at"] = datetime.utcnow().isoformat()
    elif status == ShipmentStatus.DELIVERED:
        updates["timestamps.delivered_at"] = datetime.utcnow().isoformat()
        
    doc_ref.update(updates)
    return {"shipment_id": shipment_id, "updated_fields": updates}

def update_shipment_location(shipment_id: str, location: LatLng) -> dict:
    if not db:
        return {"status": "success", "mock": True}
        
    doc_ref = db.collection("shipments").document(shipment_id)
    doc_ref.update({
        "current_location": location.to_dict(),
        "timestamps.last_location_update": datetime.utcnow().isoformat()
    })
    return {"shipment_id": shipment_id, "current_location": location.to_dict()}

def get_shipment(shipment_id: str) -> dict:
    if not db:
        return {"shipment_id": shipment_id, "status": ShipmentStatus.IN_TRANSIT.value, "mock": True}
        
    doc = db.collection("shipments").document(shipment_id).get()
    if doc.exists:
        return doc.to_dict()
    raise Exception("Shipment not found")
