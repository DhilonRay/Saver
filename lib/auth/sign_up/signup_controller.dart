import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:saver/auth/log_in/login_screen.dart';
import 'package:saver/compo/success_dialog.dart';
import '../../home_user/home_user.dart';
import '../../partner_file/partner/partner.dart';

class SignUpController extends GetxController {
  // Text Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController postCodeController = TextEditingController();
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
      String collectionName =
          selectedRole.value == 'driver' ? 'drivers' : 'users';
      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(userCredential.user!.uid)
          .set({
        'name': nameController.text.trim(),
        'firstName': firstNameController.text.trim(),
        'lastName': lastNameController.text.trim(),
        'phone': phoneController.text.trim(),
        'address': addressController.text.trim(),
        'postCode': postCodeController.text.trim(),
        'email': emailController.text.trim(),
        'uid': userCredential.user!.uid,
        'role': selectedRole.value,
        'acceptedTerms': true,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
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
        Future.delayed(const Duration(seconds: 2), () {
          Get.offAll(() => HomePage(isNewSignup: true));
        });
      }
    } catch (e) {
      debugPrint('Registration error: $e');
      _showErrorSnackbar('Registration Failed', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  bool _validateInputs() {
    if (selectedRole.value.isEmpty) {
      _showErrorSnackbar(
          'Error', 'Please select your role (User or Ambulance)');
      return false;
    }

    if (nameController.text.trim().isEmpty ||
        firstNameController.text.trim().isEmpty ||
        lastNameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        addressController.text.trim().isEmpty ||
        postCodeController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        confirmPasswordController.text.trim().isEmpty) {
      _showErrorSnackbar('Error', 'Please fill in all required fields');
      return false;
    }

    if (passwordController.text.trim() !=
        confirmPasswordController.text.trim()) {
      _showErrorSnackbar('Error', 'Passwords do not match');
      return false;
    }

    if (emailController.text.trim().isNotEmpty &&
        !isValidEmail(emailController.text.trim())) {
      _showErrorSnackbar('Error', 'Please enter a valid email address');
      return false;
    }

    if (!isValidName(nameController.text.trim())) {
      _showErrorSnackbar('Error', 'Name cannot contain numbers');
      return false;
    }

    if (!agreedToTerms.value) {
      _showErrorSnackbar(
          'Error', 'Please agree to the Terms of Use and Privacy Policy');
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

  void _showErrorSnackbar(String title, String message) {
    if (Get.context != null) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(message),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      // Fallback for extreme cases
      debugPrint('Context null, could not show snackbar: $title - $message');
    }
  }
}
