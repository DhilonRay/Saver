import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'trip_rating_controller.dart';

class TripRatingPage extends StatelessWidget {
  final Map<String, dynamic> orderData;
  const TripRatingPage({super.key, required this.orderData});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TripRatingController>(
      init: TripRatingController(orderData: orderData),
      builder: (controller) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text(
              'সার্ভিস রেটিং',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
            actions: [
              TextButton(
                onPressed: controller.skipRating,
                child: const Text('বাদ দিন', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon and Title
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle, color: Colors.blue.shade700, size: 50),
                ),
                const SizedBox(height: 16),
                const Text(
                  'আপনার যাত্রা সম্পন্ন হয়েছে!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Text(
                  'আপনার অভিজ্ঞতা কেমন ছিল? আমাদের জানান।',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 32),

                // Driver Rating Section
                _buildRatingCard(
                  title: 'চালককে রেটিং দিন',
                  subtitle: orderData['partnerName'] ?? 'অ্যাম্বুলেন্স চালক',
                  ratingValue: controller.driverRating,
                  onRatingChanged: controller.setDriverRating,
                  icon: Icons.person_pin,
                ),

                const SizedBox(height: 20),

                // Company Rating Section
                _buildRatingCard(
                  title: 'কোম্পানিকে রেটিং দিন',
                  subtitle: orderData['companyName'] ?? 'অ্যাম্বুলেন্স কোম্পানি',
                  ratingValue: controller.companyRating,
                  onRatingChanged: controller.setCompanyRating,
                  icon: Icons.business,
                ),

                const SizedBox(height: 32),

                // Complaint Section
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'অভিযোগ বা পরামর্শ (যদি থাকে)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller.complaintController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'এখানে আপনার অভিযোগ বা পরামর্শ লিখুন...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),

                const SizedBox(height: 40),

                // Submit Button
                Obx(() => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.isSubmitting.value ? null : controller.submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: controller.isSubmitting.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'রেটিং জমা দিন',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                )),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRatingCard({
    required String title,
    required String subtitle,
    required RxInt ratingValue,
    required Function(int) onRatingChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.blue.shade600, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < ratingValue.value ? Icons.star : Icons.star_border,
                      color: Colors.amber.shade600,
                      size: 40,
                    ),
                    onPressed: () => onRatingChanged(index + 1),
                  );
                }),
              )),
        ],
      ),
    );
  }
}
