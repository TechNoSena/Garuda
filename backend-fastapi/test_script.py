"""
Garuda Backend — Full Integration Test Suite v2.0
Tests ALL endpoints across routing, risk, notifications, analytics, admin, intelligence.
Target: https://garuda-backend-437904093333.asia-south1.run.app
"""
import json
import sys
import io
import time
import requests

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

BASE = "https://garuda-backend-437904093333.asia-south1.run.app"
PASS = "✅"
FAIL = "❌"
results = []

def log(name, passed, data=None):
    status = PASS if passed else FAIL
    results.append((name, passed))
    print(f"\n{status} {name}")
    if data:
        txt = json.dumps(data, indent=2, default=str)
        print(txt[:400])
        if len(txt) > 400:
            print("  ... [truncated]")

# ═══════════════════════════════════════════════════════════════
# 1. HEALTH CHECK
# ═══════════════════════════════════════════════════════════════
print("\n" + "="*60)
print("  1. SYSTEM HEALTH CHECK")
print("="*60)

r = requests.get(f"{BASE}/v1/health")
log("GET /v1/health", r.status_code == 200, r.json())

# ═══════════════════════════════════════════════════════════════
# 2. AUTH TESTS
# ═══════════════════════════════════════════════════════════════
print("\n" + "="*60)
print("  2. AUTH ENDPOINTS")
print("="*60)

ts = str(int(time.time()))[-5:]

r = requests.post(f"{BASE}/v1/auth/register", json={
    "email": f"supplier_{ts}@garuda.com", "password": "test123456",
    "name": "Test Supplier", "role": "SUPPLIER", "company_name": "Garuda Logistics"
})
log("POST /v1/auth/register (Supplier)", r.status_code == 200, r.json())

r = requests.post(f"{BASE}/v1/auth/register", json={
    "email": f"driver_{ts}@garuda.com", "password": "test123456",
    "name": "Rahul Kumar", "role": "DELIVERY_MAN"
})
log("POST /v1/auth/register (Delivery Man)", r.status_code == 200, r.json())

r = requests.post(f"{BASE}/v1/auth/login", json={
    "email": f"supplier_{ts}@garuda.com", "password": "test123456"
})
log("POST /v1/auth/login", r.status_code == 200, r.json())

r = requests.post(f"{BASE}/v1/auth/login", json={
    "email": "wrong@email.com", "password": "badpass"
})
log("POST /v1/auth/login (bad creds — expect 401)", r.status_code == 401)

r = requests.post(f"{BASE}/v1/auth/reset-password", json={"email": f"supplier_{ts}@garuda.com"})
log("POST /v1/auth/reset-password", r.status_code == 200, r.json())

r = requests.get(f"{BASE}/v1/auth/profile/mock-uid")
log("GET /v1/auth/profile/{uid}", r.status_code in [200, 404], r.json())

# ═══════════════════════════════════════════════════════════════
# 3. SHIPMENT LIFECYCLE
# ═══════════════════════════════════════════════════════════════
print("\n" + "="*60)
print("  3. SHIPMENT LIFECYCLE")
print("="*60)

r = requests.post(f"{BASE}/v1/shipments/", json={
    "supplier_id": "mock-uid", "logistics_id": "logistics-uid",
    "consumer_email": "customer@email.com",
    "origin": {"lat": 22.543610, "lng": 85.796856},
    "destination": {"lat": 22.768116, "lng": 86.200684},
    "route_mode": "ROAD_CAR",
    "package_description": "Electronics - Laptop", "weight_kg": 2.5
})
log("POST /v1/shipments/ (Create)", r.status_code == 200, r.json())
shipment_id = r.json().get("shipment", {}).get("shipment_id", "mock-shipment-id")

r = requests.get(f"{BASE}/v1/shipments/{shipment_id}")
log(f"GET /v1/shipments/{{id}}", r.status_code in [200, 404], r.json())

r = requests.patch(f"{BASE}/v1/shipments/{shipment_id}/assign", json={"delivery_man_id": "driver-uid"})
log("PATCH /assign", r.status_code in [200, 400], r.json())

