import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:saver/components/alert.dart';
import 'package:url_launcher/url_launcher.dart';

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
      Alert.info('Please select a rating');
      return;
    }

    isSubmitting.value = true;

    try {
      final user = _auth.currentUser;
      // 1. Save to feedback collection (for records)
      await _firestore.collection('feedback').add({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'feedback': feedbackController.text.trim(),
        'rating': rating.value,
        'userId': user?.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. Open Mail App with pre-filled content (Guarantees delivery)
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: 'contact.neosaver@gmail.com',
        queryParameters: {
          'subject': '✨ NeoSaver Feedback: ${nameController.text.trim()}',
          'body': 'Name: ${nameController.text.trim()}\n'
              'Email: ${emailController.text.trim()}\n'
              'Rating: ${rating.value} / 5 Stars\n\n'
              'Message:\n${feedbackController.text.trim()}\n\n'
              '-- Sent via NeoSaver App Feedback --',
        },
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch email app');
      }

      // Clear form
      nameController.clear();
      emailController.clear();
      feedbackController.clear();
      rating.value = 0;

      await Alert.success('Thank you for your feedback!');
      Get.back(); // Go back to previous screen
    } catch (e) {
      Alert.info('Failed to submit feedback: $e');
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
