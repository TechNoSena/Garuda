import requests
import math
from typing import List, Dict
from app.models import LatLng
from app.config import GOOGLE_MAPS_KEY

def calculate_haversine(p1: LatLng, p2: LatLng) -> float:
    """Haversine formula — distance between two LatLng points in km."""
    R = 6371.0
    dlat = math.radians(p2.lat - p1.lat)
    dlng = math.radians(p2.lng - p1.lng)
    a = (math.sin(dlat / 2)**2 +
         math.cos(math.radians(p1.lat)) * math.cos(math.radians(p2.lat)) *
         math.sin(dlng / 2)**2)
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


class BaseTransportStrategy:
    mode_label: str = "Unknown"
    avg_speed_kmh: float = 50.0
    cost_per_km_inr: float = 8.0
    co2_per_km_g: float = 120.0

    def get_routes(self, origin: LatLng, destination: LatLng) -> List[Dict]:
        raise NotImplementedError
    
    def optimize_multi(self, points: List[LatLng]) -> dict:
        raise NotImplementedError
    
    def estimate_cost(self, distance_km: float) -> dict:
        """Quick cost and carbon estimate for a given distance."""
        return {
            "mode": self.mode_label,
            "distance_km": round(distance_km, 2),
            "estimated_cost_inr": round(distance_km * self.cost_per_km_inr, 2),
            "estimated_co2_g": round(distance_km * self.co2_per_km_g, 2),
            "estimated_duration_mins": round((distance_km / self.avg_speed_kmh) * 60, 1)
        }


class RoadStrategy(BaseTransportStrategy):
    def __init__(self, is_bike: bool = False):
        self.travel_mode = "TWO_WHEELER" if is_bike else "DRIVE"
        self.mode_label = "Road (Bike)" if is_bike else "Road (Car/Truck)"
        self.avg_speed_kmh = 35.0 if is_bike else 50.0
        self.cost_per_km_inr = 4.0 if is_bike else 8.0
        self.co2_per_km_g = 40.0 if is_bike else 120.0

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
        try:
            resp = requests.post(url, json=payload, headers=headers, timeout=15)
            resp.raise_for_status()
            return resp.json().get('routes', [])
        except requests.RequestException as e:
            print(f"Google Routes API error: {e}")
            # Fallback to haversine estimate
            dist = calculate_haversine(origin, destination)
            return [{
                "description": f"Estimated {self.mode_label} Route (offline)",
                "distanceMeters": int(dist * 1000),
                "duration": f"{int((dist / self.avg_speed_kmh) * 3600)}s",
                "info": "Fallback estimate — Google API unreachable"
            }]

    def optimize_multi(self, points: List[LatLng]) -> dict:
        if len(points) < 2:
            return {"optimized_points": [p.model_dump() for p in points], "route": None}
        
        origin = points[0]
        destination = points[-1]
        waypoints = points[1:-1]
        
        wp_str = "|".join([p.to_string() for p in waypoints])
        if wp_str:
            wp_str = "optimize:true|" + wp_str
            
        url = (f"https://maps.googleapis.com/maps/api/directions/json"
               f"?origin={origin.to_string()}&destination={destination.to_string()}"
               f"&waypoints={wp_str}&key={GOOGLE_MAPS_KEY}")
        try:
            resp = requests.get(url, timeout=15).json()
            if resp.get("status") == "OK":
                route = resp["routes"][0]
                order = route.get("waypoint_order", [])
                ordered = [origin] + [waypoints[i] for i in order] + [destination]
                return {"optimized_points": [p.model_dump() for p in ordered], "route": route}
        except Exception as e:
            print(f"Google Directions API error: {e}")
        return {"optimized_points": [p.model_dump() for p in points], "route": None, "error": "Could not optimize"}


class RailStrategy(BaseTransportStrategy):
    mode_label = "Rail (Freight/Passenger)"
    avg_speed_kmh = 80.0
    cost_per_km_inr = 3.5
    co2_per_km_g = 30.0

    def get_routes(self, origin: LatLng, destination: LatLng) -> List[Dict]:
        dist = calculate_haversine(origin, destination)
        duration_hrs = dist / self.avg_speed_kmh
        return [{
            "description": self.mode_label,
            "distanceMeters": int(dist * 1000),
            "duration": f"{int(duration_hrs * 3600)}s",
            "info": "Simulated rail route based on straight-line distance"
        }]

    def optimize_multi(self, points: List[LatLng]) -> dict:
        return {"optimized_points": [p.model_dump() for p in points],
                "note": "Train TSP depends on fixed railway schedules."}


class FlightStrategy(BaseTransportStrategy):
    mode_label = "Air Freight / Flight"
    avg_speed_kmh = 800.0
    cost_per_km_inr = 25.0
    co2_per_km_g = 250.0

    def get_routes(self, origin: LatLng, destination: LatLng) -> List[Dict]:
        dist = calculate_haversine(origin, destination)
        duration_hrs = dist / self.avg_speed_kmh
        return [{
            "description": self.mode_label,
            "distanceMeters": int(dist * 1000),
            "duration": f"{int(duration_hrs * 3600)}s",
            "info": "Simulated air route based on great-circle distance"
        }]

    def optimize_multi(self, points: List[LatLng]) -> dict:
        return {"optimized_points": [p.model_dump() for p in points],
                "note": "Flight multi-stop optimization via air-corridor routing."}


class ShipStrategy(BaseTransportStrategy):
    mode_label = "Maritime / Sea Route"
    avg_speed_kmh = 40.0
    cost_per_km_inr = 2.0
    co2_per_km_g = 15.0

    def get_routes(self, origin: LatLng, destination: LatLng) -> List[Dict]:
        dist = calculate_haversine(origin, destination)
        duration_hrs = dist / self.avg_speed_kmh
        return [{
            "description": self.mode_label,
            "distanceMeters": int(dist * 1000),
            "duration": f"{int(duration_hrs * 3600)}s",
            "info": "Simulated maritime route based on great-circle distance"
        }]

    def optimize_multi(self, points: List[LatLng]) -> dict:
        return {"optimized_points": [p.model_dump() for p in points],
                "note": "Ship routing via standard nautical paths."}


# ── Strategy Factory ──
_STRATEGY_MAP = {
    "ROAD_CAR": lambda: RoadStrategy(is_bike=False),
    "ROAD_BIKE": lambda: RoadStrategy(is_bike=True),
    "RAIL": RailStrategy,
    "FLIGHT": FlightStrategy,
    "SHIP": ShipStrategy,
}

def get_strategy(mode: str) -> BaseTransportStrategy:
    factory = _STRATEGY_MAP.get(mode.upper())
    if factory:
        return factory()
    return RoadStrategy()

def get_all_strategies() -> Dict[str, BaseTransportStrategy]:
    """Return one instance per mode — used by compare-modes endpoint."""
    return {name: factory() for name, factory in _STRATEGY_MAP.items()}
