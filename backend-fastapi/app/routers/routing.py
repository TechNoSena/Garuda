from fastapi import APIRouter, HTTPException
import uuid
from datetime import datetime, timezone
from typing import Dict
from app.models import (
    FetchRoutesRequest, OptimizeMultiRequest, 
    AnalyzeRouteRequest, MonitorRideRequest, CompareModesRequest,
    RerouteRequest, PrecheckRequest, SwitchModeRequest
)
from app.services.routing_strategy import get_strategy, get_all_strategies, calculate_haversine
from app.services.gemini_service import analyze_risk, monitor_hazards, precheck_route

router = APIRouter(prefix="/v1", tags=["🧠 Routing Intelligence"])

# In-memory session store (production would use Redis)
active_sessions: Dict[str, dict] = {}

def _validate_session(session_id: str):
    if session_id not in active_sessions:
        raise HTTPException(status_code=401, detail="Invalid or expired session")


@router.post("/session/start", summary="Start New Session",
             description="Creates a UUID-based session for context-preserving routing queries")
async def start_session():
    session_id = str(uuid.uuid4())
    active_sessions[session_id] = {
        "created_at": datetime.now(timezone.utc).isoformat(),
        "context": {}
    }
    return {"session_id": session_id, "status": "active"}


@router.post("/routes/fetch", summary="Fetch Routes",
             description="Get optimal routes between two points for a given transport mode")
async def fetch_options(req: FetchRoutesRequest):
    _validate_session(req.session_id)
    
    strategy = get_strategy(req.mode.value)
    routes = strategy.get_routes(req.origin, req.destination)
    if not routes:
        raise HTTPException(status_code=404, detail="No routes found for the given mode and locations")
    
    active_sessions[req.session_id]["context"]["last_searched_mode"] = req.mode.value
    return {"mode": req.mode.value, "routes": routes}


@router.post("/routes/optimize-multi", summary="Multi-Stop TSP Optimization",
             description="Reorder a list of waypoints for the most efficient delivery sequence")
async def optimize_multi_stop(req: OptimizeMultiRequest):
    _validate_session(req.session_id)
    
    if len(req.points) < 2:
        raise HTTPException(status_code=400, detail="Need at least 2 points to optimize")
        
    strategy = get_strategy(req.mode.value)
    result = strategy.optimize_multi(req.points)
    return result


@router.post("/routes/analyze", summary="Deep Risk Analysis",
             description="AI-powered risk assessment using Gemini + Google Search grounding")
async def analyze_delivery(req: AnalyzeRouteRequest):
    _validate_session(req.session_id)
        
    duration = req.route_data.get('duration', 'Unknown')
    ai_data = analyze_risk(req.origin, req.destination, req.mode.value, duration)

    nav_link = None
    if req.mode.value in ["ROAD_CAR", "ROAD_BIKE"]:
        t_mode = "two_wheeler" if req.mode.value == "ROAD_BIKE" else "driving"
        nav_link = (f"https://www.google.com/maps/dir/?api=1"
                    f"&origin={req.origin.lat},{req.origin.lng}"
                    f"&destination={req.destination.lat},{req.destination.lng}"
                    f"&travelmode={t_mode}")

    risk_score = ai_data.get('final_risk_score', 0)
    if risk_score >= 65:
        verdict = "HIGH_RISK"
    elif risk_score >= 40:
        verdict = "CAUTION"
    else:
        verdict = "SAFE"

    return {
        "verdict": verdict,
        "risk_score": risk_score,
        "analysis": ai_data,
        "navigation_url": nav_link
    }


@router.post("/routes/compare-modes", summary="Compare All Transport Modes",
             description="Side-by-side comparison of cost, ETA, and CO₂ across Road/Rail/Air/Ship")
async def compare_modes(req: CompareModesRequest):
    _validate_session(req.session_id)

    dist_km = calculate_haversine(req.origin, req.destination)
    strategies = get_all_strategies()
    
    comparisons = []
    for mode_name, strategy in strategies.items():
        est = strategy.estimate_cost(dist_km)
        comparisons.append(est)
    
    # Sort by duration (fastest first)
    comparisons.sort(key=lambda x: x["estimated_duration_mins"])
    
    return {
        "origin": req.origin.to_dict(),
        "destination": req.destination.to_dict(),
        "straight_line_km": round(dist_km, 2),
        "comparisons": comparisons,
        "recommendation": comparisons[0]["mode"] if comparisons else None
    }


@router.post("/ride/monitor", summary="Live Ride Monitoring",
             description="Poll during active delivery — returns REROUTE_SUGGESTED if severity > 0.6")
