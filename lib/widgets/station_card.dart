import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ev_charge_navigator/theme/app_theme.dart';
import 'package:ev_charge_navigator/models/station_model.dart';

class StationCard extends StatelessWidget {
  final int rank;
  final StationModel station;
  final double distance;
  final double batteryNeeded;
  final bool isReachable;
  final VoidCallback onNavigate;
  final VoidCallback onGoogleMaps;
  final VoidCallback onTap;

  const StationCard({
    super.key,
    required this.rank,
    required this.station,
    required this.distance,
    required this.batteryNeeded,
    required this.isReachable,
    required this.onNavigate,
    required this.onGoogleMaps,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    isReachable ? AppColors.successGreen : AppColors.errorRed,
                child: Text(
                  '$rank',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.name,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${distance.toStringAsFixed(1)} km away',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isReachable
                                ? AppColors.successGreen.withValues(alpha: 0.1)
                                : AppColors.errorRed.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isReachable ? 'Reachable ✅' : 'Too Far ❌',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isReachable
                                  ? AppColors.successGreen
                                  : AppColors.errorRed,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${batteryNeeded.toStringAsFixed(0)}% needed',
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
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.map_outlined),
                    color: AppColors.primaryBlue,
                    onPressed: onGoogleMaps,
                    tooltip: 'Open in Google Maps',
                    iconSize: 22,
                  ),
                  IconButton(
                    icon: const Icon(Icons.navigation_rounded),
                    color: isReachable ? AppColors.primaryBlue : Colors.grey,
                    onPressed: isReachable ? onNavigate : null,
                    tooltip: 'Navigate',
                    iconSize: 22,
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
