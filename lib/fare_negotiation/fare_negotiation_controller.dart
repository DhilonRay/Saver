import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:saver/components/constants/alert.dart';
import '../services/notification_service.dart';

/// Controller for fare negotiation between user and driver.
/// Manages the Accept / Reject / Counter Offer flow.
class FareNegotiationController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;

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

  StreamSubscription<List<Map<String, dynamic>>>? _negotiationListener;
  bool _hasNavigated = false; // Guard to prevent multiple navigations

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

  /// Listen to Supabase for real-time negotiation updates
  void _startListeningToNegotiation() {
    _negotiationListener = _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', requestId)
        .listen((dataList) {
      if (dataList.isEmpty) return;

      final data = dataList.first;
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

      // If user sent a counter offer
      if (counterByValue == 'user') {
        isWaitingForDriver.value = true;
        statusMessage.value = 'ড্রাইভার প্রতিক্রিয়ার অপেক্ষায়...';
      }

      // If driver sent a counter offer
      if (counterByValue == 'driver' && counterFareValue > 0) {
        currentFare.value = counterFareValue;
        counterFare.value = counterFareValue;
        isWaitingForDriver.value = false;
        statusMessage.value = 'ড্রাইভার নতুন ভাড়া প্রস্তাব করেছে';
      }

      // If driver accepted user's offer but user hasn't seen it yet
      if (driverAccepted && !userAccepted) {
        isWaitingForDriver.value = false;
        statusMessage.value = 'ড্রাইভার আপনার অফার গ্রহণ করেছে! নিশ্চিত করুন।';
      }

      // If driver rejected
      if (status == 'rejected' || data['status'] == 'cancelled' || data['status'] == 'declined') {
        isWaitingForDriver.value = false;
        statusMessage.value = 'ড্রাইভার ভাড়া প্রত্যাখ্যান করেছে (Ride Cancelled)';
        negotiationStatus.value = 'rejected';
      }

      // If both accepted → Trip Confirmed → Go to Tracking
      if (driverAccepted && userAccepted && !_hasNavigated) {
        _hasNavigated = true;
        negotiationStatus.value = 'confirmed';
        statusMessage.value = 'ট্রিপ নিশ্চিত হয়েছে! ট্র্যাকিং পেজে যাচ্ছে...';
        _navigateToTracking(data);
      }
    });
  }

  /// User accepts the current fare
  Future<void> acceptFare() async {
    try {
      isLoading.value = true;

      await _supabase.from('orders').update({
        'negotiation': {
          'userAccepted': true,
          'status': 'accepted', // Both are agreeing
          'updatedAt': DateTime.now().toIso8601String(),
        }
      }).eq('id', requestId);

      isUserAccepted.value = true;

      // If driver already accepted (which they do by sending an offer), both accepted → confirmed
      if (isDriverAccepted.value && !_hasNavigated) {
        _hasNavigated = true;
        await _supabase.from('orders').update({
          'status': 'accepted', // Order status becomes accepted for ride start
          'confirmedFare': currentFare.value,
          'negotiation': {
            'status': 'confirmed',
            'userAccepted': true,
            'driverAccepted': true,
          }
        }).eq('id', requestId);
        negotiationStatus.value = 'confirmed';
        statusMessage.value = 'ট্রিপ নিশ্চিত হয়েছে! ট্র্যাকিং পেজে যাচ্ছে...';
        
        // Fetch fresh order data to pass to tracking page
        final orderDoc = await _supabase.from('orders').select().eq('id', requestId).maybeSingle();
        if (orderDoc != null) {
          _navigateToTracking(orderDoc);
        }
      } else if (!isDriverAccepted.value) {
        isWaitingForDriver.value = true;
        statusMessage.value = 'ড্রাইভার প্রতিক্রিয়ার অপেক্ষায়...';
      }
    } catch (e) {
      debugPrint('❌ Error accepting fare: $e');
      Alert.info(
      
        'ভাড়া গ্রহণ করতে সমস্যা হয়েছে',
     
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// User rejects the fare
  Future<void> rejectFare() async {
    try {
      isLoading.value = true;

      final orderDoc = await _supabase.from('orders').select().eq('id', requestId).maybeSingle();
      final partnerId = orderDoc?['partnerId'];

      await _supabase.from('orders').update({
        'status': 'cancelled',
        'negotiation': {
          'userAccepted': false,
          'status': 'rejected',
          'rejectedBy': 'user',
          'updatedAt': DateTime.now().toIso8601String(),
        }
      }).eq('id', requestId);
      
      if (partnerId != null) {
        final partnerDoc = await _supabase.from('partners').select().eq('id', partnerId).maybeSingle();
        final fcmToken = partnerDoc?['fcmToken'];
        if (fcmToken != null) {
          await NotificationService.sendFCMNotification(
            token: fcmToken,
            title: 'অর্ডার বাতিল',
            body: 'গ্রাহক আপনার ভাড়ার প্রস্তাব প্রত্যাখ্যান করেছেন এবং ট্রিপটি বাতিল করেছেন।',
            data: {'type': 'order_cancelled', 'orderId': requestId},
          );
        }
      }

      negotiationStatus.value = 'rejected';
      statusMessage.value = 'আপনি ভাড়া প্রত্যাখ্যান করেছেন';

      // Go back after a brief delay
      await Future.delayed(const Duration(seconds: 1));
      Get.back();
    } catch (e) {
      debugPrint('❌ Error rejecting fare: $e');
      Alert.info(
      
        'ভাড়া প্রত্যাখ্যান করতে সমস্যা হয়েছে',
     
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// User sends a counter offer with a new fare
  Future<void> sendCounterOffer(double newFare) async {
    if (newFare <= 0) {
      Alert.info(
      
        'সঠিক ভাড়া লিখুন',
     
      );
      return;
    }

    try {
      isLoading.value = true;

      await _supabase.from('orders').update({
        'negotiation': {
          'counterFare': newFare,
          'counterBy': 'user',
          'status': 'counter',
          'userAccepted': true, // User agrees to their own proposal
          'driverAccepted': false, // Now waiting for driver to agree
          'updatedAt': DateTime.now().toIso8601String(),
        }
      }).eq('id', requestId);

      currentFare.value = newFare;
      counterFare.value = newFare;
      isWaitingForDriver.value = true;
      isUserAccepted.value = false;
      isDriverAccepted.value = false;
      statusMessage.value =
          'আপনার কাউন্টার অফার পাঠানো হয়েছে। ড্রাইভারের উত্তরের অপেক্ষায়...';
    } catch (e) {
      debugPrint('❌ Error sending counter offer: $e');
      Alert.info(
      
        'কাউন্টার অফার পাঠাতে সমস্যা হয়েছে',
     
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Navigate to Tracking Page once both parties accept
  void _navigateToTracking(Map<String, dynamic> orderData) {
    Future.delayed(const Duration(milliseconds: 300), () {
      // Ensure we have the order ID in the arguments
      final args = Map<String, dynamic>.from(orderData);
      args['id'] = requestId;
      
      Get.offNamed('/user-tracking', arguments: args);
    });
  }

  /// Calculate service charge
  double get serviceCharge => currentFare.value * (serviceChargePercent / 100);

  /// Calculate grand total
  double get grandTotal => currentFare.value + serviceCharge;
}
