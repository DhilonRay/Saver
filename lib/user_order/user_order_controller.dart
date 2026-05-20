import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserOrderController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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

  Stream<QuerySnapshot> getOrdersStream() {
    if (userId.isEmpty) return Stream.empty();

    // Show all orders for the user
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId.value)
        .snapshots();
  }

  void fetchOrders() async {
    if (userId.isEmpty) return;

    try {
      isLoading.value = true;
      error.value = '';

      final snapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId.value)
          .get();

      // Sort in memory since we can't use orderBy in query
      final ordersList = snapshot.docs.map((doc) => doc.data()).toList();
      ordersList.sort((a, b) {
        final aTime =
            (a['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        final bTime =
            (b['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
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

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate().toLocal();
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
