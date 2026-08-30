import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ev_charge_navigator/theme/app_theme.dart';
import 'package:ev_charge_navigator/models/station_model.dart';
import 'package:ev_charge_navigator/models/car_model.dart';
import 'package:ev_charge_navigator/services/auth_service.dart';
import 'package:ev_charge_navigator/services/firestore_service.dart';
import 'package:ev_charge_navigator/services/location_service.dart';
import 'package:ev_charge_navigator/utils/haversine.dart';
import 'package:ev_charge_navigator/utils/battery_estimator.dart';

import 'package:ev_charge_navigator/widgets/station_card.dart';
import 'package:ev_charge_navigator/widgets/station_bottom_sheet.dart';
import 'package:ev_charge_navigator/screens/navigation_page.dart';

class TripAnalysisPage extends StatefulWidget {
  final double batteryLevel;

  const TripAnalysisPage({super.key, required this.batteryLevel});

  @override
  State<TripAnalysisPage> createState() => _TripAnalysisPageState();
}

class _TripAnalysisPageState extends State<TripAnalysisPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();

  List<_StationAnalysis> _analysisResults = [];
  CarModel? _car;
  double? _userLat;
  double? _userLng;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (!authService.isLoggedIn) return;

      // Load car
      _car = await _firestoreService.getPrimaryCar(authService.user!.uid);

      // Load user position
      final position = await _locationService.getCurrentPosition();
      _userLat = position.latitude;
      _userLng = position.longitude;

      // Load stations
      final stations = await _firestoreService.getAllStations();

      // Filter by plug type if available
      final plugType = _car?.connectorType ?? '';
      final compatibleStations = plugType.isNotEmpty
          ? stations
              .where((s) =>
                  s.connectorType.toLowerCase().contains(plugType.toLowerCase()))
              .toList()
          : stations;

      final targetStations = compatibleStations.isNotEmpty ? compatibleStations : stations;

      final results = <_StationAnalysis>[];
      final batteryCapacity = _car?.batteryCapacity ?? 60.0;

      for (final station in targetStations) {
        final distance = calculateDistance(
          _userLat!,
          _userLng!,
          station.latitude,
          station.longitude,
        );

        final estimate = BatteryConsumptionEstimator.estimate(
          distanceKm: distance,
          batteryCapacity: batteryCapacity,
          currentBatteryPct: widget.batteryLevel,
        );

        results.add(_StationAnalysis(
          station: station,
          distance: distance,
          batteryNeeded: estimate.energyPercentUsed,
          isReachable: estimate.isReachable,
          estimate: estimate,
        ));
      }

      // Sort by distance (nearest first)
      results.sort((a, b) => a.distance.compareTo(b.distance));

      if (mounted) {
        setState(() {
          _analysisResults = results;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reachableCount =
        _analysisResults.where((r) => r.isReachable).length;
    final tooFarCount = _analysisResults.length - reachableCount;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Trip Analysis',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: AppColors.errorRed),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Summary Card
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: AppGradients.cardGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildSummaryItem(
                                Icons.battery_std,
                                '${widget.batteryLevel.toStringAsFixed(0)}%',
                                'Battery',
                              ),
                              _buildSummaryItem(
                                Icons.electrical_services,
                                _car?.connectorType ?? 'N/A',
                                'Connector',
                              ),
                              _buildSummaryItem(
                                Icons.check_circle,
                                '$reachableCount',
                                'Reachable',
                                valueColor: Colors.greenAccent,
                              ),
                              _buildSummaryItem(
                                Icons.cancel,
                                '$tooFarCount',
                                'Too Far',
                                valueColor: Colors.redAccent,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Climate & vehicle category info
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                BatteryConsumptionEstimator.seasonalFactor() > 1.0
                                    ? Icons.wb_sunny
                                    : Icons.thermostat,
                                color: Colors.white70,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Climate ×${BatteryConsumptionEstimator.seasonalFactor().toStringAsFixed(2)}'
                                '  •  ${BatteryConsumptionEstimator.categorizeByCapacity(_car?.batteryCapacity ?? 60).label}'
                                '  •  ${(BatteryConsumptionEstimator.getBaseRate(_car?.batteryCapacity ?? 60) * 1000).toStringAsFixed(0)} Wh/km',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Station list
                    Expanded(
                      child: _analysisResults.isEmpty
                          ? Center(
                              child: Text(
                                'No stations found',
                                style: GoogleFonts.inter(
                                    color: AppColors.textSecondary),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _analysisResults.length,
                              padding: const EdgeInsets.only(bottom: 16),
                              itemBuilder: (context, index) {
                                final result = _analysisResults[index];
                                return StationCard(
                                  rank: index + 1,
                                  station: result.station,
                                  distance: result.distance,
                                  batteryNeeded: result.batteryNeeded,
                                  isReachable: result.isReachable,
                                  onNavigate: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => NavigationPage(
                                          station: result.station,
                                          batteryLevel: widget.batteryLevel,
                                          batteryNeeded: result.batteryNeeded,
                                        ),
                                      ),
                                    );
                                  },
                                  onGoogleMaps: () => _openGoogleMaps(result.station),
                                  onTap: () {
                                    StationBottomSheet.show(
                                      context,
                                      result.station,
                                      widget.batteryLevel,
                                      result.batteryNeeded,
                                      result.isReachable,
                                      _userLat!,
                                      _userLng!,
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String value, String label,
      {Color? valueColor}) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Future<void> _openGoogleMaps(StationModel station) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${station.latitude},${station.longitude}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}

class _StationAnalysis {
  final StationModel station;
  final double distance;
  final double batteryNeeded;
  final bool isReachable;
  final ConsumptionResult? estimate;

  _StationAnalysis({
    required this.station,
    required this.distance,
    required this.batteryNeeded,
    required this.isReachable,
    this.estimate,
  });
}
