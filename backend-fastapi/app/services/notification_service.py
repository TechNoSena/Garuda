"""
Notification & Communication Service for Garuda Platform.
Handles push notifications, notification history, and masked chat bridges.
"""
import uuid
from datetime import datetime, timezone
from typing import List, Optional, Dict, Any
from app.config import db
from app.models import (
    PushNotificationRequest, ChatBridgeRequest,
    NotificationType, NotificationPriority
)


# In-memory store for when Firebase is offline
_mock_notifications: List[dict] = []
_mock_chat_sessions: Dict[str, dict] = {}


def send_push_notification(req: PushNotificationRequest) -> dict:
    """Store a push notification and return confirmation."""
    notification_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc).isoformat()

    notification_data = {
        "notification_id": notification_id,
        "user_id": req.user_id,
        "title": req.title,
        "body": req.body,
        "type": req.notification_type.value,
        "priority": req.priority.value,
        "shipment_id": req.shipment_id,
        "data": req.data or {},
        "read": False,
        "created_at": now,
        "delivered": True  # In production, this would be async via FCM
    }

    if not db:
        _mock_notifications.append(notification_data)
        return {
            "status": "sent",
            "notification": notification_data,
            "delivery_method": "mock_store",
            "mock": True
        }

    try:
        doc_ref = db.collection("notifications").document(notification_id)
        doc_ref.set(notification_data)
        return {
            "status": "sent",
            "notification": notification_data,
            "delivery_method": "firestore_fcm"
        }
    except Exception as e:
        return {"status": "failed", "error": str(e)}


def get_notification_history(user_id: str, limit: int = 20) -> dict:
    """Fetch past notifications for a user."""
    if not db:
        # Return from mock store
        user_notifs = [n for n in _mock_notifications if n["user_id"] == user_id]
        user_notifs.sort(key=lambda x: x["created_at"], reverse=True)
        return {
            "user_id": user_id,
            "total": len(user_notifs),
            "notifications": user_notifs[:limit],
            "mock": True
        }

    try:
        from google.cloud.firestore_v1.base_query import FieldFilter
        docs = (
            db.collection("notifications")
            .where(filter=FieldFilter("user_id", "==", user_id))
            .order_by("created_at", direction="DESCENDING")
            .limit(limit)
            .stream()
        )
        notifications = [doc.to_dict() for doc in docs]
        return {
            "user_id": user_id,
            "total": len(notifications),
            "notifications": notifications
        }
    except Exception as e:
        return {"user_id": user_id, "total": 0, "notifications": [], "error": str(e)}


def create_chat_bridge(req: ChatBridgeRequest) -> dict:
    """Create a masked communication session between consumer and delivery partner."""
    session_id = f"chat-{uuid.uuid4().hex[:12]}"
    now = datetime.now(timezone.utc).isoformat()
    
    # Generate masked identifiers (privacy protection)
    masked_requester = f"User-{req.requester_id[-4:]}" if len(req.requester_id) > 4 else "User-XXXX"
    masked_partner = f"Partner-{req.shipment_id[-4:]}" if len(req.shipment_id) > 4 else "Partner-XXXX"
    
    # Generate a masked virtual phone number (in production, use Twilio/Exotel)
    import random
    random.seed(hash(session_id))
    masked_phone = f"+91-{random.randint(70000, 99999)}-{random.randint(10000, 99999)}"
    
    bridge_data = {
        "session_id": session_id,
        "shipment_id": req.shipment_id,
        "requester": {
            "id": req.requester_id,
            "role": req.requester_role.value,
            "masked_identity": masked_requester
        },
        "partner": {
            "masked_identity": masked_partner
        },
        "masked_phone": masked_phone,
        "initial_message": req.message,
        "status": "ACTIVE",
        "created_at": now,
        "expires_at": "30 minutes from creation",
        "communication_channels": ["in_app_chat", "masked_call"]
    }

    if not db:
        _mock_chat_sessions[session_id] = bridge_data
        bridge_data["mock"] = True
        return bridge_data

    try:
        doc_ref = db.collection("chat_bridges").document(session_id)
        doc_ref.set(bridge_data)
        return bridge_data
    except Exception as e:
        return {"status": "failed", "error": str(e)}
