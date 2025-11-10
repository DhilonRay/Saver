import 'dart:async';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PartnerProfileController extends GetxController {
  var isLoading = true.obs;
  var error = ''.obs;
  var personalInfo = <String, dynamic>{}.obs;
  var partnerInfo = <String, dynamic>{}.obs;
  var isEditing = false.obs;

  StreamSubscription<DocumentSnapshot>? _personalInfoSubscription;
  StreamSubscription<DocumentSnapshot>? _partnerInfoSubscription;

  @override
  void onInit() {
    super.onInit();
    _setupRealTimeListeners();
  }

  @override
  void onClose() {
    _personalInfoSubscription?.cancel();
    _partnerInfoSubscription?.cancel();
    super.onClose();
  }

  void _setupRealTimeListeners() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      error.value = 'User not logged in.';
      isLoading.value = false;
      return;
    }

    // Set up real-time listener for personal info
    _personalInfoSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen(
          (userDoc) {
            if (userDoc.exists && userDoc.data() != null) {
              personalInfo.value = userDoc.data()!;
            } else {
              personalInfo.value = {
                'name': user.displayName ?? '',
                'email': user.email ?? '',
                'phone': user.phoneNumber ?? '',
                'uid': user.uid,
              };
            }
            _checkLoadingComplete();
          },
          onError: (e) {
            personalInfo.value = {
              'name': user.displayName ?? '',
              'email': user.email ?? '',
              'phone': user.phoneNumber ?? '',
              'uid': user.uid,
            };
            _checkLoadingComplete();
          },
        );

    // Set up real-time listener for partner info
    _partnerInfoSubscription = FirebaseFirestore.instance
        .collection('partners')
        .doc(user.uid)
        .snapshots()
        .listen(
          (doc) {
            if (doc.exists && doc.data() != null) {
              partnerInfo.value = doc.data()!;
            } else {
              partnerInfo.value = {};
            }
            _checkLoadingComplete();
          },
          onError: (e) {
            partnerInfo.value = {};
            _checkLoadingComplete();
          },
        );
  }

  void _checkLoadingComplete() {
    if (personalInfo.isNotEmpty || partnerInfo.isNotEmpty) {
      isLoading.value = false;
      error.value = '';
    }
  }

  void restartListeners() {
    _personalInfoSubscription?.cancel();
    _partnerInfoSubscription?.cancel();
    _setupRealTimeListeners();
  }

  void toggleEditing() {
    isEditing.value = !isEditing.value;
  }

  Future<void> saveChanges() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Update partner info in Firestore
      if (partnerInfo.isNotEmpty) {
        await FirebaseFirestore.instance.collection('partners').doc(user.uid).update(partnerInfo);
      }
      
      // Update personal info in users collection
      if (personalInfo.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update(personalInfo);
      }

      isEditing.value = false;
      Get.snackbar('Success', 'Profile updated successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update profile: $e');
    }
  }
}
