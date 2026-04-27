from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import StreamingResponse
from app.models import (
    CreateShipmentRequest, AssignShipmentRequest, 
    UpdateLocationRequest, ShipmentStatus, EtaRequest,
    ExceptionRequest, ReportIncidentRequest, DeliveryType
)
from app.services import firebase_service

router = APIRouter(prefix="/v1/shipments", tags=["📦 Shipments"])

@router.post("/", summary="Create Shipment",
             description="Supplier creates a new shipment with origin, destination, and consumer details")
async def create_shipment(req: CreateShipmentRequest):
    try:
        shipment = firebase_service.create_shipment(req)
        return {"status": "success", "shipment": shipment}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/{shipment_id}", summary="Get Shipment Details",
            description="Fetch full shipment data including current location and status history")
async def get_shipment(shipment_id: str):
    try:
        return firebase_service.get_shipment(shipment_id)
    except Exception as e:
        raise HTTPException(status_code=404, detail=str(e))

@router.get("/{shipment_id}/eta", summary="Get Live ETA",
            description="Calculate estimated time of arrival based on current location and transport mode")
async def get_eta(shipment_id: str):
    try:
        return firebase_service.get_shipment_eta(shipment_id)
    except Exception as e:
        raise HTTPException(status_code=404, detail=str(e))

@router.get("/user/{user_id}", summary="List Shipments by User",
            description="Get all shipments for a given user based on their role")
async def list_by_user(user_id: str, role: str = Query(..., description="SUPPLIER, LOGISTICS, or DELIVERY_MAN")):
    try:
        return firebase_service.list_shipments_by_user(user_id, role)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.patch("/{shipment_id}/assign", summary="Assign Delivery Man",
              description="Logistics partner assigns a delivery man to the shipment")
async def assign_shipment(shipment_id: str, req: AssignShipmentRequest):
    try:
        return firebase_service.update_shipment_status(
            shipment_id, ShipmentStatus.ASSIGNED, req.delivery_man_id,
            delivery_type=req.delivery_type.value if hasattr(req, 'delivery_type') else None
        )
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.patch("/{shipment_id}/status", summary="Update Shipment Status",
              description="Transition shipment through status lifecycle")
async def update_status(shipment_id: str, status: ShipmentStatus):
    try:
        return firebase_service.update_shipment_status(shipment_id, status)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.patch("/{shipment_id}/location", summary="Update Live Location",
              description="Delivery man pings current GPS coordinates (called every 5-10 mins)")
async def update_location(shipment_id: str, req: UpdateLocationRequest):
    try:
        return firebase_service.update_shipment_location(shipment_id, req.current_location)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


# ═══════════════════════════════════════════════════════════════
# NEW SHIPMENT ENDPOINTS
# ═══════════════════════════════════════════════════════════════

@router.get("/{shipment_id}/live", summary="Live Tracking Stream (SSE)",
            description="Server-Sent Events stream — pushes simulated live location updates every 3 seconds")
