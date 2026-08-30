import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ev_charge_navigator/theme/app_theme.dart';

class VehicleCard extends StatelessWidget {
  final String? carName;
  final String? connectorType;
  final double? batteryCapacity;
  final VoidCallback? onTap;

  const VehicleCard({
    super.key,
    this.carName,
    this.connectorType,
    this.batteryCapacity,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
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
        child: carName != null ? _buildCarInfo() : _buildEmptyState(),
      ),
    );
  }

  Widget _buildCarInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.electric_car, color: Colors.white, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                carName!,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildChip(Icons.electrical_services, connectorType ?? ''),
            const SizedBox(width: 8),
            _buildChip(Icons.battery_full, '${batteryCapacity?.toStringAsFixed(0)} kWh'),
          ],
        ),
      ],
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.add_circle_outline, color: Colors.white, size: 48),
        const SizedBox(height: 8),
        Text(
          'No vehicle added',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap to add your EV',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}
