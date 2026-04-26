from fastapi import APIRouter, HTTPException
from app.models import CreateShipmentRequest, AssignShipmentRequest, UpdateLocationRequest, ShipmentStatus
from app.services import firebase_service

router = APIRouter(prefix="/v1/shipments", tags=["Shipments"])

@router.post("/")
async def create_shipment(req: CreateShipmentRequest):
    try:
        shipment = firebase_service.create_shipment(req)
        return {"status": "success", "shipment": shipment}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/{shipment_id}")
async def get_shipment(shipment_id: str):
    try:
        return firebase_service.get_shipment(shipment_id)
    except Exception as e:
        raise HTTPException(status_code=404, detail=str(e))

@router.patch("/{shipment_id}/assign")
async def assign_shipment(shipment_id: str, req: AssignShipmentRequest):
    try:
        return firebase_service.update_shipment_status(shipment_id, ShipmentStatus.ASSIGNED, req.delivery_man_id)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.patch("/{shipment_id}/status")
async def update_status(shipment_id: str, status: ShipmentStatus):
    try:
        return firebase_service.update_shipment_status(shipment_id, status)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.patch("/{shipment_id}/location")
async def update_location(shipment_id: str, req: UpdateLocationRequest):
    try:
        return firebase_service.update_shipment_location(shipment_id, req.current_location)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
