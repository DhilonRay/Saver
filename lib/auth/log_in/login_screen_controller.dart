import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../home_user/home_user.dart';
import '../../home_partner/home_partner.dart';
import '../sign_up/signup.dart';

class LoginController extends GetxController {
  // Text Controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController phonePasswordController = TextEditingController();

  // Reactive Variables
  var fcmToken = ''.obs;
  var isLoadingToken = false.obs;
  var isLoading = false.obs;
  var selectedTabIndex = 0.obs; // 0 for Email, 1 for Phone
  var isPasswordVisible = false.obs;
  var isPhonePasswordVisible = false.obs;
  var selectedCountryCode = '+880'.obs; // Default to Bangladesh

  @override
  void onInit() {
    super.onInit();
    initializeFirebaseAndGetToken();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    phonePasswordController.dispose();
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
    if (selectedTabIndex.value == 0) {
      // Email Login
      await signInWithEmail();
    } else {
      // Phone Login
      await signInWithPhone();
    }
  }

  Future<void> _navigateBasedOnRole(String uid) async {
    try {
      // Fetch user data from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        final role = userData?['role'] as String?;
        
        debugPrint('🔍 User document found');
        debugPrint('👤 User data: $userData');
        debugPrint('🎭 Detected role: $role');

        // Navigate based on role
        if (role == 'partner' || role == 'ambulance' || role == 'driver') {
          debugPrint('Navigating to HomePartnerPage');
          Get.snackbar(
            'Login Success',
            'Welcome Ambulance Partner!',
            backgroundColor: Colors.green[600],
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
            borderRadius: 10,
            margin: const EdgeInsets.all(10),
          );
          Future.delayed(const Duration(milliseconds: 500), () {
            Get.offAll(() => const HomePartnerPage());
          });
        } else {
          debugPrint('Navigating to HomePage (user)');
          Get.snackbar(
            'Login Success',
            'Welcome User!',
            backgroundColor: Colors.blue[600],
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
            borderRadius: 10,
            margin: const EdgeInsets.all(10),
          );
          Future.delayed(const Duration(milliseconds: 500), () {
            Get.offAll(() => HomePage());
          });
        }
      } else {
        // If user document doesn't exist, default to user role
        debugPrint('User document not found, defaulting to user role');
        Get.snackbar(
          'Login Success',
          'Welcome! (Default user role)',
          backgroundColor: Colors.orange[600],
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          borderRadius: 10,
          margin: const EdgeInsets.all(10),
        );
        Get.offAll(() => HomePage());
      }
    } catch (e) {
      debugPrint('Error fetching user role: $e');
      // On error, default to user role
      Get.snackbar(
        'Login Success',
        'Welcome! (Error checking role)',
        backgroundColor: Colors.orange[600],
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        borderRadius: 10,
        margin: const EdgeInsets.all(10),
      );
      Get.offAll(() => HomePage());
    }
  }

  Future<void> signInWithEmail() async {
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
        await _navigateBasedOnRole(userCredential.user!.uid);
      }
    } catch (e) {
      debugPrint('Email login failed: $e');
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

  Future<void> signInWithPhone() async {
    final phone = phoneController.text.trim();
    final password = phonePasswordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter phone number and password',
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

      // Find user by phone number in Firestore
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      debugPrint('📱 Phone login: Searching for phone $phone');
      debugPrint('📊 Found ${querySnapshot.docs.length} documents');

      if (querySnapshot.docs.isEmpty) {
        throw 'No account found with this phone number. Please sign up first.';
      }

      final userData = querySnapshot.docs.first.data();
      final email = userData['email'] as String?;
      final userRole = userData['role'] as String?;

      debugPrint('📧 Found email: $email');
      debugPrint('🎭 User role from phone search: $userRole');

      if (email == null || email.isEmpty) {
        throw 'Account setup incomplete. Please contact support.';
      }

      // Sign in with email and password
      final auth = FirebaseAuth.instance;
      final userCredential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await _navigateBasedOnRole(userCredential.user!.uid);
      }
    } catch (e) {
      debugPrint('Phone login failed: $e');
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

  void changeTab(int index) {
    selectedTabIndex.value = index;
    // Clear fields when switching tabs
    if (index == 0) {
      phoneController.clear();
      phonePasswordController.clear();
    } else {
      emailController.clear();
      passwordController.clear();
    }
  }

  void goToSignUp() {
    Get.to(() => const SignUpPage());
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void togglePhonePasswordVisibility() {
    isPhonePasswordVisible.value = !isPhonePasswordVisible.value;
  }

  void onCountryCodeChanged(String? countryCode) {
    if (countryCode != null) {
      selectedCountryCode.value = countryCode;
    }
  }

  Future<void> checkUserRole(String uid) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        final role = userData?['role'] as String? ?? 'user';
        
        Get.snackbar(
          'User Role Check',
          'Your role: $role\nUID: $uid',
          backgroundColor: Colors.purple[600],
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          borderRadius: 10,
          margin: const EdgeInsets.all(10),
          duration: const Duration(seconds: 5),
        );
      } else {
        Get.snackbar(
          'User Role Check',
          'User document not found in Firestore',
          backgroundColor: Colors.red[600],
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          borderRadius: 10,
          margin: const EdgeInsets.all(10),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to check role: $e',
        backgroundColor: Colors.red[600],
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        borderRadius: 10,
        margin: const EdgeInsets.all(10),
      );
    }
  }
}