async def live_tracking(shipment_id: str):
    import asyncio
    import json
    import random
    
    async def event_generator():
        from datetime import datetime, timezone
        from app.services.routing_strategy import calculate_haversine
        
        # Try to read real data from Firestore
        shipment_data = None
        try:
            from app.config import db as firestore_db
            if firestore_db:
                doc = firestore_db.collection("shipments").document(shipment_id).get()
                if doc.exists:
                    shipment_data = doc.to_dict()
        except Exception:
            pass
        
        if shipment_data and shipment_data.get("current_location"):
            # Real mode: read actual location from Firestore
            from app.models import LatLng
            dest = LatLng(**shipment_data["destination"])
            speed_map = {"ROAD_CAR": 50, "ROAD_BIKE": 35, "RAIL": 80, "FLIGHT": 800, "SHIP": 40}
            mode = shipment_data.get("route_mode", "ROAD_CAR")
            speed = speed_map.get(mode, 50)
            
            for i in range(10):  # Stream for 10 cycles (30 seconds total)
                try:
                    doc = firestore_db.collection("shipments").document(shipment_id).get()
                    if doc.exists:
                        fresh = doc.to_dict()
                        curr = LatLng(**fresh["current_location"])
                        dist_km = calculate_haversine(curr, dest)
                        eta_mins = round((dist_km / speed) * 60)
                        
                        # Proactive risk check for 1-2hr window
                        risk_alert = None
                        if i % 3 == 0:  # Check every 3rd cycle
                            try:
                                from app.services.gemini_service import analyze_route_risk
                                risk = analyze_route_risk(curr, dest, mode, {"duration": f"{eta_mins*60}s", "distanceMeters": int(dist_km*1000)})
                                if risk.get("risk_score", 0) > 60:
                                    risk_alert = {"type": "WARNING", "message": risk.get("heads_up", "Potential disruption ahead"), "risk_score": risk.get("risk_score")}
                            except Exception:
                                pass
                        
                        event_data = {
                            "shipment_id": shipment_id,
                            "status": fresh["status"],
                            "current_location": fresh["current_location"],
                            "speed_kmh": speed,
                            "remaining_km": round(dist_km, 2),
                            "eta_minutes": eta_mins,
                            "progress_pct": round(max(0, min(100, (1 - dist_km / max(calculate_haversine(LatLng(**fresh["origin"]), dest), 0.1)) * 100)), 1),
                            "timestamp": datetime.now(timezone.utc).isoformat(),
                            "event_index": i + 1
                        }
                        if risk_alert:
                            event_data["risk_alert"] = risk_alert
                        
                        yield f"data: {json.dumps(event_data)}\n\n"
                except Exception:
                    pass
                await asyncio.sleep(3)
        else:
            # Fallback: simulated movement for demo
            base_lat = 22.543610
            base_lng = 85.796856
            dest_lat = 22.768116
            dest_lng = 86.200684
            
            for i in range(5):
                progress = (i + 1) / 5
                current_lat = round(base_lat + (dest_lat - base_lat) * progress + random.uniform(-0.002, 0.002), 6)
                current_lng = round(base_lng + (dest_lng - base_lng) * progress + random.uniform(-0.002, 0.002), 6)
                
                event_data = {
                    "shipment_id": shipment_id,
                    "status": "IN_TRANSIT",
                    "current_location": {"lat": current_lat, "lng": current_lng},
                    "speed_kmh": round(random.uniform(30, 70), 1),
                    "remaining_km": round((1 - progress) * 45, 2),
                    "eta_minutes": round((1 - progress) * 54),
                    "progress_pct": round(progress * 100, 1),
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                    "event_index": i + 1
                }
                yield f"data: {json.dumps(event_data)}\n\n"
                await asyncio.sleep(1)
        
        yield f"data: {json.dumps({'status': 'STREAM_COMPLETE', 'shipment_id': shipment_id})}\n\n"
    
    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"}
    )


@router.get("/{shipment_id}/timeline", summary="Shipment Timeline",
            description="Full chronological timeline of all status transitions, location pings, and events")
async def shipment_timeline(shipment_id: str):
    try:
        return firebase_service.get_shipment_timeline(shipment_id)
    except Exception as e:
        raise HTTPException(status_code=404, detail=str(e))


@router.post("/{shipment_id}/exception", summary="Log Shipment Exception",
             description="Log an exception event — DAMAGED, DELAYED, LOST, ADDRESS_WRONG, CUSTOMS_HOLD, etc.")
async def log_exception(shipment_id: str, req: ExceptionRequest):
    try:
        return firebase_service.log_exception(
            shipment_id, req.exception_type.value,
            req.description, req.severity, req.reported_by
        )
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/{shipment_id}/report-incident", summary="Driver Report Incident",
             description="Driver manually reports a road incident (breakdown, roadblock, flooding) not detected by AI")
async def report_incident(shipment_id: str, req: ReportIncidentRequest):
    try:
        return firebase_service.log_incident(
            shipment_id, req.incident_type.value,
            req.description, req.location.to_dict(),
            req.severity, req.driver_id
        )
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/{shipment_id}/risk-details", summary="Explainable Risk Details",
            description="Detailed breakdown of why Gemini flagged a shipment as High Risk — Explainable AI transparency")
async def risk_details(shipment_id: str):
    from app.services.gemini_service import explain_risk_score
    from app.models import LatLng
    
    # In production, fetch actual shipment data
    origin = LatLng(lat=22.543610, lng=85.796856)
    destination = LatLng(lat=22.768116, lng=86.200684)
    mode = "ROAD_CAR"
    risk_score = 55.0  # Would come from stored analysis
    
    result = explain_risk_score(origin, destination, mode, risk_score)
    result["shipment_id"] = shipment_id
    return result

