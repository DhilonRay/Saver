import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Controller for the Payment Page.
/// Handles Cash and bKash payment methods.
class PaymentController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Arguments ──
  late String requestId;
  late String driverId;
  late double fare;

  // ── Reactive state ──
  final RxString paymentMethod = 'cash'.obs; // 'cash' or 'bkash'
  final RxString trxId = ''.obs;
  final RxString driverBkashNumber = ''.obs;
  final RxString driverName = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool isPaymentConfirmed = false.obs;

  // Service charge
  static const double serviceChargePercent = 5.0;

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments as Map<String, dynamic>? ?? {};
    requestId = args['requestId'] ?? '';
    driverId = args['driverId'] ?? '';
    fare = (args['fare'] as num?)?.toDouble() ?? 0.0;

    _fetchDriverDetails();
  }

  /// Fetch driver's bKash number and name
  Future<void> _fetchDriverDetails() async {
    if (driverId.isEmpty) return;

    try {
      final doc = await _firestore.collection('partners').doc(driverId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        driverBkashNumber.value = data['bkashNumber'] as String? ?? '';
        driverName.value = data['name'] as String? ?? 'ড্রাইভার';
      }
    } catch (e) {
      debugPrint('❌ Error fetching driver details: $e');
    }
  }

  /// Select payment method
  void selectPaymentMethod(String method) {
    paymentMethod.value = method;
    trxId.value = ''; // Reset TRXID when switching
  }

  /// Calculate service charge
  double get serviceCharge => fare * (serviceChargePercent / 100);

  /// Calculate grand total
  double get grandTotal => fare + serviceCharge;

  /// Show feedback dialog (used instead of Get.snackbar to avoid Overlay issues)
  void _showFeedback({
    required String title,
    required String message,
    Color? backgroundColor,
    Color? textColor,
    bool autoClose = false,
    bool navigateHome = false,
  }) {
    Get.dialog(
      AlertDialog(
        backgroundColor: backgroundColor ?? Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: TextStyle(
            color: textColor ?? Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            color: textColor ?? Colors.black54,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              try {
                Get.back();
              } catch (_) {}
              if (navigateHome) {
                Get.offAllNamed('/HomePage');
              }
            },
            child: Text(
              'ঠিক আছে',
              style: TextStyle(
                color: textColor ?? Colors.green.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    // Auto-close success dialogs after 3 seconds
    if (autoClose) {
      Future.delayed(const Duration(seconds: 3), () {
        if (Get.isDialogOpen ?? false) {
          try {
            Get.back();
          } catch (_) {}
          if (navigateHome) {
            Get.offAllNamed('/HomePage');
          }
        }
      });
    }
  }

  /// Confirm Cash payment
  Future<void> confirmCashPayment() async {
    try {
      isLoading.value = true;

      final userId = _auth.currentUser?.uid ?? '';

      await _firestore.collection('orders').doc(requestId).update({
        'payment': {
          'method': 'cash',
          'status': 'pending_collection',
          'fare': fare,
          'serviceCharge': serviceCharge,
          'grandTotal': grandTotal,
          'userId': userId,
          'driverId': driverId,
          'confirmedAt': Timestamp.now(),
        },
      });

      isPaymentConfirmed.value = true;

      _showFeedback(
        title: '✅ সফল',
        message:
            'ক্যাশ পেমেন্ট নিশ্চিত হয়েছে। রাইড শেষে ড্রাইভারকে ৳${grandTotal.toStringAsFixed(0)} দিন।',
        backgroundColor: Colors.green.shade50,
        textColor: Colors.green.shade800,
        autoClose: true,
        navigateHome: true,
      );
    } catch (e) {
      debugPrint('❌ Error confirming cash payment: $e');
      _showFeedback(
        title: 'ত্রুটি',
        message: 'পেমেন্ট নিশ্চিত করতে সমস্যা হয়েছে',
        backgroundColor: Colors.red.shade50,
        textColor: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Submit bKash payment with TRXID
  Future<void> submitBkashPayment(String transactionId) async {
    if (transactionId.trim().isEmpty) {
      _showFeedback(
        title: 'ত্রুটি',
        message: 'TRXID লিখুন',
        backgroundColor: Colors.orange.shade50,
        textColor: Colors.orange.shade800,
      );
      return;
    }

    try {
      isLoading.value = true;

      final userId = _auth.currentUser?.uid ?? '';

      await _firestore.collection('orders').doc(requestId).update({
        'payment': {
          'method': 'bkash',
          'status': 'pending_verification',
          'trxId': transactionId.trim(),
          'fare': fare,
          'serviceCharge': serviceCharge,
          'grandTotal': grandTotal,
          'driverBkashNumber': driverBkashNumber.value,
          'userId': userId,
          'driverId': driverId,
          'confirmedAt': Timestamp.now(),
        },
      });

      trxId.value = transactionId.trim();
      isPaymentConfirmed.value = true;

      _showFeedback(
        title: '✅ সফল',
        message:
            'bKash পেমেন্ট জমা দেওয়া হয়েছে। ড্রাইভার ও অ্যাডমিন যাচাই করবে।',
        backgroundColor: Colors.green.shade50,
        textColor: Colors.green.shade800,
        autoClose: true,
        navigateHome: true,
      );
    } catch (e) {
      debugPrint('❌ Error submitting bKash payment: $e');
      _showFeedback(
        title: 'ত্রুটি',
        message: 'bKash পেমেন্ট জমা দিতে সমস্যা হয়েছে',
        backgroundColor: Colors.red.shade50,
        textColor: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
