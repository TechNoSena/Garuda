import pytest
import json
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_session_start():
    response = client.post("/v1/session/start")
    assert response.status_code == 200
    data = response.json()
    assert "session_id" in data
    assert data["status"] == "active"
    print("\n--- /v1/session/start ---")
    print(json.dumps(data, indent=2))
    return data["session_id"]

def test_fetch_routes(session_id, mode):
    response = client.post("/v1/routes/fetch", json={
        "session_id": session_id,
        "origin": {"lat": 22.543610, "lng": 85.796856},
        "destination": {"lat": 22.768116, "lng": 86.200684},
        "mode": mode
    })
    assert response.status_code == 200
    data = response.json()
    assert "routes" in data
    print(f"\n--- /v1/routes/fetch ({mode}) ---")
    print(json.dumps(data, indent=2)[:300] + "\n... [TRUNCATED] ...")

def test_optimize_multi(session_id, mode):
    response = client.post("/v1/routes/optimize-multi", json={
        "session_id": session_id,
        "points": [
            {"lat": 22.543610, "lng": 85.796856},
            {"lat": 22.650000, "lng": 85.900000},
            {"lat": 22.768116, "lng": 86.200684}
        ],
        "mode": mode
    })
    assert response.status_code == 200
    data = response.json()
    assert "optimized_points" in data
    print(f"\n--- /v1/routes/optimize-multi ({mode}) ---")
    print(json.dumps(data, indent=2)[:300] + "\n... [TRUNCATED] ...")

def test_analyze_route(session_id, mode):
    response = client.post("/v1/routes/analyze", json={
        "session_id": session_id,
        "origin": {"lat": 22.543610, "lng": 85.796856},
        "destination": {"lat": 22.768116, "lng": 86.200684},
        "mode": mode,
        "route_data": {"duration": "1200s"}
    })
    assert response.status_code == 200
    data = response.json()
    assert "verdict" in data
    assert "analysis" in data
    print(f"\n--- /v1/routes/analyze ({mode}) ---")
    print(json.dumps(data, indent=2))

def test_monitor_ride(session_id, mode):
    response = client.post("/v1/ride/monitor", json={
        "session_id": session_id,
        "current_location": {"lat": 22.543610, "lng": 85.796856},
        "destination": {"lat": 22.768116, "lng": 86.200684},
        "mode": mode
    })
    assert response.status_code == 200
    data = response.json()
    assert "status" in data
    print(f"\n--- /v1/ride/monitor ({mode}) ---")
    print(json.dumps(data, indent=2))

if __name__ == "__main__":
    print("Testing /v1/session/start...")
    session_id = test_session_start()
    print("Session created:", session_id)
    
    modes = ["ROAD_CAR", "RAIL", "FLIGHT", "SHIP"]
    
    for mode in modes:
        print(f"\n>>> TESTING MODALITY: {mode} <<<")
        
        print(f"Testing /v1/routes/fetch ({mode})...")
        test_fetch_routes(session_id, mode)
        
        print(f"Testing /v1/routes/optimize-multi ({mode})...")
        test_optimize_multi(session_id, mode)
        
        print(f"Testing /v1/routes/analyze ({mode})...")
        test_analyze_route(session_id, mode)
        
        print(f"Testing /v1/ride/monitor ({mode})...")
        test_monitor_ride(session_id, mode)
    
    print("\nAll modalities tested successfully!")

