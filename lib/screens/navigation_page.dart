import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:ev_charge_navigator/theme/app_theme.dart';
import 'package:ev_charge_navigator/models/station_model.dart';
import 'package:ev_charge_navigator/services/location_service.dart';
import 'package:ev_charge_navigator/services/routing_service.dart';
import 'package:ev_charge_navigator/utils/constants.dart';
import 'package:ev_charge_navigator/utils/haversine.dart';

class NavigationPage extends StatefulWidget {
  final StationModel station;
  final double batteryLevel;
  final double batteryNeeded;

  const NavigationPage({
    super.key,
    required this.station,
    required this.batteryLevel,
    required this.batteryNeeded,
  });

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  final LocationService _locationService = LocationService();
  final RoutingService _routingService = RoutingService();

  MapboxMap? _mapboxMap;
  bool _isNavigating = false;
  bool _isLoading = true;
  geo.Position? _currentPosition;
  StreamSubscription<geo.Position>? _positionStream;

  double _routeDistance = 0;
  double _routeDuration = 0;
  List<List<double>> _routeGeometry = [];
  List<Map<String, dynamic>> _routeSteps = [];
  final int _currentStepIndex = 0;

  CircleAnnotationManager? _userMarkerManager;
  CircleAnnotationManager? _stationMarkerManager;
  PolylineAnnotationManager? _routeLineManager;

  @override
  void initState() {
    super.initState();
    _initRoute();
  }

