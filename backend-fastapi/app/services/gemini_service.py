import json
from app.models import LatLng
from app.config import model, search_tool

def analyze_risk(origin: LatLng, destination: LatLng, mode: str, duration: str) -> dict:
    if not model or not search_tool:
        return {
            "error": "Vertex AI not configured", 
            "heads_up": "Stay alert during travel.",
            "final_risk_score": 0
        }
        
    prompt = f"""
    Context: Garuda Omnichannel Traffic & Risk Analyst. 
    Trip from ({origin.lat},{origin.lng}) to ({destination.lat},{destination.lng}) by {mode}.
    Current Base Duration: {duration}.

    Tasks:
    1. Search for: Live weather/rain during the next few hours near these coordinates.
    2. Search for: Any local events, weekends, mandirs/festivals, or protests that might cause delays.
    3. Formula Calculation (Value 0.0 to 1.0 for each factor):
       - S (IncidentSeverity): Any major road blocks/accidents/air-traffic delays?
       - H (HistoricalDelayIndex): Typical delay pattern for this mode?
       - W (WeatherRisk): Rain/Storms/Visibility risk?
       - T (CongestionTrend): Is congestion increasing?
    
    Calculate Score: RiskScore = (0.40 * S) + (0.25 * H) + (0.20 * W) + (0.15 * T). Multiply by 100 for final percentage.

    4. Heads-up: Very specific advice based on mode '{mode}'.
    
    Strictly return JSON only in this format:
    {{
      "final_risk_score": float,
      "severity_breakdown": {{"s": float, "h": float, "w": float, "t": float}},
      "heads_up": "string",
      "context_reason": "string"
    }}
    """
    
    try:
        response = model.generate_content(prompt, tools=[search_tool])
        raw_text = response.text.replace("```json", "").replace("```", "").strip()
        return json.loads(raw_text)
    except Exception as e:
        print(f"AI Generation Error: {e}")
        return {"error": "AI could not finalize score", "heads_up": "Stay alert.", "final_risk_score": 0}

def monitor_hazards(current_location: LatLng, destination: LatLng, mode: str) -> dict:
    if not model or not search_tool:
        return {"blockage_severity": 0.0, "reason": "AI monitoring offline"}
        
    prompt = f"""
    Context: Live Ride Monitoring.
    Traveling from ({current_location.lat},{current_location.lng}) to ({destination.lat},{destination.lng}) by {mode}.
    Task: Check for any IMMEDIATE severe roadblocks, fresh accidents, or sudden extreme weather alerts right now.
    If the path is clear, return severity 0. If there is a major blockage, return high severity.
    Respond strictly in JSON:
    {{
        "blockage_severity": float (0.0 to 1.0),
        "reason": "string"
    }}
    """
    try:
        response = model.generate_content(prompt, tools=[search_tool])
        raw_text = response.text.replace("```json", "").replace("```", "").strip()
        return json.loads(raw_text)
    except Exception as e:
        print(f"Monitoring AI Error: {e}")
        return {"blockage_severity": 0.0, "reason": "Error checking hazards"}


# ═══════════════════════════════════════════════════════════════
# NEW AI FUNCTIONS — API Expansion
# ═══════════════════════════════════════════════════════════════

