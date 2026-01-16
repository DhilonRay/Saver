import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';

import 'package:saver/compo/success_dialog.dart';


class ForgotPasswordController extends GetxController {
  // Text Controller
  final TextEditingController emailController = TextEditingController();

  // Reactive Variables
  var isLoading = false.obs;
  var lastResetTime = 0.obs; // Timestamp of last reset attempt
  var isCooldownActive = false.obs; // Whether cooldown is active
  var cooldownSeconds = 60.obs; // Cooldown period in seconds
  var remainingTime = 0.obs; // Remaining cooldown time in seconds
  var lastEmailSent = ''.obs; // Last email address that received reset

  // Rate limiting variables
  static const int maxRequestsPerHour = 5;
  var requestCount = 0.obs;
  var firstRequestTime = 0.obs;

  // Timer for updating cooldown display
  Timer? _cooldownTimer;

  @override
  void onInit() {
    super.onInit();
    // Initialize Firebase if not already initialized
    _initializeFirebase();
    // Start cooldown timer if cooldown is active
    _startCooldownTimer();
  }

  @override
  void onClose() {
    _cooldownTimer?.cancel();
    // Removed dispose call for TextEditingController to prevent "controller used after dispose" errors
    // emailController.dispose();
    super.onClose();
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      // Configure Firebase Auth settings for better email deliverability
      await FirebaseAuth.instance.setSettings(
        appVerificationDisabledForTesting: false,
      );
    } catch (e) {
      debugPrint('Firebase initialization error: $e');
    }
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isCooldownActive.value) {
        final currentRemaining = cooldownSeconds.value -
            ((DateTime.now().millisecondsSinceEpoch - lastResetTime.value) ~/
                1000);

        remainingTime.value = currentRemaining > 0 ? currentRemaining : 0;

        if (remainingTime.value <= 0) {
          isCooldownActive.value = false;
          remainingTime.value = 0;
          _cooldownTimer?.cancel();
        }
      } else {
        remainingTime.value = 0;
        _cooldownTimer?.cancel();
      }
    });
  }

  Future<void> resetPassword() async {
    final email = emailController.text.trim();

    // Check for cooldown (allow retry for same email)
    if (isCooldownActive.value && email != lastEmailSent.value) {
      final remainingTime = cooldownSeconds.value -
          ((DateTime.now().millisecondsSinceEpoch - lastResetTime.value) ~/
              1000);
      if (remainingTime > 0) {
        Get.snackbar(
          'Please Wait',
          'Please wait $remainingTime seconds before requesting another reset',
          backgroundColor: Colors.orange[600],
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          borderRadius: 10,
          margin: const EdgeInsets.all(10),
        );
        return;
      } else {
        isCooldownActive.value = false;
      }
    }

    // Check rate limiting
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    if (firstRequestTime.value == 0) {
      firstRequestTime.value = currentTime;
    }

    // Reset counter if more than an hour has passed
    if (currentTime - firstRequestTime.value > 3600000) {
      // 1 hour in milliseconds
      requestCount.value = 0;
      firstRequestTime.value = currentTime;
    }

    if (requestCount.value >= maxRequestsPerHour) {
      Get.snackbar(
        'Rate Limit Exceeded',
        'Too many password reset requests. Please try again later.',
        backgroundColor: Colors.red[600],
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        borderRadius: 10,
        margin: const EdgeInsets.all(10),
      );
      return;
    }

    if (email.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter your email address',
        backgroundColor: Colors.red[600],
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        borderRadius: 10,
        margin: const EdgeInsets.all(10),
      );
      return;
    }

    if (!isValidEmail(email)) {
      Get.snackbar(
        'Error',
        'Please enter a valid email address',
        backgroundColor: Colors.red[600],
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        borderRadius: 10,
        margin: const EdgeInsets.all(10),
      );
      return;
    }

    isLoading.value = true;
    requestCount.value++; // Increment request count

    try {
      await Firebase.initializeApp();
      final auth = FirebaseAuth.instance;

      await auth.sendPasswordResetEmail(email: email);

      // Activate cooldown after successful reset
      lastResetTime.value = DateTime.now().millisecondsSinceEpoch;
      isCooldownActive.value = true;
      _startCooldownTimer(); // Start the countdown timer

      // Store the email for retry purposes
      lastEmailSent.value = email;

      SuccessDialog.show(
        title: 'Reset Email Sent!',
        message:
            'Password reset link sent to $email\n\n📧 Check your inbox (and spam/junk folder)',
        autoCloseDuration: const Duration(seconds: 10),
      );

      // Clear the email field
      emailController.clear();

      // Navigate back to login after the dialog closes
      Future.delayed(const Duration(seconds: 30), () {
        Get.back();
      });
    } catch (e) {
      debugPrint('Password reset failed: $e');

      String errorMessage = 'Failed to send reset email';
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'No account found with this email address';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email address';
            break;
          case 'too-many-requests':
            errorMessage = 'Too many requests. Please try again later';
            // Activate longer cooldown for Firebase rate limit
            lastResetTime.value = DateTime.now().millisecondsSinceEpoch;
            isCooldownActive.value = true;
            cooldownSeconds.value = 300; // 5 minutes cooldown
            _startCooldownTimer(); // Start the countdown timer
            break;
          default:
            errorMessage = e.message ?? 'An error occurred';
        }
      }

      Get.snackbar(
        'Reset Failed',
        errorMessage,
        backgroundColor: Colors.red[600],
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        borderRadius: 10,
        margin: const EdgeInsets.all(10),
      );
    } finally {
      isLoading.value = false;
    }
  }

  bool isValidEmail(String email) {
    // More comprehensive email validation
    final emailRegex = RegExp(
        r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$');
    if (!emailRegex.hasMatch(email)) return false;

    // Check for common disposable email domains
    final disposableDomains = [
      '10minutemail.com',
      'guerrillamail.com',
      'mailinator.com',
      'temp-mail.org',
      'throwaway.email',
      'yopmail.com',
      'maildrop.cc',
      'tempail.com'
    ];

    final domain = email.split('@').last.toLowerCase();
    if (disposableDomains.contains(domain)) return false;

    return true;
  }
}
