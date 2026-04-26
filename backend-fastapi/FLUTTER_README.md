# 🦅 Garuda Logistics API - Flutter Integration Guide

Welcome to the Garuda Backend API! This guide is designed specifically for the Flutter frontend developer to easily connect the mobile app to our Python FastAPI backend.

The backend is a **Full Omnichannel Logistics Management System** with live Firebase integration and real-time AI Risk Intelligence.

---

## 🚀 Getting Started

**Base URL (Local Testing):** `http://10.0.2.2:8000` (for Android Emulator) or `http://localhost:8000` (for iOS Simulator / Web)

### Interactive API Docs (Swagger)
When the backend is running, you can view the interactive documentation and test payloads directly at:
👉 `http://localhost:8000/docs`

---

## 👥 User Roles
The app will have 4 main types of users. You should handle UI routing based on the `role` returned during login:
1. `SUPPLIER`: Creates shipments and tracks them.
2. `LOGISTICS`: Assigns delivery men and views optimal pathways.
3. `DELIVERY_MAN`: Uses the app to navigate (Multi-stop) and updates live locations.
4. `CONSUMER`: Tracks their package using a Tracking ID.

---

## 🔐 1. Authentication Endpoints

### Register User
`POST /v1/auth/register`
```json
// Request
{
  "email": "driver@garuda.com",
  "password": "securepassword",
  "name": "Rahul Kumar",
  "role": "DELIVERY_MAN", // SUPPLIER | LOGISTICS | DELIVERY_MAN | CONSUMER
  "company_name": "Optional"
}
// Response -> Returns User Data & UID
```

### Login User
`POST /v1/auth/login`
```json
// Request
{
  "email": "driver@garuda.com",
  "password": "securepassword"
}
// Response -> Returns Firebase idToken (save this securely in Flutter Secure Storage)
```

---

## 📦 2. Shipment Management

### Create Shipment (Supplier Action)
`POST /v1/shipments/`
```json
// Request
{
  "supplier_id": "uid_of_supplier",
  "logistics_id": "uid_of_logistics_company",
  "consumer_email": "consumer@email.com",
  "origin": {"lat": 22.543610, "lng": 85.796856},
  "destination": {"lat": 22.768116, "lng": 86.200684},
  "route_mode": "ROAD_CAR" // ROAD_CAR, ROAD_BIKE, RAIL, FLIGHT, SHIP
}
// Response -> Returns the `shipment_id` (Tracking ID)
```

### Track/Get Shipment
`GET /v1/shipments/{shipment_id}`
Returns all details about the shipment, including `current_location` and `status` (`PENDING`, `ASSIGNED`, `DISPATCHED`, `IN_TRANSIT`, `DELIVERED`).

### Update Live Location (Delivery Man Action)
`PATCH /v1/shipments/{shipment_id}/location`
```json
// Request (Triggered by Flutter's background location service)
{
  "current_location": {"lat": 22.650000, "lng": 85.900000}
}
```

---

## 🗺️ 3. Routing & Intelligence (Core Features)

Before using these, hit `POST /v1/session/start` to get a `session_id`. Pass this `session_id` in all routing requests.

### Fetch Best Routes
`POST /v1/routes/fetch`
Pass `session_id`, `origin`, `destination`, and `mode`. Returns a list of Google Maps polylines, distances, and times.

### Deep Risk Analysis (AI Intelligence)
`POST /v1/routes/analyze`
Pass the selected route data. The backend will use Gemini to crawl the web for live weather, protests, and traffic, and return a `RiskScore` along with a custom **Heads-Up** message (e.g., "Carry a raincoat").
*Show this Heads-Up prominently in the UI before they start the ride.*

### Multi-Stop Optimization (Traveling Salesman Problem)
`POST /v1/routes/optimize-multi`
If a delivery man has 10 packages to drop off, send an array of 10 `LatLng` points. The backend will return them completely reordered for the fastest delivery time!

### Live Ride Monitoring (Active Trip)
`POST /v1/ride/monitor`
While the delivery man is driving, ping this every 5-10 minutes. 
```json
// Request
{
  "session_id": "uuid",
  "current_location": {"lat": ..., "lng": ...},
  "destination": {"lat": ..., "lng": ...},
  "mode": "ROAD_CAR"
}
```
**Handling the Response in Flutter:**
If the backend detects a sudden severe roadblock or extreme weather, it will return `"status": "REROUTE_SUGGESTED"`. Your Flutter app should immediately trigger a warning dialog and redraw the map with the `new_route` provided in the response!

---

## 🛠️ Important Notes for Flutter
1. **Google Maps UI**: The backend returns raw `polyline` strings. You will need to decode these strings in Flutter (using a package like `flutter_polyline_points`) to draw the actual blue line on your `GoogleMap` widget.
2. **Tokens**: Currently, auth endpoints return standard Firebase structures. Handle the token expiry locally or use the Firebase Flutter SDK alongside the backend for seamless state management.