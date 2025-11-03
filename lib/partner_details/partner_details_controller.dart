import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PartnerDetailsController extends GetxController {
  final RxBool isLoading = true.obs;
  final RxMap<String, dynamic> partnerDetails = <String, dynamic>{}.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isUpdating = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadPartnerDetails();
  }

  Future<void> loadPartnerDetails() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        errorMessage.value = 'User not authenticated';
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('partners')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        partnerDetails.value = doc.data() ?? {};
      } else {
        errorMessage.value = 'Partner details not found. Please complete registration.';
      }
    } catch (e) {
      errorMessage.value = 'Failed to load partner details: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Not available';

    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<bool> updatePartnerDetailsOptimistic(Map<String, dynamic> updates) async {
    if (isUpdating.value) return false; // Prevent multiple simultaneous updates

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      errorMessage.value = 'User not authenticated';
      return false;
    }

    // Optimistic update - update UI immediately
    final updatedData = Map<String, dynamic>.from(partnerDetails);
    updatedData.addAll(updates);
    partnerDetails.value = updatedData;

    isUpdating.value = true;

    // Sync with Firestore in background
    try {
      await FirebaseFirestore.instance
          .collection('partners')
          .doc(user.uid)
          .update(updates);

      // Success - keep the optimistic update
      return true;
    } catch (e) {
      // Failure - revert the optimistic update
      final revertedData = Map<String, dynamic>.from(partnerDetails);
      updates.forEach((key, value) {
        revertedData.remove(key);
      });
      partnerDetails.value = revertedData;

      errorMessage.value = 'Failed to save changes: ${e.toString()}';
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  Future<bool> updateVehicleInfo(String vehicleNumber, String ambulanceType) async {
    return await updatePartnerDetailsOptimistic({
      'vehicleNumber': vehicleNumber.trim(),
      'ambulanceType': ambulanceType.trim(),
    });
  }

  Future<bool> updateLicenseInfo(String licenseNumber, String contactNumber) async {
    return await updatePartnerDetailsOptimistic({
      'licenseNumber': licenseNumber.trim(),
      'contact': contactNumber.trim(),
    });
  }

  Future<bool> updateServiceArea(String coverageArea) async {
    return await updatePartnerDetailsOptimistic({
      'coverageArea': coverageArea.trim(),
    });
  }

  Future<bool> updateBusinessInfo(String companyName) async {
    return await updatePartnerDetailsOptimistic({
      'companyName': companyName.trim(),
    });
  }
}