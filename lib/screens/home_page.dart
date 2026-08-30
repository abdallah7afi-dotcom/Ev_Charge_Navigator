import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ev_charge_navigator/theme/app_theme.dart';
import 'package:ev_charge_navigator/services/auth_service.dart';
import 'package:ev_charge_navigator/services/firestore_service.dart';
import 'package:ev_charge_navigator/services/location_service.dart';
import 'package:ev_charge_navigator/models/car_model.dart';
import 'package:ev_charge_navigator/models/station_model.dart';
import 'package:ev_charge_navigator/utils/haversine.dart';
import 'package:ev_charge_navigator/widgets/vehicle_card.dart';
import 'package:ev_charge_navigator/widgets/battery_dialog.dart';
import 'package:ev_charge_navigator/widgets/station_bottom_sheet.dart';
import 'package:ev_charge_navigator/widgets/app_drawer.dart';
import 'package:ev_charge_navigator/screens/trip_analysis_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  CarModel? _primaryCar;
  List<_NearbyStation> _nearbyStations = [];
  bool _loading = true;
  bool _loadingStations = true;
  double? _userLat;
  double? _userLng;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.isLoggedIn) return;

    try {
      final car = await _firestoreService.getPrimaryCar(authService.user!.uid);
      if (mounted) {
        setState(() {
          _primaryCar = car;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }

    _loadNearbyStations();
  }

  Future<void> _loadNearbyStations() async {
    try {
      final position = await _locationService.getCurrentPosition();
      _userLat = position.latitude;
      _userLng = position.longitude;

      final stations = await _firestoreService.getAllStations();

      final nearby = <_NearbyStation>[];
      for (final station in stations) {
        final distance = calculateDistance(
          _userLat!,
          _userLng!,
          station.latitude,
          station.longitude,
        );
        nearby.add(_NearbyStation(station: station, distance: distance));
      }

      nearby.sort((a, b) => a.distance.compareTo(b.distance));
      final top5 = nearby.take(5).toList();

      if (mounted) {
        setState(() {
          _nearbyStations = top5;
          _loadingStations = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingStations = false);
    }
  }

  Future<void> _handleFindStation() async {
    final batteryLevel = await BatteryDialog.show(context);
    if (batteryLevel != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TripAnalysisPage(batteryLevel: batteryLevel),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.surface,
      drawer: AppDrawer(primaryCar: _primaryCar, onDataChanged: _loadData),
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.textDark),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/ev_logo_clean.png',
                width: 20,
                height: 28,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'EV Navigator',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting
                  Text(
                    'Hi, ${authService.userName.isNotEmpty ? authService.userName : "Driver"} 👋',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ready to charge?',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Vehicle Card
                  VehicleCard(
                    carName: _primaryCar?.name,
                    connectorType: _primaryCar?.connectorType,
                    batteryCapacity: _primaryCar?.batteryCapacity,
                    onTap: _primaryCar == null
                        ? () => Navigator.pushNamed(context, '/car-selection')
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // Find Nearest Station Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _handleFindStation,
                      icon: const Icon(Icons.search, size: 22),
                      label: Text(
                        'Find Nearest Station',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Nearby Stations Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Nearby Stations',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/charging-map'),
                        child: Text(
                          'View All',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_loadingStations)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    )
                  else if (_nearbyStations.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'No stations found nearby',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  else
                    ..._nearbyStations.map(
                      (nearby) => _buildNearbyStationCard(nearby),
                    ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildNearbyStationCard(_NearbyStation nearby) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (_userLat != null && _userLng != null) {
            StationBottomSheet.show(
              context,
              nearby.station,
              50.0, // default battery
              10.0, // default needed
              true,
              _userLat!,
              _userLng!,
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Station icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.ev_station,
                  color: AppColors.primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Station info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nearby.station.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.bolt, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 2),
                        Text(
                          '${nearby.station.power.toStringAsFixed(0)} kW',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.electrical_services,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            nearby.station.connectorType,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          '${nearby.station.rating}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          nearby.station.fee,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: nearby.station.fee == 'Free'
                                ? AppColors.successGreen
                                : AppColors.textSecondary,
                            fontWeight: nearby.station.fee == 'Free'
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Distance
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    nearby.distance.toStringAsFixed(1),
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  Text(
                    'km',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NearbyStation {
  final StationModel station;
  final double distance;

  _NearbyStation({required this.station, required this.distance});
}
