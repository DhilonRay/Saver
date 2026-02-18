import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Controller for fare negotiation between user and driver.
/// Manages the Accept / Reject / Counter Offer flow.
class FareNegotiationController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Arguments passed when navigating ──
  late String requestId;
  late String driverId;
  late double originalFare;

  // ── Reactive state ──
  final RxString negotiationStatus =
      'pending'.obs; // pending, accepted, rejected, counter
  final RxDouble currentFare = 0.0.obs;
  final RxDouble counterFare = 0.0.obs;
  final RxString counterBy = ''.obs; // 'user' or 'driver'
  final RxBool isUserAccepted = false.obs;
  final RxBool isDriverAccepted = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isWaitingForDriver = false.obs;
  final RxString statusMessage = ''.obs;

  StreamSubscription<DocumentSnapshot>? _negotiationListener;

  // Service charge
  static const double serviceChargePercent = 5.0;

  @override
  void onInit() {
    super.onInit();

    // Read arguments
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    requestId = args['requestId'] ?? '';
    driverId = args['driverId'] ?? '';
    originalFare = (args['fare'] as num?)?.toDouble() ?? 0.0;

    currentFare.value = originalFare;
    statusMessage.value = 'ড্রাইভারের প্রস্তাবিত ভাড়া';

    if (requestId.isNotEmpty) {
      _startListeningToNegotiation();
    }
  }

  @override
  void onClose() {
    _negotiationListener?.cancel();
    super.onClose();
  }

  /// Listen to Firestore for real-time negotiation updates
  void _startListeningToNegotiation() {
    _negotiationListener = _firestore
        .collection('orders')
        .doc(requestId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final negotiation = data['negotiation'] as Map<String, dynamic>? ?? {};

      // Update local state from Firestore
      final driverAccepted = negotiation['driverAccepted'] as bool? ?? false;
      final userAccepted = negotiation['userAccepted'] as bool? ?? false;
      final status = negotiation['status'] as String? ?? 'pending';
      final counterByValue = negotiation['counterBy'] as String? ?? '';
      final counterFareValue =
          (negotiation['counterFare'] as num?)?.toDouble() ?? 0.0;

      isDriverAccepted.value = driverAccepted;
      isUserAccepted.value = userAccepted;
      negotiationStatus.value = status;
      counterBy.value = counterByValue;

      // If driver sent a counter offer
      if (counterByValue == 'driver' && counterFareValue > 0) {
        currentFare.value = counterFareValue;
        counterFare.value = counterFareValue;
        isWaitingForDriver.value = false;
        statusMessage.value = 'ড্রাইভার নতুন ভাড়া প্রস্তাব করেছে';
      }

      // If driver accepted
      if (driverAccepted && !userAccepted) {
        isWaitingForDriver.value = false;
        statusMessage.value = 'ড্রাইভার আপনার অফার গ্রহণ করেছে! নিশ্চিত করুন।';
      }

      // If driver rejected
      if (status == 'rejected') {
        isWaitingForDriver.value = false;
        statusMessage.value = 'ড্রাইভার ভাড়া প্রত্যাখ্যান করেছে';
        negotiationStatus.value = 'rejected';
      }

      // If both accepted → Trip Confirmed → Go to Payment
      if (driverAccepted && userAccepted) {
        negotiationStatus.value = 'confirmed';
        statusMessage.value = 'ট্রিপ নিশ্চিত হয়েছে! পেমেন্ট পেজে যাচ্ছে...';
        _navigateToPayment();
      }
    });
  }

  /// User accepts the current fare
  Future<void> acceptFare() async {
    try {
      isLoading.value = true;

      await _firestore.collection('orders').doc(requestId).update({
        'negotiation.userAccepted': true,
        'negotiation.status': 'user_accepted',
        'negotiation.acceptedFare': currentFare.value,
        'negotiation.updatedAt': Timestamp.now(),
      });

      isUserAccepted.value = true;

      // If driver already accepted, both accepted → confirmed
      if (isDriverAccepted.value) {
        await _firestore.collection('orders').doc(requestId).update({
          'status': 'confirmed',
          'negotiation.status': 'confirmed',
          'confirmedFare': currentFare.value,
        });
        negotiationStatus.value = 'confirmed';
        statusMessage.value = 'ট্রিপ নিশ্চিত হয়েছে!';
        _navigateToPayment();
      } else {
        isWaitingForDriver.value = true;
        statusMessage.value = 'ড্রাইভার প্রতিক্রিয়ার অপেক্ষায়...';
      }
    } catch (e) {
      debugPrint('❌ Error accepting fare: $e');
      Get.snackbar(
        'ত্রুটি',
        'ভাড়া গ্রহণ করতে সমস্যা হয়েছে',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// User rejects the fare
  Future<void> rejectFare() async {
    try {
      isLoading.value = true;

      await _firestore.collection('orders').doc(requestId).update({
        'negotiation.userAccepted': false,
        'negotiation.status': 'rejected',
        'negotiation.rejectedBy': 'user',
        'negotiation.updatedAt': Timestamp.now(),
        'status': 'cancelled',
      });

      negotiationStatus.value = 'rejected';
      statusMessage.value = 'আপনি ভাড়া প্রত্যাখ্যান করেছেন';

      // Go back after a brief delay
      await Future.delayed(const Duration(seconds: 1));
      Get.back();
    } catch (e) {
      debugPrint('❌ Error rejecting fare: $e');
      Get.snackbar(
        'ত্রুটি',
        'ভাড়া প্রত্যাখ্যান করতে সমস্যা হয়েছে',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// User sends a counter offer with a new fare
  Future<void> sendCounterOffer(double newFare) async {
    if (newFare <= 0) {
      Get.snackbar(
        'ত্রুটি',
        'সঠিক ভাড়া লিখুন',
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
      );
      return;
    }

    try {
      isLoading.value = true;

      await _firestore.collection('orders').doc(requestId).update({
        'negotiation.counterFare': newFare,
        'negotiation.counterBy': 'user',
        'negotiation.status': 'counter',
        'negotiation.userAccepted': false,
        'negotiation.driverAccepted': false,
        'negotiation.updatedAt': Timestamp.now(),
      });

      currentFare.value = newFare;
      counterFare.value = newFare;
      isWaitingForDriver.value = true;
      isUserAccepted.value = false;
      isDriverAccepted.value = false;
      statusMessage.value =
          'আপনার কাউন্টার অফার পাঠানো হয়েছে। ড্রাইভারের উত্তরের অপেক্ষায়...';
    } catch (e) {
      debugPrint('❌ Error sending counter offer: $e');
      Get.snackbar(
        'ত্রুটি',
        'কাউন্টার অফার পাঠাতে সমস্যা হয়েছে',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Navigate to Payment Page once both parties accept
  void _navigateToPayment() {
    Future.delayed(const Duration(milliseconds: 800), () {
      Get.offNamed('/payment', arguments: {
        'requestId': requestId,
        'driverId': driverId,
        'fare': currentFare.value,
      });
    });
  }

  /// Calculate service charge
  double get serviceCharge => currentFare.value * (serviceChargePercent / 100);

  /// Calculate grand total
  double get grandTotal => currentFare.value + serviceCharge;
}
