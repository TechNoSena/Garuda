<div align="center">

  # 📱 Garuda Flutter App — Omnichannel Logistics Platform

  [![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev/)
  [![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat-square&logo=dart&logoColor=white)](https://dart.dev/)
  [![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=flat-square&logo=firebase&logoColor=black)](https://firebase.google.com/)

  **4 Roles · 1 Codebase · Native Performance**

</div>

---

## 🎯 Overview

A single Flutter codebase powering **four distinct stakeholder portals** with role-based access control, real-time GPS tracking, and AI-driven reroute overlays.

---

## 👥 Role-Based Portals

### 🏭 Supplier Portal
- Create new shipments with Google Places autocomplete
- Pre-flight risk assessment before dispatch
- Compare transport modes (cost / time / carbon)
- View shipment history and analytics

### 🏢 Logistics Admin Portal
- Fleet management dashboard
- Assign drivers to pending shipments
- Active alerts heatmap
- Performance analytics and delay reports

### 🚚 Delivery Driver Portal
- Live navigation with Google Maps
- Real-time AI reroute alerts with overlay
- Start / complete ride lifecycle
- Report on-road incidents and exceptions

### 👤 Consumer Portal
- Track shipments via tracking ID
- Live map with driver GPS position
- Dynamic ETA updates
- "Why is this delayed?" — AI explanations

---

## 🎨 Design System — FunkyBox

The app uses a custom **FunkyBox** brutalist-modern design system with:
- Theme-aware dark / light mode transitions
- Offset shadow cards with vibrant accent borders
- Smooth micro-animations and shimmer loading states
- Consistent spacing, typography, and color tokens

---

## 📁 Architecture

```
lib/
├── main.dart                    # Entry point, Firebase init, providers
├── app.dart                     # App shell, routing, theme switching
│
├── core/                        # Shared infrastructure
│   ├── models/                  # Data models (Shipment, User, Route)
│   ├── providers/               # Riverpod state management
│   │   ├── shipment_provider    # Shipment CRUD & status
│   │   ├── intelligence_provider # AI risk & monitoring
│   │   └── analytics_provider   # Fleet metrics
│   ├── services/                # API client, auth service
│   ├── theme/                   # FunkyBox theme data & tokens
│   └── widgets/                 # Reusable components
│       ├── funky_box.dart       # Core design system widget
│       ├── live_map_widget.dart  # Google Maps integration
│       ├── loading_shimmer.dart  # Skeleton loading states
│       └── status_timeline.dart  # Shipment status tracker
│
└── features/                    # Role-specific screens
    ├── auth/                    # Login & registration
    ├── supplier/                # Shipment creation, analytics
    ├── logistics/               # Fleet dashboard, driver assignment
    ├── delivery/                # Active ride, AI overlay
    ├── consumer/                # Tracking, ETA, explanations
    └── shared/                  # Cross-role (chat, settings)
```

---

## 🔌 Backend Integration

All API calls go through a centralized API service connecting to the FastAPI backend:

| Feature | Endpoint | Method |
|:---|:---|:---|
| Create Shipment | `/v1/shipments/` | `POST` |
| Track Shipment | `/v1/shipments/{id}` | `GET` |
| Pre-flight Check | `/v1/routes/precheck` | `POST` |
| AI Ride Monitor | `/v1/ride/monitor` | `POST` |
| Risk Explanation | `/v1/shipments/{id}/risk-details` | `GET` |
| Update Location | `/v1/shipments/{id}/location` | `PATCH` |

---

## 🚀 Getting Started

```bash
# Install dependencies
flutter pub get

# Run on device/emulator
flutter run

# Build release APK
flutter build apk --release
```

---

## 🔑 Demo Accounts

| Role | Email | Password |
|:---|:---|:---|
| 🏭 Supplier | `demos@gmail.com` | `demo1234` |
| 🏢 Logistics | `demolp@gmail.com` | `demo1234` |
| 🚚 Driver | `demodm@gmail.com` | `demo1234` |
| 👤 Consumer | `democ@gmail.com` | `demo1234` |

---

<div align="center">

  *Part of **Project Garuda** · Google Solution Challenge 2026 · Team DietCoke*

</div>
