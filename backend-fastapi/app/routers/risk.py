"""Risk & Disruption Detection Router — Garuda Platform"""
from fastapi import APIRouter, HTTPException
from datetime import datetime, timezone
from app.models import RiskEvaluateRequest, DisruptionDetectRequest
from app.services.gemini_service import analyze_risk, predict_disruptions
from app.services.routing_strategy import calculate_haversine

router = APIRouter(prefix="/v1", tags=["🛡️ Risk & Disruption"])


@router.post("/risk/evaluate", summary="Evaluate Risk Score",
             description="Standalone risk evaluation for any origin-destination pair with full factor breakdown")
async def evaluate_risk(req: RiskEvaluateRequest):
    dist_km = calculate_haversine(req.origin, req.destination)
    
    # Get AI risk analysis
    ai_data = analyze_risk(req.origin, req.destination, req.mode.value, f"{int((dist_km / 50) * 3600)}s")
    
    risk_score = ai_data.get("final_risk_score", 0)
    
    # Cargo-type risk multiplier
    cargo_multipliers = {"fragile": 1.3, "perishable": 1.25, "hazardous": 1.5, "high_value": 1.2, "general": 1.0}
    multiplier = cargo_multipliers.get(req.cargo_type, 1.0)
    adjusted_score = min(100, round(risk_score * multiplier, 1))
    
    if adjusted_score >= 75:
        verdict = "CRITICAL"
    elif adjusted_score >= 65:
        verdict = "HIGH_RISK"
    elif adjusted_score >= 40:
        verdict = "CAUTION"
    else:
        verdict = "SAFE"

    return {
        "verdict": verdict,
        "base_risk_score": risk_score,
        "cargo_multiplier": multiplier,
        "adjusted_risk_score": adjusted_score,
        "cargo_type": req.cargo_type,
        "distance_km": round(dist_km, 2),
        "mode": req.mode.value,
        "analysis": ai_data,
        "evaluated_at": datetime.now(timezone.utc).isoformat()
    }


@router.post("/disruptions/detect", summary="Detect Disruptions in Zone",
             description="AI scans for active disruptions (protests, weather, accidents) in a geographic zone")
async def detect_disruptions(req: DisruptionDetectRequest):
    modes_list = [m.value for m in req.modes_to_check]
    result = predict_disruptions(req.center, req.radius_km, modes_list)
    result["scanned_at"] = datetime.now(timezone.utc).isoformat()
    return result
