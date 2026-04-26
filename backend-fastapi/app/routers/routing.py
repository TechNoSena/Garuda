from fastapi import APIRouter, HTTPException
import uuid
from typing import Dict
from app.models import FetchRoutesRequest, OptimizeMultiRequest, AnalyzeRouteRequest, MonitorRideRequest
from app.services.routing_strategy import get_strategy
from app.services.gemini_service import analyze_risk, monitor_hazards

router = APIRouter(prefix="/v1", tags=["Routing Intelligence"])

# In-memory session store
active_sessions: Dict[str, dict] = {}

@router.post("/session/start")
async def start_session():
    session_id = str(uuid.uuid4())
    active_sessions[session_id] = {"created_at": "now", "context": {}}
    return {"session_id": session_id, "status": "active"}

@router.post("/routes/fetch")
async def fetch_options(req: FetchRoutesRequest):
    if req.session_id not in active_sessions:
        raise HTTPException(status_code=401, detail="Invalid session")
    
    strategy = get_strategy(req.mode)
    routes = strategy.get_routes(req.origin, req.destination)
    if not routes:
        return {"error": "No routes found"}
    
    active_sessions[req.session_id]["context"]["last_searched_mode"] = req.mode
    return {"routes": routes}

@router.post("/routes/optimize-multi")
async def optimize_multi_stop(req: OptimizeMultiRequest):
    if req.session_id not in active_sessions:
        raise HTTPException(status_code=401, detail="Invalid session")
        
    strategy = get_strategy(req.mode)
    result = strategy.optimize_multi(req.points)
    return result

@router.post("/routes/analyze")
async def analyze_delivery(req: AnalyzeRouteRequest):
    if req.session_id not in active_sessions:
        raise HTTPException(status_code=401, detail="Invalid session")
        
    duration = req.route_data.get('duration', 'Unknown')
    ai_data = analyze_risk(req.origin, req.destination, req.mode, duration)

    nav_link = None
    if req.mode in ["ROAD_CAR", "ROAD_BIKE"]:
        t_mode = "two_wheeler" if req.mode == "ROAD_BIKE" else "driving"
        nav_link = f"https://www.google.com/maps/dir/?api=1&origin={req.origin.lat},{req.origin.lng}&destination={req.destination.lat},{req.destination.lng}&travelmode={t_mode}"

    return {
        "verdict": "SAFE" if ai_data.get('final_risk_score', 0) < 65 else "CAUTION",
        "analysis": ai_data,
        "navigation_url": nav_link
    }

@router.post("/ride/monitor")
async def monitor_ride(req: MonitorRideRequest):
    if req.session_id not in active_sessions:
        raise HTTPException(status_code=401, detail="Invalid session")
        
    strategy = get_strategy(req.mode)
    
    # 1. Fetch current best routes
    routes = strategy.get_routes(req.current_location, req.destination)
    if not routes:
        return {"status": "NO_ROUTE", "message": "Cannot calculate route from current location."}
        
    best_route = routes[0]
    
    # 2. Check for roadblocks via Gemini
    ai_data = monitor_hazards(req.current_location, req.destination, req.mode)
    severity = ai_data.get("blockage_severity", 0.0)
    reason = ai_data.get("reason", "Clear")
    
    if severity > 0.6:
        return {
            "status": "REROUTE_SUGGESTED",
            "reason": f"Urgent roadblock/hazard detected: {reason}",
            "new_route": best_route
        }
            
    return {
        "status": "ON_TRACK",
        "message": "Path looks clear. Continue on current route.",
        "remaining_distance": best_route.get("distanceMeters", "Unknown"),
        "remaining_duration": best_route.get("duration", "Unknown")
    }
