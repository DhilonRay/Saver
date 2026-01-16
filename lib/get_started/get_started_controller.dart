import 'package:get/get.dart';
import 'package:saver/auth/log_in/login_screen.dart';

class GetStartedController extends GetxController {
  String currentLanguage = 'English';

  void navigateToLogin() {
    Get.offAll(() => const LoginPage());
  }

  void changeLanguage(String language) {
    currentLanguage = language;
    update();
  }

  void navigateToPrivacyPolicy() {
    Get.toNamed('/privacy-policy');
  }

  void navigateToTerms() {
    Get.toNamed('/terms-conditions');
  }
}
