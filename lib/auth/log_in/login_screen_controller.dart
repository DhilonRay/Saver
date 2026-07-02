import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../services/supabase_service.dart';
import 'package:saver/components/constants/alert.dart';
import '../../home_user/home_user.dart';
import '../../partner_file/home_partner/home_partner.dart';
import '../../services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../glm_dashboard/glm_dashboard.dart';
import '../sign_up/signup.dart';
import '../../config/api_keys_secret.dart';
import '../../config/security_helper.dart';
// import '../phone_verification/phone_verification_screen.dart';

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


      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
     
        fcmToken.value = newToken;
      });
    } catch (e) {
      isLoadingToken.value = false;
    
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
      final glmData = await SupabaseService.getGLMAccount(identifier);

      if (glmData != null) {
        final String inputPass = passwordController.text.trim();
        final String dbPass = glmData['password'] ?? '';

        // FIX #2: SHA-256 hash দিয়ে compare করো
        // নতুন accounts-এ hash store হয়, পুরানো plain text-এ fallback করো
        final bool passMatch = dbPass.length == 64
            ? SecurityHelper.verifyPassword(inputPass, dbPass) // hash comparison
            : inputPass == dbPass; // legacy plain text fallback

        if (passMatch) {
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
      final adminData = await SupabaseService.getAdmin(uid);

      if (adminData != null) {
      
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isAdminLoggedIn', true);
        Get.offAllNamed('/admin-dashboard');
        return;
      }

      // Priority 1: Check Partners Collection
      final partnerData = await SupabaseService.getPartner(uid);

      if (partnerData != null) {
       
        _navigateToPartner();
        return;
      }

      // Priority 2: Check Drivers Collection
      final driverData = await SupabaseService.getDriver(uid);

      if (driverData != null) {
        
        _navigateToPartner();
        return;
      }

      // Priority 3: Default to User Role
    
      _navigateToUser();
    } catch (e) {
    
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
            await SupabaseService.upsertAdmin(uc.user!.uid, {
              'email': email,
            });
          } catch (_) {}
        }
        isLoading.value = false;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isAdminLoggedIn', true);
      
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
        // Phone Verification check (Commented out for now)
        /*
        await userCredential.user!.reload();
        if (email != ApiKeysSecret.adminEmail && userCredential.user!.phoneNumber == null) {
          isLoading.value = false;
          String userRole = 'user';
          String phone = '';

          // Check 'users' table
          final userDoc = await SupabaseService.getUser(userCredential.user!.uid);

          if (userDoc != null) {
            final data = SupabaseService.toCamelCase(userDoc);
            userRole = data['role'] as String? ?? 'user';
            phone = data['phone'] as String? ?? '';
          } else {
            // Check 'drivers' table
            final driverDoc = await SupabaseService.getDriver(userCredential.user!.uid);
            if (driverDoc != null) {
              final data = SupabaseService.toCamelCase(driverDoc);
              userRole = data['role'] as String? ?? 'driver';
              phone = data['phone'] as String? ?? '';
            }
          }

          // Format phone number
          String formattedPhone = phone.trim();
          if (!formattedPhone.startsWith('+')) {
            if (formattedPhone.startsWith('88')) {
              formattedPhone = '+$formattedPhone';
            } else if (formattedPhone.startsWith('0')) {
              formattedPhone = '+880${formattedPhone.substring(1)}';
            } else {
              formattedPhone = '+880$formattedPhone';
            }
          }

          if (formattedPhone.isNotEmpty) {
            Get.offAll(() => PhoneVerificationScreen(
                  userPhone: formattedPhone,
                  userRole: userRole,
                ));
          } else {
            // Fallback: login normally if no phone is found in database
            await _navigateBasedOnRole(userCredential.user!.uid);
          }
          return;
        }
        */

        // Store FCM token in user document
        if (fcmToken.value.isNotEmpty) {
          try {
            await SupabaseService.updateUser(userCredential.user!.uid, {
              'fcmToken': fcmToken.value,
              'lastLogin': DateTime.now().toIso8601String(),
            });
          } catch (_) {
            await SupabaseService.upsertUser(userCredential.user!.uid, {
              'fcmToken': fcmToken.value,
              'lastLogin': DateTime.now().toIso8601String(),
            });
          }
        }
        await _navigateBasedOnRole(userCredential.user!.uid);
      }
    } catch (e) {
    
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

      // Find user by phone number in Supabase
      final userResults = await SupabaseService.client
          .from('users')
          .select()
          .eq('phone', phone)
          .limit(1);

      
      if (userResults.isEmpty) {
        throw 'No account found with this phone number. Please sign up first.';
      }

      final userData = userResults.first;
      final email = userData['email'] as String?;

    

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
        // Phone Verification check (phone login) (Commented out for now)
        /*
        await userCredential.user!.reload();
        if (userCredential.user!.phoneNumber == null) {
          isLoading.value = false;
          
          String formattedPhone = phone.trim();
          if (!formattedPhone.startsWith('+')) {
            if (formattedPhone.startsWith('88')) {
              formattedPhone = '+$formattedPhone';
            } else if (formattedPhone.startsWith('0')) {
              formattedPhone = '+880${formattedPhone.substring(1)}';
            } else {
              formattedPhone = '+880$formattedPhone';
            }
          }

          Get.offAll(() => PhoneVerificationScreen(
                userPhone: formattedPhone,
                userRole: userRole ?? 'user',
              ));
          return;
        }
        */

        // Store FCM token in user document
        if (fcmToken.value.isNotEmpty) {
          try {
            await SupabaseService.updateUser(userCredential.user!.uid, {
              'fcmToken': fcmToken.value,
              'lastLogin': DateTime.now().toIso8601String(),
            });
          } catch (_) {
            await SupabaseService.upsertUser(userCredential.user!.uid, {
              'fcmToken': fcmToken.value,
              'lastLogin': DateTime.now().toIso8601String(),
            });
          }
        }
        await _navigateBasedOnRole(userCredential.user!.uid);
      }
    } catch (e) {
 
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
      final userData = await SupabaseService.getUser(uid);

      if (userData != null) {
        final role = userData['role'] as String? ?? 'user';

        Alert.info('Your role: $role\nUID: $uid');
      } else {
        Alert.error('User document not found in database');
      }
    } catch (e) {
      Alert.error('Failed to check role: $e');
    }
  }
}
