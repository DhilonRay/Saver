import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saver/components/alert.dart';
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
        
          try {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              await user.linkWithCredential(credential);
              _onVerificationSuccess();
            }
          } catch (e) {
        
            if (e.toString().contains('credential-already-in-use') || e.toString().contains('provider-already-linked')) {
              _onVerificationSuccess();
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
         
          Alert.error(e.message ?? 'Unknown error');
          isLoading.value = false;
        },
        codeSent: (String verId, int? forceResendingToken) {
          verificationId.value = verId;
          resendToken.value = forceResendingToken;
          isLoading.value = false;
          _startCooldown();
          Alert.success('$userPhone নম্বরে একটি OTP পাঠানো হয়েছে।');
        },
        codeAutoRetrievalTimeout: (String verId) {
          verificationId.value = verId;
        },
        forceResendingToken: resendToken.value,
      );
    } catch (e) {
     
      Alert.error(e.toString());
      isLoading.value = false;
    }
  }

  Future<void> verifyOtp() async {
    if (otpController.text.length != 6) {
      Alert.error('৬ ডিজিটের OTP কোড লিখুন');
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
     
      if (e.toString().contains('credential-already-in-use') || e.toString().contains('provider-already-linked')) {
        _onVerificationSuccess();
      } else {
        Alert.error('ভুল OTP কোড। আবার চেষ্টা করুন।');
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
    Alert.success('আপনার অ্যাকাউন্ট সফলভাবে verify হয়েছে।');
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
