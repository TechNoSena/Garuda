"""Analytics & Billing Router — Garuda Platform"""
from fastapi import APIRouter, HTTPException, Query
from app.models import BillingEstimateParams, LatLng, TransportMode
from app.services.firebase_service import get_shipment_analytics
from app.services.gemini_service import assess_package_integrity
from app.services.routing_strategy import calculate_haversine, get_strategy

router = APIRouter(prefix="/v1", tags=["📊 Analytics & Billing"])


@router.get("/analytics/shipment/{shipment_id}", summary="Shipment Analytics",
            description="Full carbon footprint, fuel cost, toll estimate, and efficiency score for a shipment")
async def shipment_analytics(shipment_id: str):
    try:
        return get_shipment_analytics(shipment_id)
    except Exception as e:
        raise HTTPException(status_code=404, detail=str(e))


@router.get("/analytics/package-integrity/{shipment_id}", summary="Package Integrity Score",
            description="Assess risk to package based on route vibration, weather, handling — for fragile/temp-sensitive goods")
async def package_integrity(
    shipment_id: str,
    cargo_type: str = Query("general", description="fragile, perishable, hazardous, high_value, general, electronics"),
    weight_kg: float = Query(5.0, ge=0.1, description="Package weight in kg"),
    mode: TransportMode = Query(TransportMode.ROAD_CAR, description="Transport mode")
):
    # Use default test coordinates (in production, fetch from shipment)
    origin = LatLng(lat=22.543610, lng=85.796856)
    destination = LatLng(lat=22.768116, lng=86.200684)
    
    result = assess_package_integrity(origin, destination, mode.value, weight_kg, cargo_type)
    result["shipment_id"] = shipment_id
    return result


@router.get("/billing/estimate", summary="Billing Cost Estimate",
            description="Pre-route cost estimation — toll + fuel + carbon tax + surcharges breakdown before finalizing route")
async def billing_estimate(
    origin_lat: float = Query(22.543610), origin_lng: float = Query(85.796856),
    dest_lat: float = Query(22.768116), dest_lng: float = Query(86.200684),
    mode: TransportMode = Query(TransportMode.ROAD_CAR),
    weight_kg: float = Query(10.0, ge=0.1),
    is_express: bool = Query(False),
    is_fragile: bool = Query(False)
):
    origin = LatLng(lat=origin_lat, lng=origin_lng)
    destination = LatLng(lat=dest_lat, lng=dest_lng)
    dist_km = calculate_haversine(origin, destination)
    
    strategy = get_strategy(mode.value)
    base = strategy.estimate_cost(dist_km)
    
    transport_cost = base["estimated_cost_inr"]
    toll = round(dist_km * 1.5, 2) if mode.value in ["ROAD_CAR", "ROAD_BIKE"] else 0
    
    # Weight surcharge (₹2/kg above 20kg)
    weight_surcharge = round(max(0, weight_kg - 20) * 2, 2)
    
    # Express surcharge (40% extra)
    express_surcharge = round(transport_cost * 0.40, 2) if is_express else 0
    
    # Fragile handling (₹150 flat + 10% of transport)
    fragile_surcharge = round(150 + transport_cost * 0.10, 2) if is_fragile else 0
    
    # Carbon tax (₹0.5 per kg CO2 equivalent)
    carbon_tax = round(base["estimated_co2_g"] / 1000 * 0.5, 2)
    
    # GST (18%)
    subtotal = transport_cost + toll + weight_surcharge + express_surcharge + fragile_surcharge + carbon_tax
    gst = round(subtotal * 0.18, 2)
    total = round(subtotal + gst, 2)
    
    return {
        "route": {
            "origin": origin.to_dict(),
            "destination": destination.to_dict(),
            "distance_km": round(dist_km, 2),
            "mode": mode.value
        },
        "cost_breakdown": {
            "transport_cost_inr": transport_cost,
            "toll_charges_inr": toll,
            "weight_surcharge_inr": weight_surcharge,
            "express_surcharge_inr": express_surcharge,
            "fragile_handling_inr": fragile_surcharge,
            "carbon_tax_inr": carbon_tax,
            "subtotal_inr": round(subtotal, 2),
            "gst_18_pct_inr": gst,
            "total_inr": total
        },
        "estimated_duration_mins": base["estimated_duration_mins"],
        "estimated_co2_g": base["estimated_co2_g"],
        "weight_kg": weight_kg,
        "is_express": is_express,
        "is_fragile": is_fragile
    }
