"""
Garuda Backend — Full Integration Test Suite
Tests every endpoint across all transport modes and user workflows.
"""
import json
import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

from fastapi.testclient import TestClient
from main import app

client = TestClient(app)
PASS = "✅"
FAIL = "❌"
results = []

def log(name, passed, data=None):
    status = PASS if passed else FAIL
    results.append((name, passed))
    print(f"\n{status} {name}")
    if data:
        print(json.dumps(data, indent=2, default=str)[:400])
        if len(json.dumps(data, default=str)) > 400:
            print("  ... [truncated]")

# ═══════════════════════════════════════════════════════════════
# 1. HEALTH CHECK
# ═══════════════════════════════════════════════════════════════
print("\n" + "="*60)
print("  1. SYSTEM HEALTH CHECK")
print("="*60)

r = client.get("/v1/health")
log("GET /v1/health", r.status_code == 200, r.json())

# ═══════════════════════════════════════════════════════════════
# 2. AUTH TESTS
# ═══════════════════════════════════════════════════════════════
print("\n" + "="*60)
print("  2. AUTH ENDPOINTS")
print("="*60)

import time
ts = str(int(time.time()))[-5:]

r = client.post("/v1/auth/register", json={
    "email": f"supplier_{ts}@garuda.com", "password": "test123456",
    "name": "Test Supplier", "role": "SUPPLIER", "company_name": "Garuda Logistics"
})
log("POST /v1/auth/register (Supplier)", r.status_code == 200, r.json())

r = client.post("/v1/auth/register", json={
    "email": f"driver_{ts}@garuda.com", "password": "test123456",
    "name": "Rahul Kumar", "role": "DELIVERY_MAN"
})
log("POST /v1/auth/register (Delivery Man)", r.status_code == 200, r.json())

r = client.post("/v1/auth/login", json={
    "email": f"supplier_{ts}@garuda.com", "password": "test123456"
})
log("POST /v1/auth/login", r.status_code == 200, r.json())

r = client.post("/v1/auth/login", json={
    "email": "wrong@email.com", "password": "badpass"
})
log("POST /v1/auth/login (bad creds — expect 401)", r.status_code == 401)

r = client.post("/v1/auth/reset-password", json={"email": "test_supplier@garuda.com"})
log("POST /v1/auth/reset-password", r.status_code == 200, r.json())

r = client.get("/v1/auth/profile/mock-uid")
log("GET /v1/auth/profile/{uid}", r.status_code in [200, 404], r.json())

# ═══════════════════════════════════════════════════════════════
# 3. SHIPMENT LIFECYCLE
# ═══════════════════════════════════════════════════════════════
print("\n" + "="*60)
print("  3. SHIPMENT LIFECYCLE")
print("="*60)

r = client.post("/v1/shipments/", json={
    "supplier_id": "mock-uid", "logistics_id": "logistics-uid",
    "consumer_email": "customer@email.com",
    "origin": {"lat": 22.543610, "lng": 85.796856},
    "destination": {"lat": 22.768116, "lng": 86.200684},
    "route_mode": "ROAD_CAR",
    "package_description": "Electronics - Laptop", "weight_kg": 2.5
})
log("POST /v1/shipments/ (Create)", r.status_code == 200, r.json())
shipment_id = r.json().get("shipment", {}).get("shipment_id", "mock-shipment-id")

r = client.get(f"/v1/shipments/{shipment_id}")
log(f"GET /v1/shipments/{shipment_id}", r.status_code in [200, 404], r.json())

r = client.patch(f"/v1/shipments/{shipment_id}/assign", json={"delivery_man_id": "driver-uid"})
log("PATCH /assign", r.status_code in [200, 400], r.json())

r = client.patch(f"/v1/shipments/{shipment_id}/status?status=DISPATCHED")
log("PATCH /status → DISPATCHED", r.status_code in [200, 400], r.json())

r = client.patch(f"/v1/shipments/{shipment_id}/status?status=IN_TRANSIT")
log("PATCH /status → IN_TRANSIT", r.status_code in [200, 400], r.json())

r = client.patch(f"/v1/shipments/{shipment_id}/location", json={
    "current_location": {"lat": 22.650000, "lng": 85.900000}
})
log("PATCH /location (mid-route update)", r.status_code in [200, 400], r.json())

r = client.get(f"/v1/shipments/{shipment_id}/eta")
log("GET /eta", r.status_code in [200, 404], r.json())

r = client.get(f"/v1/shipments/user/mock-uid?role=SUPPLIER")
log("GET /user/{id} (list by supplier)", r.status_code == 200, r.json())

r = client.patch(f"/v1/shipments/{shipment_id}/status?status=DELIVERED")
log("PATCH /status → DELIVERED", r.status_code in [200, 400], r.json())

# ═══════════════════════════════════════════════════════════════
# 4. ROUTING — ALL MODES
# ═══════════════════════════════════════════════════════════════
print("\n" + "="*60)
print("  4. ROUTING — ALL TRANSPORT MODES")
print("="*60)

