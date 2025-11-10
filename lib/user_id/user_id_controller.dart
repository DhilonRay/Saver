import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class UserIdController extends GetxController {
  final Rx<Map<String, dynamic>?> userData = Rx<Map<String, dynamic>?>(null);
  final Rx<Map<String, dynamic>?> partnerData = Rx<Map<String, dynamic>?>(null);
  final RxBool isEditing = false.obs;
  final RxBool isLoading = true.obs;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController vehicleNumberController = TextEditingController();
  final TextEditingController licenseNumberController = TextEditingController();
  final TextEditingController ambulanceTypeController = TextEditingController();
  final TextEditingController coverageAreaController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController companyNameController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    isLoading.value = true;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final userDocRef = FirebaseFirestore.instance.collection('users').doc(uid);
        final userDoc = await userDocRef.get();

        if (userDoc.exists) {
          userData.value = userDoc.data();
          nameController.text = userData.value?['name'] ?? '';
          phoneController.text = userData.value?['phone'] ?? '';
          addressController.text = userData.value?['address'] ?? '';
          emailController.text = userData.value?['email'] ?? '';
        } else {
          userData.value = {
            'name': 'N/A',
            'email': FirebaseAuth.instance.currentUser!.email,
            'phone': 'N/A',
            'address': 'N/A',
            'uid': uid,
            'role': 'user', // Default role for users
            'createdAt': Timestamp.now(),
          };
          nameController.text = 'N/A';
          phoneController.text = 'N/A';
          addressController.text = 'N/A';
          emailController.text = FirebaseAuth.instance.currentUser!.email ?? 'N/A';
          await userDocRef.set(userData.value!);
        }

        final partnerDoc = await FirebaseFirestore.instance.collection('partners').doc(uid).get();
        if (partnerDoc.exists) {
          partnerData.value = partnerDoc.data();
          vehicleNumberController.text = partnerData.value?['vehicleNumber'] ?? '';
          licenseNumberController.text = partnerData.value?['licenseNumber'] ?? '';
          ambulanceTypeController.text = partnerData.value?['ambulanceType'] ?? '';
          coverageAreaController.text = partnerData.value?['coverageArea'] ?? '';
          contactController.text = partnerData.value?['contact'] ?? '';
          companyNameController.text = partnerData.value?['companyName'] ?? '';
        }

        await _updateLocation(uid);
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to load user data: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } else {
      // Handle case when user is not authenticated
      userData.value = null;
      Get.snackbar(
        'Authentication Required',
        'Please log in to view your profile',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    }
    isLoading.value = false;
  }

  Future<void> updateUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'name': nameController.text.trim(),
          'phone': phoneController.text.trim(),
          'address': addressController.text.trim(),
          'email': emailController.text.trim(),
        });

        if (partnerData.value != null) {
          await FirebaseFirestore.instance.collection('partners').doc(uid).update({
            'vehicleNumber': vehicleNumberController.text.trim(),
            'licenseNumber': licenseNumberController.text.trim(),
            'ambulanceType': ambulanceTypeController.text.trim(),
            'coverageArea': coverageAreaController.text.trim(),
            'contact': contactController.text.trim(),
            'companyName': companyNameController.text.trim(),
          });
          partnerData.value = {
            ...partnerData.value!,
            'vehicleNumber': vehicleNumberController.text.trim(),
            'licenseNumber': licenseNumberController.text.trim(),
            'ambulanceType': ambulanceTypeController.text.trim(),
            'coverageArea': coverageAreaController.text.trim(),
            'contact': contactController.text.trim(),
            'companyName': companyNameController.text.trim(),
          };
        }

        userData.value = {
          ...userData.value!,
          'name': nameController.text.trim(),
          'phone': phoneController.text.trim(),
          'address': addressController.text.trim(),
          'email': emailController.text.trim(),
        };

        Get.snackbar(
          'Success',
          'Profile updated successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        isEditing.value = false;
      } catch (e) {
        Get.snackbar(
          'Error',
          'Error updating profile: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  Future<void> _updateLocation(String uid) async {
    try {
      Position position = await _getCurrentLocation();
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'latitude': position.latitude,
        'longitude': position.longitude,
      });
    } catch (e) {
      // Silently fail to avoid disrupting user experience
    }
  }

  Future<Position> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    return position;
  }

  void toggleEditing() {
    isEditing.value = !isEditing.value;
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    emailController.dispose();
    vehicleNumberController.dispose();
    licenseNumberController.dispose();
    ambulanceTypeController.dispose();
    coverageAreaController.dispose();
    contactController.dispose();
    companyNameController.dispose();
    super.onClose();
  }
}
