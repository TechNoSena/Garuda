"""Notifications & Communication Router — Garuda Platform"""
from fastapi import APIRouter, HTTPException, Query
from app.models import PushNotificationRequest, ChatBridgeRequest
from app.services.notification_service import (
    send_push_notification, get_notification_history, create_chat_bridge
)

router = APIRouter(prefix="/v1", tags=["🔔 Notifications & Communication"])


@router.post("/notifications/push", summary="Send Push Notification",
             description="Send a push notification to a specific user or broadcast to all users by role")
async def push_notification(req: PushNotificationRequest):
    result = send_push_notification(req)
    if result.get("status") == "failed":
        raise HTTPException(status_code=500, detail=result.get("error", "Notification failed"))
    return result


@router.get("/notifications/history", summary="Get Notification History",
            description="Fetch past notifications for a user — reroute alerts, delivery updates, risk warnings, etc.")
async def notification_history(
    user_id: str = Query(..., description="User UID to fetch history for"),
    limit: int = Query(20, ge=1, le=100, description="Max notifications to return")
):
    return get_notification_history(user_id, limit)


@router.post("/support/chat-bridge", summary="Create Chat Bridge",
             description="Create a masked communication channel between consumer and delivery partner for privacy-first interaction")
async def chat_bridge(req: ChatBridgeRequest):
    result = create_chat_bridge(req)
    if result.get("status") == "failed":
        raise HTTPException(status_code=500, detail=result.get("error", "Chat bridge creation failed"))
    return result
