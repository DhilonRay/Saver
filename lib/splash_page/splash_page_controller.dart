import 'package:firebase_auth/firebase_auth.dart';
import 'package:neosaver/auth/log_in/login_screen.dart';
import '../home_user/home_user.dart';
import 'package:get/get.dart';


class SplashPageController {
  /// Navigate after the splash delay using Get navigation to avoid
  /// passing a BuildContext across an async gap.
  void navigateAfterSplash() {
    Future.delayed(const Duration(seconds: 3), () {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Replace entire stack with HomePage
        Get.offAll(() => HomePage());
      } else {
        // Replace entire stack with LoginPage
        Get.offAll(() => const LoginPage());
      }
    });
  }
}
