import 'package:get/get.dart';
import 'package:saver/auth/log_in/login_screen.dart';

class GetStartedController extends GetxController {
  void navigateToLogin() {
    Get.offAll(() => const LoginPage());
  }
}
