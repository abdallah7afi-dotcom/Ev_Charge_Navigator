"""
EV-Charge Navigator — AI Trip Feasibility Engine
=================================================
Flask backend using scikit-learn and NumPy for battery consumption prediction.

Variables considered:
  1. Distance (km) — primary consumption driver
  2. Elevation gain/loss (m) — terrain impact
  3. Temperature (°C) — weather/climate correction
  4. Traffic level — congestion penalty (stop-and-go)

Formula:
  Energy (kWh) = [(distance × base_rate) 
                  + (elev_gain × climb_cost) 
                  − (elev_loss × regen_rate)]
                 × climate_factor 
                 × traffic_factor

If predicted remaining battery < threshold (20%), the engine returns
`feasible: false` and identifies the nearest compatible charging station.
"""

import os
import numpy as np
from flask import Flask, request, jsonify
from sklearn.linear_model import LinearRegression
from datetime import datetime

app = Flask(__name__)

# ──────────────────────────────────────────────────────────────
# Constants
# ──────────────────────────────────────────────────────────────

# Base consumption rates by vehicle category (kWh/km)
CATEGORY_RATES = {
    "economy": 0.16,    # Small EVs (≤45 kWh)
    "sedan": 0.15,      # Mid-size (≤75 kWh)
    "suv": 0.19,        # Standard SUVs (≤100 kWh)
    "luxury_suv": 0.24, # Large/luxury (>100 kWh)
}

# Elevation constants
CLIMB_COST_PER_METER = 0.0015     # kWh per meter climbed
REGEN_RECOVERY_PER_METER = 0.0010 # kWh per meter descended

# Low-battery threshold (%)
LOW_BATTERY_THRESHOLD = 20.0

# Safety buffer (%)
SAFETY_BUFFER = 5.0


# ──────────────────────────────────────────────────────────────
# Helper Functions
# ──────────────────────────────────────────────────────────────

def categorize_vehicle(battery_capacity_kwh: float) -> str:
    """Determine vehicle category from battery capacity."""
    if battery_capacity_kwh <= 45:
        return "economy"
    elif battery_capacity_kwh <= 75:
        return "sedan"
    elif battery_capacity_kwh <= 100:
        return "suv"
    return "luxury_suv"


def get_base_rate(battery_capacity_kwh: float, custom_rate: float = None) -> float:
    """Get base consumption rate. Use custom if provided, else auto-detect."""
    if custom_rate and custom_rate > 0:
        return custom_rate
    category = categorize_vehicle(battery_capacity_kwh)
    return CATEGORY_RATES[category]


def get_climate_factor_by_temp(temp_celsius: float) -> float:
    """
    Advanced temperature correction factor.
    
    Ranges:
      15–25°C → ×1.00 (optimal battery efficiency)
      25–35°C → ×1.10 (AC load begins)
      35–45°C → ×1.20 (heavy AC, battery thermal mgmt)
       >45°C  → ×1.30 (extreme heat — common in Saudi summer)
      5–15°C  → ×1.10 (cold battery chemistry)
       <5°C   → ×1.20 (very cold — rare in KSA)
    """
    if 15 <= temp_celsius <= 25:
        return 1.00
    elif 25 < temp_celsius <= 35:
        return 1.10
    elif 35 < temp_celsius <= 45:
        return 1.20
    elif temp_celsius > 45:
        return 1.30
    elif 5 <= temp_celsius < 15:
        return 1.10
    else:
        return 1.20


def get_climate_factor_by_month(month: int = None) -> float:
    """
    Simple seasonal correction (fallback when temperature unavailable).
    
    Saudi Arabia climate:
      May–Sep  → ×1.20 (summer, heavy AC usage)
      Dec–Feb  → ×1.10 (winter, battery less efficient)
      Mar–Apr, Oct–Nov → ×1.00 (optimal)
    """
    if month is None:
        month = datetime.now().month
    if 5 <= month <= 9:
        return 1.20
    elif month == 12 or month <= 2:
        return 1.10
    return 1.00


def get_traffic_factor(traffic_level: str) -> float:
    """
    Traffic congestion penalty.
    
    Stop-and-go driving increases consumption due to:
      - Frequent acceleration/deceleration
      - Reduced regenerative braking efficiency
      - Extended AC/heating runtime
    
    Levels:
      low    → ×1.00 (free-flowing highway)
      medium → ×1.10 (moderate congestion)
      high   → ×1.25 (heavy stop-and-go, city peak hours)
    """
    factors = {
        "low": 1.00,
        "medium": 1.10,
        "high": 1.25,
    }
    return factors.get(traffic_level.lower(), 1.00)


