import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ev_charge_navigator/theme/app_theme.dart';
import 'package:ev_charge_navigator/models/car_model.dart';
import 'package:ev_charge_navigator/services/auth_service.dart';
import 'package:ev_charge_navigator/services/firestore_service.dart';
import 'package:ev_charge_navigator/utils/constants.dart';

class CarSelectionPage extends StatefulWidget {
  const CarSelectionPage({super.key});

  @override
  State<CarSelectionPage> createState() => _CarSelectionPageState();
}

class _CarSelectionPageState extends State<CarSelectionPage> {
  int? _selectedIndex;
  bool _isSaving = false;
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _handleGetStarted() async {
    if (_selectedIndex == null) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.isLoggedIn) return;

    setState(() => _isSaving = true);

    try {
      final carData = EVCarDatabase.cars[_selectedIndex!];
      final car = CarModel(
        id: CarModel.generateId(carData['name'].toString()),
        name: carData['name'],
        connectorType: carData['connectorType'],
        batteryCapacity: carData['batteryCapacity'],
      );

      await _firestoreService.saveCar(authService.user!.uid, car);

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving vehicle: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<AuthService>(context);
    final selectedCar =
        _selectedIndex != null ? EVCarDatabase.cars[_selectedIndex!] : null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Select Your Vehicle',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dropdown

            // Dropdown
            DropdownButtonFormField<int>(
              value: _selectedIndex,
              isExpanded: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.directions_car,
                    color: AppColors.primaryBlue),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              hint: Text('Select your EV model',
                  style: GoogleFonts.inter(color: AppColors.textSecondary)),
              items: List.generate(
                EVCarDatabase.cars.length,
                (index) => DropdownMenuItem<int>(
                  value: index,
                  child: Text(
                    EVCarDatabase.cars[index]['name'],
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() => _selectedIndex = value);
              },
            ),
            const SizedBox(height: 16),

            // Selected car info
            if (selectedCar != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.lightBlue.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.electrical_services,
                            color: AppColors.primaryBlue, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Connector: ',
                          style: GoogleFonts.inter(
                              fontSize: 14, color: AppColors.textSecondary),
                        ),
                        Text(
                          selectedCar['connectorType'],
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.battery_full,
                            color: AppColors.primaryBlue, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Battery: ',
                          style: GoogleFonts.inter(
                              fontSize: 14, color: AppColors.textSecondary),
                        ),
                        Text(
                          '${selectedCar['batteryCapacity']} kWh',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Get Started button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed:
                    _selectedIndex != null && !_isSaving ? _handleGetStarted : null,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Get Started',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
