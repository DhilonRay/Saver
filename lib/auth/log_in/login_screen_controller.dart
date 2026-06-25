import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// TODO: Re-enable push notifications using OneSignal or keep FCM
// import 'package:firebase_messaging/firebase_messaging.dart';
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
      
      // TODO: Re-implement push notifications. 
      // For now, we will leave the fcmToken empty since we removed Firebase.
      fcmToken.value = 'dummy_token_for_now';
      
      isLoadingToken.value = false;
    } catch (e) {
      isLoadingToken.value = false;
      debugPrint('Error getting token: $e');
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
      final client = Supabase.instance.client;
      final glmResponse = await client
          .from('glm_accounts')
          .select()
          .eq('id', identifier)
          .maybeSingle();

      if (glmResponse != null) {
        final String inputPass = passwordController.text.trim();
        final String dbPass = glmResponse['password'] ?? '';
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
      final client = Supabase.instance.client;

      // Priority 1: Check admin
      final adminDoc = await client.from('admins').select().eq('id', uid).maybeSingle();
      if (adminDoc != null) {
        debugPrint('🔑 Admin user detected - navigating to admin dashboard');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isAdminLoggedIn', true);
        Get.offAllNamed('/admin-dashboard');
        return;
      }

      // Priority 2: Check partners
      final partnerDoc = await client.from('partners').select().eq('id', uid).maybeSingle();
      if (partnerDoc != null) {
        debugPrint('Navigating to HomePartnerPage (found in partners)');
        _navigateToPartner();
        return;
      }

      // Priority 3: Check drivers
      final driverDoc = await client.from('drivers').select().eq('id', uid).maybeSingle();
      if (driverDoc != null) {
        debugPrint('Navigating to HomePartnerPage (found in drivers)');
        _navigateToPartner();
        return;
      }

      // Priority 4: Default to User
      debugPrint('User/Driver doc not found in partner collections, defaulting to HomePage (User)');
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
      final client = Supabase.instance.client;

      // ----------------------------------------------------
      // ADMIN CREDENTIALS BYPASS
      // ----------------------------------------------------
      if (email == ApiKeysSecret.adminEmail && password == ApiKeysSecret.adminPassword) {
        try {
          await client.auth.signInWithPassword(email: email, password: password);
        } catch (e) {
          try {
            final authResponse = await client.auth.signUp(email: email, password: password);
            if (authResponse.user != null) {
              await client.from('admins').insert({
                'id': authResponse.user!.id,
                'email': email,
                'createdAt': DateTime.now().toIso8601String(),
              });
            }
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

      final authResponse = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user != null) {
        // Store FCM token in user document (using upsert for merge-like behavior)
        if (fcmToken.value.isNotEmpty) {
          try {
            await client.from('users').upsert({
              'id': authResponse.user!.id,
              'fcmToken': fcmToken.value,
              'lastLogin': DateTime.now().toIso8601String(),
            });
          } catch (e) {
            debugPrint('Failed to update fcmToken: $e');
          }
        }
        await _navigateBasedOnRole(authResponse.user!.id);
      }
    } on AuthException catch (e) {
      debugPrint('Email login failed: ${e.message}');
      Alert.error(e.message);
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
      final client = Supabase.instance.client;

      // Find user by phone number in Supabase
      final querySnapshot = await client
          .from('users')
          .select()
          .eq('phone', phone)
          .limit(1);

      debugPrint('📱 Phone login: Searching for phone $phone');
      debugPrint('📊 Found ${querySnapshot.length} documents');

      if (querySnapshot.isEmpty) {
        throw 'No account found with this phone number. Please sign up first.';
      }

      final userData = querySnapshot.first;
      final email = userData['email'] as String?;
      final userRole = userData['role'] as String?;

      debugPrint('📧 Found email: $email');
      debugPrint('🎭 User role from phone search: $userRole');

      if (email == null || email.isEmpty) {
        throw 'Account setup incomplete. Please contact support.';
      }

      // Sign in with email and password
      final authResponse = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user != null) {
        // Store FCM token in user document
        if (fcmToken.value.isNotEmpty) {
          try {
            await client.from('users').upsert({
              'id': authResponse.user!.id,
              'fcmToken': fcmToken.value,
              'lastLogin': DateTime.now().toIso8601String(),
            });
          } catch (e) {
            debugPrint('Failed to update fcmToken: $e');
          }
        }
        await _navigateBasedOnRole(authResponse.user!.id);
      }
    } on AuthException catch (e) {
      debugPrint('Phone login failed: ${e.message}');
      Alert.error(e.message);
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
      final client = Supabase.instance.client;
      final userDoc = await client.from('users').select().eq('id', uid).maybeSingle();

      if (userDoc != null) {
        final role = userDoc['role'] as String? ?? 'user';
        Alert.info('Your role: $role\nUID: $uid');
      } else {
        Alert.error('User record not found in Supabase');
      }
    } catch (e) {
      Alert.error('Failed to check role: $e');
    }
  }
}
