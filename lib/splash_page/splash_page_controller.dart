import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saver/auth/log_in/login_screen.dart';
import '../home_user/home_user.dart';
import '../home_partner/home_partner.dart';
import 'package:get/get.dart';


class SplashPageController {
  /// Navigate after the splash delay using Get navigation to avoid
  /// passing a BuildContext across an async gap.
  void navigateAfterSplash() {
    Future.delayed(const Duration(seconds: 3), () async {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          // Read the user document to determine role
          final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          final data = doc.data();
          final role = data != null && data.containsKey('role') ? data['role'] as String : null;

          if (role != null && role == 'driver') {
            // Navigate to partner home for drivers
            Get.offAll(() => const HomePartnerPage());
          } else {
            // Default to user home
            Get.offAll(() => HomePage());
          }
        } catch (e) {
          // On error, default to user home or fallback to login
          print('Error fetching user role: $e');
          Get.offAll(() => HomePage());
        }
      } else {
        // Replace entire stack with LoginPage
        Get.offAll(() => const LoginPage());
      }
    });
  }
}
