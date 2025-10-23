import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../home/home.dart';
import '../sign_up/signup.dart';

class LoginController extends GetxController {
  // Text Controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Reactive Variables
  var fcmToken = ''.obs;
  var isLoadingToken = false.obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    initializeFirebaseAndGetToken();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  Future<void> initializeFirebaseAndGetToken() async {
    try {
      isLoadingToken.value = true;
      await Firebase.initializeApp();

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        fcmToken.value = token;
      }
      isLoadingToken.value = false;

      debugPrint('FCM Token: $token');

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Token Refreshed: $newToken');
        fcmToken.value = newToken;
      });
    } catch (e) {
      isLoadingToken.value = false;
      debugPrint('Error getting FCM token: $e');
    }
  }

  Future<void> signIn() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter email and password',
        backgroundColor: Colors.red[600],
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        borderRadius: 10,
        margin: const EdgeInsets.all(10),
      );
      return;
    }

    isLoading.value = true;

    try {
      await Firebase.initializeApp();
      final auth = FirebaseAuth.instance;

      final userCredential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        Get.offAll(() => const HomePage());
      }
    } catch (e) {
      debugPrint('Login failed: $e');
      Get.snackbar(
        'Login Failed',
        e.toString(),
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

  void goToSignUp() {
    Get.to(() => const SignUpPage());
  }

  void showForgotPasswordDialog() {
    Get.defaultDialog(
      title: 'Reset Password',
      content: const Text('Password reset feature will be available soon. Please contact support for assistance.'),
      textConfirm: 'OK',
      confirmTextColor: Colors.white,
      onConfirm: () => Get.back(),
    );
  }
}
