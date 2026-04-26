"""Admin Dashboard Router — Garuda Platform (Expanded)"""
from fastapi import APIRouter, HTTPException, Query
from datetime import datetime, timezone
from app.models import AdminBroadcastRequest
from app.services.firebase_service import get_fleet_status
from app.services.notification_service import send_push_notification
from app.models import PushNotificationRequest, NotificationType, NotificationPriority

router = APIRouter(prefix="/v1/admin", tags=["🏢 Administration"])

# In-memory stores for demo (production → Redis/DB)
_disruption_log = []
_system_start_time = datetime.now(timezone.utc)


@router.get("/fleet-status", summary="Fleet Status Overview",
            description="Bird's-eye view of all fleet vehicles — In Transit / Idle / Breakdown counts across city or region")
async def fleet_status(region: str = Query("all", description="Region filter: all, north, south, east, west, or city name")):
    return get_fleet_status(region)


@router.get("/system-metrics", summary="System Performance Metrics",
            description="Server health, API call stats, active sessions, memory usage — the ops dashboard")
async def system_metrics():
    import sys
    uptime_seconds = (datetime.now(timezone.utc) - _system_start_time).total_seconds()
    
    # Import active sessions count from routing module
    try:
        from app.routers.routing import active_sessions
        session_count = len(active_sessions)
    except:
        session_count = 0

    return {
        "server_status": "HEALTHY",
        "uptime_seconds": round(uptime_seconds, 1),
        "uptime_human": f"{int(uptime_seconds // 3600)}h {int((uptime_seconds % 3600) // 60)}m {int(uptime_seconds % 60)}s",
        "python_version": sys.version.split()[0],
        "active_sessions": session_count,
        "api_stats": {
            "total_endpoints": 35,
            "avg_response_time_ms": 142,
            "requests_last_hour": 1847,
            "error_rate_pct": 0.3,
            "peak_rps": 45
        },
        "infrastructure": {
            "cpu_usage_pct": 34.2,
            "memory_usage_mb": 256,
            "disk_usage_pct": 18.7,
            "db_connections_active": 5,
            "db_connections_pool": 20
        },
        "ai_engine": {
            "gemini_model": "gemini-2.5-flash",
            "ai_calls_today": 234,
            "avg_ai_latency_ms": 1850,
            "grounding_enabled": True
        },
        "timestamp": datetime.now(timezone.utc).isoformat()
    }


@router.get("/active-sessions", summary="Active Routing Sessions",
            description="List all currently active routing sessions with their creation time and context")
async def list_active_sessions():
    try:
        from app.routers.routing import active_sessions
        sessions = []
        for sid, data in active_sessions.items():
            sessions.append({
                "session_id": sid,
                "created_at": data.get("created_at"),
                "context_keys": list(data.get("context", {}).keys()),
                "status": "ACTIVE"
            })
        return {
            "total_active": len(sessions),
            "sessions": sessions,
            "timestamp": datetime.now(timezone.utc).isoformat()
        }
    except Exception as e:
        return {"total_active": 0, "sessions": [], "error": str(e)}


@router.get("/shipment-heatmap", summary="Shipment Heatmap Data",
            description="Heatmap data of shipment origins and destinations — for geographic demand visualization")
async def shipment_heatmap(
    time_range: str = Query("24h", description="Time range: 1h, 6h, 24h, 7d, 30d")
):
    # Simulated heatmap data (in production, aggregate from Firestore)
    return {
        "time_range": time_range,
        "total_shipments": 342,
        "hotspots": [
            {"location": {"lat": 22.5726, "lng": 88.3639}, "city": "Kolkata", "count": 87, "intensity": 0.92},
            {"location": {"lat": 22.7196, "lng": 85.8763}, "city": "Jamshedpur", "count": 64, "intensity": 0.78},
            {"location": {"lat": 23.3441, "lng": 85.3096}, "city": "Ranchi", "count": 52, "intensity": 0.65},
            {"location": {"lat": 22.8046, "lng": 86.2029}, "city": "Ghatsila", "count": 45, "intensity": 0.58},
            {"location": {"lat": 21.4934, "lng": 86.9135}, "city": "Balasore", "count": 38, "intensity": 0.48},
            {"location": {"lat": 20.2961, "lng": 85.8245}, "city": "Bhubaneswar", "count": 56, "intensity": 0.71}
        ],
        "origin_clusters": 12,
        "destination_clusters": 15,
        "peak_corridor": {
            "from": "Jamshedpur",
            "to": "Kolkata",
            "daily_avg": 23
        }
    }


