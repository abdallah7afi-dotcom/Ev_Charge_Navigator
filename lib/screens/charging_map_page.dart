import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
import 'package:url_launcher/url_launcher.dart';
import 'package:ev_charge_navigator/theme/app_theme.dart';
import 'package:ev_charge_navigator/models/station_model.dart';
import 'package:ev_charge_navigator/services/firestore_service.dart';
import 'package:ev_charge_navigator/services/location_service.dart';
import 'package:ev_charge_navigator/utils/constants.dart';
import 'package:ev_charge_navigator/widgets/station_bottom_sheet.dart';

class ChargingMapPage extends StatefulWidget {
  const ChargingMapPage({super.key});

  @override
  State<ChargingMapPage> createState() => _ChargingMapPageState();
}

class _ChargingMapPageState extends State<ChargingMapPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();

  MapboxMap? _mapboxMap;
  List<StationModel> _stations = [];
  double? _userLat;
  double? _userLng;
  bool _loading = true;

  CircleAnnotationManager? _stationAnnotationManager;
  CircleAnnotationManager? _userAnnotationManager;

  final Map<String, int> _annotationStationMap = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final position = await _locationService.getCurrentPosition();
      _userLat = position.latitude;
      _userLng = position.longitude;

      final stations = await _firestoreService.getAllStations();

      if (mounted) {
        setState(() {
          _stations = stations;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;

    while (_loading) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    await _addUserMarker();
    await _addStationMarkers();
  }

  Future<void> _addUserMarker() async {
    if (_mapboxMap == null || _userLat == null) return;

    _userAnnotationManager =
        await _mapboxMap!.annotations.createCircleAnnotationManager();
    await _userAnnotationManager!.create(
      CircleAnnotationOptions(
        geometry: Point(
          coordinates: Position(_userLng!, _userLat!),
        ),
        circleRadius: 10.0,
        circleColor: AppColors.primaryBlue.toARGB32(),
        circleStrokeColor: Colors.white.toARGB32(),
        circleStrokeWidth: 3.0,
      ),
    );
  }

  Future<void> _addStationMarkers() async {
    if (_mapboxMap == null || _stations.isEmpty) return;

    _stationAnnotationManager =
        await _mapboxMap!.annotations.createCircleAnnotationManager();

    for (int i = 0; i < _stations.length; i++) {
      final station = _stations[i];
      final annotation = await _stationAnnotationManager!.create(
        CircleAnnotationOptions(
          geometry: Point(
            coordinates: Position(station.longitude, station.latitude),
          ),
          circleRadius: 9.0,
          circleColor: AppColors.accentOrange.toARGB32(),
          circleStrokeColor: Colors.white.toARGB32(),
          circleStrokeWidth: 2.0,
        ),
      );
      _annotationStationMap[annotation.id] = i;
    }

    _stationAnnotationManager!.tapEvents(
      onTap: (CircleAnnotation annotation) {
        final index = _annotationStationMap[annotation.id];
        if (index != null && index < _stations.length) {
          _showStationBottomSheet(_stations[index]);
        }
      },
    );
  }

  void _showStationBottomSheet(StationModel station) {
    StationBottomSheet.show(
      context,
      station,
      75.0, // Default battery level for map view
      18.0, // Estimated battery needed
      true, // Safe to reach
      _userLat ?? AppConstants.defaultLat,
      _userLng ?? AppConstants.defaultLng,
    );
  }

  Future<void> _refreshLocation() async {
    try {
      final position = await _locationService.getCurrentPosition();
      setState(() {
        _userLat = position.latitude;
        _userLng = position.longitude;
      });

      if (_mapboxMap != null) {
        _mapboxMap!.flyTo(
          CameraOptions(
            center: Point(coordinates: Position(_userLng!, _userLat!)),
            zoom: 13,
          ),
          MapAnimationOptions(duration: 1000),
        );

        if (_userAnnotationManager != null) {
          await _userAnnotationManager!.deleteAll();
          await _userAnnotationManager!.create(
            CircleAnnotationOptions(
              geometry:
                  Point(coordinates: Position(_userLng!, _userLat!)),
              circleRadius: 10.0,
              circleColor: AppColors.primaryBlue.toARGB32(),
              circleStrokeColor: Colors.white.toARGB32(),
              circleStrokeWidth: 3.0,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Charging Map',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey('charging_map'),
            mapOptions: MapOptions(
              pixelRatio: MediaQuery.of(context).devicePixelRatio,
            ),
            styleUri: MapboxStyles.MAPBOX_STREETS,
            viewport: CameraViewportState(
              center: Point(
                coordinates: Position(
                  _userLng ?? AppConstants.defaultLng,
                  _userLat ?? AppConstants.defaultLat,
                ),
              ),
              zoom: 11,
            ),
            onMapCreated: _onMapCreated,
          ),

          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.ev_station,
                        color: AppColors.primaryBlue, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '${_stations.length} stations',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _refreshLocation,
                      child: const Icon(Icons.my_location,
                          color: AppColors.primaryBlue, size: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: ElevatedButton.icon(
              onPressed: () async {
                final lat = _userLat ?? AppConstants.defaultLat;
                final lng = _userLng ?? AppConstants.defaultLng;
                final url = Uri.parse(
                  'https://www.google.com/maps/search/EV+charging+station/@$lat,$lng,12z',
                );
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.search),
              label: const Text('Find EV Stations on Google Maps'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          if (_loading)
            Container(
              color: Colors.white.withValues(alpha: 0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}


