import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


import 'package:image_picker/image_picker.dart';
import 'package:saver/components/alert.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class FeedbackController extends GetxController {
  final GoTrueClient _auth = Supabase.instance.client.auth;
  final SupabaseClient _firestore = Supabase.instance.client;

  // Text controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final feedbackController = TextEditingController();

  // Rating
  var rating = 0.obs;

  // Loading state
  var isSubmitting = false.obs;

  // Attachment
  final ImagePicker _picker = ImagePicker();
  final RxList<XFile> selectedFiles = <XFile>[].obs;
  var isUploading = false.obs;

  // Max file size: 10 MB
  static const int maxFileSize = 10 * 1024 * 1024;
  // Max number of files: 5
  static const int maxFileCount = 5;

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

  Future<void> pickAttachment() async {
    if (selectedFiles.length >= maxFileCount) {
      Alert.info('You can only attach up to $maxFileCount files');
      return;
    }

    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (file != null) {
        final int fileSize = await file.length();
        if (fileSize > maxFileSize) {
          Alert.info('File size must be less than 10 MB');
          return;
        }
        selectedFiles.add(file);
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      Alert.info('Error picking file');
    }
  }

  void removeAttachment(int index) {
    if (index >= 0 && index < selectedFiles.length) {
      selectedFiles.removeAt(index);
    }
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
      final List<String> attachmentUrls = [];

      // 0. Upload attachments if they exist
      if (selectedFiles.isNotEmpty) {
        isUploading.value = true;
        for (var xFile in selectedFiles) {
          final file = File(xFile.path);
          final fileName =
              'feedback_${DateTime.now().millisecondsSinceEpoch}_${xFile.name}';

          final path = '${user?.id ?? 'anonymous'}/feedback/$fileName';

          await Supabase.instance.client.storage
              .from('profile_images')
              .upload(path, file);

          final url = Supabase.instance.client.storage
              .from('profile_images')
              .getPublicUrl(path);
              
          attachmentUrls.add(url);
        }
        isUploading.value = false;
      }

      // 1. Save to feedback collection (for records)
      await _firestore.from('feedback').insert({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'feedback': feedbackController.text.trim(),
        'rating': rating.value,
        'userId': user?.id,
        'attachmentUrls': attachmentUrls,
        'timestamp': DateTime.now().toIso8601String(),
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
      selectedFiles.clear();

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
