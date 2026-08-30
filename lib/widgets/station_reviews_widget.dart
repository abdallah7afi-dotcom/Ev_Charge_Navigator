import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class StationReviewsWidget extends StatefulWidget {
  final String stationId;

  const StationReviewsWidget({
    super.key,
    required this.stationId,
  });

  @override
  State<StationReviewsWidget> createState() => _StationReviewsWidgetState();
}

class _StationReviewsWidgetState extends State<StationReviewsWidget> {
  final TextEditingController _commentController = TextEditingController();
  double _userRating = 4.0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a comment before submitting.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? 'anonymous';
      final userName = user?.displayName ?? user?.email?.split('@').first ?? 'EV Driver';

      await FirebaseFirestore.instance
          .collection('charging_stations')
          .doc(widget.stationId)
          .collection('reviews')
          .add({
        'stationId': widget.stationId,
        'userId': userId,
        'userName': userName,
        'rating': _userRating,
        'comment': commentText,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _commentController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Review submitted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting review: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Text(
          'Reviews & Comments',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Input Box (Rating + TextField + Submit Button)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Leave a Review:',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              // Star Rating Picker
              RatingBar.builder(
                initialRating: _userRating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemSize: 28,
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (rating) {
                  setState(() => _userRating = rating);
                },
              ),
              const SizedBox(height: 10),

              // Comment TextField
              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Type your experience or comment here...',
                  hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Submit Button
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitComment,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send, size: 16),
                  label: Text(
                    _isSubmitting ? 'Submitting...' : 'Submit Comment',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // StreamBuilder for Existing Reviews
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('charging_stations')
              .doc(widget.stationId)
              .collection('reviews')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return Text(
                'Error loading reviews: ${snapshot.error}',
                style: GoogleFonts.inter(color: Colors.red, fontSize: 12),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'No reviews yet. Be the first to leave a comment!',
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final userName = data['userName'] ?? 'User';
                final comment = data['comment'] ?? '';
                final rating = (data['rating'] ?? 0).toDouble();
                final timestamp = data['createdAt'] as Timestamp?;
                final dateStr = timestamp != null
                    ? '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}'
                    : 'Just now';

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: Theme.of(context).primaryColor,
                              child: Text(
                                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                userName,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(5, (starIdx) {
                                return Icon(
                                  starIdx < rating.floor() ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                  size: 14,
                                );
                              }),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              dateStr,
                              style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                        if (comment.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            comment,
                            style: GoogleFonts.inter(fontSize: 13, color: Colors.black87),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
