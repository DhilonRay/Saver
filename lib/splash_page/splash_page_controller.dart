import 'package:firebase_auth/firebase_auth.dart';
import '../services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saver/get_started/get_started_page.dart';
import '../home_user/home_user.dart';
import '../partner_file/home_partner/home_partner.dart';
import '../services/notification_service.dart';
import '../fare_negotiation/fare_negotiation_page.dart';
import '../user_tracking/user_tracking_page.dart';
import '../partner_file/accept_maps/accept_maps.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../admin/admin_dashboard/admin_dashboard.dart';
import '../glm_dashboard/glm_dashboard.dart';
// import '../config/api_keys_secret.dart';
// import '../auth/phone_verification/phone_verification_screen.dart';

class SplashPageController {
  /// Navigate after the splash delay using Get navigation to avoid
  /// passing a BuildContext across an async gap.
  void navigateAfterSplash() {
    Future.delayed(const Duration(seconds: 3), () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        bool isAdmin = prefs.getBool('isAdminLoggedIn') ?? false;
        debugPrint('🔍 SplashPageController: isAdminLoggedIn = $isAdmin');
        if (isAdmin) {
          debugPrint('🚀 SplashPageController: Admin session active, routing to AdminDashboard');
          Get.offAll(() => const AdminDashboard());
          _initializeFCMDelayed();
          return;
        }

        bool isGLM = prefs.getBool('isGLMLoggedIn') ?? false;
        String? currentGLMId = prefs.getString('currentGLMId');
        debugPrint('🔍 SplashPageController: isGLMLoggedIn = $isGLM, GLM ID = $currentGLMId');
        if (isGLM && currentGLMId != null) {
          debugPrint('🚀 SplashPageController: GLM session active, routing to GLMDashboard');
          Get.offAll(() => GLMDashboard(glmId: currentGLMId));
          return;
        }
      } catch (e) {
        debugPrint('⚠️ SplashPageController: SharedPreferences error: $e');
      }

      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Check if user is not phone verified (excluding admin) (Commented out for now)
        /*
        if (user.email != ApiKeysSecret.adminEmail && user.phoneNumber == null) {
          try {
            String role = 'user';
            String phone = '';

            // Check users collection first
            final userDoc = await SupabaseService.getUser(user.uid);

            if (userDoc != null) {
              final data = SupabaseService.toCamelCase(userDoc);
              role = data['role'] as String? ?? 'user';
              phone = data['phone'] as String? ?? '';
            } else {
              // Check drivers collection
              final driverDoc = await SupabaseService.getDriver(user.uid);
              if (driverDoc != null) {
                final data = SupabaseService.toCamelCase(driverDoc);
                role = data['role'] as String? ?? 'driver';
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
                    userRole: role,
                  ));
              return;
            }
          } catch (e) {
            debugPrint('Error getting phone verification data on splash: $e');
          }
        }
        */
        try {
          // Priority Check: Active Order Persistence
          final activeUserOrders = await SupabaseService.getOrdersByUserId(user.uid);
          final activePartnerOrders = await SupabaseService.getOrdersByPartnerId(user.uid);

          // Check for active user orders
          if (activeUserOrders.isNotEmpty) {
            final docs = activeUserOrders
                .where((d) => ![
                      'completed',
                      'cancelled',
                      'rejected',
                      'declined'
                    ].contains(d['status']?.toString().toLowerCase()))
                .toList();

            if (docs.isNotEmpty) {
              // Safe sorting
              docs.sort((a, b) {
                final aTime = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime.now();
                final bTime = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime.now();
                return bTime.compareTo(aTime);
              });

              final orderData = Map<String, dynamic>.from(docs.first);
              final status = orderData['status']?.toString().toLowerCase();

              if (status == 'sent' ||
                  status == 'counter' ||
                  status == 'pending') {
                final negotiation =
                    orderData['extra_data'] is Map ? orderData['extra_data'] as Map<String, dynamic> : <String, dynamic>{};
                Get.offAll(() => FareNegotiationPage(), arguments: {
                  'requestId': orderData['id'],
                  'driverId': orderData['driver_id'] ??
                      negotiation['driverId'] ??
                      orderData['partner_id'] ??
                      '',
                  'fare': (negotiation['counterFare'] as num?)?.toDouble() ??
                      (orderData['fare'] as num?)?.toDouble() ??
                      0.0,
                });
                _initializeFCMDelayed();
                return;
              } else if (['accepted', 'pickup', 'in_transit', 'to_destination']
                  .contains(status)) {
                Get.offAll(() => const UserTrackingPage(),
                    arguments: orderData);
                _initializeFCMDelayed();
                return;
              }
            }
          }

          // Check for active partner orders
          if (activePartnerOrders.isNotEmpty) {
            final docs = activePartnerOrders.where((d) {
              final status = d['status']?.toString().toLowerCase();
              final extraData = d['extra_data'] is Map ? d['extra_data'] as Map<String, dynamic> : <String, dynamic>{};
              final negStatus = extraData['status']?.toString().toLowerCase();
              return [
                    'accepted',
                    'confirmed',
                    'pickup',
                    'in_transit',
                    'to_destination'
                  ].contains(status) ||
                  ['accepted', 'confirmed'].contains(negStatus);
            }).toList();

            if (docs.isNotEmpty) {
              // Safe sorting
              docs.sort((a, b) {
                final aTime = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime.now();
                final bTime = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime.now();
                return bTime.compareTo(aTime);
              });

              final orderData = Map<String, dynamic>.from(docs.first);

              final fare = (orderData['fare'] as num?)?.toInt() ??
                  (orderData['final_fare'] as num?)?.toInt() ??
                  (orderData['counter_fare'] as num?)?.toInt() ??
                  2500;

              Get.offAll(() => const AcceptMapsPage(), arguments: {
                'request': orderData,
                'serviceRate': fare,
              });
              _initializeFCMDelayed();
              return;
            }
          }

          // Standard role-based redirect
          final adminData = await SupabaseService.getAdmin(user.uid);
          if (adminData != null) {
            Get.offAll(() => const AdminDashboard());
            _initializeFCMDelayed();
            return;
          }

          final partnerData = await SupabaseService.getPartner(user.uid);
          if (partnerData != null) {
            Get.offAll(() => HomePartnerPage());
            _initializeFCMDelayed();
            return;
          }

          final driverData = await SupabaseService.getDriver(user.uid);
          if (driverData != null) {
            Get.offAll(() => HomePartnerPage());
            _initializeFCMDelayed();
            return;
          }

          Get.offAll(() => HomePage());
          _initializeFCMDelayed();
        } catch (e) {
          debugPrint('Error in splash redirection: $e');
          Get.offAll(() => HomePage());
        }
      } else {
        Get.offAll(() => const GetStartedPage());
      }
    });
  }

  void _initializeFCMDelayed() {
    Future.delayed(const Duration(seconds: 1), () {
      NotificationService.ensureFCMInitialized();
    });
  }
}
