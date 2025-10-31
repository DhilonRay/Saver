import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedbackController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Text controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final feedbackController = TextEditingController();

  // Rating
  var rating = 0.obs;

  // Loading state
  var isSubmitting = false.obs;

  // Form key
  final formKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    // Pre-fill email if user is logged in
    final user = _auth.currentUser;
    if (user != null && user.email != null) {
      emailController.text = user.email!;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    feedbackController.dispose();
    super.onClose();
  }

  void setRating(int value) {
    rating.value = value;
  }

  Future<void> submitFeedback() async {
    if (!formKey.currentState!.validate()) return;

    if (rating.value == 0) {
      Get.snackbar('Error', 'Please select a rating');
      return;
    }

    isSubmitting.value = true;

    try {
      final user = _auth.currentUser;
      await _firestore.collection('feedback').add({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'feedback': feedbackController.text.trim(),
        'rating': rating.value,
        'userId': user?.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Clear form
      nameController.clear();
      emailController.clear();
      feedbackController.clear();
      rating.value = 0;

      Get.snackbar('Success', 'Thank you for your feedback!');
      Get.back(); // Go back to previous screen
    } catch (e) {
      Get.snackbar('Error', 'Failed to submit feedback: $e');
    } finally {
      isSubmitting.value = false;
    }
  }

  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!GetUtils.isEmail(value.trim())) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? validateFeedback(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Feedback is required';
    }
    if (value.trim().length < 10) {
      return 'Feedback must be at least 10 characters';
    }
    return null;
  }
}