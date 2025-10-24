import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class AmbulanceServiceController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Reactive variables
  var isLoading = false.obs;
  var ambulancePartners = <QueryDocumentSnapshot>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchAmbulancePartners();
  }

  Future<void> fetchAmbulancePartners() async {
    try {
      isLoading.value = true;
      final snapshot = await _firestore.collection('partners').get();
      ambulancePartners.value = snapshot.docs;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load ambulance partners: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'Success',
      'Phone number copied!',
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
    );
  }

  Future<void> startAirAmbulanceChat(String partnerId, String companyName) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      Get.snackbar(
        'Authentication Required',
        'You need to be logged in to place an order.',
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
      );
      return;
    }

    try {
      isLoading.value = true;
      await _firestore.collection('orders').add({
        'userId': userId,
        'partnerId': partnerId,
        'orderStatus': 'pending',
        'createdAt': Timestamp.now(),
        'companyName': companyName,
      });

      Get.snackbar(
        'Order Placed',
        'Order placed with $companyName. Waiting for confirmation.',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to place order: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void refreshData() {
    fetchAmbulancePartners();
  }
}
