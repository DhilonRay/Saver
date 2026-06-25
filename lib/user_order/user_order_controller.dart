import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserOrderController extends GetxController {
  final SupabaseClient _client = Supabase.instance.client;

  // Reactive variables
  final RxList<Map<String, dynamic>> orders = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;
  final RxString userId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    initializeUser();
  }

  void initializeUser() async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser != null) {
        userId.value = currentUser.id;
        fetchOrders();
      } else {
        final prefs = await SharedPreferences.getInstance();
        bool isGLM = prefs.getBool('isGLMLoggedIn') ?? false;
        String? glmId = prefs.getString('currentGLMId');
        if (isGLM && glmId != null) {
          userId.value = glmId;
          fetchOrders();
        } else {
          isLoading.value = false;
          error.value = 'User not authenticated';
        }
      }
    } catch (e) {
      isLoading.value = false;
      error.value = 'Failed to initialize session: ${e.toString()}';
    }
  }

  Stream<List<Map<String, dynamic>>> getOrdersStream() {
    if (userId.isEmpty) return const Stream.empty();

    // Show all orders for the user
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('userId', userId.value);
  }

  void fetchOrders() async {
    if (userId.isEmpty) return;

    try {
      isLoading.value = true;
      error.value = '';

      final snapshot = await _client
          .from('orders')
          .select()
          .eq('userId', userId.value)
          .order('timestamp', ascending: false);

      orders.value = snapshot;
    } catch (e) {
      error.value = 'Failed to fetch trips: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  Color getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return const Color(0xFFE65100); // Orange
      case 'cancelled':
        return const Color(0xFFD32F2F); // Red
      case 'accepted':
        return const Color(0xFF388E3C); // Green
      case 'completed':
        return const Color(0xFF1976D2); // Blue
      default:
        return const Color(0xFF757575); // Grey
    }
  }

  String formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is String) {
      final date = DateTime.parse(timestamp).toLocal();
      return DateFormat('MMM d, h:mm a').format(date);
    }
    return 'N/A';
  }

  String getShortPartnerId(String? partnerId) {
    if (partnerId == null || partnerId.length < 8) return partnerId ?? 'N/A';
    return '${partnerId.substring(0, 8)}...';
  }

  void refreshOrders() {
    fetchOrders();
  }

  @override
  void onClose() {
    orders.clear();
    super.onClose();
  }
}
