import requests
import json
import time

BASE_URL = "https://garuda-backend-437904093333.asia-south1.run.app"

def setup_test():
    print("1. Creating Supplier Shipment...")
    payload = {
        "supplier_id": "test-supplier",
        "logistics_id": "test-logistics",
        "consumer_email": "consumer@test.com",
        "origin": {"lat": 19.076, "lng": 72.877},
        "destination": {"lat": 28.704, "lng": 77.102},
        "route_mode": "ROAD_CAR",
        "package_description": "E2E Heavy Test Package",
        "weight_kg": 50.5
    }
    r = requests.post(f"{BASE_URL}/v1/shipments/", json=payload)
    if r.status_code != 200:
        print("Failed to create shipment:", r.text)
        return
    
    shipment_data = r.json().get("shipment", {})
    shipment_id = shipment_data.get("shipment_id")
    print(f"✅ Created Shipment: {shipment_id}")

    print("2. Assigning Driver...")
    assign_payload = {"delivery_man_id": "test-driver-001"}
    r = requests.patch(f"{BASE_URL}/v1/shipments/{shipment_id}/assign", json=assign_payload)
    print(f"✅ Driver Assigned: {r.status_code}")

    print("3. Updating Status to DISPATCHED...")
    r = requests.patch(f"{BASE_URL}/v1/shipments/{shipment_id}/status?new_status=DISPATCHED")
    print(f"✅ Status Updated: {r.status_code}")

    print("4. Sending Live Location Update...")
    loc_payload = {"current_location": {"lat": 20.0, "lng": 73.0}}
    r = requests.patch(f"{BASE_URL}/v1/shipments/{shipment_id}/location", json=loc_payload)
    print(f"✅ Location Updated: {r.status_code}")
    
    print("\n--- TEST DATA ---")
    print(f"Use this Tracking ID in Consumer UI: {shipment_id}")

if __name__ == "__main__":
    setup_test()