def predict_disruptions(center: LatLng, radius_km: float, modes: list) -> dict:
    """AI scans for disruptions (protests, weather, accidents) in a geographic zone."""
    if not model or not search_tool:
        return {
            "disruptions_found": 1,
            "zone": {"center": center.to_dict(), "radius_km": radius_km},
            "disruptions": [
                {
                    "type": "WEATHER_ALERT",
                    "severity": 0.4,
                    "description": "Light rain expected in the region (AI offline — simulated)",
                    "affected_modes": ["ROAD_CAR", "ROAD_BIKE"],
                    "estimated_delay_mins": 15,
                    "location": center.to_dict()
                }
            ],
            "overall_risk": "LOW",
            "scanned_at": "now",
            "ai_status": "offline"
        }

    modes_str = ", ".join(modes)
    prompt = f"""
    Context: Garuda Disruption Intelligence System.
    Scan Zone: Center ({center.lat},{center.lng}), Radius: {radius_km} km.
    Transport modes of interest: {modes_str}.
    
    Tasks:
    1. Search for: Any active road accidents, roadblocks, protests, or construction in this zone.
    2. Search for: Weather alerts, flooding, storms, visibility issues in this zone.
    3. Search for: Any rail disruptions, flight delays, or port closures if those modes are relevant.
    4. Search for: Any local events, festivals, or rallies causing congestion.
    
    For each disruption found, provide type, severity (0.0-1.0), description, affected_modes, and estimated_delay_mins.
    
    Strictly return JSON:
    {{
      "disruptions_found": int,
      "disruptions": [
        {{
          "type": "ACCIDENT|WEATHER|PROTEST|CONSTRUCTION|RAIL_DISRUPTION|FLIGHT_DELAY|PORT_CLOSURE|EVENT",
          "severity": float,
          "description": "string",
          "affected_modes": ["string"],
          "estimated_delay_mins": int,
          "location": {{"lat": float, "lng": float}}
        }}
      ],
      "overall_risk": "LOW|MEDIUM|HIGH|CRITICAL",
      "advisory": "string"
    }}
    """
    try:
        response = model.generate_content(prompt, tools=[search_tool])
        raw_text = response.text.replace("```json", "").replace("```", "").strip()
        result = json.loads(raw_text)
        result["zone"] = {"center": center.to_dict(), "radius_km": radius_km}
        return result
    except Exception as e:
        print(f"Disruption AI Error: {e}")
        return {
            "disruptions_found": 0, "disruptions": [],
            "overall_risk": "UNKNOWN", "error": str(e)
        }


def precheck_route(origin: LatLng, destination: LatLng, mode: str, dispatch_time: str, cargo_type: str) -> dict:
    """Pre-dispatch predictive alert — checks weather, events, congestion BEFORE dispatch."""
    if not model or not search_tool:
        return {
            "dispatch_clearance": "PROCEED_WITH_CAUTION",
            "predicted_risk_score": 25.0,
            "weather_forecast": "Partly cloudy, no severe weather expected (AI offline — simulated)",
            "congestion_prediction": "Moderate traffic expected during dispatch window",
            "event_alerts": [],
            "recommended_dispatch_time": dispatch_time or "now",
            "recommended_mode": mode,
            "alternate_modes": [],
            "ai_status": "offline"
        }

    prompt = f"""
    Context: Garuda Pre-Dispatch Route Precheck System (Predictive Alert Engine).
    Route: ({origin.lat},{origin.lng}) → ({destination.lat},{destination.lng})
    Mode: {mode}, Planned Dispatch: {dispatch_time or 'ASAP'}, Cargo: {cargo_type}.

    CRITICAL TASKS (Search for EACH):
    1. Weather forecast for the ENTIRE route corridor for the next 6-12 hours.
    2. Known events, festivals, protests, or rallies along the route or near origin/destination.
    3. Predicted traffic congestion patterns for the dispatch time window.
    4. Any road closures, construction, or maintenance schedules.
    5. If cargo is perishable/fragile — any temperature or vibration risks.

    Calculate a Predicted Risk Score (0-100) and give a dispatch clearance verdict.

    Strictly return JSON:
    {{
      "dispatch_clearance": "CLEAR|PROCEED_WITH_CAUTION|DELAY_RECOMMENDED|DO_NOT_DISPATCH",
      "predicted_risk_score": float,
      "weather_forecast": "string",
      "congestion_prediction": "string",
      "event_alerts": ["string"],
      "risk_factors": [{{"factor": "string", "severity": float, "detail": "string"}}],
      "recommended_dispatch_time": "string",
      "recommended_mode": "string",
      "alternate_modes": ["string"],
      "advisory": "string"
    }}
    """
    try:
        response = model.generate_content(prompt, tools=[search_tool])
        raw_text = response.text.replace("```json", "").replace("```", "").strip()
        return json.loads(raw_text)
    except Exception as e:
        print(f"Precheck AI Error: {e}")
        return {
            "dispatch_clearance": "UNKNOWN", "predicted_risk_score": 0,
            "error": str(e)
        }


