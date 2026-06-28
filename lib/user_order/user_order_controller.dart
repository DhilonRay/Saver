import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/supabase_service.dart';

class UserOrderController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        userId.value = currentUser.uid;
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
    if (userId.isEmpty) return Stream.value([]);

    // Show all orders for the user
    return SupabaseService.client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId.value)
        .map((list) {
          final sorted = List<Map<String, dynamic>>.from(list);
          sorted.sort((a, b) {
            final aTime = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime.now();
            final bTime = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime.now();
            return bTime.compareTo(aTime);
          });
          return sorted.map((o) => SupabaseService.toCamelCase(o)).toList();
        });
  }

  void fetchOrders() async {
    if (userId.isEmpty) return;

    try {
      isLoading.value = true;
      error.value = '';

      final response = await SupabaseService.getOrdersByUserId(userId.value);

      // Sort in memory since we can't use orderBy in query
      final ordersList = response.map((o) => SupabaseService.toCamelCase(o)).toList();
      ordersList.sort((a, b) {
        final aTime = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime.now();
        final bTime = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime.now();
        return bTime.compareTo(aTime); // Descending order
      });

      orders.value = ordersList;
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
    DateTime date;
    if (timestamp is DateTime) {
      date = timestamp.toLocal();
    } else {
      date = DateTime.tryParse(timestamp.toString())?.toLocal() ?? DateTime.now();
    }
    return DateFormat('MMM d, h:mm a').format(date);
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
