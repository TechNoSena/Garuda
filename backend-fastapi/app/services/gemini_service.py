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
