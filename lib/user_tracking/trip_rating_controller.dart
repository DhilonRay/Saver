import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:saver/components/alert.dart';
import 'package:saver/home_user/home_user.dart';
import '../../services/supabase_service.dart';

class TripRatingController extends GetxController {
  final Map<String, dynamic> orderData;
  TripRatingController({required this.orderData});

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // State variables
  var driverRating = 0.obs;
  var companyRating = 0.obs;
  final complaintController = TextEditingController();
  var isSubmitting = false.obs;

  void setDriverRating(int value) {
    driverRating.value = value;
  }

  void setCompanyRating(int value) {
    companyRating.value = value;
  }

  Future<void> submitReview() async {
    if (driverRating.value == 0 || companyRating.value == 0) {
      Alert.info('দয়া করে চালক এবং কোম্পানি উভয়কেই রেটিং দিন');
      return;
    }

    isSubmitting.value = true;

    try {
      final user = _auth.currentUser;
      final orderId = orderData['id'] ?? orderData['orderId'];
      final partnerId = orderData['partnerId'];

      await SupabaseService.addOrderReview(
        SupabaseService.buildOrderReviewPayload(
          orderId: orderId,
          userId: user?.uid,
          partnerId: partnerId,
          companyName: orderData['companyName'] ?? 'Unknown Company',
          driverRating: driverRating.value,
          companyRating: companyRating.value,
          complaint: complaintController.text.trim(),
        ),
      );

      // Update the order document to mark as reviewed (optional but good)
      if (orderId != null) {
        await SupabaseService.updateOrder(orderId, {
          'isReviewed': true,
          'driverRating': driverRating.value,
          'companyRating': companyRating.value,
        });
      }

      await Alert.success('আপনার মতামতের জন্য ধন্যবাদ!');
      Get.offAll(() => HomePage());
    } catch (e) {
      debugPrint('Error submitting review: $e');
      Alert.info('রিভিউ সাবমিট করতে সমস্যা হয়েছে। আবার চেষ্টা করুন।');
    } finally {
      isSubmitting.value = false;
    }
  }

  void skipRating() {
    Get.offAll(() => HomePage());
  }

  @override
  void onClose() {
    complaintController.dispose();
    super.onClose();
  }
}