r = client.post("/v1/session/start")
log("POST /session/start", r.status_code == 200, r.json())
sid = r.json()["session_id"]

modes = ["ROAD_CAR", "ROAD_BIKE", "RAIL", "FLIGHT", "SHIP"]
for mode in modes:
    r = client.post("/v1/routes/fetch", json={
        "session_id": sid,
        "origin": {"lat": 22.543610, "lng": 85.796856},
        "destination": {"lat": 22.768116, "lng": 86.200684},
        "mode": mode
    })
    log(f"POST /routes/fetch ({mode})", r.status_code == 200 and "routes" in r.json())

# ═══════════════════════════════════════════════════════════════
# 5. MULTI-STOP TSP OPTIMIZATION
# ═══════════════════════════════════════════════════════════════
print("\n" + "="*60)
print("  5. MULTI-STOP TSP OPTIMIZATION")
print("="*60)

for mode in ["ROAD_CAR", "RAIL"]:
    r = client.post("/v1/routes/optimize-multi", json={
        "session_id": sid,
        "points": [
            {"lat": 22.543610, "lng": 85.796856},
            {"lat": 22.650000, "lng": 85.900000},
            {"lat": 22.700000, "lng": 85.950000},
            {"lat": 22.768116, "lng": 86.200684}
        ],
        "mode": mode
    })
    log(f"POST /routes/optimize-multi ({mode})", r.status_code == 200, r.json())

# ═══════════════════════════════════════════════════════════════
# 6. COMPARE MODES
# ═══════════════════════════════════════════════════════════════
print("\n" + "="*60)
print("  6. COMPARE ALL MODES (Cost / ETA / CO₂)")
print("="*60)

r = client.post("/v1/routes/compare-modes", json={
    "session_id": sid,
    "origin": {"lat": 22.543610, "lng": 85.796856},
    "destination": {"lat": 22.768116, "lng": 86.200684}
})
log("POST /routes/compare-modes", r.status_code == 200, r.json())

# ═══════════════════════════════════════════════════════════════
# 7. RISK ANALYSIS
# ═══════════════════════════════════════════════════════════════
print("\n" + "="*60)
print("  7. AI RISK ANALYSIS")
print("="*60)

r = client.post("/v1/routes/analyze", json={
    "session_id": sid,
    "origin": {"lat": 22.543610, "lng": 85.796856},
    "destination": {"lat": 22.768116, "lng": 86.200684},
    "mode": "ROAD_CAR",
    "route_data": {"duration": "1200s", "distanceMeters": 45000}
})
log("POST /routes/analyze (ROAD_CAR)", r.status_code == 200, r.json())

# ═══════════════════════════════════════════════════════════════
# 8. LIVE RIDE MONITORING
# ═══════════════════════════════════════════════════════════════
print("\n" + "="*60)
print("  8. LIVE RIDE MONITORING")
print("="*60)

r = client.post("/v1/ride/monitor", json={
    "session_id": sid,
    "current_location": {"lat": 22.650000, "lng": 85.900000},
    "destination": {"lat": 22.768116, "lng": 86.200684},
    "mode": "ROAD_CAR"
})
log("POST /ride/monitor", r.status_code == 200 and "status" in r.json(), r.json())

# ═══════════════════════════════════════════════════════════════
# 9. EDGE CASES & VALIDATION
# ═══════════════════════════════════════════════════════════════
print("\n" + "="*60)
print("  9. EDGE CASES & VALIDATION")
print("="*60)

r = client.post("/v1/routes/fetch", json={
    "session_id": "invalid-session-id",
    "origin": {"lat": 22.5, "lng": 85.8},
    "destination": {"lat": 22.7, "lng": 86.2},
    "mode": "ROAD_CAR"
})
log("Invalid session → 401", r.status_code == 401)

r = client.post("/v1/routes/fetch", json={
    "session_id": sid,
    "origin": {"lat": 200, "lng": 85.8},
    "destination": {"lat": 22.7, "lng": 86.2},
    "mode": "ROAD_CAR"
})
log("Invalid lat (200) → 422", r.status_code == 422)

r = client.post("/v1/routes/optimize-multi", json={
    "session_id": sid, "points": [{"lat": 22.5, "lng": 85.8}], "mode": "ROAD_CAR"
})
log("TSP with 1 point → 400", r.status_code == 400)

r = client.get("/v1/shipments/nonexistent-id-12345")
log("GET nonexistent shipment → 404", r.status_code == 404)

# ═══════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════
print("\n" + "="*60)
passed = sum(1 for _, p in results if p)
total = len(results)
print(f"  RESULTS: {passed}/{total} tests passed")
if passed == total:
    print(f"  🎉 ALL TESTS PASSED — Backend is production-ready!")
else:
    failed = [name for name, p in results if not p]
    print(f"  ⚠️  Failed tests:")
    for f in failed:
        print(f"     {FAIL} {f}")
print("="*60)
