import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:ev_charge_navigator/theme/app_theme.dart';
import 'package:ev_charge_navigator/services/auth_service.dart';
import 'package:ev_charge_navigator/utils/constants.dart';
import 'package:ev_charge_navigator/screens/login_page.dart';
import 'package:ev_charge_navigator/screens/register_page.dart';
import 'package:ev_charge_navigator/screens/car_selection_page.dart';
import 'package:ev_charge_navigator/screens/main_shell.dart';
import 'package:ev_charge_navigator/screens/charging_map_page.dart';

import 'package:ev_charge_navigator/screens/admin/admin_dashboard.dart';
import 'package:ev_charge_navigator/screens/price_comparison_page.dart';

import 'package:ev_charge_navigator/services/firestore_service.dart';
import 'package:ev_charge_navigator/services/station_seed_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Set Mapbox access token
  MapboxOptions.setAccessToken(AppConstants.mapboxToken);

  // Auto-Load Seed Stations on Startup if Firestore collection is empty
  try {
    await FirestoreService().seedStationsIfEmpty(StationSeedService.riyadhStations);
    await AuthService().seedAdminAccountIfEmpty();
  } catch (_) {}

  runApp(const EVChargeNavigatorApp());
}

class EVChargeNavigatorApp extends StatelessWidget {
  const EVChargeNavigatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: MaterialApp(
        title: 'EV Charge Navigator',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
          '/car-selection': (context) => const CarSelectionPage(),
          '/main': (context) => const MainShell(),
          '/charging-map': (context) => const ChargingMapPage(),
          '/admin': (context) => const AdminDashboardPage(),
          '/price-comparison': (context) => const PriceComparisonPage(),
        },
      ),
    );
  }
}