@router.post("/broadcast", summary="Broadcast Alert",
             description="Send a system-wide broadcast to all drivers in a region or to all users of a specific role")
async def broadcast_alert(req: AdminBroadcastRequest):
    # Create notification request from broadcast
    notif = PushNotificationRequest(
        user_id="broadcast",
        title=f"[BROADCAST] {req.title}",
        body=req.body,
        notification_type=NotificationType.SYSTEM_BROADCAST,
        priority=req.priority
    )
    result = send_push_notification(notif)
    result["broadcast_target"] = req.target_role.value if req.target_role else "ALL_USERS"
    result["region_filter"] = req.region_center.to_dict() if req.region_center else None
    return result


@router.get("/driver-leaderboard", summary="Driver Performance Leaderboard",
            description="Top drivers ranked by deliveries completed, on-time rate, and customer rating")
async def driver_leaderboard(
    time_range: str = Query("30d", description="Time range: 7d, 30d, 90d"),
    limit: int = Query(10, ge=1, le=50)
):
    # Simulated leaderboard (production → aggregate from Firestore)
    drivers = [
        {"rank": 1, "driver_id": "DRV-001", "name": "Rahul Kumar", "deliveries": 187, "on_time_pct": 96.2, "rating": 4.9, "avg_delivery_mins": 28, "incidents": 0},
        {"rank": 2, "driver_id": "DRV-007", "name": "Amit Singh", "deliveries": 172, "on_time_pct": 94.8, "rating": 4.8, "avg_delivery_mins": 31, "incidents": 1},
        {"rank": 3, "driver_id": "DRV-012", "name": "Priya Sharma", "deliveries": 165, "on_time_pct": 97.1, "rating": 4.9, "avg_delivery_mins": 26, "incidents": 0},
        {"rank": 4, "driver_id": "DRV-003", "name": "Vikram Patel", "deliveries": 158, "on_time_pct": 91.5, "rating": 4.7, "avg_delivery_mins": 33, "incidents": 2},
        {"rank": 5, "driver_id": "DRV-019", "name": "Sneha Das", "deliveries": 149, "on_time_pct": 93.9, "rating": 4.8, "avg_delivery_mins": 30, "incidents": 1},
        {"rank": 6, "driver_id": "DRV-025", "name": "Ravi Verma", "deliveries": 142, "on_time_pct": 90.3, "rating": 4.6, "avg_delivery_mins": 35, "incidents": 3},
        {"rank": 7, "driver_id": "DRV-008", "name": "Anita Roy", "deliveries": 138, "on_time_pct": 95.4, "rating": 4.8, "avg_delivery_mins": 27, "incidents": 0},
        {"rank": 8, "driver_id": "DRV-014", "name": "Deepak Jha", "deliveries": 131, "on_time_pct": 88.7, "rating": 4.5, "avg_delivery_mins": 38, "incidents": 4},
        {"rank": 9, "driver_id": "DRV-030", "name": "Neha Gupta", "deliveries": 125, "on_time_pct": 92.6, "rating": 4.7, "avg_delivery_mins": 32, "incidents": 1},
        {"rank": 10, "driver_id": "DRV-006", "name": "Suresh Yadav", "deliveries": 118, "on_time_pct": 89.4, "rating": 4.6, "avg_delivery_mins": 36, "incidents": 2},
    ]
    return {
        "time_range": time_range,
        "total_drivers": 48,
        "leaderboard": drivers[:limit],
        "fleet_avg_on_time_pct": 93.1,
        "fleet_avg_rating": 4.73
    }


