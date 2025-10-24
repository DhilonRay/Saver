import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import 'package:intl/intl.dart';

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

  void initializeUser() {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      userId.value = currentUser.uid;
      fetchOrders();
    } else {
      isLoading.value = false;
      error.value = 'User not authenticated';
    }
  }

  Stream<QuerySnapshot> getOrdersStream() {
    if (userId.isEmpty) return Stream.empty();

    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId.value)
        .orderBy('createdAt', descending: true)
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
          .orderBy('createdAt', descending: true)
          .get();

      orders.value = snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      error.value = 'Failed to fetch orders: ${e.toString()}';
      Get.snackbar(
        'Error',
        error.value,
        snackPosition: SnackPosition.BOTTOM,
      );
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
