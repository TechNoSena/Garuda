from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import StreamingResponse
from app.models import (
    CreateShipmentRequest, AssignShipmentRequest, 
    UpdateLocationRequest, ShipmentStatus, EtaRequest,
    ExceptionRequest, ReportIncidentRequest
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
        return firebase_service.update_shipment_status(shipment_id, ShipmentStatus.ASSIGNED, req.delivery_man_id)
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
        # Base coordinates (simulated movement along a route)
        base_lat = 22.543610
        base_lng = 85.796856
        dest_lat = 22.768116
        dest_lng = 86.200684
        
        for i in range(5):  # Send 5 events then close
            progress = (i + 1) / 5
            current_lat = round(base_lat + (dest_lat - base_lat) * progress + random.uniform(-0.002, 0.002), 6)
            current_lng = round(base_lng + (dest_lng - base_lng) * progress + random.uniform(-0.002, 0.002), 6)
            
            from datetime import datetime, timezone
            event_data = {
                "shipment_id": shipment_id,
                "location": {"lat": current_lat, "lng": current_lng},
                "speed_kmh": round(random.uniform(30, 70), 1),
                "heading_degrees": round(random.uniform(0, 360), 1),
                "progress_pct": round(progress * 100, 1),
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "event_index": i + 1
            }
            yield f"data: {json.dumps(event_data)}\n\n"
            await asyncio.sleep(1)  # 1 second for testing (3s in production)
        
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

