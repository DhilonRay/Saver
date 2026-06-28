import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../home_user/home_user.dart';
import '../../partner_file/home_partner/home_partner.dart';

class PhoneVerificationController extends GetxController {
  final String userPhone;
  final String userRole;

  PhoneVerificationController({
    required this.userPhone,
    required this.userRole,
  });

  final TextEditingController otpController = TextEditingController();

  var isLoading = false.obs;
  var isVerifying = false.obs;
  var isCooldown = false.obs;
  var cooldownSeconds = 60.obs;
  var verificationId = ''.obs;
  
  // To handle resending OTP
  var resendToken = Rx<int?>(null);

  Timer? _cooldownTimer;

  @override
  void onInit() {
    super.onInit();
    sendOtp();
  }

  @override
  void onClose() {
    _cooldownTimer?.cancel();
    otpController.dispose();
    super.onClose();
  }

  Future<void> sendOtp() async {
    if (isCooldown.value) return;

    isLoading.value = true;
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: userPhone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('✅ PhoneAuth auto verified!');
          try {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              await user.linkWithCredential(credential);
              _onVerificationSuccess();
            }
          } catch (e) {
            debugPrint('Auto verify link error: $e');
            if (e.toString().contains('credential-already-in-use') || e.toString().contains('provider-already-linked')) {
              _onVerificationSuccess();
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('❌ Phone Auth verificationFailed: ${e.message}');
          Get.snackbar('OTP পাঠানো যায়নি', e.message ?? 'Unknown error',
              backgroundColor: Colors.red[600], colorText: Colors.white);
          isLoading.value = false;
        },
        codeSent: (String verId, int? forceResendingToken) {
          verificationId.value = verId;
          resendToken.value = forceResendingToken;
          isLoading.value = false;
          _startCooldown();
          Get.snackbar('📱 OTP পাঠানো হয়েছে!',
              '$userPhone নম্বরে একটি OTP পাঠানো হয়েছে।',
              backgroundColor: Colors.green[600], colorText: Colors.white);
        },
        codeAutoRetrievalTimeout: (String verId) {
          verificationId.value = verId;
        },
        forceResendingToken: resendToken.value,
      );
    } catch (e) {
      debugPrint('Send OTP error: $e');
      Get.snackbar('Error', e.toString(),
          backgroundColor: Colors.red[600], colorText: Colors.white);
      isLoading.value = false;
    }
  }

  Future<void> verifyOtp() async {
    if (otpController.text.length != 6) {
      Get.snackbar('ত্রুটি', '৬ ডিজিটের OTP কোড লিখুন',
          backgroundColor: Colors.red[600], colorText: Colors.white);
      return;
    }

    isVerifying.value = true;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw 'User not logged in';
      }

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId.value,
        smsCode: otpController.text.trim(),
      );

      await user.linkWithCredential(credential);
      _onVerificationSuccess();
    } catch (e) {
      debugPrint('OTP verification failed: $e');
      if (e.toString().contains('credential-already-in-use') || e.toString().contains('provider-already-linked')) {
        _onVerificationSuccess();
      } else {
        Get.snackbar('ত্রুটি', 'ভুল OTP কোড। আবার চেষ্টা করুন।',
            backgroundColor: Colors.red[600], colorText: Colors.white);
      }
    } finally {
      isVerifying.value = false;
    }
  }

  void _startCooldown() {
    isCooldown.value = true;
    cooldownSeconds.value = 60;

    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      cooldownSeconds.value--;
      if (cooldownSeconds.value <= 0) {
        isCooldown.value = false;
        timer.cancel();
      }
    });
  }

  void _onVerificationSuccess() {
    _cooldownTimer?.cancel();
    Get.snackbar(
      '✅ Phone Verified!',
      'আপনার অ্যাকাউন্ট সফলভাবে verify হয়েছে।',
      backgroundColor: Colors.green[600],
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
    );
    Future.delayed(const Duration(seconds: 1), () {
      if (userRole == 'driver') {
        Get.offAll(() => HomePartnerPage());
      } else {
        Get.offAll(() => HomePage(isNewSignup: true));
      }
    });
  }

  Future<void> signOut() async {
    _cooldownTimer?.cancel();
    await FirebaseAuth.instance.signOut();
  }
}