def haversine_distance(lat1, lng1, lat2, lng2) -> float:
    """Calculate great-circle distance between two GPS points (km)."""
    R = 6371.0  # Earth's radius in km
    d_lat = np.radians(lat2 - lat1)
    d_lng = np.radians(lng2 - lng1)
    a = (np.sin(d_lat / 2) ** 2 +
         np.cos(np.radians(lat1)) * np.cos(np.radians(lat2)) *
         np.sin(d_lng / 2) ** 2)
    return R * 2 * np.arctan2(np.sqrt(a), np.sqrt(1 - a))


# ──────────────────────────────────────────────────────────────
# Core Prediction Engine
# ──────────────────────────────────────────────────────────────

def predict_consumption(
    distance_km: float,
    elevation_gain_m: float = 0,
    elevation_loss_m: float = 0,
    temperature_c: float = None,
    traffic_level: str = "low",
    battery_capacity_kwh: float = 60.0,
    consumption_rate: float = None,
    current_battery_pct: float = 100.0,
) -> dict:
    """
    Predict battery consumption for a trip.
    
    Returns a detailed breakdown including:
      - energy_consumed_kwh: total energy used
      - remaining_battery_pct: battery % at destination
      - remaining_battery_kwh: battery kWh at destination
      - feasible: whether the trip can be completed safely
      - breakdown: detailed component-level breakdown
    """
    # Step 1: Determine base consumption rate
    base_rate = get_base_rate(battery_capacity_kwh, consumption_rate)
    category = categorize_vehicle(battery_capacity_kwh)
    
    # Step 2: Flat-terrain energy from distance
    flat_energy = distance_km * base_rate
    
    # Step 3: Elevation adjustments
    climb_energy = elevation_gain_m * CLIMB_COST_PER_METER
    regen_recovery = elevation_loss_m * REGEN_RECOVERY_PER_METER
    
    # Step 4: Climate correction
    if temperature_c is not None:
        climate_factor = get_climate_factor_by_temp(temperature_c)
        climate_source = "temperature"
    else:
        climate_factor = get_climate_factor_by_month()
        climate_source = "seasonal"
    
    # Step 5: Traffic correction
    traffic_factor = get_traffic_factor(traffic_level)
    
    # Step 6: Total energy consumed
    raw_energy = flat_energy + climb_energy - regen_recovery
    total_energy = max(0.0, raw_energy * climate_factor * traffic_factor)
    
    # Step 7: Battery state after trip
    energy_pct_used = (total_energy / battery_capacity_kwh) * 100
    remaining_pct = current_battery_pct - energy_pct_used
    remaining_kwh = max(0.0, (remaining_pct / 100.0) * battery_capacity_kwh)
    
    # Step 8: Feasibility check
    feasible = remaining_pct >= LOW_BATTERY_THRESHOLD
    critical = remaining_pct < SAFETY_BUFFER
    
    return {
        "energy_consumed_kwh": round(total_energy, 2),
        "energy_pct_used": round(energy_pct_used, 1),
        "remaining_battery_pct": round(max(0, remaining_pct), 1),
        "remaining_battery_kwh": round(remaining_kwh, 1),
        "feasible": feasible,
        "critical": critical,
        "vehicle_category": category,
        "base_rate_kwh_per_km": base_rate,
        "breakdown": {
            "flat_energy_kwh": round(flat_energy, 3),
            "climb_energy_kwh": round(climb_energy, 3),
            "regen_recovery_kwh": round(regen_recovery, 3),
            "climate_factor": climate_factor,
            "climate_source": climate_source,
            "traffic_factor": traffic_factor,
            "traffic_level": traffic_level,
        },
    }


def find_nearest_compatible_station(
    user_lat: float,
    user_lng: float,
    plug_type: str,
    stations: list,
) -> dict:
    """
    Find the nearest charging station compatible with the user's plug type.
    
    Uses NumPy vectorized Haversine for performance.
    """
    if not stations:
        return None
    
    compatible = [s for s in stations if plug_type.lower() in 
                  s.get("connectorType", "").lower()]
    
    if not compatible:
        # Fallback: return nearest regardless of plug type
        compatible = stations
    
    # Vectorized distance calculation using NumPy
    lats = np.array([s["latitude"] for s in compatible])
    lngs = np.array([s["longitude"] for s in compatible])
    
    distances = np.array([
        haversine_distance(user_lat, user_lng, lat, lng)
        for lat, lng in zip(lats, lngs)
    ])
    
    nearest_idx = np.argmin(distances)
    nearest = compatible[nearest_idx]
    nearest["distance_km"] = round(float(distances[nearest_idx]), 2)
    
    return nearest


