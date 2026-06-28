import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../components/alert.dart';
import '../home_partner/home_partner.dart';
import '../../services/supabase_service.dart';

class PartnerController extends GetxController {
  final TextEditingController vehicleNumber = TextEditingController();
  final TextEditingController licenseNumber =
      TextEditingController(); // Driver License Number
  final TextEditingController roadTaxToken = TextEditingController();
  final TextEditingController nationalId = TextEditingController();
  final TextEditingController ambulanceType = TextEditingController();
  final TextEditingController coverageArea = TextEditingController();
  final TextEditingController contactNumberController = TextEditingController();
  final TextEditingController emailAddressController = TextEditingController();
  final TextEditingController companyNameController =
      TextEditingController(); // Hospital / Company Name
  final TextEditingController referenceId = TextEditingController();

  final RxBool isLoading = false.obs;

  Future<void> savePartnerDetails(String uid) async {
    if (isLoading.value) return;

    // Validate required fields
    if (vehicleNumber.text.trim().isEmpty ||
        licenseNumber.text.trim().isEmpty ||
        roadTaxToken.text.trim().isEmpty ||
        nationalId.text.trim().isEmpty ||
        ambulanceType.text.trim().isEmpty ||
        coverageArea.text.trim().isEmpty ||
        contactNumberController.text.trim().isEmpty ||
        emailAddressController.text.trim().isEmpty ||
        companyNameController.text.trim().isEmpty) {
      Alert.info('Please fill in all required fields');
      return;
    }

    isLoading.value = true;

    // Prepare data to save
    final partnerData = {
      'vehicleNumber': vehicleNumber.text.trim(),
      'licenseNumber': licenseNumber.text.trim(),
      'roadTaxToken': roadTaxToken.text.trim(),
      'nationalId': nationalId.text.trim(),
      'ambulanceType': ambulanceType.text.trim(),
      'coverageArea': coverageArea.text.trim(),
      'contact': contactNumberController.text.trim(),
      'email': emailAddressController.text.trim(),
      'companyName': companyNameController.text.trim(),
      'referenceId': referenceId.text.trim(),
      'uid': uid,
      'createdAt': DateTime.now().toIso8601String(),
    };

    print('🚑 Saving partner data to Supabase...');
    print('👤 User ID: $uid');
    print('📊 Data to save: $partnerData');

    try {
      // Save partner data to Supabase
      await SupabaseService.upsertPartner(uid, partnerData);

      // Verify data was saved by reading it back
      final savedDoc = await SupabaseService.getPartner(uid);

      if (savedDoc != null) {
        print('✅ Partner data successfully saved to Supabase');
        print('📄 Document ID: $uid');
        print('📊 Saved Data: $savedDoc');

        Alert.info('Partner info submitted successfully');

        clearForm();
        // Navigate to home partner page after successful registration
        Get.offAll(() => HomePartnerPage(isNewSignup: true));
      } else {
        throw Exception(
            'Data verification failed - document not found after save');
      }
    } catch (e) {
      print('❌ Error saving partner data: $e');
      Alert.info('Failed to save partner data: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  void clearForm() {
    vehicleNumber.clear();
    licenseNumber.clear();
    roadTaxToken.clear();
    nationalId.clear();
    ambulanceType.clear();
    coverageArea.clear();
    contactNumberController.clear();
    emailAddressController.clear();
    companyNameController.clear();
    referenceId.clear();
  }

  @override
  void onClose() {
    vehicleNumber.dispose();
    licenseNumber.dispose();
    roadTaxToken.dispose();
    nationalId.dispose();
    ambulanceType.dispose();
    coverageArea.dispose();
    contactNumberController.dispose();
    emailAddressController.dispose();
    companyNameController.dispose();
    referenceId.dispose();
    super.onClose();
  }
}
