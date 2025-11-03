import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PartnerProfileController extends GetxController {
  // Text Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  // Reactive Variables
  final RxBool isLoading = true.obs;
  final RxBool isUpdating = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserData();
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.onClose();
  }

  Future<void> loadUserData() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        nameController.text = data['name'] ?? '';
        emailController.text = data['email'] ?? '';
        phoneController.text = data['phone'] ?? '';
        addressController.text = data['address'] ?? '';
      }
    } catch (e) {
      errorMessage.value = 'Failed to load data: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProfile() async {
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        addressController.text.trim().isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please fill in all fields',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    isUpdating.value = true;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'address': addressController.text.trim(),
      });

      Get.snackbar(
        'Success',
        'Profile updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update profile: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isUpdating.value = false;
    }
  }
}