# ──────────────────────────────────────────────────────────────
# scikit-learn ML Model (trained on synthetic data)
# ──────────────────────────────────────────────────────────────

def build_ml_model():
    """
    Build and train a LinearRegression model on synthetic EV consumption data.
    
    Features: [distance_km, elevation_gain_m, temperature_c, traffic_code]
    Target:   energy_consumed_kwh
    
    This model supplements the rule-based engine for edge cases and
    can be retrained on real user trip data for improved accuracy.
    """
    np.random.seed(42)
    n_samples = 500
    
    # Synthetic training data
    distances = np.random.uniform(5, 300, n_samples)
    elevations = np.random.uniform(0, 500, n_samples)
    temperatures = np.random.uniform(10, 50, n_samples)
    traffic_codes = np.random.choice([0, 1, 2], n_samples)  # low=0, med=1, high=2
    
    # Generate labels using our rule-based formula (ground truth)
    base_rate = 0.17  # average
    energies = []
    for i in range(n_samples):
        flat = distances[i] * base_rate
        climb = elevations[i] * CLIMB_COST_PER_METER
        climate = get_climate_factor_by_temp(temperatures[i])
        traffic = [1.0, 1.10, 1.25][traffic_codes[i]]
        energy = (flat + climb) * climate * traffic
        energies.append(energy)
    
    X = np.column_stack([distances, elevations, temperatures, traffic_codes])
    y = np.array(energies)
    
    model = LinearRegression()
    model.fit(X, y)
    
    return model


# Train the ML model at startup
ml_model = build_ml_model()


# ──────────────────────────────────────────────────────────────
# Flask API Endpoints
# ──────────────────────────────────────────────────────────────

@app.route("/api/health", methods=["GET"])
def health_check():
    """Health check endpoint."""
    return jsonify({"status": "ok", "version": "1.0.0"})


@app.route("/api/predict-consumption", methods=["POST"])
def api_predict_consumption():
    """
    Predict battery consumption for a trip.
    
    Request body (JSON):
      {
        "distance_km": 120.5,
        "elevation_gain_m": 200,      (optional, default 0)
        "elevation_loss_m": 150,      (optional, default 0)
        "temperature_c": 38.5,        (optional, falls back to seasonal)
        "traffic_level": "medium",    (optional, default "low")
        "battery_capacity_kwh": 83.0,
        "consumption_rate": 0.15,     (optional, auto-detect if null)
        "current_battery_pct": 85.0
      }
    
    Response (JSON):
      {
        "energy_consumed_kwh": 25.4,
        "remaining_battery_pct": 54.4,
        "remaining_battery_kwh": 45.2,
        "feasible": true,
        "breakdown": { ... }
      }
    """
    data = request.get_json()
    
    if not data or "distance_km" not in data or "battery_capacity_kwh" not in data:
        return jsonify({"error": "Missing required fields: distance_km, battery_capacity_kwh"}), 400
    
    result = predict_consumption(
        distance_km=float(data["distance_km"]),
        elevation_gain_m=float(data.get("elevation_gain_m", 0)),
        elevation_loss_m=float(data.get("elevation_loss_m", 0)),
        temperature_c=data.get("temperature_c"),
        traffic_level=data.get("traffic_level", "low"),
        battery_capacity_kwh=float(data["battery_capacity_kwh"]),
        consumption_rate=data.get("consumption_rate"),
        current_battery_pct=float(data.get("current_battery_pct", 100)),
    )
    
    return jsonify(result)


