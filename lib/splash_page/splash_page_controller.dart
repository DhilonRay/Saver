import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          // Priority Check: Active Order Persistence
          final activeUserOrder = await FirebaseFirestore.instance
              .collection('orders')
              .where('userId', isEqualTo: user.uid)
              .get();

          final activePartnerOrder = await FirebaseFirestore.instance
              .collection('orders')
              .where('partnerId', isEqualTo: user.uid)
              .get();

          // Check for active user orders
          if (activeUserOrder.docs.isNotEmpty) {
            final docs = activeUserOrder.docs
                .where((d) => ![
                      'completed',
                      'cancelled',
                      'rejected',
                      'declined'
                    ].contains(d.data()['status']?.toString().toLowerCase()))
                .toList();

            if (docs.isNotEmpty) {
              // Safe sorting
              docs.sort((a, b) {
                final aTime =
                    (a.data()['createdAt'] as Timestamp?) ?? Timestamp.now();
                final bTime =
                    (b.data()['createdAt'] as Timestamp?) ?? Timestamp.now();
                return bTime.compareTo(aTime);
              });

              final orderDoc = docs.first;
              final orderData = orderDoc.data();
              final status = orderData['status']?.toString().toLowerCase();

              if (status == 'sent' ||
                  status == 'counter' ||
                  status == 'pending') {
                final negotiation =
                    orderData['negotiation'] as Map<String, dynamic>? ?? {};
                Get.offAll(() => FareNegotiationPage(), arguments: {
                  'requestId': orderDoc.id,
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
                orderData['id'] = orderDoc.id;
                Get.offAll(() => const UserTrackingPage(),
                    arguments: orderData);
                _initializeFCMDelayed();
                return;
              }
            }
          }

          // Check for active partner orders
          if (activePartnerOrder.docs.isNotEmpty) {
            final docs = activePartnerOrder.docs.where((d) {
              final data = d.data();
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
                final aTime =
                    (a.data()['createdAt'] as Timestamp?) ?? Timestamp.now();
                final bTime =
                    (b.data()['createdAt'] as Timestamp?) ?? Timestamp.now();
                return bTime.compareTo(aTime);
              });

              final orderDoc = docs.first;
              final orderData = orderDoc.data();
              orderData['id'] = orderDoc.id;

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
          final adminDoc = await FirebaseFirestore.instance
              .collection('admins')
              .doc(user.uid)
              .get();
          if (adminDoc.exists) {
            Get.offAll(() => const AdminDashboard());
            _initializeFCMDelayed();
            return;
          }

          final partnerDoc = await FirebaseFirestore.instance
              .collection('partners')
              .doc(user.uid)
              .get();
          if (partnerDoc.exists) {
            Get.offAll(() => HomePartnerPage());
            _initializeFCMDelayed();
            return;
          }

          final driverDoc = await FirebaseFirestore.instance
              .collection('drivers')
              .doc(user.uid)
              .get();
          if (driverDoc.exists) {
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
