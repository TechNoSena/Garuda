from fastapi import APIRouter, HTTPException, Query
from app.models import (
    CreateShipmentRequest, AssignShipmentRequest, 
    UpdateLocationRequest, ShipmentStatus, EtaRequest
)
from app.services import firebase_service

router = APIRouter(prefix="/v1/shipments", tags=["📦 Shipments"])

@router.post("/", summary="Create Shipment",
             description="Supplier creates a new shipment with origin, destination, and consumer details")
async def create_shipment(req: CreateShipmentRequest):
    try:
        shipment = firebase_service.create_shipment(req)
        return {"status": "success", "shipment": shipment}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/{shipment_id}", summary="Get Shipment Details",
            description="Fetch full shipment data including current location and status history")
async def get_shipment(shipment_id: str):
    try:
        return firebase_service.get_shipment(shipment_id)
    except Exception as e:
        raise HTTPException(status_code=404, detail=str(e))

@router.get("/{shipment_id}/eta", summary="Get Live ETA",
            description="Calculate estimated time of arrival based on current location and transport mode")
async def get_eta(shipment_id: str):
    try:
        return firebase_service.get_shipment_eta(shipment_id)
    except Exception as e:
        raise HTTPException(status_code=404, detail=str(e))

@router.get("/user/{user_id}", summary="List Shipments by User",
            description="Get all shipments for a given user based on their role")
async def list_by_user(user_id: str, role: str = Query(..., description="SUPPLIER, LOGISTICS, or DELIVERY_MAN")):
    try:
        return firebase_service.list_shipments_by_user(user_id, role)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.patch("/{shipment_id}/assign", summary="Assign Delivery Man",
              description="Logistics partner assigns a delivery man to the shipment")
async def assign_shipment(shipment_id: str, req: AssignShipmentRequest):
    try:
        return firebase_service.update_shipment_status(shipment_id, ShipmentStatus.ASSIGNED, req.delivery_man_id)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.patch("/{shipment_id}/status", summary="Update Shipment Status",
              description="Transition shipment through status lifecycle")
async def update_status(shipment_id: str, status: ShipmentStatus):
    try:
        return firebase_service.update_shipment_status(shipment_id, status)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.patch("/{shipment_id}/location", summary="Update Live Location",
              description="Delivery man pings current GPS coordinates (called every 5-10 mins)")
async def update_location(shipment_id: str, req: UpdateLocationRequest):
    try:
        return firebase_service.update_shipment_location(shipment_id, req.current_location)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
