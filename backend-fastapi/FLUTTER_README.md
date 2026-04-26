# 🦅 Project Garuda: Flutter Developer's Handook

Welcome to the mission control for Project Garuda. This document is your technical blueprint for connecting the Flutter frontend to our high-performance, AI-driven logistics backend.

---

## 💎 Premium API Documentation (Scalar)
Forget old-school Swagger. We use **Scalar** for a modern, high-tech API testing experience.
👉 **Docs URL:** `http://localhost:8000/scalar`
*Features: Dark Mode, Code Snippet Generation (Dart/HTTP), and live request testing.*

---

## 🛠️ Connectivity & Environment
- **Base URL (Local Android):** `http://10.0.2.2:8000`
- **Base URL (iOS/Web):** `http://localhost:8000`
- **Headers:** All private requests require `Content-Type: application/json`. Auth headers should be passed as `Authorization: Bearer <idToken>`.

---

## 🌊 Core Workflows by User Role

### 1. 🏗️ Supplier (The Originator)
- **Goal:** Create and monitor orders.
- **Key API:** `POST /v1/shipments/`
- **Workflow:** 
  - Input origin/destination coordinates.
  - Select mode (ROAD, RAIL, FLIGHT).
  - Backend returns a `shipment_id`. Save this!

### 2. 🚛 Logistics Partner (The Orchestrator)
- **Goal:** Assign delivery personnel and optimize fleets.
- **Key API:** `PATCH /v1/shipments/{id}/assign`
- **Workflow:**
  - View all `PENDING` shipments.
  - Assign a `delivery_man_id` from your team.

### 3. 🛵 Delivery Man (The Executor)
- **Goal:** Navigate efficiently and update status.
- **Key API:** `POST /v1/routes/optimize-multi`
- **Workflow:**
  - Send a list of 10 stops. Backend returns them in the **optimal order (TSP)**.
  - PING `PATCH /v1/shipments/{id}/location` every 5-10 minutes via background service.
  - **Live Monitoring:** Call `POST /v1/ride/monitor` periodically. If response is `REROUTE_SUGGESTED`, show a high-priority overlay in Flutter to recalculate the path.

### 4. 👤 Consumer (The Receiver)
- **Goal:** Track package in real-time.
- **Key API:** `GET /v1/shipments/{id}`
- **Workflow:**
  - Poll this endpoint to update the package icon on the map.
  - Display the `status` (`IN_TRANSIT`, `DELIVERED`, etc.) prominently.

---

## 🧠 AI Intelligence: Risk Analysis
Before starting any journey, call:
`POST /v1/routes/analyze`
**Response Payload:**
- `verdict`: "SAFE" or "CAUTION"
- `analysis.heads_up`: "Specific AI advice" (e.g., "Heavy rain at Toll Plaza 3, carry extra fuel.")
- `analysis.final_risk_score`: 0-100%

*UI Suggestion: Use a Glassmorphic Card to show the 'Heads-Up' before the driver clicks "Start Navigation".*

---

## 📍 Flutter Integration Tips

### 1. Decoding Polylines
The backend returns encoded polylines (from Google Routes API).
```dart
// Use the 'flutter_polyline_points' package
PolylinePoints polylinePoints = PolylinePoints();
List<PointLatLng> result = polylinePoints.decodePolyline(encodedString);
```

### 2. Background Tasks
For the Delivery Man app, use `flutter_background_service` to ensure location updates continue even when the phone is in the driver's pocket.

### 3. State Management
- Use **Riverpod** or **Bloc** to handle the Shipment status lifecycle.
- Listen for `REROUTE_SUGGESTED` events to trigger a local notification or sound alert.

---

## 🚥 API Status Codes
- `200 OK`: Request successful.
- `400 Bad Request`: Validation error (check your Lat/Lng formats).
- `401 Unauthorized`: Session expired or invalid token.
- `404 Not Found`: Shipment ID doesn't exist.

---