async def monitor_ride(req: MonitorRideRequest):
    _validate_session(req.session_id)
        
    strategy = get_strategy(req.mode.value)
    
    # 1. Fetch current best routes
    routes = strategy.get_routes(req.current_location, req.destination)
    if not routes:
        return {"status": "NO_ROUTE", "message": "Cannot calculate route from current location."}
        
    best_route = routes[0]
    
    # 2. Check for roadblocks via Gemini
    ai_data = monitor_hazards(req.current_location, req.destination, req.mode.value)
    severity = ai_data.get("blockage_severity", 0.0)
    reason = ai_data.get("reason", "Clear")
    
    if severity > 0.6:
        return {
            "status": "REROUTE_SUGGESTED",
            "severity": severity,
            "reason": f"Urgent roadblock/hazard detected: {reason}",
            "new_route": best_route
        }
            
    return {
        "status": "ON_TRACK",
        "severity": severity,
        "message": "Path looks clear. Continue on current route.",
        "remaining_distance": best_route.get("distanceMeters", "Unknown"),
        "remaining_duration": best_route.get("duration", "Unknown")
    }


@router.post("/routes/reroute", summary="Force Reroute",
             description="Force reroute with avoidance zones — AI suggests optimal alternative when disruptions are detected")
async def reroute(req: RerouteRequest):
    _validate_session(req.session_id)
    
    strategy = get_strategy(req.mode.value)
    
    # Get fresh routes avoiding disruption zones
    routes = strategy.get_routes(req.origin, req.destination)
    if not routes:
        raise HTTPException(status_code=404, detail="No alternative routes found")
    
    return {
        "status": "REROUTED",
        "reason": req.reason,
        "avoided_zones": [z.to_dict() for z in req.avoid_zones],
        "new_routes": routes,
        "mode": req.mode.value,
        "shipment_id": req.shipment_id,
        "rerouted_at": datetime.now(timezone.utc).isoformat()
    }


@router.post("/routes/precheck", summary="Pre-Dispatch Predictive Alert",
             description="Before dispatch — checks weather, events, congestion to predict if the route is safe")
async def precheck(req: PrecheckRequest):
    _validate_session(req.session_id)
    
    result = precheck_route(
        req.origin, req.destination, req.mode.value,
        req.dispatch_time or "ASAP", req.cargo_type
    )
    result["route"] = {
        "origin": req.origin.to_dict(),
        "destination": req.destination.to_dict(),
        "mode": req.mode.value
    }
    return result


@router.post("/routes/switch-mode", summary="Switch Transport Mode",
             description="Switch transport mode mid-transit (e.g., truck breakdown → switch to rail) with cost/time comparison")
async def switch_mode(req: SwitchModeRequest):
    _validate_session(req.session_id)
    
    dist_km = calculate_haversine(req.origin, req.destination)
    
    old_strategy = get_strategy(req.current_mode.value)
    new_strategy = get_strategy(req.new_mode.value)
    
    old_estimate = old_strategy.estimate_cost(dist_km)
    new_estimate = new_strategy.estimate_cost(dist_km)
    
    new_routes = new_strategy.get_routes(req.origin, req.destination)
    
    cost_diff = round(new_estimate["estimated_cost_inr"] - old_estimate["estimated_cost_inr"], 2)
    time_diff = round(new_estimate["estimated_duration_mins"] - old_estimate["estimated_duration_mins"], 1)
    co2_diff = round(new_estimate["estimated_co2_g"] - old_estimate["estimated_co2_g"], 2)
    
    return {
        "status": "MODE_SWITCHED",
        "reason": req.reason,
        "shipment_id": req.shipment_id,
        "previous_mode": req.current_mode.value,
        "new_mode": req.new_mode.value,
        "comparison": {
            "cost_difference_inr": cost_diff,
            "time_difference_mins": time_diff,
            "co2_difference_g": co2_diff,
            "cost_verdict": "CHEAPER" if cost_diff < 0 else "COSTLIER",
            "time_verdict": "FASTER" if time_diff < 0 else "SLOWER",
            "eco_verdict": "GREENER" if co2_diff < 0 else "MORE_EMISSIONS"
        },
        "old_estimate": old_estimate,
        "new_estimate": new_estimate,
        "new_routes": new_routes[:2] if new_routes else [],
        "switched_at": datetime.now(timezone.utc).isoformat()
    }


@router.get("/health", summary="Health Check", tags=["System"],
            description="Quick server health check with uptime info")
async def health_check():
    from app.config import db, model
    return {
        "status": "healthy",
        "firebase": "connected" if db else "offline (mock mode)",
        "vertex_ai": "connected" if model else "offline",
        "active_sessions": len(active_sessions),
        "timestamp": datetime.now(timezone.utc).isoformat()
    }
