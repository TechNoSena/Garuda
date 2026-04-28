# 📝 Changelog

All notable changes to **Project Garuda** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0-beta] — 2026-04-28

### 🚀 Initial Beta Release

#### ✨ Added
- **Multi-Role Flutter App** — Unified application with 4 portals: Supplier, Logistics Partner, Delivery Driver, Consumer
- **Agentic RAG Engine** — Continuous 5-minute monitoring cycle fusing live news, weather, and historical data for risk scoring
- **Preemptive Rerouting** — Auto-triggers `avoid_waypoints` via Google Routes API when risk score crosses critical threshold (≥65)
- **Explainable AI (XAI)** — Gemini 2.5 Pro generates plain-language explanations for all reroute decisions
- **Omni-Modal Support** — Coverage across Air, Maritime, Rail, Road, and Last-Mile transport
- **Pre-flight Risk Check** — Suppliers can assess route risk before dispatching shipments
- **Live GPS Tracking** — Real-time driver location streaming via Firestore + SSE
- **Consumer Tracking Portal** — Live map, dynamic ETA, and AI delay explanations
- **Driver Incident Reporting** — On-road hazard and exception logging
- **TSP Last-Mile Optimization** — Multi-stop route optimization for delivery drivers
- **Firebase Auth** — Role-based access control across all 4 user portals
- **FunkyBox Design System** — Brutalist-modern UI with theme-aware dark/light mode
- **CI/CD Pipeline** — Automated APK builds via GitHub Actions on every push to master

#### 🏗️ Infrastructure
- FastAPI backend deployed on **Google Cloud Run** (auto-scaling, serverless)
- **BigQuery** data warehouse for historical delay analysis
- **Vertex AI** for predictive demand surge modeling
- **Google Programmable Search API** for live RAG retrieval
- **Cloud Firestore** for real-time data synchronization

#### 🌱 SDG Alignment
- SDG 9 — Resilient AI-driven logistics infrastructure
- SDG 11 — Urban congestion reduction via intelligent fleet routing
- SDG 13 — Up to 13.6% fuel consumption reduction

---

<div align="center">

  *Maintained by **Team DietCoke** · Google Solution Challenge 2026*

</div>
