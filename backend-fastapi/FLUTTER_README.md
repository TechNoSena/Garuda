# 🦅 Project Garuda: Flutter Developer's Handbook

Welcome to the mission control for Project Garuda. This document is your complete technical blueprint for connecting the Flutter frontend to our AI-driven logistics backend.

---

## 💎 Premium API Documentation (Scalar)
Forget old-school Swagger. We use **Scalar** for a modern, high-tech API testing experience.
👉 **Docs URL:** `http://localhost:8000/scalar`

*Features: Dark Mode, Code Snippet Generation (Dart/HTTP/cURL), and live request testing.*

---

## 🛠️ Connectivity & Environment
| Platform | Base URL |
|---|---|
| Android Emulator | `http://10.0.2.2:8000` |
| iOS Simulator / Web | `http://localhost:8000` |

**Headers:** All requests require `Content-Type: application/json`.

---

## 📋 Complete API Reference

### 🔐 Auth
| Method | Endpoint | Purpose |
|---|---|---|
| `POST` | `/v1/auth/register` | Register new user (SUPPLIER / LOGISTICS / DELIVERY_MAN / CONSUMER) |
| `POST` | `/v1/auth/login` | Login → returns Firebase `idToken` + user profile with `role` |
| `POST` | `/v1/auth/reset-password` | Send password reset email |
| `GET` | `/v1/auth/profile/{uid}` | Fetch user profile from Firestore |

### 📦 Shipments
| Method | Endpoint | Purpose |
|---|---|---|
| `POST` | `/v1/shipments/` | Create shipment (origin, destination, mode, package info) |
| `GET` | `/v1/shipments/{id}` | Get full shipment details + current location |
| `GET` | `/v1/shipments/{id}/eta` | Live ETA calculation based on current location & mode |
| `GET` | `/v1/shipments/user/{uid}?role=SUPPLIER` | List all shipments for a user by role |
| `PATCH` | `/v1/shipments/{id}/assign` | Assign a delivery man |
| `PATCH` | `/v1/shipments/{id}/status?status=IN_TRANSIT` | Update shipment status |
| `PATCH` | `/v1/shipments/{id}/location` | Ping GPS location (every 5-10 mins) |

### 🧠 Routing Intelligence
| Method | Endpoint | Purpose |
|---|---|---|
| `POST` | `/v1/session/start` | Start a new routing session (returns `session_id`) |
| `POST` | `/v1/routes/fetch` | Get optimal routes for a transport mode |
| `POST` | `/v1/routes/optimize-multi` | Multi-stop TSP — reorders waypoints for fastest delivery |
| `POST` | `/v1/routes/analyze` | AI Risk Analysis (Gemini + Google Search grounding) |
| `POST` | `/v1/routes/compare-modes` | Side-by-side Cost / ETA / CO₂ across all 5 modes |
| `POST` | `/v1/ride/monitor` | Live ride polling — returns `REROUTE_SUGGESTED` if hazard detected |
| `GET` | `/v1/health` | System health check (Firebase + Vertex AI status) |

---

## 🌊 Workflows by User Role

### 1. 🏗️ Supplier (The Originator)
- Register → Login → Create Shipment → Track via `GET /shipments/{id}` or `/eta`
- Use `GET /shipments/user/{uid}?role=SUPPLIER` to see all their shipments

### 2. 🚛 Logistics Partner (The Orchestrator)
- View pending shipments → Assign delivery man via `PATCH /assign`
- Use `POST /routes/compare-modes` to pick the best transport mode
- Use `POST /routes/analyze` to check risk before dispatching

### 3. 🛵 Delivery Man (The Executor)
- Get optimized delivery order: `POST /routes/optimize-multi` (send 10 stops, get them reordered)
- During delivery: ping `PATCH /shipments/{id}/location` every 5-10 mins via background service
- Poll `POST /ride/monitor` periodically — if response is `REROUTE_SUGGESTED`, show a high-priority overlay and redraw the map

### 4. 👤 Consumer (The Receiver)
- Track package: `GET /shipments/{id}` — shows `current_location` and `status`
- Get live ETA: `GET /shipments/{id}/eta`
- Status lifecycle: `PENDING → ASSIGNED → DISPATCHED → IN_TRANSIT → OUT_FOR_DELIVERY → DELIVERED`

---

## 🧠 AI Risk Verdicts
The `/routes/analyze` endpoint returns a 3-tier verdict:

| Verdict | Risk Score | Meaning |
|---|---|---|
| `SAFE` | 0–39 | All clear, proceed normally |
| `CAUTION` | 40–64 | Minor risks detected, monitor closely |
| `HIGH_RISK` | 65–100 | Severe hazard — trigger reroute |

**UI Suggestion:** Use a Glassmorphic Card to show the `heads_up` message before the driver clicks "Start Navigation".

---

## 📍 Flutter Integration Tips

### 1. Decoding Polylines
```dart
// Use the 'flutter_polyline_points' package
PolylinePoints polylinePoints = PolylinePoints();
List<PointLatLng> result = polylinePoints.decodePolyline(encodedString);
```

### 2. Background Location Updates
Use `flutter_background_service` to ensure location pings continue when the app is backgrounded.

### 3. State Management
Use **Riverpod** or **Bloc** to handle the shipment status lifecycle. Listen for `REROUTE_SUGGESTED` events to trigger a local notification or alert sound.

### 4. Compare Modes UI
The `/routes/compare-modes` endpoint returns `estimated_cost_inr`, `estimated_co2_g`, and `estimated_duration_mins` for each mode. Build a comparison card UI sorted by fastest/cheapest/greenest.

---

## 🚥 API Status Codes
| Code | Meaning |
|---|---|
| `200` | Success |
| `400` | Validation error (bad input) |
| `401` | Invalid session or auth token |
| `404` | Resource not found |
| `422` | Invalid coordinates (lat/lng out of range) |

---