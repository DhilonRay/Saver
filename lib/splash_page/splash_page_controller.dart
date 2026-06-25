import 'package:supabase_flutter/supabase_flutter.dart';
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

      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user != null) {
        try {
          // Priority Check: Active Order Persistence
          final activeUserOrder = await client
              .from('orders')
              .select()
              .eq('userId', user.id);

          final activePartnerOrder = await client
              .from('orders')
              .select()
              .eq('partnerId', user.id);

          // Check for active user orders
          if (activeUserOrder.isNotEmpty) {
            final docs = activeUserOrder
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
                final aTime = a['createdAt'] != null ? DateTime.parse(a['createdAt']) : DateTime.now();
                final bTime = b['createdAt'] != null ? DateTime.parse(b['createdAt']) : DateTime.now();
                return bTime.compareTo(aTime);
              });

              final orderData = docs.first;
              final status = orderData['status']?.toString().toLowerCase();

              if (status == 'sent' ||
                  status == 'counter' ||
                  status == 'pending') {
                final negotiation =
                    orderData['negotiation'] as Map<String, dynamic>? ?? {};
                Get.offAll(() => FareNegotiationPage(), arguments: {
                  'requestId': orderData['id'],
                  'driverId': orderData['driverId'] ??
                      negotiation['driverId'] ??
                      orderData['partnerId'] ??
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
          if (activePartnerOrder.isNotEmpty) {
            final docs = activePartnerOrder.where((data) {
              final status = data['status']?.toString().toLowerCase();
              final negStatus =
                  data['negotiation']?['status']?.toString().toLowerCase();
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
                final aTime = a['createdAt'] != null ? DateTime.parse(a['createdAt']) : DateTime.now();
                final bTime = b['createdAt'] != null ? DateTime.parse(b['createdAt']) : DateTime.now();
                return bTime.compareTo(aTime);
              });

              final orderData = docs.first;

              final fare = (orderData['fareAmount'] as num?)?.toInt() ??
                  (orderData['finalFare'] as num?)?.toInt() ??
                  (orderData['confirmedFare'] as num?)?.toInt() ??
                  (orderData['negotiation']?['counterFare'] as num?)?.toInt() ??
                  (orderData['negotiation']?['finalFare'] as num?)?.toInt() ??
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
          final adminDoc = await client
              .from('admins')
              .select()
              .eq('id', user.id)
              .maybeSingle();
          if (adminDoc != null) {
            Get.offAll(() => const AdminDashboard());
            _initializeFCMDelayed();
            return;
          }

          final partnerDoc = await client
              .from('partners')
              .select()
              .eq('id', user.id)
              .maybeSingle();
          if (partnerDoc != null) {
            Get.offAll(() => HomePartnerPage());
            _initializeFCMDelayed();
            return;
          }

          final driverDoc = await client
              .from('drivers')
              .select()
              .eq('id', user.id)
              .maybeSingle();
          if (driverDoc != null) {
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
