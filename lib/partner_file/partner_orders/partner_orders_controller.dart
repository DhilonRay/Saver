import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/notification_service.dart';

class PartnerOrdersController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;

  final RxString partnerId = ''.obs;
  final RxList<Map<String, dynamic>> activeOrders = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> completedOrders = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> cancelledOrders = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;

  StreamSubscription<List<Map<String, dynamic>>>? _ordersSubscription;

  @override
  void onInit() {
    super.onInit();
    partnerId.value = _supabase.auth.currentUser?.id ?? '';
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
    _ordersSubscription = getOrdersStream().listen((dataList) {
      activeOrders.value = dataList.where((data) {
        return data['status'] == 'active' ||
            data['status'] == 'accepted' ||
            data['status'] == 'in_transit' ||
            data['status'] == 'pickup' ||
            data['status'] == 'declined';
      }).toList();

      completedOrders.value = dataList.where((data) {
        return data['status'] == 'completed';
      }).toList();

      cancelledOrders.value = dataList.where((data) {
        return data['status'] == 'cancelled';
      }).toList();

      isLoading.value = false;
    });
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _supabase
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId);

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
      final orderDoc = await _supabase.from('orders').select().eq('id', orderId).maybeSingle();
      if (orderDoc == null) return;

      final userId = orderDoc['userId'];
      if (userId == null) return;

      // Get user's FCM token
      final userDoc = await _supabase.from('users').select().eq('id', userId).maybeSingle();
      if (userDoc == null) return;

      final fcmToken = userDoc['fcmToken'];
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
      return await _supabase.from('users').select().eq('id', userId).maybeSingle();
    } catch (e) {
      return null;
    }
  }

  Stream<List<Map<String, dynamic>>> getOrdersStream() {
    if (partnerId.value.isEmpty) {
      return const Stream.empty();
    }

    return _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('partnerId', partnerId.value);
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
