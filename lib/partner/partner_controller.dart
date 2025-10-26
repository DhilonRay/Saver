import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../partner_orders/partners_orders_page.dart';

class PartnerController extends GetxController {
  final TextEditingController vehicleNumber = TextEditingController();
  final TextEditingController licenseNumber = TextEditingController();
  final TextEditingController ambulanceType = TextEditingController();
  final TextEditingController coverageArea = TextEditingController();
  final TextEditingController contactNumberController = TextEditingController();
  final TextEditingController companyNameController = TextEditingController();

  final RxBool isLoading = false.obs;

  Future<void> savePartnerDetails(String uid) async {
    if (isLoading.value) return;

    // Validate required fields
    if (vehicleNumber.text.trim().isEmpty ||
        licenseNumber.text.trim().isEmpty ||
        ambulanceType.text.trim().isEmpty ||
        coverageArea.text.trim().isEmpty ||
        contactNumberController.text.trim().isEmpty ||
        companyNameController.text.trim().isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please fill in all required fields',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;

    // Prepare data to save
    final partnerData = {
      'vehicleNumber': vehicleNumber.text.trim(),
      'licenseNumber': licenseNumber.text.trim(),
      'ambulanceType': ambulanceType.text.trim(),
      'coverageArea': coverageArea.text.trim(),
      'contact': contactNumberController.text.trim(),
      'companyName': companyNameController.text.trim(),
      'uid': uid,
      'createdAt': Timestamp.now(),
    };

    print('🚑 Saving partner data to Firestore...');
    print('👤 User ID: $uid');
    print('📊 Data to save: $partnerData');

    try {
      // Save partner data to Firestore
      await FirebaseFirestore.instance
          .collection('partners')
          .doc(uid)
          .set(partnerData);

      // Verify data was saved by reading it back
      final savedDoc = await FirebaseFirestore.instance
          .collection('partners')
          .doc(uid)
          .get();

      if (savedDoc.exists) {
        print('✅ Partner data successfully saved to Firestore');
        print('📄 Document ID: ${savedDoc.id}');
        print('📊 Saved Data: ${savedDoc.data()}');

        Get.snackbar(
          'Success',
          'Partner info submitted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        clearForm();
        // Navigate to partners orders page after successful registration
        Get.offAll(() => PartnersOrdersPage());
      } else {
        throw Exception('Data verification failed - document not found after save');
      }
    } catch (e) {
      print('❌ Error saving partner data: $e');
      Get.snackbar(
        'Error',
        'Failed to save partner data: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void clearForm() {
    vehicleNumber.clear();
    licenseNumber.clear();
    ambulanceType.clear();
    coverageArea.clear();
    contactNumberController.clear();
    companyNameController.clear();
  }

  @override
  void onClose() {
    vehicleNumber.dispose();
    licenseNumber.dispose();
    ambulanceType.dispose();
    coverageArea.dispose();
    contactNumberController.dispose();
    companyNameController.dispose();
    super.onClose();
  }
}
