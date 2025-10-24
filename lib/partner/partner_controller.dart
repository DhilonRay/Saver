import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

    isLoading.value = true;

    try {
      await FirebaseFirestore.instance
          .collection('partners')
          .doc(uid)
          .set({
        'vehicleNumber': vehicleNumber.text.trim(),
        'licenseNumber': licenseNumber.text.trim(),
        'ambulanceType': ambulanceType.text.trim(),
        'coverageArea': coverageArea.text.trim(),
        'contact': contactNumberController.text.trim(),
        'companyName': companyNameController.text.trim(),
        'uid': uid,
        'createdAt': Timestamp.now(),
      });

      Get.snackbar(
        'Success',
        'Partner info submitted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      Get.back();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error saving data: ${e.toString()}',
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
