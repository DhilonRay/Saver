import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Controller for Help & Support page.
class HelpSupportController extends GetxController {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final messageController = TextEditingController();

  final loading = false.obs;

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    messageController.dispose();
    super.onClose();
  }

  /// Validate input and submit a support message to Firestore.
  Future<void> submit() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final message = messageController.text.trim();

    if (name.isEmpty || email.isEmpty || message.isEmpty) {
      Get.snackbar('Validation', 'Please fill all fields', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    loading.value = true;
    try {
      await FirebaseFirestore.instance.collection('support_messages').add({
        'name': name,
        'email': email,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar('Thanks', 'Your message was sent. We will contact you soon.', snackPosition: SnackPosition.BOTTOM);

      // Clear form
      nameController.clear();
      emailController.clear();
      messageController.clear();
    } catch (e) {
      Get.snackbar('Error', 'Failed to send message: $e', snackPosition: SnackPosition.BOTTOM);
    } finally {
      loading.value = false;
    }
  }
}
