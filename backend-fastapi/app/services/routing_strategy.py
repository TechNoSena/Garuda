import requests
import math
from typing import List, Dict
from app.models import LatLng
from app.config import GOOGLE_MAPS_KEY

def calculate_haversine(p1: LatLng, p2: LatLng) -> float:
    R = 6371.0 # Earth radius in km
    dlat = math.radians(p2.lat - p1.lat)
    dlng = math.radians(p2.lng - p1.lng)
    a = math.sin(dlat / 2)**2 + math.cos(math.radians(p1.lat)) * math.cos(math.radians(p2.lat)) * math.sin(dlng / 2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c

class BaseTransportStrategy:
    def get_routes(self, origin: LatLng, destination: LatLng) -> List[Dict]:
        raise NotImplementedError
    
    def optimize_multi(self, points: List[LatLng]) -> dict:
        raise NotImplementedError

class RoadStrategy(BaseTransportStrategy):
    def __init__(self, is_bike: bool = False):
        self.travel_mode = "TWO_WHEELER" if is_bike else "DRIVE"
        
    def get_routes(self, origin: LatLng, destination: LatLng) -> List[Dict]:
        url = "https://routes.googleapis.com/directions/v2:computeRoutes"
        headers = {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': GOOGLE_MAPS_KEY,
            'X-Goog-Fieldmask': 'routes.duration,routes.distanceMeters,routes.staticDuration,routes.description,routes.polyline'
        }
        payload = {
            "origin": {"location": {"latLng": {"latitude": origin.lat, "longitude": origin.lng}}},
            "destination": {"location": {"latLng": {"latitude": destination.lat, "longitude": destination.lng}}},
            "travelMode": self.travel_mode,
            "computeAlternativeRoutes": True,
            "routingPreference": "TRAFFIC_AWARE_OPTIMAL"
        }
        resp = requests.post(url, json=payload, headers=headers).json()
        return resp.get('routes', [])

    def optimize_multi(self, points: List[LatLng]) -> dict:
        if len(points) < 2:
            return {"optimized_points": [p.dict() for p in points], "route": None}
        
        origin = points[0]
        destination = points[-1]
        waypoints = points[1:-1]
        
        wp_str = "|".join([p.to_string() for p in waypoints])
        if wp_str:
            wp_str = "optimize:true|" + wp_str
            
        url = f"https://maps.googleapis.com/maps/api/directions/json?origin={origin.to_string()}&destination={destination.to_string()}&waypoints={wp_str}&key={GOOGLE_MAPS_KEY}"
        resp = requests.get(url).json()
        
        if resp.get("status") == "OK":
            route = resp["routes"][0]
            order = route.get("waypoint_order", [])
            ordered_points = [origin]
            for idx in order:
                ordered_points.append(waypoints[idx])
            ordered_points.append(destination)
            return {"optimized_points": [p.dict() for p in ordered_points], "route": route}
        return {"optimized_points": [p.dict() for p in points], "route": None, "error": "Could not optimize"}

class RailStrategy(BaseTransportStrategy):
    def get_routes(self, origin: LatLng, destination: LatLng) -> List[Dict]:
        dist = calculate_haversine(origin, destination)
        duration_hrs = dist / 80.0
        return [{
            "description": "Freight/Passenger Rail Route",
            "distanceMeters": int(dist * 1000),
            "duration": f"{int(duration_hrs * 3600)}s",
            "info": "Simulated Route"
        }]
    def optimize_multi(self, points: List[LatLng]) -> dict:
        return {"optimized_points": [p.dict() for p in points], "note": "Train TSP depends on fixed schedules."}

class FlightStrategy(BaseTransportStrategy):
    def get_routes(self, origin: LatLng, destination: LatLng) -> List[Dict]:
        dist = calculate_haversine(origin, destination)
        duration_hrs = dist / 800.0
        return [{
            "description": "Air Freight / Direct Flight",
            "distanceMeters": int(dist * 1000),
            "duration": f"{int(duration_hrs * 3600)}s",
            "info": "Simulated Route"
        }]
    def optimize_multi(self, points: List[LatLng]) -> dict:
        return {"optimized_points": [p.dict() for p in points], "note": "Flight multi-stop optimization handled via air-corridor routing."}

class ShipStrategy(BaseTransportStrategy):
    def get_routes(self, origin: LatLng, destination: LatLng) -> List[Dict]:
        dist = calculate_haversine(origin, destination)
        duration_hrs = dist / 40.0
        return [{
            "description": "Maritime Sea Route",
            "distanceMeters": int(dist * 1000),
            "duration": f"{int(duration_hrs * 3600)}s",
            "info": "Simulated Route"
        }]
    def optimize_multi(self, points: List[LatLng]) -> dict:
         return {"optimized_points": [p.dict() for p in points], "note": "Ship routing via standard nautical paths."}

def get_strategy(mode: str) -> BaseTransportStrategy:
    mode = mode.upper()
    if mode == "ROAD_CAR": return RoadStrategy(is_bike=False)
    elif mode == "ROAD_BIKE": return RoadStrategy(is_bike=True)
    elif mode == "RAIL": return RailStrategy()
    elif mode == "FLIGHT": return FlightStrategy()
    elif mode == "SHIP": return ShipStrategy()
    else: return RoadStrategy()