@app.route("/api/predict-ml", methods=["POST"])
def api_predict_ml():
    """
    ML-based consumption prediction using the trained scikit-learn model.
    
    Request body (JSON):
      {
        "distance_km": 120.5,
        "elevation_gain_m": 200,
        "temperature_c": 38.5,
        "traffic_level": "medium",
        "battery_capacity_kwh": 83.0,
        "current_battery_pct": 85.0
      }
    """
    data = request.get_json()
    
    if not data or "distance_km" not in data:
        return jsonify({"error": "Missing required field: distance_km"}), 400
    
    traffic_map = {"low": 0, "medium": 1, "high": 2}
    traffic_code = traffic_map.get(data.get("traffic_level", "low"), 0)
    temp = data.get("temperature_c", 35.0)
    
    features = np.array([[
        float(data["distance_km"]),
        float(data.get("elevation_gain_m", 0)),
        float(temp),
        traffic_code,
    ]])
    
    predicted_kwh = float(ml_model.predict(features)[0])
    battery_cap = float(data.get("battery_capacity_kwh", 60))
    current_pct = float(data.get("current_battery_pct", 100))
    
    energy_pct = (predicted_kwh / battery_cap) * 100
    remaining_pct = current_pct - energy_pct
    
    return jsonify({
        "energy_consumed_kwh": round(max(0, predicted_kwh), 2),
        "remaining_battery_pct": round(max(0, remaining_pct), 1),
        "feasible": remaining_pct >= LOW_BATTERY_THRESHOLD,
        "model": "scikit-learn-linear-regression",
    })


@app.route("/api/plan-trip", methods=["POST"])
def api_plan_trip():
    """
    Full trip planning with auto-routing to charging stations.
    
    Request body (JSON):
      {
        "origin": {"lat": 24.7136, "lng": 46.6753},
        "destination": {"lat": 21.4225, "lng": 39.8262},
        "distance_km": 950,
        "elevation_gain_m": 300,
        "elevation_loss_m": 250,
        "temperature_c": 42,
        "traffic_level": "medium",
        "battery_capacity_kwh": 83,
        "consumption_rate": 0.15,
        "current_battery_pct": 90,
        "plug_type": "CCS2",
        "stations": [ { station objects... } ]
      }
    
    Response (JSON):
      {
        "feasible": false,
        "prediction": { ... },
        "charging_stops": [
          { "station": {...}, "distance_from_origin_km": 280, "charge_to_pct": 80 }
        ],
        "total_stops": 1,
        "revised_feasible": true
      }
    """
    data = request.get_json()
    
    if not data:
        return jsonify({"error": "Missing request body"}), 400
    
    # Step 1: Predict consumption for full trip
    prediction = predict_consumption(
        distance_km=float(data["distance_km"]),
        elevation_gain_m=float(data.get("elevation_gain_m", 0)),
        elevation_loss_m=float(data.get("elevation_loss_m", 0)),
        temperature_c=data.get("temperature_c"),
        traffic_level=data.get("traffic_level", "low"),
        battery_capacity_kwh=float(data["battery_capacity_kwh"]),
        consumption_rate=data.get("consumption_rate"),
        current_battery_pct=float(data.get("current_battery_pct", 100)),
    )
    
    result = {
        "feasible": prediction["feasible"],
        "prediction": prediction,
        "charging_stops": [],
        "total_stops": 0,
        "revised_feasible": prediction["feasible"],
    }
    
    # Step 2: If not feasible, find charging stops
    if not prediction["feasible"]:
        stations = data.get("stations", [])
        plug_type = data.get("plug_type", "")
        origin = data.get("origin", {})
        
        if stations and origin:
            # Find nearest compatible station from origin
            nearest = find_nearest_compatible_station(
                user_lat=float(origin["lat"]),
                user_lng=float(origin["lng"]),
                plug_type=plug_type,
                stations=stations,
            )
            
            if nearest:
                # Calculate if we can reach the station first
                station_distance = nearest.get("distance_km", 0)
                to_station = predict_consumption(
                    distance_km=station_distance,
                    battery_capacity_kwh=float(data["battery_capacity_kwh"]),
                    consumption_rate=data.get("consumption_rate"),
                    current_battery_pct=float(data.get("current_battery_pct", 100)),
                    temperature_c=data.get("temperature_c"),
                    traffic_level=data.get("traffic_level", "low"),
                )
                
                can_reach_station = to_station["remaining_battery_pct"] >= SAFETY_BUFFER
                
                result["charging_stops"].append({
                    "station": nearest,
                    "distance_from_origin_km": station_distance,
                    "can_reach": can_reach_station,
                    "battery_at_station": to_station["remaining_battery_pct"],
                    "charge_to_pct": 80,  # Recommend charging to 80%
                })
                result["total_stops"] = 1
                result["revised_feasible"] = can_reach_station
    
    return jsonify(result)


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port, debug=True)
