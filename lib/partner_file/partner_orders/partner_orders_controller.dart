import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/notification_service.dart';
import '../../services/supabase_service.dart';

class PartnerOrdersController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxString partnerId = ''.obs;
  final RxList<Map<String, dynamic>> activeOrders =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> completedOrders =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> cancelledOrders =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;

  StreamSubscription<List<Map<String, dynamic>>>? _ordersSubscription;

  @override
  void onInit() {
    super.onInit();
    partnerId.value = _auth.currentUser?.uid ?? '';
    if (partnerId.value.isNotEmpty) {
      _setupOrdersStream();
    }
  }

  @override
  void onClose() {
    _ordersSubscription?.cancel();
    super.onClose();
  }

  void _setupOrdersStream() {
    _ordersSubscription = getOrdersStream().listen((list) {
      activeOrders.value = list.where((item) {
        final data = SupabaseService.toCamelCase(item);
        final status = data['status'];
        return status == 'active' ||
            status == 'accepted' ||
            status == 'inTransit' ||
            status == 'in_transit' ||
            status == 'pickup' ||
            status == 'declined';
      }).map((item) => SupabaseService.toCamelCase(item)).toList();

      completedOrders.value = list.where((item) {
        final data = SupabaseService.toCamelCase(item);
        return data['status'] == 'completed';
      }).map((item) => SupabaseService.toCamelCase(item)).toList();

      cancelledOrders.value = list.where((item) {
        final data = SupabaseService.toCamelCase(item);
        return data['status'] == 'cancelled';
      }).map((item) => SupabaseService.toCamelCase(item)).toList();

      isLoading.value = false;
    });
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await SupabaseService.updateOrder(orderId, {'status': newStatus});

      // Send notification to user about status change
      await _sendStatusChangeNotification(orderId, newStatus);

      Get.snackbar(
        'Success',
        'Order status updated to $newStatus',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update order status: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  // Send notification to user when order status changes
  Future<void> _sendStatusChangeNotification(
      String orderId, String status) async {
    try {
      // Get order data to find userId
      final orderMap = await SupabaseService.getOrder(orderId);
      if (orderMap == null) return;
      final orderData = SupabaseService.toCamelCase(orderMap);
      final userId = orderData['userId'];
      if (userId == null) return;

      // Get user's FCM token
      final userMap = await SupabaseService.getUser(userId);
      if (userMap == null) return;
      final userData = SupabaseService.toCamelCase(userMap);

      final fcmToken = userData['fcmToken'];
      if (fcmToken != null && fcmToken.isNotEmpty) {
        String title = 'Order Status Update';
        String body = 'Your order status has been updated to: $status';

        // Customize message based on status
        switch (status) {
          case 'accepted':
            title = 'রাইড গ্রহণ করা হয়েছে';
            body = 'আপনার রাইড গ্রহণ করা হয়েছে। অ্যাম্বুলেন্স আসছে।';
            break;
          case 'in_transit':
          case 'inTransit':
            title = 'অ্যাম্বুলেন্স রওনা হয়েছে';
            body = 'আপনার অ্যাম্বুলেন্স রওনা হয়েছে।';
            break;
          case 'pickup':
            title = 'পেশেন্ট পিকআপ সম্পন্ন';
            body = 'পেশেন্ট পিকআপ সম্পন্ন হয়েছে। গন্তব্যের দিকে যাচ্ছে।';
            break;
          case 'to_destination':
            title = 'গন্তব্যের দিকে যাচ্ছে';
            body = 'অ্যাম্বুলেন্স গন্তব্যের দিকে যাচ্ছে।';
            break;
          case 'completed':
            title = 'রাইড সম্পন্ন';
            body = 'আপনার রাইড সম্পন্ন হয়েছে।';
            break;
          case 'cancelled':
            title = 'রাইড বাতিল';
            body = 'আপনার রাইড বাতিল করা হয়েছে।';
            break;
        }

        await NotificationService.sendFCMNotification(
          token: fcmToken,
          title: title,
          body: body,
          data: {
            'type': 'status_update',
            'orderId': orderId,
            'status': status,
          },
        );
        debugPrint('✅ Status change notification sent for status: $status');
      }
    } catch (e) {
      debugPrint('❌ Error sending status change notification: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final userMap = await SupabaseService.getUser(userId);
      return userMap != null ? SupabaseService.toCamelCase(userMap) : null;
    } catch (e) {
      return null;
    }
  }

  Stream<List<Map<String, dynamic>>> getOrdersStream() {
    if (partnerId.value.isEmpty) {
      return const Stream.empty();
    }

    return SupabaseService.client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('partner_id', partnerId.value);
  }

  void showOrderDetails(BuildContext context, String? userId, String? userName,
      String? companyName, String? orderStatus) async {
    if (userId == null) {
      Get.snackbar(
        'Error',
        'User information not available.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final userData = await getUserData(userId);

    String userNameInDialog = userName ?? 'User Info Not Available';
    String userPhoneInDialog =
        userData?['phone'] as String? ?? 'Number not available';
    String userLocationInDialog = 'Location not available';

    if (userData != null) {
      final latitude = userData['latitude'];
      final longitude = userData['longitude'];

      if (latitude != null && longitude != null) {
        userLocationInDialog =
            'Lat: ${latitude.toStringAsFixed(2)}, Lng: ${longitude.toStringAsFixed(2)}';
      }
    }

    Get.dialog(
      AlertDialog(
        title: const Text('Order Details'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('User: $userNameInDialog'),
            Text('User ID: ${userId.substring(0, 8)}...'),
            if (companyName != null) Text('Company: $companyName'),
            Text(userLocationInDialog),
            Text('Phone: $userPhoneInDialog'),
            if (orderStatus != null) Text('Status: $orderStatus'),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Close'),
            onPressed: () => Get.back(),
          ),
        ],
      ),
    );
  }

  Color getStatusColor(String? status, ColorScheme colorScheme) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange.shade700;
      case 'processing':
        return colorScheme.secondary;
      case 'shipped':
        return Colors.blue.shade700;
      case 'delivered':
        return Colors.green.shade700;
      case 'cancelled':
        return Colors.red.shade700;
      case 'accepted':
        return Colors.green.shade700;
      default:
        return colorScheme.onSurface.withValues(alpha: 0.6);
    }
  }
}