def explain_risk_score(origin: LatLng, destination: LatLng, mode: str, risk_score: float) -> dict:
    """Explainable AI — detailed breakdown of why Gemini flagged a risk score."""
    if not model or not search_tool:
        return {
            "risk_score": risk_score,
            "verdict": "HIGH_RISK" if risk_score >= 65 else "CAUTION" if risk_score >= 40 else "SAFE",
            "explanation": {
                "primary_reason": "AI offline — cannot generate detailed explanation",
                "contributing_factors": [
                    {"factor": "Historical Delay Index", "weight": 0.25, "value": 0.3, "detail": "Moderate historical delays on this corridor"},
                    {"factor": "Weather Risk", "weight": 0.20, "value": 0.2, "detail": "No severe weather detected (simulated)"},
                    {"factor": "Congestion Trend", "weight": 0.15, "value": 0.4, "detail": "Peak hour congestion expected"},
                    {"factor": "Incident Severity", "weight": 0.40, "value": 0.1, "detail": "No active incidents (simulated)"}
                ],
                "recommendation": "Proceed with normal precautions",
                "data_sources": ["Historical patterns (simulated)", "Weather API (offline)"]
            },
            "ai_status": "offline"
        }

    prompt = f"""
    Context: Garuda Explainable AI Risk Engine.
    Route: ({origin.lat},{origin.lng}) → ({destination.lat},{destination.lng}) by {mode}.
    Previous Risk Score: {risk_score}/100.

    Task: Provide a DETAILED, TRANSPARENT explanation of why this risk score was assigned.
    Break down each contributing factor with its weight, actual measured value, and specific real-world reason.
    This is for "Explainable AI" — the user must understand WHY the AI decided this.

    Strictly return JSON:
    {{
      "risk_score": float,
      "verdict": "SAFE|CAUTION|HIGH_RISK|CRITICAL",
      "explanation": {{
        "primary_reason": "string — single most important factor",
        "contributing_factors": [
          {{"factor": "string", "weight": float, "value": float, "detail": "string"}}
        ],
        "recommendation": "string",
        "data_sources": ["string"],
        "confidence_level": float
      }}
    }}
    """
    try:
        response = model.generate_content(prompt, tools=[search_tool])
        # Handle multi-part responses from Gemini
        try:
            raw_text = response.text
        except Exception:
            # Fallback: concatenate all text parts
            raw_text = ""
            for candidate in response.candidates:
                for part in candidate.content.parts:
                    if hasattr(part, 'text') and part.text:
                        raw_text += part.text
        raw_text = raw_text.replace("```json", "").replace("```", "").strip()
        return json.loads(raw_text)
    except Exception as e:
        print(f"Explain Risk AI Error: {e}")
        # Return the offline fallback instead of an error
        return {
            "risk_score": risk_score,
            "verdict": "HIGH_RISK" if risk_score >= 65 else "CAUTION" if risk_score >= 40 else "SAFE",
            "explanation": {
                "primary_reason": "AI analysis encountered multi-part response — using algorithmic fallback",
                "contributing_factors": [
                    {"factor": "Historical Delay Index", "weight": 0.25, "value": 0.3, "detail": "Moderate historical delays on this corridor"},
                    {"factor": "Weather Risk", "weight": 0.20, "value": 0.2, "detail": "No severe weather detected (fallback)"},
                    {"factor": "Congestion Trend", "weight": 0.15, "value": 0.4, "detail": "Peak hour congestion expected"},
                    {"factor": "Incident Severity", "weight": 0.40, "value": 0.1, "detail": "No active incidents (fallback)"}
                ],
                "recommendation": "Proceed with normal precautions",
                "data_sources": ["Algorithmic fallback", "Historical patterns"]
            }
        }


