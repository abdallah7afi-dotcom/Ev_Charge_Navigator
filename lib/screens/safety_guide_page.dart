import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ev_charge_navigator/theme/app_theme.dart';

class SafetyGuidePage extends StatelessWidget {
  const SafetyGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 24,
                bottom: 32,
                left: 24,
                right: 24,
              ),
              decoration: const BoxDecoration(
                gradient: AppGradients.darkGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'SEC Home Charging',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Safety Guidelines for Electric Vehicles',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Saudi Electricity Company Standards',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),

            // Sections
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSection(
                    icon: Icons.bolt,
                    title: '⚡ Electrical Requirements',
                    items: [
                      'Use a dedicated 240V/40A circuit for Level 2 charging',
                      'Install a GFCI (Ground Fault Circuit Interrupter) outlet',
                      'Ensure proper grounding of all electrical connections',
                      'Wire gauge must be minimum 8 AWG for 40A circuits',
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSection(
                    icon: Icons.build,
                    title: '🔧 Installation Guidelines',
                    items: [
                      'Hire a SEC-licensed electrician for installation',
                      'Keep the charging unit away from water sources',
                      'Install at a height of 1.0-1.5 meters from ground',
                      'Ensure adequate ventilation around the charger',
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSection(
                    icon: Icons.battery_charging_full,
                    title: '🔋 Charging Best Practices',
                    items: [
                      'Keep battery between 20% and 80% for daily use',
                      'Use scheduled charging during off-peak hours (10 PM - 6 AM)',
                      'Avoid charging in extreme temperatures above 45°C',
                      'Unplug the charger when not in use',
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSection(
                    icon: Icons.security,
                    title: '🛡️ Safety Rules',
                    items: [
                      'Never use damaged or frayed charging cables',
                      'Do not charge in flooded or wet conditions',
                      'Keep children away from charging equipment',
                      'Install a fire extinguisher near the charging area',
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSection(
                    icon: Icons.description,
                    title: '📋 SEC Permit Requirements',
                    items: [
                      'Submit application through SEC portal (mysec.com.sa)',
                      'Provide property ownership or NOC documents',
                      'Electrical load study may be required for high-power chargers',
                      'Annual inspection required for commercial installations',
                    ],
                  ),
                  const SizedBox(height: 16),

                  // SEC Contact card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primaryBlue.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.phone,
                            color: AppColors.primaryBlue, size: 28),
                        const SizedBox(height: 8),
                        Text(
                          'SEC Support',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '920001919',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'mysec.com.sa',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<String> items,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.primaryBlue, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryBlue,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
