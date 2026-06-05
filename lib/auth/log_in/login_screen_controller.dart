import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saver/components/constants/alert.dart';
import '../../home_user/home_user.dart';
import '../../partner_file/home_partner/home_partner.dart';
import '../../services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../glm_dashboard/glm_dashboard.dart';
import '../sign_up/signup.dart';
import '../../config/api_keys_secret.dart';

class LoginController extends GetxController {
  // Text Controllers
  final TextEditingController identifierController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Reactive Variables
  var fcmToken = ''.obs;
  var isLoadingToken = false.obs;
  var isLoading = false.obs;
  var isPasswordVisible = false.obs;
  var selectedCountryCode = '+880'.obs; // Default to Bangladesh

  @override
  void onInit() {
    super.onInit();
    initializeFirebaseAndGetToken();
  }

  @override
  void onClose() {
    // Removed dispose calls for TextEditingControllers to prevent "controller used after dispose" errors
    // identifierController.dispose();
    // passwordController.dispose();
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
    final identifier = identifierController.text.trim();

    if (identifier.isEmpty) {
      Alert.error('Please enter GLM ID, email or phone number');
      return;
    }

    isLoading.value = true;
    try {
      // Check if this matches a manually created GLM Account ID
      DocumentSnapshot glmDoc = await FirebaseFirestore.instance
          .collection('glm_accounts')
          .doc(identifier)
          .get();

      if (glmDoc.exists) {
        var glmData = glmDoc.data() as Map<String, dynamic>;
        final String inputPass = passwordController.text.trim();
        final String dbPass = glmData['password'] ?? '';
        if (inputPass == dbPass) {
          isLoading.value = false;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isGLMLoggedIn', true);
          await prefs.setString('currentGLMId', identifier);
          
          Alert.info('Welcome GLM Partner!');
          Get.offAll(() => GLMDashboard(glmId: identifier));
          return;
        } else {
          isLoading.value = false;
          Alert.error('Incorrect password for GLM account');
          return;
        }
      }
    } catch (e) {
      debugPrint('GLM Account check failed: $e');
    } finally {
      isLoading.value = false;
    }

    if (identifier.contains('@')) {
      // Email Login
      await signInWithEmail();
    } else {
      // Phone Login
      await signInWithPhone();
    }
  }

  Future<void> _navigateBasedOnRole(String uid) async {
    try {
      // Check if user is admin first
      DocumentSnapshot adminDoc =
          await FirebaseFirestore.instance.collection('admins').doc(uid).get();

      if (adminDoc.exists) {
        debugPrint('🔑 Admin user detected - navigating to admin dashboard');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isAdminLoggedIn', true);
        Get.offAllNamed('/admin-dashboard');
        return;
      }

      // Priority 1: Check Partners Collection
      DocumentSnapshot partnerDoc = await FirebaseFirestore.instance
          .collection('partners')
          .doc(uid)
          .get();

      if (partnerDoc.exists) {
        debugPrint('Navigating to HomePartnerPage (found in partners)');
        _navigateToPartner();
        return;
      }

      // Priority 2: Check Drivers Collection
      DocumentSnapshot driverDoc =
          await FirebaseFirestore.instance.collection('drivers').doc(uid).get();

      if (driverDoc.exists) {
        debugPrint('Navigating to HomePartnerPage (found in drivers)');
        _navigateToPartner();
        return;
      }

      // Priority 3: Default to User Role
      debugPrint(
          'User/Driver doc not found in partner collections, defaulting to HomePage (User)');
      _navigateToUser();
    } catch (e) {
      debugPrint('Error fetching user role: $e');
      _navigateToUser();
    }
  }

  void _navigateToPartner() {
    Alert.info('Welcome Ambulance Partner!');
    Future.delayed(const Duration(milliseconds: 500), () {
      Get.offAll(() => HomePartnerPage());
      Future.delayed(const Duration(seconds: 1), () {
        NotificationService.ensureFCMInitialized();
      });
    });
  }

  void _navigateToUser() {
    Alert.info('Welcome User!');
    Future.delayed(const Duration(milliseconds: 500), () {
      Get.offAll(() => HomePage());
      Future.delayed(const Duration(seconds: 1), () {
        NotificationService.ensureFCMInitialized();
      });
    });
  }

  Future<void> signInWithEmail() async {
    final email = identifierController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      Alert.error('Please enter email and password');
      return;
    }

    isLoading.value = true;

    try {
      await Firebase.initializeApp();

      // ----------------------------------------------------
      // FIXED ADMIN CREDENTIALS BYPASS
      // ----------------------------------------------------
      if (email == ApiKeysSecret.adminEmail && password == ApiKeysSecret.adminPassword) {
        try {
          await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
        } catch (e) {
          try {
            UserCredential uc = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
            await FirebaseFirestore.instance.collection('admins').doc(uc.user!.uid).set({
              'email': email,
              'createdAt': FieldValue.serverTimestamp(),
            });
          } catch (_) {}
        }
        isLoading.value = false;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isAdminLoggedIn', true);
        debugPrint('💾 LoginController: Set isAdminLoggedIn = true successfully');
        Get.offAllNamed('/admin-dashboard');
        return;
      }
      // ----------------------------------------------------

      final auth = FirebaseAuth.instance;

      final userCredential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Store FCM token in user document
        if (fcmToken.value.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .update({
            'fcmToken': fcmToken.value,
            'lastLogin': Timestamp.now(),
          }).catchError((error) {
            // If update fails, try to set the token
            FirebaseFirestore.instance
                .collection('users')
                .doc(userCredential.user!.uid)
                .set({
              'fcmToken': fcmToken.value,
              'lastLogin': Timestamp.now(),
            }, SetOptions(merge: true));
          });
        }
        await _navigateBasedOnRole(userCredential.user!.uid);
      }
    } catch (e) {
      debugPrint('Email login failed: $e');
      Alert.error(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signInWithPhone() async {
    final phone = identifierController.text.trim();
    final password = passwordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      Alert.error('Please enter phone number and password');
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
        // Store FCM token in user document
        if (fcmToken.value.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .update({
            'fcmToken': fcmToken.value,
            'lastLogin': Timestamp.now(),
          }).catchError((error) {
            // If update fails, try to set the token
            FirebaseFirestore.instance
                .collection('users')
                .doc(userCredential.user!.uid)
                .set({
              'fcmToken': fcmToken.value,
              'lastLogin': Timestamp.now(),
            }, SetOptions(merge: true));
          });
        }
        await _navigateBasedOnRole(userCredential.user!.uid);
      }
    } catch (e) {
      debugPrint('Phone login failed: $e');
      Alert.error(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void goToSignUp() {
    Get.to(() => const SignUpPage());
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void onCountryCodeChanged(String? countryCode) {
    if (countryCode != null) {
      selectedCountryCode.value = countryCode;
    }
  }

  Future<void> checkUserRole(String uid) async {
    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        final role = userData?['role'] as String? ?? 'user';

        Alert.info('Your role: $role\nUID: $uid');
      } else {
        Alert.error('User document not found in Firestore');
      }
    } catch (e) {
      Alert.error('Failed to check role: $e');
    }
  }
}
