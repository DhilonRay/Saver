import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutController extends GetxController {
  // App information
  final String appName = 'NeoSaver';
  final String appVersion = '1.0.0';
  final String contactEmail = 'neosaver@gmail.com';
  final String developerName = 'Shawon Biswas';

  // Reactive variables for potential future features
  var isLoading = false.obs;

  // Contact functionality
  Future<void> launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: contactEmail,
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        Get.snackbar(
          'Error',
          'Could not open email client',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to open email: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  // Navigate back
  void goBack() {
    Get.back();
  }

  // Future method for app rating (could be implemented later)
  void rateApp() {
    Get.snackbar(
      'Coming Soon',
      'App rating feature will be available soon!',
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
    );
  }

  // Future method for sharing app (could be implemented later)
  void shareApp() {
    Get.snackbar(
      'Coming Soon',
      'Share app feature will be available soon!',
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
    );
  }
}
