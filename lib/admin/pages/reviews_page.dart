import 'package:flutter/material.dart';
import '../admin_theme.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';

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
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _loadReviews(),
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

                final reviews = snapshot.data ?? [];

                if (reviews.isEmpty) {
                  return const Center(
                    child: Text('No reviews found', style: AdminTheme.body),
                  );
                }

                return ListView.builder(
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final data = reviews[index];
                    final isFeedback = data['recordType'] == 'feedback';
                    final title = data['title'] ?? (isFeedback ? 'User Feedback' : 'Company Review');
                    final details = data['details'] ?? '';
                    final ratingValue = data['ratingValue'] ?? 0;
                    final driverRating = isFeedback ? null : data['driverRating'] ?? 0;
                    final companyRating = isFeedback ? null : data['companyRating'] ?? 0;
                    final companyName = isFeedback
                        ? (data['name'] ?? data['email'] ?? 'User Feedback')
                        : (data['companyName'] ?? 'Unknown Company');
                    final email = data['email'];

                    DateTime? date;
                    final timestampValue = data['submittedAt'] ?? data['timestamp'] ?? data['createdAt'];
                    if (timestampValue != null) {
                      date = DateTime.tryParse(timestampValue.toString());
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
                              if (isFeedback) ...[
                                _buildRatingChip('Rating', ratingValue),
                              ] else ...[
                                _buildRatingChip('Driver', driverRating),
                                const SizedBox(width: 12),
                                _buildRatingChip('Company', companyRating),
                              ],
                            ],
                          ),
                          if (email != null && email.toString().trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Email: $email',
                              style: AdminTheme.bodySmall.copyWith(color: AdminTheme.textSecondary),
                            ),
                          ],
                          if (details.toString().trim().isNotEmpty) ...[
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
                                      details,
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

  Future<List<Map<String, dynamic>>> _loadReviews() async {
    final feedbackRows = await SupabaseService.getAllFeedback();
    final reviewRows = await SupabaseService.getAllOrderReviews();

    final normalizedFeedbacks = feedbackRows.map((item) {
      final data = SupabaseService.toCamelCase(item);
      return {
        ...data,
        'recordType': 'feedback',
        'title': data['name'] ?? 'User Feedback',
        'details': data['feedback'] ?? '',
        'ratingValue': data['rating'] ?? 0,
        'submittedAt': data['createdAt'],
      };
    }).toList();

    final normalizedReviews = reviewRows.map((item) {
      final data = SupabaseService.normalizeOrderReview(item);
      return {
        ...data,
        'recordType': 'order_review',
        'title': data['companyName'] ?? 'Company Review',
        'details': data['complaint'] ?? data['review'] ?? '',
        'ratingValue': ((data['driverRating'] ?? 0) + (data['companyRating'] ?? 0)) / 2,
        'submittedAt': data['timestamp'] ?? data['createdAt'],
      };
    }).toList();

    final all = [...normalizedFeedbacks, ...normalizedReviews];
    all.sort((a, b) {
      final aTs = a['submittedAt'];
      final bTs = b['submittedAt'];
      final aDate = aTs != null ? DateTime.tryParse(aTs.toString()) : null;
      final bDate = bTs != null ? DateTime.tryParse(bTs.toString()) : null;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });
    return all;
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
