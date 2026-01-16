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
          // Read the user document to determine role - check users first, then drivers
          DocumentSnapshot doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          if (!doc.exists) {
            doc = await FirebaseFirestore.instance
                .collection('drivers')
                .doc(user.uid)
                .get();
          }
          final data = doc.data() as Map<String, dynamic>?;
          final role = data != null && data.containsKey('role')
              ? data['role'] as String
              : null;

          // Check if it's a partner by checking partners collection if role is null
          bool isPartner = false;
          if (role == null) {
            final partnerDoc = await FirebaseFirestore.instance
                .collection('partners')
                .doc(user.uid)
                .get();
            if (partnerDoc.exists) {
              isPartner = true;
            }
          }

          if ((role != null && role != 'user') || isPartner) {
            // Navigate to partner home for drivers
            Get.offAll(() => HomePartnerPage());
          } else {
            // Default to user home
            Get.offAll(() => HomePage());
          }

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