  Future<void> _initRoute() async {
    try {
      final position = await _locationService.getCurrentPosition();
      _currentPosition = position;

      final routeData = await _routingService.getRoute(
        position.latitude,
        position.longitude,
        widget.station.latitude,
        widget.station.longitude,
      );

      if (mounted) {
        setState(() {
          _routeDistance = routeData['distance'];
          _routeDuration = routeData['duration'];
          _routeGeometry = List<List<double>>.from(routeData['geometry']);
          _routeSteps =
              List<Map<String, dynamic>>.from(routeData['steps']);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading route: $e')),
        );
      }
    }
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;

    // Wait for route data
    while (_isLoading) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (_currentPosition == null || _routeGeometry.isEmpty) return;

    await _drawRoute();
    await _addMarkers();
    await _fitCameraToBounds();
  }

  Future<void> _drawRoute() async {
    if (_mapboxMap == null || _routeGeometry.isEmpty) return;

    _routeLineManager =
        await _mapboxMap!.annotations.createPolylineAnnotationManager();

    final coordinates = _routeGeometry
        .map((point) => Position(point[1], point[0])) // lng, lat
        .toList();

    await _routeLineManager!.create(
      PolylineAnnotationOptions(
        geometry: LineString(coordinates: coordinates),
        lineColor: AppColors.primaryBlue.toARGB32(),
        lineWidth: 5.0,
        lineOpacity: 0.8,
      ),
    );
  }

  Future<void> _addMarkers() async {
    if (_mapboxMap == null || _currentPosition == null) return;

    // User marker (blue)
    _userMarkerManager =
        await _mapboxMap!.annotations.createCircleAnnotationManager();
    await _userMarkerManager!.create(
      CircleAnnotationOptions(
        geometry: Point(
          coordinates: Position(
              _currentPosition!.longitude, _currentPosition!.latitude),
        ),
        circleRadius: 10.0,
        circleColor: AppColors.primaryBlue.toARGB32(),
        circleStrokeColor: Colors.white.toARGB32(),
        circleStrokeWidth: 3.0,
      ),
    );

    // Station marker (orange)
    _stationMarkerManager =
        await _mapboxMap!.annotations.createCircleAnnotationManager();
    await _stationMarkerManager!.create(
      CircleAnnotationOptions(
        geometry: Point(
          coordinates:
              Position(widget.station.longitude, widget.station.latitude),
        ),
        circleRadius: 12.0,
        circleColor: AppColors.accentOrange.toARGB32(),
        circleStrokeColor: Colors.white.toARGB32(),
        circleStrokeWidth: 3.0,
      ),
    );
  }

  Future<void> _fitCameraToBounds() async {
    if (_mapboxMap == null || _currentPosition == null) return;

    final minLng = _currentPosition!.longitude < widget.station.longitude
        ? _currentPosition!.longitude
        : widget.station.longitude;
    final minLat = _currentPosition!.latitude < widget.station.latitude
        ? _currentPosition!.latitude
        : widget.station.latitude;
    final maxLng = _currentPosition!.longitude > widget.station.longitude
        ? _currentPosition!.longitude
        : widget.station.longitude;
    final maxLat = _currentPosition!.latitude > widget.station.latitude
        ? _currentPosition!.latitude
        : widget.station.latitude;

    await _mapboxMap!.flyTo(
      CameraOptions(
        center: Point(
          coordinates: Position(
            (minLng + maxLng) / 2,
            (minLat + maxLat) / 2,
          ),
        ),
        zoom: 12,
        padding: MbxEdgeInsets(top: 100, left: 60, bottom: 300, right: 60),
      ),
      MapAnimationOptions(duration: 1000),
    );
  }

  void _startNavigation() {
    setState(() => _isNavigating = true);

    _positionStream = _locationService
        .getPositionStream(distanceFilter: 5)
        .listen((geo.Position position) async {
      _currentPosition = position;

      // Update user marker
      if (_userMarkerManager != null) {
        await _userMarkerManager!.deleteAll();
        await _userMarkerManager!.create(
          CircleAnnotationOptions(
            geometry: Point(
              coordinates: Position(position.longitude, position.latitude),
            ),
            circleRadius: 10.0,
            circleColor: AppColors.primaryBlue.toARGB32(),
            circleStrokeColor: Colors.white.toARGB32(),
            circleStrokeWidth: 3.0,
          ),
        );
      }

      // Move camera to follow
      _mapboxMap?.flyTo(
        CameraOptions(
          center: Point(
            coordinates: Position(position.longitude, position.latitude),
          ),
          zoom: 16,
        ),
        MapAnimationOptions(duration: 500),
      );

      // Check arrival
      final distToStation = calculateDistance(
        position.latitude,
        position.longitude,
        widget.station.latitude,
        widget.station.longitude,
      );

      if (distToStation < AppConstants.arrivalThreshold) {
        _stopNavigation();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '🎉 You have arrived at ${widget.station.name}!',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              backgroundColor: AppColors.successGreen,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }

      if (mounted) setState(() {});
    });
  }

  void _stopNavigation() {
    _positionStream?.cancel();
    _positionStream = null;
    if (mounted) setState(() => _isNavigating = false);
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.batteryLevel - widget.batteryNeeded;
    final isReachable = widget.batteryNeeded <= widget.batteryLevel;
    final eta = DateTime.now().add(Duration(minutes: _routeDuration.toInt()));
    final etaFormatted = DateFormat('h:mm a').format(eta);

    return Scaffold(
      body: Stack(
        children: [
          // Map
          MapWidget(
            key: const ValueKey('navigation_map'),
            mapOptions: MapOptions(
              pixelRatio: MediaQuery.of(context).devicePixelRatio,
            ),
            styleUri: MapboxStyles.MAPBOX_STREETS,
            viewport: CameraViewportState(
              center: Point(
                coordinates: Position(
                  _currentPosition?.longitude ?? AppConstants.defaultLng,
                  _currentPosition?.latitude ?? AppConstants.defaultLat,
                ),
              ),
              zoom: 13,
            ),
            onMapCreated: _onMapCreated,
          ),

          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: GestureDetector(
              onTap: () {
                _stopNavigation();
                Navigator.pop(context);
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back, color: AppColors.primaryBlue),
              ),
            ),
          ),

          // Direction Banner (when navigating)
          if (_isNavigating && _routeSteps.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentStepIndex < _routeSteps.length
                          ? _routeSteps[_currentStepIndex]['instruction'] ?? 'Continue'
                          : 'Arriving',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (_currentStepIndex < _routeSteps.length &&
                        (_routeSteps[_currentStepIndex]['name'] as String).isNotEmpty)
                      Text(
                        _routeSteps[_currentStepIndex]['name'],
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.white.withValues(alpha: 0.7),
              child: const Center(child: CircularProgressIndicator()),
            ),

          // Bottom Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Station name
                  Text(
                    widget.station.name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Time, Distance, ETA row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            '${_routeDuration.toInt()} min',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          Text('Time left',
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                      Container(width: 1, height: 40, color: Colors.grey.shade200),
                      Column(
                        children: [
                          Text(
                            '${_routeDistance.toStringAsFixed(1)} km',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text('Distance',
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                      Container(width: 1, height: 40, color: Colors.grey.shade200),
                      Column(
                        children: [
                          Text(
                            etaFormatted,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text('Arriving at',
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Divider(color: Colors.grey.shade200),
                  const SizedBox(height: 8),

                  // Battery info row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildBatteryInfo(
                        'Remaining',
                        '${remaining.toStringAsFixed(0)}%',
                        remaining > 20 ? AppColors.successGreen : AppColors.errorRed,
                      ),
                      _buildBatteryInfo(
                        'Needed',
                        '${widget.batteryNeeded.toStringAsFixed(0)}%',
                        AppColors.textPrimary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Status banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isReachable
                          ? AppColors.successGreen.withValues(alpha: 0.1)
                          : AppColors.errorRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isReachable
                              ? '✅ Safe to reach this station'
                              : '⚠️ Battery may not be enough!',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isReachable
                                ? AppColors.successGreen
                                : AppColors.errorRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Navigation buttons
                  if (!_isNavigating)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _startNavigation,
                        icon: const Icon(Icons.navigation),
                        label: Text(
                          'Start Navigation',
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
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _stopNavigation,
                        icon: const Icon(Icons.stop),
                        label: Text(
                          'Stop Navigation',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.errorRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatteryInfo(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