def estimate_driver_fatigue(driver_id: str, drive_hours: float, total_km: float, breaks: int, time_of_day_hour: int) -> dict:
    """AI estimates driver fatigue risk based on drive time, time-of-day, route complexity."""
    # Algorithmic fatigue model (works without AI)
    fatigue_score = 0.0

    # Hours driven factor (max 0.4)
    if drive_hours > 10:
        fatigue_score += 0.4
    elif drive_hours > 6:
        fatigue_score += 0.25
    elif drive_hours > 4:
        fatigue_score += 0.15
    else:
        fatigue_score += 0.05

    # Night driving factor (max 0.25)
    if 0 <= time_of_day_hour <= 5 or time_of_day_hour >= 22:
        fatigue_score += 0.25
    elif 18 <= time_of_day_hour < 22:
        fatigue_score += 0.10

    # Distance factor (max 0.2)
    if total_km > 300:
        fatigue_score += 0.20
    elif total_km > 150:
        fatigue_score += 0.10
    else:
        fatigue_score += 0.03

    # Breaks factor (max 0.15) — fewer breaks = more fatigue
    expected_breaks = max(1, int(drive_hours / 2))
    if breaks < expected_breaks:
        fatigue_score += 0.15
    elif breaks == expected_breaks:
        fatigue_score += 0.05

    fatigue_pct = min(round(fatigue_score * 100, 1), 100.0)

    if fatigue_pct >= 70:
        verdict = "CRITICAL"
        action = "MANDATORY REST STOP — Pull over immediately. Fatigue level is dangerously high."
    elif fatigue_pct >= 50:
        verdict = "HIGH"
        action = "REST RECOMMENDED — Take a 20-30 min break at the next rest stop."
    elif fatigue_pct >= 30:
        verdict = "MODERATE"
        action = "CAUTION — Stay hydrated, take short breaks every hour."
    else:
        verdict = "LOW"
        action = "All clear — Driver is within safe driving parameters."

    return {
        "driver_id": driver_id,
        "fatigue_score": fatigue_pct,
        "verdict": verdict,
        "action_required": action,
        "breakdown": {
            "hours_driven": drive_hours,
            "km_driven": total_km,
            "breaks_taken": breaks,
            "expected_breaks": expected_breaks,
            "is_night_driving": 0 <= time_of_day_hour <= 5 or time_of_day_hour >= 22,
            "time_of_day_hour": time_of_day_hour
        },
        "regulations": {
            "max_continuous_drive_hours": 4.5,
            "mandatory_break_mins": 30,
            "max_daily_drive_hours": 9,
            "note": "As per MoRTH (India) driver hours regulation"
        }
    }