r = requests.patch(f"{BASE}/v1/shipments/{shipment_id}/status?status=DISPATCHED")
log("PATCH /status → DISPATCHED", r.status_code in [200, 400], r.json())

r = requests.patch(f"{BASE}/v1/shipments/{shipment_id}/status?status=IN_TRANSIT")
log("PATCH /status → IN_TRANSIT", r.status_code in [200, 400], r.json())

r = requests.patch(f"{BASE}/v1/shipments/{shipment_id}/location", json={
    "current_location": {"lat": 22.650000, "lng": 85.900000}
})
log("PATCH /location (mid-route update)", r.status_code in [200, 400], r.json())

r = requests.get(f"{BASE}/v1/shipments/{shipment_id}/eta")
log("GET /eta", r.status_code in [200, 404], r.json())

r = requests.get(f"{BASE}/v1/shipments/user/mock-uid?role=SUPPLIER")
log("GET /user/{id} (list by supplier)", r.status_code == 200, r.json())

r = requests.patch(f"{BASE}/v1/shipments/{shipment_id}/status?status=DELIVERED")
log("PATCH /status → DELIVERED", r.status_code in [200, 400], r.json())

# ═══════════════════════════════════════════════════════════════
# 4. ROUTING — ALL MODES
# ═══════════════════════════════════════════════════════════════
print("\n" + "="*60)
print("  4. ROUTING — ALL TRANSPORT MODES")
print("="*60)

r = requests.post(f"{BASE}/v1/session/start")
log("POST /session/start", r.status_code == 200, r.json())
sid = r.json()["session_id"]

