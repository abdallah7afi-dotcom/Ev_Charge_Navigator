import 'dart:math';

/// Estimates EV battery consumption based on distance, elevation, and climate.
///
/// Uses the formula:
///   Energy (kWh) = [(distance × baseRate) + (elevGain × climbCost) - (elevLoss × regenRate)]
///                  × temperatureFactor
///
/// Results are returned as [ConsumptionResult] with kWh used, remaining kWh,
/// and remaining percentage of total battery.
class BatteryConsumptionEstimator {
  // ─── Elevation constants ───
  /// Extra energy cost per meter of elevation gain (kWh/m)
  static const double _climbCostPerMeter = 0.0015;

  /// Energy recovered per meter of elevation loss via regen braking (kWh/m)
  static const double _regenRecoveryPerMeter = 0.0010;

  // ─── Safety buffer ───
  /// Minimum battery % to keep as reserve (don't plan trips below this)
  static const double safetyBufferPercent = 5.0;

  /// Default base consumption rates by vehicle category (kWh/km).
  /// Used as fallback when no per-model rate is available.
  static const Map<VehicleCategory, double> categoryRates = {
    VehicleCategory.economy: 0.16,
    VehicleCategory.sedan: 0.15,
    VehicleCategory.suv: 0.19,
    VehicleCategory.luxurySuv: 0.24,
  };

  /// Determine the vehicle category from its battery capacity.
  /// Bigger battery typically = bigger/heavier vehicle.
  static VehicleCategory categorizeByCapacity(double batteryKwh) {
    if (batteryKwh <= 45) return VehicleCategory.economy;
    if (batteryKwh <= 75) return VehicleCategory.sedan;
    if (batteryKwh <= 100) return VehicleCategory.suv;
    return VehicleCategory.luxurySuv;
  }

  /// Look up the base consumption rate for a given battery capacity.
  /// Automatically categorizes the vehicle and returns kWh/km.
  static double getBaseRate(double batteryKwh) {
    final category = categorizeByCapacity(batteryKwh);
    return categoryRates[category]!;
  }

  // ─── Temperature / Season correction ───

  /// Simple season-based correction using month of year.
  ///   May–Sep (summer in Saudi Arabia) → ×1.20 (AC load)
  ///   Dec–Feb (winter)                 → ×1.10 (battery chemistry)
  ///   Mar–Apr, Oct–Nov                 → ×1.00 (optimal)
  static double seasonalFactor({DateTime? now}) {
    final month = (now ?? DateTime.now()).month;
    if (month >= 5 && month <= 9) return 1.20; // Summer
    if (month == 12 || month <= 2) return 1.10; // Winter
    return 1.0; // Spring / Autumn
  }

  /// Advanced correction using actual ambient temperature (°C).
  ///   15–25°C → ×1.00 (optimal range)
  ///   25–35°C → ×1.10
  ///   35–45°C → ×1.20
  ///    >45°C  → ×1.30
  ///   5–15°C  → ×1.10
  ///    <5°C   → ×1.20
  static double temperatureFactor(double tempCelsius) {
    if (tempCelsius >= 15 && tempCelsius <= 25) return 1.00;
    if (tempCelsius > 25 && tempCelsius <= 35) return 1.10;
    if (tempCelsius > 35 && tempCelsius <= 45) return 1.20;
    if (tempCelsius > 45) return 1.30;
    if (tempCelsius >= 5 && tempCelsius < 15) return 1.10;
    return 1.20; // Below 5°C
  }

  // ─── Core estimation ───

