import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../admin_theme.dart';
import 'package:intl/intl.dart';

class ReviewsPage extends StatelessWidget {
  const ReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('User Reviews & Ratings', style: AdminTheme.heading1),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client
                  .from('order_reviews')
                  .stream(primaryKey: ['id'])
                  .order('timestamp', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AdminTheme.accent),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Error loading reviews', style: AdminTheme.body),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No reviews found', style: AdminTheme.body),
                  );
                }

                final reviews = snapshot.data!;

                return ListView.builder(
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final data = reviews[index];
                    
                    final driverRating = data['driverRating'] ?? 0;
                    final companyRating = data['companyRating'] ?? 0;
                    final complaint = data['complaint'] ?? '';
                    final companyName = data['companyName'] ?? 'Unknown Company';
                    
                    DateTime? date;
                    if (data['timestamp'] != null) {
                      date = DateTime.parse(data['timestamp'].toString());
                    }
                    
                    final dateString = date != null 
                        ? DateFormat('dd MMM yyyy, hh:mm a').format(date)
                        : 'Unknown date';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AdminTheme.bgSurface.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(companyName, style: AdminTheme.heading3),
                              Text(dateString, style: AdminTheme.caption),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildRatingChip('Driver', driverRating),
                              const SizedBox(width: 12),
                              _buildRatingChip('Company', companyRating),
                            ],
                          ),
                          if (complaint.toString().trim().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AdminTheme.red.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AdminTheme.red.withOpacity(0.1)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.feedback_outlined, size: 16, color: AdminTheme.red),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      complaint,
                                      style: AdminTheme.bodySmall.copyWith(color: AdminTheme.textPrimary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingChip(String label, dynamic rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AdminTheme.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AdminTheme.amber.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: AdminTheme.caption.copyWith(color: AdminTheme.textSecondary)),
          const Icon(Icons.star_rounded, color: AdminTheme.amber, size: 14),
          const SizedBox(width: 2),
          Text(
            rating.toString(),
            style: const TextStyle(
              color: AdminTheme.amber,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
