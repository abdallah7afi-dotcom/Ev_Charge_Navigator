import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:ev_charge_navigator/models/station_model.dart';
import 'package:ev_charge_navigator/utils/battery_estimator.dart';

/// Client for the Python/Flask AI Trip Feasibility Engine.
///
/// Communicates with the Flask backend for ML-powered predictions.
/// Falls back to local [BatteryConsumptionEstimator] when the server
/// is unreachable (offline mode).
class AiService {
  /// Base URL of the Flask AI backend.
  /// Change this to your deployed server URL in production.
  static const String _baseUrl = 'http://10.0.2.2:5000'; // Android emulator
  // static const String _baseUrl = 'http://192.168.x.x:5000'; // Physical device

  /// Timeout for API requests (must stay under 3s per non-functional req).
  static const Duration _timeout = Duration(seconds: 3);

  // ─── API Methods ───

  /// Predict battery consumption via the Flask AI backend.
  /// Falls back to local estimation on failure.
  static Future<TripFeasibilityResult> predictConsumption({
    required double distanceKm,
    required double batteryCapacityKwh,
    required double currentBatteryPct,
    double elevationGainM = 0,
    double elevationLossM = 0,
    double? temperatureC,
    String trafficLevel = 'low',
    double? consumptionRate,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/predict-consumption'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'distance_km': distanceKm,
              'elevation_gain_m': elevationGainM,
              'elevation_loss_m': elevationLossM,
              'temperature_c': temperatureC,
              'traffic_level': trafficLevel,
              'battery_capacity_kwh': batteryCapacityKwh,
              'consumption_rate': consumptionRate,
              'current_battery_pct': currentBatteryPct,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return TripFeasibilityResult.fromApiResponse(data);
      }
    } catch (_) {
      // Fall through to local estimation
    }

    // Offline fallback: use local BatteryConsumptionEstimator
    return _localEstimate(
      distanceKm: distanceKm,
      batteryCapacityKwh: batteryCapacityKwh,
      currentBatteryPct: currentBatteryPct,
      elevationGainM: elevationGainM,
      elevationLossM: elevationLossM,
      temperatureC: temperatureC,
      trafficLevel: trafficLevel,
      consumptionRate: consumptionRate,
    );
  }

  /// Plan a full trip with auto-routing to charging stations.
  ///
  /// If the trip is not feasible (battery < 20%), this method
  /// automatically finds the nearest compatible station and
  /// returns it as a suggested charging stop.
  static Future<TripPlanResult> planTrip({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    required double distanceKm,
    required double batteryCapacityKwh,
    required double currentBatteryPct,
    required String plugType,
    required List<StationModel> stations,
    double elevationGainM = 0,
    double elevationLossM = 0,
    double? temperatureC,
    String trafficLevel = 'low',
    double? consumptionRate,
  }) async {
    // Step 1: Get consumption prediction
    final prediction = await predictConsumption(
      distanceKm: distanceKm,
      batteryCapacityKwh: batteryCapacityKwh,
      currentBatteryPct: currentBatteryPct,
      elevationGainM: elevationGainM,
      elevationLossM: elevationLossM,
      temperatureC: temperatureC,
      trafficLevel: trafficLevel,
      consumptionRate: consumptionRate,
    );

    // Step 2: Check feasibility (threshold = 20%)
    final feasible = prediction.remainingBatteryPct >= 20.0;

    // Step 3: If not feasible, find nearest compatible station
    List<ChargingStop> chargingStops = [];
    bool revisedFeasible = feasible;

    if (!feasible) {
      final compatibleStations = _filterCompatible(stations, plugType);
      final nearest = _findNearest(originLat, originLng, compatibleStations);

      if (nearest != null) {
        // Check if we can reach the charging station
        final distToStation = _haversine(
          originLat,
          originLng,
          nearest.latitude,
          nearest.longitude,
        );

        final toStationPrediction = await predictConsumption(
          distanceKm: distToStation,
          batteryCapacityKwh: batteryCapacityKwh,
          currentBatteryPct: currentBatteryPct,
          temperatureC: temperatureC,
          trafficLevel: trafficLevel,
          consumptionRate: consumptionRate,
        );

        final canReachStation = toStationPrediction.remainingBatteryPct >= 5.0;

        chargingStops.add(
          ChargingStop(
            station: nearest,
            distanceFromOriginKm: distToStation,
            canReach: canReachStation,
            batteryAtStation: toStationPrediction.remainingBatteryPct,
            chargeToPct: 80.0,
          ),
        );

        revisedFeasible = canReachStation;
      }
    }

    return TripPlanResult(
      prediction: prediction,
      feasible: feasible,
      revisedFeasible: revisedFeasible,
      chargingStops: chargingStops,
    );
  }

  // ─── Local Fallback ───

  static TripFeasibilityResult _localEstimate({
    required double distanceKm,
    required double batteryCapacityKwh,
    required double currentBatteryPct,
    double elevationGainM = 0,
    double elevationLossM = 0,
    double? temperatureC,
    String trafficLevel = 'low',
    double? consumptionRate,
  }) {
    // Use existing BatteryConsumptionEstimator
    final result = BatteryConsumptionEstimator.estimate(
      distanceKm: distanceKm,
      batteryCapacity: batteryCapacityKwh,
      currentBatteryPct: currentBatteryPct,
      baseRateKwhPerKm: consumptionRate,
      elevationGainM: elevationGainM,
      elevationLossM: elevationLossM,
      tempCelsius: temperatureC,
    );

    // Apply traffic factor locally
    final trafficFactors = {'low': 1.0, 'medium': 1.10, 'high': 1.25};
    final trafficFactor = trafficFactors[trafficLevel] ?? 1.0;
    final adjustedEnergy = result.totalEnergyKwh * trafficFactor;
    final adjustedPctUsed = (adjustedEnergy / batteryCapacityKwh) * 100;
    final adjustedRemaining = currentBatteryPct - adjustedPctUsed;

    return TripFeasibilityResult(
      energyConsumedKwh: adjustedEnergy,
      energyPctUsed: adjustedPctUsed,
      remainingBatteryPct: adjustedRemaining.clamp(0, 100),
      remainingBatteryKwh: (adjustedRemaining / 100 * batteryCapacityKwh).clamp(
        0,
        batteryCapacityKwh,
      ),
      feasible: adjustedRemaining >= 20.0,
      vehicleCategory: result.vehicleCategory.label,
      climateFactor: result.climateFactor,
      trafficFactor: trafficFactor,
      source: 'local',
    );
  }

  // ─── Helpers ───

  /// Filter stations by plug-type compatibility.
  static List<StationModel> _filterCompatible(
    List<StationModel> stations,
    String plugType,
  ) {
    if (plugType.isEmpty) return stations;
    return stations
        .where(
          (s) => s.connectorType.toLowerCase().contains(plugType.toLowerCase()),
        )
        .toList();
  }

  /// Find nearest station by Haversine distance.
  static StationModel? _findNearest(
    double lat,
    double lng,
    List<StationModel> stations,
  ) {
    if (stations.isEmpty) return null;

    StationModel? nearest;
    double minDist = double.infinity;

    for (final s in stations) {
      final d = _haversine(lat, lng, s.latitude, s.longitude);
      if (d < minDist) {
        minDist = d;
        nearest = s;
      }
    }
    return nearest;
  }

  /// Haversine distance (km), using dart:math's built-in trig functions
  /// for full accuracy (no approximation).
  static double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLng = (lng2 - lng1) * math.pi / 180;
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }
}

