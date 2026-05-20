import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saver/auth/log_in/login_screen.dart';
import 'package:saver/compo/success_dialog.dart';
import '../../home_user/home_user.dart';
import '../../partner_file/partner/partner.dart';

class SignUpController extends GetxController {
  // Text Controllers
  // final TextEditingController nameController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController postCodeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController companyNameController = TextEditingController();

  // Reactive Variables
  var selectedRole = 'user'.obs;
  var isLoading = false.obs;
  var isPasswordVisible = false.obs;
  var isConfirmPasswordVisible = false.obs;
  var selectedCountryCode = '+880'.obs; // Default to Bangladesh
  var agreedToTerms = false.obs;

  // Image Selection
  final ImagePicker _picker = ImagePicker();
  var profileImage = Rx<XFile?>(null);
  var licenseImage = Rx<XFile?>(null);
  var ambulanceImage = Rx<XFile?>(null);
  var nidImage = Rx<XFile?>(null);
  var registrationPapersImage = Rx<XFile?>(null);
  var isUploadingImages = false.obs;

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

  // Image Picking Methods
  Future<void> pickProfileImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image != null) {
      profileImage.value = image;
    }
  }

  Future<void> pickLicenseImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image != null) {
      licenseImage.value = image;
    }
  }

  Future<void> pickNidImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image != null) {
      nidImage.value = image;
    }
  }

  Future<void> pickRegistrationPapersImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image != null) {
      registrationPapersImage.value = image;
    }
  }

  Future<void> pickAmbulanceImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image != null) {
      ambulanceImage.value = image;
    }
  }

  Future<String?> _uploadImage(XFile? xFile, String folder, String fileName) async {
    if (xFile == null) return null;
    try {
      final file = File(xFile.path);
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images') // Using confirmed path
          .child(folder)
          .child(fileName);
      
      final uploadTask = await ref.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
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

      String uid = userCredential.user!.uid;
      String? profileImageUrl;
      String? licenseImageUrl;
      String? ambulanceImageUrl;
      String? nidImageUrl;
      String? registrationPapersImageUrl;

      // Upload Images if any
      isUploadingImages.value = true;
      
      if (profileImage.value != null) {
        profileImageUrl = await _uploadImage(
          profileImage.value, 
          uid, 
          'profile_${DateTime.now().millisecondsSinceEpoch}.jpg'
        );
      }

      if (selectedRole.value == 'driver') {
        if (licenseImage.value != null) {
          licenseImageUrl = await _uploadImage(
            licenseImage.value, 
            uid, 
            'license_${DateTime.now().millisecondsSinceEpoch}.jpg'
          );
        }
        if (nidImage.value != null) {
          nidImageUrl = await _uploadImage(
            nidImage.value, 
            uid, 
            'nid_${DateTime.now().millisecondsSinceEpoch}.jpg'
          );
        }
        if (registrationPapersImage.value != null) {
          registrationPapersImageUrl = await _uploadImage(
            registrationPapersImage.value, 
            uid, 
            'registration_${DateTime.now().millisecondsSinceEpoch}.jpg'
          );
        }
        if (ambulanceImage.value != null) {
          ambulanceImageUrl = await _uploadImage(
            ambulanceImage.value, 
            uid, 
            'ambulance_${DateTime.now().millisecondsSinceEpoch}.jpg'
          );
        }
      }
      isUploadingImages.value = false;

      // Save user data to Firestore
      String collectionName =
          selectedRole.value == 'driver' ? 'drivers' : 'users';
      
      Map<String, dynamic> userData = {
        'name':
            '${firstNameController.text.trim()} ${lastNameController.text.trim()}',
        'firstName': firstNameController.text.trim(),
        'lastName': lastNameController.text.trim(),
        'phone': phoneController.text.trim(),
        'address': addressController.text.trim(),
        'postCode': postCodeController.text.trim(),
        'email': emailController.text.trim(),
        'uid': uid,
        'role': selectedRole.value,
        'acceptedTerms': true,
        'profileImageUrl': profileImageUrl,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      // Add driver specific fields
      if (selectedRole.value == 'driver') {
        userData.addAll({
          'licenseImageUrl': licenseImageUrl,
          'ambulanceImageUrl': ambulanceImageUrl,
          'nidImageUrl': nidImageUrl,
          'registrationPapersImageUrl': registrationPapersImageUrl,
          'isApproved': true, // Auto-approve drivers
          'isOnline': false,
          'companyName': companyNameController.text.trim(),
        });

        // Send notification to admin panel
        await _sendAdminNotification(uid, userData);
        
        // Also save to 'partners' collection for the map and other features
        await FirebaseFirestore.instance
            .collection('partners')
            .doc(uid)
            .set(userData);
      }

      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(uid)
          .set(userData);

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

    if (firstNameController.text.trim().isEmpty ||
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

    if (!isValidName(firstNameController.text.trim()) ||
        !isValidName(lastNameController.text.trim())) {
      _showErrorSnackbar('Error', 'Names cannot contain numbers');
      return false;
    }

    if (!agreedToTerms.value) {
      _showErrorSnackbar(
          'Error', 'Please agree to the Terms of Use and Privacy Policy');
      return false;
    }

    // Driver specific validation
    if (selectedRole.value == 'driver') {
      if (licenseImage.value == null) {
        _showErrorSnackbar('Error', 'Please upload your License photo');
        return false;
      }
      if (nidImage.value == null) {
        _showErrorSnackbar('Error', 'Please upload your NID photo');
        return false;
      }
      if (registrationPapersImage.value == null) {
        _showErrorSnackbar('Error', 'Please upload Ambulance Registration papers');
        return false;
      }
      if (ambulanceImage.value == null) {
        _showErrorSnackbar('Error', 'Please upload a photo of your ambulance');
        return false;
      }
      if (companyNameController.text.trim().isEmpty) {
        _showErrorSnackbar('Error', 'Please enter your Company/Service name');
        return false;
      }
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

  Future<void> _sendAdminNotification(
      String uid, Map<String, dynamic> userData) async {
    try {
      await FirebaseFirestore.instance.collection('admin_notifications').add({
        'type': 'new_driver_signup',
        'title': 'New Driver Verification Request',
        'message':
            '${userData['name']} has registered as an ambulance driver and needs verification.',
        'userId': uid,
        'userData': userData,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Admin notification sent');
    } catch (e) {
      debugPrint('❌ Failed to send admin notification: $e');
    }
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