@router.get("/route-efficiency", summary="Route Efficiency Report",
            description="Overall route efficiency metrics — fuel saved, CO₂ reduced, SLA adherence vs legacy routing")
async def route_efficiency(time_range: str = Query("30d")):
    return {
        "time_range": time_range,
        "total_shipments_analyzed": 4287,
        "garuda_vs_legacy": {
            "fuel_saved_litres": 2340,
            "fuel_saved_pct": 18.7,
            "co2_reduced_kg": 5876,
            "co2_reduced_pct": 22.3,
            "avg_delivery_time_reduction_mins": 14,
            "sla_adherence_garuda_pct": 96.4,
            "sla_adherence_legacy_pct": 81.2,
            "cost_saved_inr": 187500
        },
        "mode_distribution": {
            "ROAD_CAR": 62.3,
            "ROAD_BIKE": 21.7,
            "RAIL": 8.4,
            "FLIGHT": 5.1,
            "SHIP": 2.5
        },
        "reroutes_triggered": 127,
        "reroutes_successful_pct": 94.5,
        "disruptions_avoided": 89,
        "ai_predictions_accuracy_pct": 91.7
    }


@router.get("/disruption-log", summary="Disruption History Log",
            description="Historical log of all detected and resolved disruptions across the platform")
async def disruption_log(
    limit: int = Query(20, ge=1, le=100),
    severity_min: float = Query(0.0, ge=0.0, le=1.0)
):
    # Simulated historical disruptions
    logs = [
        {"id": "DSR-001", "type": "ACCIDENT", "severity": 0.85, "location": {"lat": 22.65, "lng": 85.90}, "area": "NH-33 Junction", "detected_at": "2026-04-26T08:30:00Z", "resolved_at": "2026-04-26T11:45:00Z", "affected_shipments": 7, "reroutes_triggered": 5, "status": "RESOLVED"},
        {"id": "DSR-002", "type": "WEATHER", "severity": 0.65, "location": {"lat": 22.57, "lng": 88.36}, "area": "Kolkata Metro", "detected_at": "2026-04-26T06:00:00Z", "resolved_at": None, "affected_shipments": 12, "reroutes_triggered": 3, "status": "ACTIVE"},
        {"id": "DSR-003", "type": "PROTEST", "severity": 0.90, "location": {"lat": 23.34, "lng": 85.31}, "area": "Ranchi Main Road", "detected_at": "2026-04-25T14:00:00Z", "resolved_at": "2026-04-25T20:30:00Z", "affected_shipments": 4, "reroutes_triggered": 4, "status": "RESOLVED"},
        {"id": "DSR-004", "type": "CONSTRUCTION", "severity": 0.40, "location": {"lat": 22.80, "lng": 86.20}, "area": "Ghatsila Bypass", "detected_at": "2026-04-24T10:00:00Z", "resolved_at": None, "affected_shipments": 2, "reroutes_triggered": 1, "status": "ONGOING"},
        {"id": "DSR-005", "type": "FLOODING", "severity": 0.95, "location": {"lat": 21.49, "lng": 86.91}, "area": "Balasore District", "detected_at": "2026-04-23T03:00:00Z", "resolved_at": "2026-04-24T18:00:00Z", "affected_shipments": 15, "reroutes_triggered": 12, "status": "RESOLVED"},
    ]
    
    filtered = [l for l in logs if l["severity"] >= severity_min][:limit]
    
    return {
        "total_disruptions": len(filtered),
        "active": sum(1 for l in filtered if l["status"] in ["ACTIVE", "ONGOING"]),
        "resolved": sum(1 for l in filtered if l["status"] == "RESOLVED"),
        "disruptions": filtered,
        "timestamp": datetime.now(timezone.utc).isoformat()
    }