// ──────────────────────────────────────────────────────────────
// Result Models
// ──────────────────────────────────────────────────────────────

/// Result of an AI consumption prediction.
class TripFeasibilityResult {
  final double energyConsumedKwh;
  final double energyPctUsed;
  final double remainingBatteryPct;
  final double remainingBatteryKwh;
  final bool feasible;
  final String vehicleCategory;
  final double climateFactor;
  final double trafficFactor;
  final String source; // 'api' or 'local'

  const TripFeasibilityResult({
    required this.energyConsumedKwh,
    required this.energyPctUsed,
    required this.remainingBatteryPct,
    required this.remainingBatteryKwh,
    required this.feasible,
    this.vehicleCategory = '',
    this.climateFactor = 1.0,
    this.trafficFactor = 1.0,
    this.source = 'local',
  });

  factory TripFeasibilityResult.fromApiResponse(Map<String, dynamic> data) {
    final breakdown = data['breakdown'] as Map<String, dynamic>? ?? {};
    return TripFeasibilityResult(
      energyConsumedKwh: (data['energy_consumed_kwh'] ?? 0).toDouble(),
      energyPctUsed: (data['energy_pct_used'] ?? 0).toDouble(),
      remainingBatteryPct: (data['remaining_battery_pct'] ?? 0).toDouble(),
      remainingBatteryKwh: (data['remaining_battery_kwh'] ?? 0).toDouble(),
      feasible: data['feasible'] ?? false,
      vehicleCategory: data['vehicle_category'] ?? '',
      climateFactor: (breakdown['climate_factor'] ?? 1.0).toDouble(),
      trafficFactor: (breakdown['traffic_factor'] ?? 1.0).toDouble(),
      source: 'api',
    );
  }

  @override
  String toString() =>
      'TripFeasibility(consumed: ${energyConsumedKwh.toStringAsFixed(1)} kWh, '
      'remaining: ${remainingBatteryPct.toStringAsFixed(1)}%, '
      'feasible: $feasible, source: $source)';
}

/// A suggested charging stop along the route.
class ChargingStop {
  final StationModel station;
  final double distanceFromOriginKm;
  final bool canReach;
  final double batteryAtStation;
  final double chargeToPct;

  const ChargingStop({
    required this.station,
    required this.distanceFromOriginKm,
    required this.canReach,
    required this.batteryAtStation,
    required this.chargeToPct,
  });
}

/// Full trip plan result with auto-routing data.
class TripPlanResult {
  final TripFeasibilityResult prediction;
  final bool feasible;
  final bool revisedFeasible;
  final List<ChargingStop> chargingStops;

  const TripPlanResult({
    required this.prediction,
    required this.feasible,
    required this.revisedFeasible,
    required this.chargingStops,
  });

  bool get needsCharging => !feasible && chargingStops.isNotEmpty;
  int get totalStops => chargingStops.length;
}
