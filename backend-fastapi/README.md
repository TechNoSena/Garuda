<div align="center">

  # ⚙️ Garuda Backend — FastAPI Orchestration Engine

  [![Deployed on Cloud Run](https://img.shields.io/badge/Deployed_on-Google_Cloud_Run-4285F4?style=flat-square&logo=google-cloud&logoColor=white)](https://garuda-backend-437904093333.asia-south1.run.app/scalar)
  [![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=flat-square&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com/)
  [![Gemini 2.5 Pro](https://img.shields.io/badge/Gemini_2.5_Pro-EA4335?style=flat-square&logo=googlegemini&logoColor=white)](https://deepmind.google/technologies/gemini/)

  **Live API Docs:** [garuda-backend-437904093333.asia-south1.run.app/scalar](https://garuda-backend-437904093333.asia-south1.run.app/scalar)

</div>

---

## 🏗️ Architecture

The backend is a **FastAPI** application deployed on **Google Cloud Run**. It acts as the central orchestration layer, connecting the Flutter frontend to Google's AI, Maps, and Firebase services via an **Agentic RAG** pipeline.

```
backend-fastapi/
├── main.py                    # FastAPI entry point & CORS config
├── Dockerfile                 # Cloud Run container build
├── cloudbuild.yaml            # Google Cloud Build CI/CD pipeline
├── requirements.txt           # Python dependencies
└── app/
    ├── config.py              # Environment & API key management
    ├── models.py              # Pydantic request/response schemas
    ├── routers/               # API endpoint handlers
    │   ├── auth.py            # Authentication & user management
    │   ├── shipments.py       # CRUD, status updates, assignment
    │   ├── routing.py         # Route computation, precheck, rerouting
    │   ├── intelligence.py    # AI-powered ride monitoring & risk analysis
    │   ├── risk.py            # Risk scoring & disruption detection
    │   ├── analytics.py       # Fleet analytics & performance metrics
    │   ├── notifications.py   # Push notification dispatch
    │   └── admin.py           # Admin operations & system management
    └── services/              # Core business logic
        ├── gemini_service.py       # Gemini 2.5 Pro integration (RAG, XAI)
        ├── firebase_service.py     # Firestore CRUD & Firebase Auth
        ├── routing_strategy.py     # Google Routes API & TSP solver
        └── notification_service.py # Notification dispatch service
```

---

## 🔌 API Endpoints

### 🔐 Authentication (`/v1/auth`)
| Method | Endpoint | Description |
|:---|:---|:---|
| `POST` | `/v1/auth/register` | Register new user with role assignment |
| `POST` | `/v1/auth/login` | Authenticate and receive session token |

### 📦 Shipments (`/v1/shipments`)
| Method | Endpoint | Description |
|:---|:---|:---|
| `POST` | `/v1/shipments/` | Create new shipment (origin/dest lat/lng) |
| `GET` | `/v1/shipments/{id}` | Get shipment by ID with live status |
| `GET` | `/v1/shipments/user/{uid}` | Get all shipments for a user (role-filtered) |
| `PATCH` | `/v1/shipments/{id}/assign` | Assign driver to shipment |
| `PATCH` | `/v1/shipments/{id}/status` | Update shipment status |
| `PATCH` | `/v1/shipments/{id}/location` | Update live GPS coordinates |
| `GET` | `/v1/shipments/{id}/risk-details` | AI-generated risk breakdown & explanation |

### 🗺️ Routing (`/v1/routes`)
| Method | Endpoint | Description |
|:---|:---|:---|
| `POST` | `/v1/routes/precheck` | Pre-flight risk assessment before dispatch |
| `POST` | `/v1/routes/compute` | Compute optimal route with waypoints |
| `POST` | `/v1/routes/reroute` | Trigger reroute with `avoid_waypoints` |
| `POST` | `/v1/routes/compare-modes` | Compare transport mode cost/time/carbon |

### 🧠 Intelligence (`/v1/ride`)
| Method | Endpoint | Description |
|:---|:---|:---|
| `POST` | `/v1/ride/monitor` | Continuous AI monitoring (called every 5 min) |
| `POST` | `/v1/ride/explain` | Generate XAI explanation for delay/reroute |

### 📊 Analytics (`/v1/analytics`)
| Method | Endpoint | Description |
|:---|:---|:---|
| `GET` | `/v1/analytics/fleet` | Fleet performance metrics |
| `GET` | `/v1/analytics/delays` | Historical delay pattern analysis |

### 🔔 Notifications (`/v1/notifications`)
| Method | Endpoint | Description |
|:---|:---|:---|
| `POST` | `/v1/notifications/send` | Push notification to stakeholders |

---

## 🧠 Core Services

### Gemini Service (`gemini_service.py`)
The heart of Garuda's intelligence. Integrates with **Gemini 2.5 Pro** to:
- Parse unstructured text (news, weather alerts) into structured risk assessments
- Generate numerical **Risk Scores (0–100)** with severity classification
- Produce **Explainable AI** natural-language explanations for all decisions
- Power the Agentic RAG pipeline with contextual reasoning

### Firebase Service (`firebase_service.py`)
Handles all Firestore CRUD operations and Firebase Authentication:
- Shipment creation, updates, and real-time status tracking
- User management with role-based access control
- Live GPS coordinate persistence for driver tracking

### Routing Strategy (`routing_strategy.py`)
Integrates with **Google Routes API** for:
- Optimal route computation with waypoint extraction
- Alternate path generation using `avoid_waypoints` for rerouting
- Multi-stop TSP optimization for last-mile delivery
- Transport mode comparison (cost, time, carbon)

---

## 🚀 Local Development

```bash
# 1. Create and activate virtual environment
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate

# 2. Install dependencies
pip install -r requirements.txt

# 3. Configure environment variables
cp .env.example .env
# Required: PROJECT_ID, GOOGLE_MAPS_KEY, FIREBASE_WEB_API_KEY, GEMINI_API_KEY

# 4. Run the development server
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

API docs will be available at `http://localhost:8000/scalar`

---

## ☁️ Deployment

The backend auto-deploys to **Google Cloud Run** via `cloudbuild.yaml`:

```bash
gcloud builds submit --config cloudbuild.yaml
```

**Live Production URL:** `https://garuda-backend-437904093333.asia-south1.run.app/scalar`

---

<div align="center">

  *Part of **Project Garuda** · Google Solution Challenge 2026 · Team DietCoke*

</div>
