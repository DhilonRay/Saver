import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saver/get_started/get_started_page.dart';
import '../home_user/home_user.dart';
import '../partner_file/home_partner/home_partner.dart';
import '../services/notification_service.dart';
import 'package:get/get.dart';

class SplashPageController {
  /// Navigate after the splash delay using Get navigation to avoid
  /// passing a BuildContext across an async gap.
  void navigateAfterSplash() {
    Future.delayed(const Duration(seconds: 3), () async {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          // Priority 1: Check Partners Collection
          final partnerDoc = await FirebaseFirestore.instance
              .collection('partners')
              .doc(user.uid)
              .get();

          if (partnerDoc.exists) {
            Get.offAll(() => HomePartnerPage());
            Future.delayed(const Duration(seconds: 1), () {
              NotificationService.ensureFCMInitialized();
            });
            return;
          }

          // Priority 2: Check Drivers Collection
          final driverDoc = await FirebaseFirestore.instance
              .collection('drivers')
              .doc(user.uid)
              .get();

          if (driverDoc.exists) {
            Get.offAll(() => HomePartnerPage());
            Future.delayed(const Duration(seconds: 1), () {
              NotificationService.ensureFCMInitialized();
            });
            return;
          }

          // Priority 3: Check Users Collection (Default)
          // Even if not found, we default to HomePage for patients
          Get.offAll(() => HomePage());

          // Ensure FCM token is initialized after navigation
          Future.delayed(const Duration(seconds: 1), () {
            NotificationService.ensureFCMInitialized();
          });
        } catch (e) {
          // On error, default to user home or fallback to login
          print('Error fetching user role: $e');
          Get.offAll(() => HomePage());
        }
      } else {
        // Replace entire stack with GetStartedPage
        Get.offAll(() => const GetStartedPage());
      }
    });
  }
}
