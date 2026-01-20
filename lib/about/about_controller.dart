import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutController extends GetxController {
  // App information
  final String appName = 'NeoSaver';
  final String appVersion = '1.0.0';
  final String contactEmail = 'contact.neosaver@gmail.com';
  final String developerName = 'Shawon Biswas';

  // Reactive variables for potential future features
  var isLoading = false.obs;

  // Contact functionality - directly launches email app
  Future<void> launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: contactEmail,
      queryParameters: {
        'subject': 'NeoSaver Support Inquiry',
      },
    );

    try {
      await launchUrl(emailUri);
    } catch (e) {
      debugPrint('Failed to open email: $e');
    }
  }

  // Navigate back
  void goBack() {
    Get.back();
  }

  // Future method for app rating
  void rateApp() {
    // TODO: Implement app store rating
    debugPrint('Rate app tapped');
  }

  // Future method for sharing app
  void shareApp() {
    // TODO: Implement share functionality
    debugPrint('Share app tapped');
  }
}