def predict_demand_surge(center: LatLng, radius_km: float, days_ahead: int, category: str) -> dict:
    """Predict demand surge in a region using historical + event data."""
    if not model or not search_tool:
        # Smart simulated response
        import random
        random.seed(int(center.lat * 1000))
        base_surge = random.uniform(1.0, 2.5)
        return {
            "region": {"center": center.to_dict(), "radius_km": radius_km},
            "prediction_window_days": days_ahead,
            "category": category,
            "surge_multiplier": round(base_surge, 2),
            "confidence": 0.72,
            "predicted_daily_volumes": [
                {"day": i + 1, "volume_index": round(base_surge * (1 + random.uniform(-0.2, 0.3)), 2)}
                for i in range(min(days_ahead, 7))
            ],
            "factors": [
                {"factor": "Weekend Pattern", "impact": "moderate", "detail": "Weekend volumes typically 1.3x weekday"},
                {"factor": "Regional Festival", "impact": "high", "detail": "Upcoming festival may increase demand by 40-60%"}
            ],
            "advisory": "Consider pre-positioning additional fleet resources in this zone.",
            "ai_status": "offline"
        }

    prompt = f"""
    Context: Garuda Demand Surge Prediction Engine.
    Region: Center ({center.lat},{center.lng}), Radius: {radius_km}km.
    Prediction Window: Next {days_ahead} days. Category: {category}.
    
    Tasks:
    1. Search for: Any upcoming festivals, sales events (Amazon/Flipkart), holidays in this region.
    2. Search for: Historical demand patterns for this region and category.
    3. Search for: Weather forecasts that might affect demand (heavy rain = more indoor orders).
    4. Provide a surge multiplier (1.0 = normal, 2.0 = double demand).
    
    Strictly return JSON:
    {{
      "surge_multiplier": float,
      "confidence": float,
      "predicted_daily_volumes": [{{"day": int, "volume_index": float}}],
      "factors": [{{"factor": "string", "impact": "low|moderate|high", "detail": "string"}}],
      "advisory": "string"
    }}
    """
    try:
        response = model.generate_content(prompt, tools=[search_tool])
        raw_text = response.text.replace("```json", "").replace("```", "").strip()
        result = json.loads(raw_text)
        result["region"] = {"center": center.to_dict(), "radius_km": radius_km}
        result["prediction_window_days"] = days_ahead
        result["category"] = category
        return result
    except Exception as e:
        print(f"Demand Surge AI Error: {e}")
        return {"surge_multiplier": 1.0, "error": str(e)}


def assess_package_integrity(origin: LatLng, destination: LatLng, mode: str, weight_kg: float, cargo_type: str) -> dict:
    """Package integrity score — risk to package based on route vibration, weather, handling."""
    from app.services.routing_strategy import calculate_haversine
    dist_km = calculate_haversine(origin, destination)
    
    # Algorithmic integrity model
    integrity_score = 100.0  # Start at 100%, degrade based on risks

    # Distance degradation (longer = more risk)
    if dist_km > 500:
        integrity_score -= 15
    elif dist_km > 200:
        integrity_score -= 8
    elif dist_km > 50:
        integrity_score -= 3

    # Mode-based vibration risk
    vibration_map = {"ROAD_CAR": 12, "ROAD_BIKE": 20, "RAIL": 8, "FLIGHT": 5, "SHIP": 6}
    integrity_score -= vibration_map.get(mode, 10)

    # Cargo type sensitivity
    sensitivity_map = {"fragile": 25, "perishable": 20, "hazardous": 15, "high_value": 10, "general": 3, "electronics": 18}
    integrity_score -= sensitivity_map.get(cargo_type, 5)

    # Weight factor (heavier = more damage risk on drops)
    if weight_kg > 50:
        integrity_score -= 10
    elif weight_kg > 20:
        integrity_score -= 5

    integrity_score = max(0, round(integrity_score, 1))

    if integrity_score >= 80:
        verdict = "SAFE"
        recommendation = "Standard packaging sufficient. No special handling required."
    elif integrity_score >= 60:
        verdict = "MODERATE_RISK"
        recommendation = "Use reinforced packaging. Add 'FRAGILE' labels. Consider shock-absorbent inserts."
    elif integrity_score >= 40:
        verdict = "HIGH_RISK"
        recommendation = "Use premium packaging with foam inserts. Temperature-controlled container if perishable. GPS tracking mandatory."
    else:
        verdict = "CRITICAL_RISK"
        recommendation = "Switch to AIR mode for fastest delivery. Use military-grade packaging. Real-time vibration monitoring required."

    return {
        "integrity_score": integrity_score,
        "verdict": verdict,
        "recommendation": recommendation,
        "risk_factors": {
            "distance_km": round(dist_km, 2),
            "mode": mode,
            "cargo_type": cargo_type,
            "weight_kg": weight_kg,
            "vibration_risk": vibration_map.get(mode, 10),
            "sensitivity_penalty": sensitivity_map.get(cargo_type, 5)
        }
    }
