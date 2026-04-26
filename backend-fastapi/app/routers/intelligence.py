"""Garuda Intelligence Router — Geofence, Fatigue Detection, Demand Surge"""
from fastapi import APIRouter, HTTPException
from datetime import datetime, timezone
from app.models import GeofenceCheckRequest, FatigueCheckRequest, DemandSurgeRequest
from app.services.gemini_service import estimate_driver_fatigue, predict_demand_surge
from app.services.routing_strategy import calculate_haversine

router = APIRouter(prefix="/v1", tags=["🧬 Garuda Intelligence"])


@router.post("/geofence/check", summary="Geofence Zone Check",
             description="Check if a shipment has entered or exited a geofence zone (warehouse, city boundary, delivery radius)")
async def check_geofence(req: GeofenceCheckRequest):
    dist_km = calculate_haversine(req.current_location, req.zone_center)
    is_inside = dist_km <= req.zone_radius_km
    
    if is_inside:
        proximity_pct = round((1 - dist_km / req.zone_radius_km) * 100, 1)
        status = "INSIDE_ZONE"
        message = f"Shipment is INSIDE '{req.zone_name}' zone ({proximity_pct}% towards center)"
    else:
        distance_to_boundary = round(dist_km - req.zone_radius_km, 2)
        proximity_pct = 0
        status = "OUTSIDE_ZONE"
        message = f"Shipment is {distance_to_boundary} km OUTSIDE '{req.zone_name}' zone boundary"
    
    # Estimate time to reach zone boundary (assuming 40 km/h avg)
    if not is_inside:
        eta_to_zone_mins = round((dist_km - req.zone_radius_km) / 40 * 60, 1)
    else:
        eta_to_zone_mins = 0
    
    return {
        "shipment_id": req.shipment_id,
        "zone_name": req.zone_name,
        "status": status,
        "is_inside": is_inside,
        "distance_from_center_km": round(dist_km, 2),
        "zone_radius_km": req.zone_radius_km,
        "proximity_percentage": proximity_pct,
        "eta_to_zone_mins": eta_to_zone_mins,
        "message": message,
        "checked_at": datetime.now(timezone.utc).isoformat(),
        "trigger_events": {
            "entry_alert": is_inside,
            "approaching_alert": not is_inside and dist_km <= req.zone_radius_km * 1.5,
            "exit_alert": False
        }
    }


@router.post("/driver/fatigue-check", summary="Driver Fatigue Risk Assessment",
             description="AI estimates driver fatigue risk based on drive time, time-of-day, breaks taken, and distance covered")
async def fatigue_check(req: FatigueCheckRequest):
    # Parse drive start time to calculate hours
    try:
        from datetime import datetime as dt
        start = dt.fromisoformat(req.drive_start_time)
        now = dt.now(start.tzinfo or timezone.utc)
        drive_hours = max(0, (now - start).total_seconds() / 3600)
        current_hour = now.hour
    except:
        drive_hours = 6.0
        current_hour = 14
    
    result = estimate_driver_fatigue(
        driver_id=req.driver_id,
        drive_hours=round(drive_hours, 1),
        total_km=req.total_km_driven,
        breaks=req.breaks_taken,
        time_of_day_hour=current_hour
    )
    return result


@router.post("/predictions/demand-surge", summary="Demand Surge Prediction",
             description="Predict delivery demand surge in a region using historical patterns, festivals, events, and weather data")
async def demand_surge(req: DemandSurgeRequest):
    result = predict_demand_surge(
        center=req.region_center,
        radius_km=req.radius_km,
        days_ahead=req.prediction_window_days,
        category=req.category
    )
    return result
