import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'fare_negotiation_controller.dart';
import '../widgets/billing_breakdown_widget.dart';

/// Fare negotiation page where user can Accept, Reject, or Counter Offer.
class FareNegotiationPage extends StatelessWidget {
  FareNegotiationPage({super.key});

  final controller = Get.put(FareNegotiationController());
  final TextEditingController _counterFareController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'ভাড়া আলোচনা',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: Obx(() {
        final status = controller.negotiationStatus.value;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status message card
              _buildStatusCard(),
              const SizedBox(height: 20),

              // Billing Breakdown
              BillingBreakdownWidget(
                fare: controller.currentFare.value,
              ),
              const SizedBox(height: 24),

              // Waiting indicator
              if (controller.isWaitingForDriver.value) ...[
                _buildWaitingIndicator(),
                const SizedBox(height: 20),
              ],

              // Action buttons (only show if not confirmed/rejected and not waiting)
              if (status != 'confirmed' &&
                  status != 'rejected' &&
                  !controller.isWaitingForDriver.value) ...[
                _buildActionButtons(context),
              ],

              // Confirmed state
              if (status == 'confirmed') ...[
                _buildConfirmedCard(),
              ],

              // Rejected state
              if (status == 'rejected') ...[
                _buildRejectedCard(),
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatusCard() {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (controller.negotiationStatus.value) {
      case 'confirmed':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade800;
        icon = Icons.check_circle;
        break;
      case 'rejected':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade800;
        icon = Icons.cancel;
        break;
      case 'counter':
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade800;
        icon = Icons.swap_horiz;
        break;
      default:
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade800;
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              controller.statusMessage.value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Colors.amber.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'ড্রাইভার প্রতিক্রিয়ার অপেক্ষায়...',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.amber.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'অনুগ্রহ করে অপেক্ষা করুন',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Accept Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: controller.isLoading.value
                ? null
                : () => controller.acceptFare(),
            icon: const Icon(Icons.check_circle, size: 22),
            label: const Text(
              'গ্রহণ করুন (Accept)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 4,
              shadowColor: Colors.green.shade200,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Counter Offer Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: controller.isLoading.value
                ? null
                : () => _showCounterOfferDialog(context),
            icon:
                Icon(Icons.swap_horiz, size: 22, color: Colors.orange.shade700),
            label: Text(
              'কাউন্টার অফার (Counter Offer)',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.orange.shade700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.orange.shade400, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Reject Button
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: controller.isLoading.value
                ? null
                : () => _showRejectConfirmation(context),
            icon: Icon(Icons.cancel, size: 22, color: Colors.red.shade600),
            label: Text(
              'প্রত্যাখ্যান (Reject)',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.red.shade600,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.red.shade200),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmedCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.green.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle, size: 48, color: Colors.green.shade700),
          const SizedBox(height: 12),
          Text(
            '🎉 ট্রিপ নিশ্চিত হয়েছে!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'পেমেন্ট পেজে নিয়ে যাচ্ছে...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.green.shade600,
            ),
          ),
          const SizedBox(height: 12),
          const CircularProgressIndicator(strokeWidth: 2),
        ],
      ),
    );
  }

  Widget _buildRejectedCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.cancel, size: 48, color: Colors.red.shade600),
          const SizedBox(height: 12),
          Text(
            'ভাড়া আলোচনা ব্যর্থ হয়েছে',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade800,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('ফিরে যান'),
            ),
          ),
        ],
      ),
    );
  }

  void _showCounterOfferDialog(BuildContext context) {
    _counterFareController.clear();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.swap_horiz, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Text(
              'কাউন্টার অফার',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'বর্তমান ভাড়া: ৳${controller.currentFare.value.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _counterFareController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'আপনার প্রস্তাবিত ভাড়া (৳)',
                hintText: 'যেমন: 2000',
                prefixIcon: const Icon(Icons.monetization_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Colors.orange.shade400, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'বাতিল',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final fareText = _counterFareController.text.trim();
              final newFare = double.tryParse(fareText);
              if (newFare != null && newFare > 0) {
                Get.back();
                controller.sendCounterOffer(newFare);
              } else {
                Get.snackbar(
                  'ত্রুটি',
                  'সঠিক ভাড়া লিখুন',
                  backgroundColor: Colors.orange.shade100,
                  colorText: Colors.orange.shade800,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('অফার পাঠান'),
          ),
        ],
      ),
    );
  }

  void _showRejectConfirmation(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Text(
              'নিশ্চিত করুন',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'আপনি কি এই ভাড়া প্রত্যাখ্যান করতে চান? এটি রাইড বাতিল করবে।',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'না',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.rejectFare();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('হ্যাঁ, প্রত্যাখ্যান করুন'),
          ),
        ],
      ),
    );
  }
}