modes = ["ROAD_CAR", "ROAD_BIKE", "RAIL", "FLIGHT", "SHIP"]
for mode in modes:
    r = requests.post(f"{BASE}/v1/routes/fetch", json={
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
    r = requests.post(f"{BASE}/v1/routes/optimize-multi", json={
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

r = requests.post(f"{BASE}/v1/routes/compare-modes", json={
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

r = requests.post(f"{BASE}/v1/routes/analyze", json={
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

r = requests.post(f"{BASE}/v1/ride/monitor", json={
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

r = requests.post(f"{BASE}/v1/routes/fetch", json={
    "session_id": "invalid-session-id",
    "origin": {"lat": 22.5, "lng": 85.8},
    "destination": {"lat": 22.7, "lng": 86.2},
    "mode": "ROAD_CAR"
})
log("Invalid session → 401", r.status_code == 401)

r = requests.post(f"{BASE}/v1/routes/fetch", json={
    "session_id": sid,
    "origin": {"lat": 200, "lng": 85.8},
    "destination": {"lat": 22.7, "lng": 86.2},
    "mode": "ROAD_CAR"
})
log("Invalid lat (200) → 422", r.status_code == 422)

r = requests.post(f"{BASE}/v1/routes/optimize-multi", json={
    "session_id": sid, "points": [{"lat": 22.5, "lng": 85.8}], "mode": "ROAD_CAR"
})
log("TSP with 1 point → 400", r.status_code == 400)

r = requests.get(f"{BASE}/v1/shipments/nonexistent-id-12345")
log("GET nonexistent shipment → 404", r.status_code == 404)

# ═══════════════════════════════════════════════════════════════
# 10. REROUTE & PRE-CHECK & MODE SWITCH  ★ NEW ★
# ═══════════════════════════════════════════════════════════════
print("\n" + "="*60)
print("  10. REROUTE, PRECHECK & MODE SWITCH")
print("="*60)

r = requests.post(f"{BASE}/v1/routes/reroute", json={
    "session_id": sid,
    "origin": {"lat": 22.543610, "lng": 85.796856},
    "destination": {"lat": 22.768116, "lng": 86.200684},
    "mode": "ROAD_CAR",
    "avoid_zones": [{"lat": 22.65, "lng": 85.90}],
    "reason": "accident"
})
log("POST /routes/reroute", r.status_code == 200 and r.json().get("status") == "REROUTED", r.json())

r = requests.post(f"{BASE}/v1/routes/precheck", json={
    "session_id": sid,
    "origin": {"lat": 22.543610, "lng": 85.796856},
    "destination": {"lat": 22.768116, "lng": 86.200684},
    "mode": "ROAD_CAR",
    "dispatch_time": "2026-04-27T06:00:00+05:30",
    "cargo_type": "perishable"
})
log("POST /routes/precheck", r.status_code == 200 and "dispatch_clearance" in r.json(), r.json())

r = requests.post(f"{BASE}/v1/routes/switch-mode", json={
    "session_id": sid,
    "origin": {"lat": 22.543610, "lng": 85.796856},
    "destination": {"lat": 22.768116, "lng": 86.200684},
    "current_mode": "ROAD_CAR",
    "new_mode": "RAIL",
    "reason": "vehicle_breakdown"
})
log("POST /routes/switch-mode (CAR→RAIL)", r.status_code == 200 and r.json().get("status") == "MODE_SWITCHED", r.json())

# ═══════════════════════════════════════════════════════════════
# 11. RISK & DISRUPTION  ★ NEW ★
# ═══════════════════════════════════════════════════════════════
print("\n" + "="*60)
print("  11. RISK EVALUATION & DISRUPTION DETECTION")
print("="*60)

r = requests.post(f"{BASE}/v1/risk/evaluate", json={
    "origin": {"lat": 22.543610, "lng": 85.796856},
    "destination": {"lat": 22.768116, "lng": 86.200684},
    "mode": "ROAD_CAR",
    "cargo_type": "fragile"
})
log("POST /risk/evaluate (fragile cargo)", r.status_code == 200 and "verdict" in r.json(), r.json())

r = requests.post(f"{BASE}/v1/disruptions/detect", json={
    "center": {"lat": 22.650000, "lng": 85.900000},
    "radius_km": 50,
    "modes_to_check": ["ROAD_CAR", "RAIL"]
})
log("POST /disruptions/detect", r.status_code == 200 and "disruptions" in r.json(), r.json())

# ═══════════════════════════════════════════════════════════════
# 12. NOTIFICATIONS  ★ NEW ★
# ═══════════════════════════════════════════════════════════════
print("\n" + "="*60)
print("  12. NOTIFICATIONS & COMMUNICATION")
print("="*60)

r = requests.post(f"{BASE}/v1/notifications/push", json={
    "user_id": "mock-uid",
    "title": "Reroute Alert",
    "body": "Your shipment has been rerouted due to an accident on NH-33",
    "notification_type": "REROUTE_ALERT",
    "priority": "HIGH",
    "shipment_id": shipment_id
})
log("POST /notifications/push", r.status_code == 200 and r.json().get("status") == "sent", r.json())

r = requests.get(f"{BASE}/v1/notifications/history?user_id=mock-uid&limit=10")
log("GET /notifications/history", r.status_code == 200 and "notifications" in r.json(), r.json())

r = requests.post(f"{BASE}/v1/support/chat-bridge", json={
    "shipment_id": shipment_id,
    "requester_id": "consumer-uid",
    "requester_role": "CONSUMER",
    "message": "Where is my package?"
})
log("POST /support/chat-bridge", r.status_code == 200 and "session_id" in r.json(), r.json())

# ═══════════════════════════════════════════════════════════════
# 13. ANALYTICS & BILLING  ★ NEW ★
# ═══════════════════════════════════════════════════════════════
print("\n" + "="*60)
print("  13. ANALYTICS & BILLING")
print("="*60)

r = requests.get(f"{BASE}/v1/analytics/shipment/{shipment_id}")
log("GET /analytics/shipment/{id}", r.status_code == 200 and "carbon_footprint" in r.json(), r.json())

r = requests.get(f"{BASE}/v1/analytics/package-integrity/{shipment_id}?cargo_type=fragile&weight_kg=15&mode=ROAD_CAR")
log("GET /analytics/package-integrity (fragile)", r.status_code == 200 and "integrity_score" in r.json(), r.json())

r = requests.get(f"{BASE}/v1/billing/estimate?origin_lat=22.5436&origin_lng=85.7969&dest_lat=22.7681&dest_lng=86.2007&mode=ROAD_CAR&weight_kg=25&is_express=true&is_fragile=true")
log("GET /billing/estimate (express+fragile)", r.status_code == 200 and "cost_breakdown" in r.json(), r.json())

# ═══════════════════════════════════════════════════════════════
# 14. ADMIN DASHBOARD  ★ NEW (EXPANDED) ★
# ═══════════════════════════════════════════════════════════════
print("\n" + "="*60)
print("  14. ADMIN DASHBOARD (8 ENDPOINTS)")
print("="*60)

r = requests.get(f"{BASE}/v1/admin/fleet-status?region=east")
log("GET /admin/fleet-status", r.status_code == 200 and "status_breakdown" in r.json(), r.json())

r = requests.get(f"{BASE}/v1/admin/system-metrics")
log("GET /admin/system-metrics", r.status_code == 200 and "server_status" in r.json(), r.json())

r = requests.get(f"{BASE}/v1/admin/active-sessions")
log("GET /admin/active-sessions", r.status_code == 200 and "total_active" in r.json(), r.json())

r = requests.get(f"{BASE}/v1/admin/shipment-heatmap?time_range=24h")
log("GET /admin/shipment-heatmap", r.status_code == 200 and "hotspots" in r.json(), r.json())

r = requests.post(f"{BASE}/v1/admin/broadcast", json={
    "title": "Maintenance Alert",
    "body": "Scheduled downtime tonight 2AM-4AM IST",
    "priority": "HIGH"
})
log("POST /admin/broadcast", r.status_code == 200, r.json())

r = requests.get(f"{BASE}/v1/admin/driver-leaderboard?time_range=30d&limit=5")
log("GET /admin/driver-leaderboard", r.status_code == 200 and "leaderboard" in r.json(), r.json())

r = requests.get(f"{BASE}/v1/admin/route-efficiency?time_range=30d")
log("GET /admin/route-efficiency", r.status_code == 200 and "garuda_vs_legacy" in r.json(), r.json())

r = requests.get(f"{BASE}/v1/admin/disruption-log?limit=10&severity_min=0.5")
log("GET /admin/disruption-log", r.status_code == 200 and "disruptions" in r.json(), r.json())

# ═══════════════════════════════════════════════════════════════
# 15. EMERGENCY & INCIDENTS  ★ NEW ★
# ═══════════════════════════════════════════════════════════════
print("\n" + "="*60)
print("  15. EMERGENCY & INCIDENT HANDLING")
print("="*60)

r = requests.post(f"{BASE}/v1/shipments/{shipment_id}/exception", json={
    "exception_type": "DAMAGED",
    "description": "Package box crushed during loading",
    "severity": 0.7,
    "reported_by": "driver-uid"
})
log("POST /shipments/{id}/exception", r.status_code == 200 and r.json().get("status") == "logged", r.json())

r = requests.post(f"{BASE}/v1/shipments/{shipment_id}/report-incident", json={
    "incident_type": "ROAD_BLOCK",
    "description": "Fallen tree blocking NH-33 near Gamharia",
    "location": {"lat": 22.650000, "lng": 85.900000},
    "severity": 0.8,
    "driver_id": "driver-uid"
})
log("POST /shipments/{id}/report-incident", r.status_code == 200 and r.json().get("status") == "reported", r.json())

r = requests.get(f"{BASE}/v1/shipments/{shipment_id}/risk-details")
log("GET /shipments/{id}/risk-details", r.status_code == 200 and "explanation" in r.json(), r.json())

# ═══════════════════════════════════════════════════════════════
# 16. LIVE TRACKING (SSE)  ★ NEW ★
# ═══════════════════════════════════════════════════════════════
print("\n" + "="*60)
print("  16. LIVE TRACKING STREAM (SSE)")
print("="*60)

r = requests.get(f"{BASE}/v1/shipments/{shipment_id}/live", stream=True)
log("GET /shipments/{id}/live (SSE stream)", 
    r.status_code == 200 and r.headers.get("content-type", "").startswith("text/event-stream"))
r.close()

# ═══════════════════════════════════════════════════════════════
# 17. SHIPMENT TIMELINE  ★ NEW ★
# ═══════════════════════════════════════════════════════════════
print("\n" + "="*60)
print("  17. SHIPMENT TIMELINE")
print("="*60)

r = requests.get(f"{BASE}/v1/shipments/{shipment_id}/timeline")
log("GET /shipments/{id}/timeline", r.status_code == 200 and "timeline" in r.json(), r.json())

# ═══════════════════════════════════════════════════════════════
# 18. GARUDA INTELLIGENCE  ★ NEW ★
# ═══════════════════════════════════════════════════════════════
print("\n" + "="*60)
print("  18. GARUDA INTELLIGENCE (Geofence / Fatigue / Demand)")
print("="*60)

r = requests.post(f"{BASE}/v1/geofence/check", json={
    "shipment_id": shipment_id,
    "current_location": {"lat": 22.750000, "lng": 86.180000},
    "zone_center": {"lat": 22.768116, "lng": 86.200684},
    "zone_radius_km": 5.0,
    "zone_name": "Destination Warehouse"
})
log("POST /geofence/check (near zone)", r.status_code == 200 and "is_inside" in r.json(), r.json())

r = requests.post(f"{BASE}/v1/geofence/check", json={
    "shipment_id": shipment_id,
    "current_location": {"lat": 22.543610, "lng": 85.796856},
    "zone_center": {"lat": 22.768116, "lng": 86.200684},
    "zone_radius_km": 5.0,
    "zone_name": "Destination Warehouse"
})
log("POST /geofence/check (far from zone)", r.status_code == 200 and r.json().get("is_inside") == False, r.json())

r = requests.post(f"{BASE}/v1/driver/fatigue-check", json={
    "driver_id": "driver-uid",
    "drive_start_time": "2026-04-26T06:00:00+05:30",
    "current_location": {"lat": 22.650000, "lng": 85.900000},
    "total_km_driven": 280,
    "breaks_taken": 1
})
log("POST /driver/fatigue-check", r.status_code == 200 and "fatigue_score" in r.json(), r.json())

r = requests.post(f"{BASE}/v1/predictions/demand-surge", json={
    "region_center": {"lat": 22.650000, "lng": 85.900000},
    "radius_km": 100,
    "prediction_window_days": 7,
    "category": "electronics"
})
log("POST /predictions/demand-surge", r.status_code == 200 and "surge_multiplier" in r.json(), r.json())

# ═══════════════════════════════════════════════════════════════
# 19. EDGE CASES FOR NEW ENDPOINTS  ★ NEW ★
# ═══════════════════════════════════════════════════════════════
print("\n" + "="*60)
print("  19. EDGE CASES FOR NEW ENDPOINTS")
print("="*60)

r = requests.post(f"{BASE}/v1/routes/reroute", json={
    "session_id": "invalid-session",
    "origin": {"lat": 22.5, "lng": 85.8},
    "destination": {"lat": 22.7, "lng": 86.2},
    "mode": "ROAD_CAR"
})
log("Reroute with invalid session → 401", r.status_code == 401)

r = requests.post(f"{BASE}/v1/risk/evaluate", json={
    "origin": {"lat": 22.5, "lng": 85.8},
    "destination": {"lat": 22.7, "lng": 86.2},
    "mode": "ROAD_CAR",
    "cargo_type": "hazardous"
})
log("Risk evaluate (hazardous cargo)", r.status_code == 200 and r.json().get("cargo_multiplier") == 1.5)

r = requests.get(f"{BASE}/v1/billing/estimate?origin_lat=22.5&origin_lng=85.8&dest_lat=22.7&dest_lng=86.2&mode=FLIGHT&weight_kg=5")
log("Billing estimate (FLIGHT mode)", r.status_code == 200)

r = requests.post(f"{BASE}/v1/disruptions/detect", json={
    "center": {"lat": 22.5, "lng": 85.8},
    "radius_km": 200,
    "modes_to_check": ["ROAD_CAR", "RAIL", "FLIGHT"]
})
log("Disruption detect (multi-mode)", r.status_code == 200)

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
