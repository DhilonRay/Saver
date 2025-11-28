import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:saver/auth/log_in/login_screen.dart';
import '../../home_user/home_user.dart';
import '../../partner_file/partner/partner.dart';
import '../../components/success_dialog.dart';

class SignUpController extends GetxController {
  // Text Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  // Reactive Variables
  var selectedRole = 'user'.obs;
  var isLoading = false.obs;
  var isPasswordVisible = false.obs;
  var isConfirmPasswordVisible = false.obs;
  var selectedCountryCode = '+880'.obs; // Default to Bangladesh
  var agreedToTerms = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize Firebase if not already initialized
    _initializeFirebase();
  }

  @override
  void onClose() {
    // Removed dispose calls for TextEditingControllers to prevent "controller used after dispose" errors
    // nameController.dispose();
    // phoneController.dispose();
    // addressController.dispose();
    // emailController.dispose();
    // passwordController.dispose();
    // confirmPasswordController.dispose();
    super.onClose();
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Firebase initialization error: $e');
    }
  }

  void updateSelectedRole(String role) {
    selectedRole.value = role;
  }

  Future<void> registerUser() async {
    // Validation
    if (!_validateInputs()) {
      return;
    }

    isLoading.value = true;

    try {
      // Use email if provided, otherwise use phone number as email
      String emailForAuth = emailController.text.trim().isEmpty
          ? '${phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), '')}@neosaver.app'
          : emailController.text.trim();

      // Create user with Firebase Auth
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailForAuth,
        password: passwordController.text.trim(),
      );

      // Save user data to Firestore
      String collectionName = selectedRole.value == 'driver' ? 'drivers' : 'users';
      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(userCredential.user!.uid)
          .set({
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'address': addressController.text.trim(),
        'email': emailController.text.trim(),
        'uid': userCredential.user!.uid,
        'role': selectedRole.value,
        'createdAt': Timestamp.now(),
      });

      debugPrint('User registered with role: ${selectedRole.value}');
      debugPrint('User data saved to Firestore: ${userCredential.user!.uid}');

      // Navigate based on role
      if (selectedRole.value == 'driver') {
        Get.offAll(() => PartnerPage(uid: userCredential.user!.uid));
      } else {
        SuccessDialog.show(
          title: 'Account Created',
          message: 'Your account has been created successfully!',
        );
        // Navigate directly to home page since user is already authenticated
        Future.delayed(const Duration(milliseconds: 100), () {
          Get.offAll(() => HomePage(isNewSignup: true));
        });
      }
    } catch (e) {
      debugPrint('Registration error: $e');
      Get.snackbar(
        'Registration Failed',
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

  bool _validateInputs() {
    if (selectedRole.value.isEmpty) {
      Get.snackbar(
        'Error',
        'Please select your role (User or Ambulance)',
        backgroundColor: Colors.red[600],
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        borderRadius: 10,
        margin: const EdgeInsets.all(10),
      );
      return false;
    }

    if (nameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        addressController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        confirmPasswordController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill in all required fields',
        backgroundColor: Colors.red[600],
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        borderRadius: 10,
        margin: const EdgeInsets.all(10),
      );
      return false;
    }

    if (passwordController.text.trim() !=
        confirmPasswordController.text.trim()) {
      Get.snackbar(
        'Error',
        'Passwords do not match',
        backgroundColor: Colors.red[600],
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        borderRadius: 10,
        margin: const EdgeInsets.all(10),
      );
      return false;
    }

    if (emailController.text.trim().isNotEmpty && !isValidEmail(emailController.text.trim())) {
      Get.snackbar(
        'Error',
        'Please enter a valid email address',
        backgroundColor: Colors.red[600],
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        borderRadius: 10,
        margin: const EdgeInsets.all(10),
      );
      return false;
    }

    if (!isValidName(nameController.text.trim())) {
      Get.snackbar(
        'Error',
        'Name cannot contain numbers',
        backgroundColor: Colors.red[600],
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        borderRadius: 10,
        margin: const EdgeInsets.all(10),
      );
      return false;
    }

    if (!agreedToTerms.value) {
      Get.snackbar(
        'Error',
        'Please agree to the Terms of Use and Privacy Policy',
        backgroundColor: Colors.red[600],
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        borderRadius: 10,
        margin: const EdgeInsets.all(10),
      );
      return false;
    }

    return true;
  }

  bool isValidEmail(String email) {
    final emailRegex =
        RegExp(r'^[\w-]+(\.[\w-]+)*@([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,7}$');
    return emailRegex.hasMatch(email);
  }

  bool isValidName(String name) {
    return RegExp(r'^[a-zA-Z\s]+$').hasMatch(name);
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  void onCountryCodeChanged(String? countryCode) {
    if (countryCode != null) {
      selectedCountryCode.value = countryCode;
    }
  }

  void goToLogin() {
    Future.delayed(const Duration(milliseconds: 100), () {
      Get.offAll(() => LoginPage());
    });
  }
}
