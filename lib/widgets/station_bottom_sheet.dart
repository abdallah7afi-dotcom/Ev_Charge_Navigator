import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:ev_charge_navigator/theme/app_theme.dart';
import 'package:ev_charge_navigator/models/station_model.dart';
import 'package:ev_charge_navigator/models/review_model.dart';
import 'package:ev_charge_navigator/services/firestore_service.dart';
import 'package:ev_charge_navigator/services/auth_service.dart';
import 'package:ev_charge_navigator/screens/navigation_page.dart';
import 'package:ev_charge_navigator/widgets/review_card.dart';

class StationBottomSheet {
  static void show(
    BuildContext context,
    StationModel station,
    double batteryLevel,
    double batteryNeeded,
    bool isReachable,
    double userLat,
    double userLng,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => _SheetContent(
          station: station,
          batteryLevel: batteryLevel,
          batteryNeeded: batteryNeeded,
          isReachable: isReachable,
          userLat: userLat,
          userLng: userLng,
          scrollController: scrollController,
        ),
      ),
    );
  }
}

class _SheetContent extends StatefulWidget {
  final StationModel station;
  final double batteryLevel;
  final double batteryNeeded;
  final bool isReachable;
  final double userLat;
  final double userLng;
  final ScrollController scrollController;

  const _SheetContent({
    required this.station,
    required this.batteryLevel,
    required this.batteryNeeded,
    required this.isReachable,
    required this.userLat,
    required this.userLng,
    required this.scrollController,
  });

  @override
  State<_SheetContent> createState() => _SheetContentState();
}

class _SheetContentState extends State<_SheetContent> {
  final FirestoreService _firestoreService = FirestoreService();
  List<ReviewModel> _reviews = [];

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final reviews =
        await _firestoreService.getStationReviews(widget.station.id);
    if (mounted) {
      setState(() {
        _reviews = reviews;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.batteryLevel - widget.batteryNeeded;

    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Station Name
          Text(
            widget.station.name,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.station.address,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // Info Chips + Status Chip
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusChip(widget.station.status),
              _buildInfoChip(
                  Icons.electrical_services, widget.station.connectorType, AppColors.primary),
              _buildInfoChip(
                  Icons.bolt, '${widget.station.power.toStringAsFixed(0)} kW', AppColors.primary),
              _buildInfoChip(
                  Icons.attach_money, '${widget.station.pricePerKwh.toStringAsFixed(2)} SAR/kWh', AppColors.primary),
              _buildInfoChip(
                  Icons.star, widget.station.rating.toStringAsFixed(1), AppColors.accent),
            ],
          ),
          const SizedBox(height: 16),

          // Battery Analysis Panel
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Battery Analysis',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildAnalysisRow('Current Battery:',
                    '${widget.batteryLevel.toStringAsFixed(0)}%', AppColors.primaryBlue),
                _buildAnalysisRow('Battery Needed:',
                    '${widget.batteryNeeded.toStringAsFixed(0)}%', AppColors.textPrimary),
                _buildAnalysisRow(
                  'Remaining After:',
                  '${remaining.toStringAsFixed(0)}%',
                  remaining > 20 ? AppColors.successGreen : AppColors.errorRed,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      widget.isReachable ? Icons.check_circle : Icons.warning,
                      color: widget.isReachable
                          ? AppColors.successGreen
                          : AppColors.errorRed,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.isReachable
                          ? 'Safe to reach'
                          : 'Battery may not be enough',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.isReachable
                            ? AppColors.successGreen
                            : AppColors.errorRed,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Reviews & Written Comments Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'User Reviews & Comments',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showAddReviewDialog(context),
                icon: const Icon(Icons.rate_review_outlined, size: 16),
                label: const Text('Add Review'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(90, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Real-time StreamBuilder for Written Comments & Ratings
          StreamBuilder<List<ReviewModel>>(
            stream: _firestoreService.streamStationReviews(widget.station.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && _reviews.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final reviewsList = snapshot.data ?? _reviews;

              if (reviewsList.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Center(
                    child: Text(
                      'No text comments yet. Tap "Add Review" to write a comment!',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return Column(
                children: reviewsList.map((review) => ReviewCard(review: review)).toList(),
              );
            },
          ),

          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.isReachable
                      ? () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NavigationPage(
                                station: widget.station,
                                batteryLevel: widget.batteryLevel,
                                batteryNeeded: widget.batteryNeeded,
                              ),
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.navigation),
                  label: const Text('Navigate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isReachable
                        ? AppColors.primaryBlue
                        : Colors.grey,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openGoogleMaps(),
                  icon: const Icon(Icons.map),
                  label: const Text('Google Maps'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    side: const BorderSide(color: AppColors.primaryBlue),
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 13, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
          Text(
            value,
            style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.bold, color: valueColor),
          ),
        ],
      ),
    );
  }

  void _showAddReviewDialog(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to leave a review.')),
      );
      return;
    }

    double rating = 3.0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Write a Review',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RatingBar.builder(
                initialRating: 3,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemSize: 36,
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (value) {
                  rating = value;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Share your experience...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (commentController.text.trim().isEmpty) return;

              final review = ReviewModel(
                id: '',
                stationId: widget.station.id,
                userId: authService.user!.uid,
                userName: authService.userName.isNotEmpty
                    ? authService.userName
                    : 'User',
                rating: rating,
                comment: commentController.text.trim(),
                createdAt: DateTime.now(),
              );

              await _firestoreService.addReview(widget.station.id, review);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              _loadReviews();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Submit Comment', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _openGoogleMaps() async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${widget.station.latitude},${widget.station.longitude}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildStatusChip(String currentStatus) {
    Color color = AppColors.positive;
    IconData icon = Icons.check_circle;
    if (currentStatus == 'Occupied') {
      color = Colors.orange;
      icon = Icons.error_outline;
    } else if (currentStatus == 'Maintenance') {
      color = Colors.purple;
      icon = Icons.build_outlined;
    } else if (currentStatus == 'Offline') {
      color = AppColors.negative;
      icon = Icons.cancel;
    }

    return InkWell(
      onTap: _showUpdateStatusDialog,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              currentStatus,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  void _showUpdateStatusDialog() {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Update Station Status',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        children: ['Available', 'Occupied', 'Maintenance', 'Offline'].map((st) {
          Color color = AppColors.positive;
          if (st == 'Occupied') color = Colors.orange;
          if (st == 'Maintenance') color = Colors.purple;
          if (st == 'Offline') color = AppColors.negative;

          return SimpleDialogOption(
            onPressed: () async {
              Navigator.pop(ctx);
              await _firestoreService.updateStationStatus(widget.station.id, st);
              if (mounted) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Station status updated to $st'),
                    backgroundColor: AppColors.positive,
                  ),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(radius: 6, backgroundColor: color),
                  const SizedBox(width: 12),
                  Text(st, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