  /// Estimate battery consumption for a trip.
  ///
  /// Parameters:
  ///   [distanceKm]       – driving distance in kilometers
  ///   [batteryCapacity]  – total battery capacity in kWh
  ///   [currentBatteryPct]– current charge level as percentage (0–100)
  ///   [baseRateKwhPerKm] – base consumption rate (kWh per km).
  ///                        If null, auto-determined from [batteryCapacity].
  ///   [elevationGainM]   – total meters climbed (positive elevation)
  ///   [elevationLossM]   – total meters descended (negative elevation, as positive value)
  ///   [tempCelsius]      – ambient temperature for advanced correction.
  ///                        If null, falls back to seasonal correction.
  static ConsumptionResult estimate({
    required double distanceKm,
    required double batteryCapacity,
    required double currentBatteryPct,
    double? baseRateKwhPerKm,
    double elevationGainM = 0,
    double elevationLossM = 0,
    double? tempCelsius,
  }) {
    // Step 1: Determine base consumption rate
    final baseRate = baseRateKwhPerKm ?? getBaseRate(batteryCapacity);

    // Step 2: Flat-terrain energy from distance
    final flatEnergy = distanceKm * baseRate;

    // Step 3: Elevation adjustments
    final climbEnergy = elevationGainM * _climbCostPerMeter;
    final regenRecovery = elevationLossM * _regenRecoveryPerMeter;

    // Step 4: Temperature / season correction
    final climateFactor = tempCelsius != null
        ? temperatureFactor(tempCelsius)
        : seasonalFactor();

    // Step 5: Total energy consumed (kWh)
    // Formula: [(dist × rate) + climb - regen] × climate factor
    final rawEnergy = flatEnergy + climbEnergy - regenRecovery;
    final totalEnergyKwh = max(0.0, rawEnergy * climateFactor);

    // Step 6: Convert to battery percentage
    final energyPct = (totalEnergyKwh / batteryCapacity) * 100;
    final remainingPct = currentBatteryPct - energyPct;
    final remainingKwh = (remainingPct / 100) * batteryCapacity;

    // Step 7: Reachability check (must keep ≥ safetyBufferPercent)
    final isReachable = remainingPct >= safetyBufferPercent;

    return ConsumptionResult(
      distanceKm: distanceKm,
      baseRateKwhPerKm: baseRate,
      flatEnergyKwh: flatEnergy,
      climbEnergyKwh: climbEnergy,
      regenRecoveryKwh: regenRecovery,
      climateFactor: climateFactor,
      totalEnergyKwh: totalEnergyKwh,
      energyPercentUsed: energyPct,
      remainingPct: remainingPct.clamp(0, 100),
      remainingKwh: max(0, remainingKwh),
      isReachable: isReachable,
      vehicleCategory: categorizeByCapacity(batteryCapacity),
    );
  }
}

/// Vehicle size categories with default consumption rates.
enum VehicleCategory {
  economy,   // Small EVs:       ~0.16 kWh/km (e.g. BYD Dolphin Mini, Nissan Leaf)
  sedan,     // Mid-size sedans: ~0.15 kWh/km (e.g. Tesla Model 3, BYD Seal)
  suv,       // Standard SUVs:   ~0.19 kWh/km (e.g. Tesla Model Y, Hyundai Ioniq 5)
  luxurySuv, // Large/luxury:    ~0.24 kWh/km (e.g. GMC Hummer EV, Rivian R1S)
}

/// Extension to get human-readable label for each category.
extension VehicleCategoryLabel on VehicleCategory {
  String get label {
    switch (this) {
      case VehicleCategory.economy:
        return 'Economy';
      case VehicleCategory.sedan:
        return 'Sedan';
      case VehicleCategory.suv:
        return 'SUV';
      case VehicleCategory.luxurySuv:
        return 'Large SUV';
    }
  }
}

/// Holds the detailed breakdown of a consumption estimate.
class ConsumptionResult {
  /// Trip distance in km
  final double distanceKm;

  /// Base consumption rate used (kWh/km)
  final double baseRateKwhPerKm;

  /// Energy from flat-terrain driving (kWh)
  final double flatEnergyKwh;

  /// Extra energy from climbing (kWh)
  final double climbEnergyKwh;

  /// Energy recovered from descending/regen (kWh)
  final double regenRecoveryKwh;

  /// Climate correction multiplier applied
  final double climateFactor;

  /// Total energy consumed after all adjustments (kWh)
  final double totalEnergyKwh;

  /// Battery percentage consumed
  final double energyPercentUsed;

  /// Remaining battery percentage after trip
  final double remainingPct;

  /// Remaining battery in kWh after trip
  final double remainingKwh;

  /// Whether the destination is reachable with safety buffer
  final bool isReachable;

  /// Detected vehicle category
  final VehicleCategory vehicleCategory;

  const ConsumptionResult({
    required this.distanceKm,
    required this.baseRateKwhPerKm,
    required this.flatEnergyKwh,
    required this.climbEnergyKwh,
    required this.regenRecoveryKwh,
    required this.climateFactor,
    required this.totalEnergyKwh,
    required this.energyPercentUsed,
    required this.remainingPct,
    required this.remainingKwh,
    required this.isReachable,
    required this.vehicleCategory,
  });

  @override
  String toString() {
    return 'ConsumptionResult('
        'distance: ${distanceKm.toStringAsFixed(1)} km, '
        'used: ${totalEnergyKwh.toStringAsFixed(2)} kWh (${energyPercentUsed.toStringAsFixed(1)}%), '
        'remaining: ${remainingKwh.toStringAsFixed(1)} kWh (${remainingPct.toStringAsFixed(1)}%), '
        'reachable: $isReachable, '
        'category: ${vehicleCategory.label}, '
        'climate: ×${climateFactor.toStringAsFixed(2)}'
        ')';
  }
}
