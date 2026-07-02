import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';
import '../../services/supabase_service.dart';
import 'package:saver/compo/success_dialog.dart';
import 'package:saver/components/alert.dart';

/// ResetMode — email বা phone দিয়ে reset করা যাবে
enum ResetMode { email, phone }

class ForgotPasswordController extends GetxController {
  // Text Controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  // Reactive Variables
  var isLoading = false.obs;
  var resetMode = ResetMode.email.obs; // email বা phone
  var selectedCountryCode = '+880'.obs;

  // Email reset cooldown
  var lastResetTime = 0.obs;
  var isCooldownActive = false.obs;
  var cooldownSeconds = 60.obs;
  var remainingTime = 0.obs;
  var lastEmailSent = ''.obs;
  var requestCount = 0.obs;
  var firstRequestTime = 0.obs;

  // Phone OTP state
  var isOtpSent = false.obs;
  var isSendingOtp = false.obs;
  var isVerifyingOtp = false.obs;
  var phoneVerificationId = ''.obs;
  var otpCountdown = 60.obs;
  var isOtpCooldown = false.obs;
  var isShowPasswordReset = false.obs; // OTP verified → show new password fields
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  var isNewPasswordVisible = false.obs;

  static const int maxRequestsPerHour = 5;

  Timer? _cooldownTimer;
  Timer? _otpTimer;

  @override
  void onInit() {
    super.onInit();
    _initializeFirebase();
    _startCooldownTimer();
  }

  @override
  void onClose() {
    _cooldownTimer?.cancel();
    _otpTimer?.cancel();
    super.onClose();
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      await FirebaseAuth.instance.setSettings(
        appVerificationDisabledForTesting: false,
      );
    } catch (e) {
    
    }
  }

  void switchMode(ResetMode mode) {
    resetMode.value = mode;
    isOtpSent.value = false;
    isShowPasswordReset.value = false;
    otpController.clear();
  }

  // ─────────────────────────────────────────
  //  EMAIL RESET METHODS
  // ─────────────────────────────────────────

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isCooldownActive.value) {
        final currentRemaining = cooldownSeconds.value -
            ((DateTime.now().millisecondsSinceEpoch - lastResetTime.value) ~/
                1000);
        remainingTime.value = currentRemaining > 0 ? currentRemaining : 0;
        if (remainingTime.value <= 0) {
          isCooldownActive.value = false;
          remainingTime.value = 0;
          _cooldownTimer?.cancel();
        }
      }
    });
  }

  Future<void> resetPassword() async {
    final email = emailController.text.trim();

    if (isCooldownActive.value && email != lastEmailSent.value) {
      final remaining = cooldownSeconds.value -
          ((DateTime.now().millisecondsSinceEpoch - lastResetTime.value) ~/ 1000);
      if (remaining > 0) {
        Alert.info('$remaining সেকেন্ড পর আবার try করুন');
        return;
      } else {
        isCooldownActive.value = false;
      }
    }

    final currentTime = DateTime.now().millisecondsSinceEpoch;
    if (firstRequestTime.value == 0) firstRequestTime.value = currentTime;
    if (currentTime - firstRequestTime.value > 3600000) {
      requestCount.value = 0;
      firstRequestTime.value = currentTime;
    }
    if (requestCount.value >= maxRequestsPerHour) {
      Alert.info('অনেকবার request করা হয়েছে। পরে আবার চেষ্টা করুন।');
      return;
    }

    if (email.isEmpty) {
      Alert.error('ইমেইল ঠিকানা লিখুন');
      return;
    }

    if (!isValidEmail(email)) {
      Alert.error('সঠিক ইমেইল ঠিকানা লিখুন');
      return;
    }

    isLoading.value = true;
    requestCount.value++;

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      lastResetTime.value = DateTime.now().millisecondsSinceEpoch;
      isCooldownActive.value = true;
      lastEmailSent.value = email;
      _startCooldownTimer();

      SuccessDialog.show(
        title: 'Reset Email Sent!',
        message: '$email-এ password reset link পাঠানো হয়েছে।\n\n📧 Inbox এবং Spam folder চেক করুন।',
        autoCloseDuration: const Duration(seconds: 10),
      );
      emailController.clear();

      Future.delayed(const Duration(seconds: 12), () {
        Get.back();
      });
    } catch (e) {
      String errorMessage = 'Reset email পাঠাতে সমস্যা হয়েছে';
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'এই ইমেইলে কোনো অ্যাকাউন্ট নেই';
            break;
          case 'invalid-email':
            errorMessage = 'ইমেইল ঠিকানাটি সঠিক নয়';
            break;
          case 'too-many-requests':
            errorMessage = 'অনেকবার request করা হয়েছে। পরে আবার চেষ্টা করুন।';
            lastResetTime.value = DateTime.now().millisecondsSinceEpoch;
            isCooldownActive.value = true;
            cooldownSeconds.value = 300;
            _startCooldownTimer();
            break;
          default:
            errorMessage = e.message ?? 'Unknown error';
        }
      }
      Alert.error(errorMessage);
    } finally {
      isLoading.value = false;
    }
  }

  // ─────────────────────────────────────────
  //  PHONE OTP RESET METHODS
  // ─────────────────────────────────────────

  /// ধাপ ১: Phone number-এ OTP পাঠাও
  Future<void> sendOtpToPhone() async {
    final phone = phoneController.text.trim();
    if (phone.isEmpty) {
      Alert.error('ফোন নম্বর লিখুন');
      return;
    }

    final fullPhone = '${selectedCountryCode.value}$phone';

    isSendingOtp.value = true;
    try {
      final query = await SupabaseService.client
          .from('users')
          .select()
          .eq('phone', phone)
          .limit(1);

      if (query.isEmpty) {
        // Drivers collection-এও check করো
        final driverQuery = await SupabaseService.client
            .from('drivers')
            .select()
            .eq('phone', phone)
            .limit(1);

        if (driverQuery.isEmpty) {
          Alert.error('এই ফোন নম্বরে কোনো অ্যাকাউন্ট নেই। আগে সাইনআপ করুন।');
          isSendingOtp.value = false;
          return;
        }
      }

      // OTP পাঠাও
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: fullPhone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verify (Android only)
        
          isOtpSent.value = true;
          await _applyAutoCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
        
          Alert.error(e.message ?? 'Unknown error');
          isSendingOtp.value = false;
        },
        codeSent: (String verificationId, int? resendToken) {
          phoneVerificationId.value = verificationId;
          isOtpSent.value = true;
          isSendingOtp.value = false;
          _startOtpCountdown();
          Alert.success('$fullPhone নম্বরে একটি OTP পাঠানো হয়েছে।');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          phoneVerificationId.value = verificationId;
        },
      );
    } catch (e) {
    
      Alert.error(e.toString());
    } finally {
      isSendingOtp.value = false;
    }
  }

  // Auto-verify credential handler (Android instant verify)
  Future<void> _applyAutoCredential(PhoneAuthCredential cred) async {
    try {
      await FirebaseAuth.instance.signInWithCredential(cred);
      isShowPasswordReset.value = true;
    } catch (e) {
   
    }
  }

  void _startOtpCountdown() {
    otpCountdown.value = 60;
    isOtpCooldown.value = true;
    _otpTimer?.cancel();
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      otpCountdown.value--;
      if (otpCountdown.value <= 0) {
        isOtpCooldown.value = false;
        t.cancel();
      }
    });
  }

  /// ধাপ ২: OTP verify করো
  Future<void> verifyOtp() async {
    final otp = otpController.text.trim();
    if (otp.length < 6) {
      Alert.error('৬ সংখ্যার OTP লিখুন');
      return;
    }

    isVerifyingOtp.value = true;
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: phoneVerificationId.value,
        smsCode: otp,
      );

      // OTP verify করে temporarily sign in করো
      final result = await FirebaseAuth.instance.signInWithCredential(credential);

      if (result.user != null) {
        // OTP verified! → New password enter করার UI দেখাও
        isShowPasswordReset.value = true;
        Alert.success('এখন নতুন password সেট করুন।');
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'OTP ভুল হয়েছে';
      if (e.code == 'invalid-verification-code') msg = 'OTP সঠিক নয়। আবার চেক করুন।';
      if (e.code == 'session-expired') msg = 'OTP মেয়াদ শেষ। আবার পাঠান।';
      Alert.error(msg);
    } finally {
      isVerifyingOtp.value = false;
    }
  }

  /// ধাপ ৩: নতুন password সেট করো
  Future<void> setNewPassword() async {
    final newPass = newPasswordController.text.trim();
    final confirmPass = confirmPasswordController.text.trim();

    if (newPass.length < 6) {
      Alert.error('Password কমপক্ষে ৬ অক্ষর হতে হবে');
      return;
    }
    if (newPass != confirmPass) {
      Alert.error('দুটো password মিলছে না');
      return;
    }

    isLoading.value = true;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'User not found';

      await user.updatePassword(newPass);

      SuccessDialog.show(
        title: '✅ Password পরিবর্তন হয়েছে!',
        message: 'আপনার নতুন password সফলভাবে সেট হয়েছে। এখন লগিন করুন।',
        autoCloseDuration: const Duration(seconds: 5),
      );

      // Sign out করো এবং login page-এ যাও
      await FirebaseAuth.instance.signOut();
      Future.delayed(const Duration(seconds: 5), () {
        Get.back();
      });
    } catch (e) {
      String msg = 'Password পরিবর্তন করা যায়নি';
      if (e is FirebaseAuthException && e.code == 'requires-recent-login') {
        msg = 'Security কারণে আবার OTP verify করুন।';
        isShowPasswordReset.value = false;
        isOtpSent.value = false;
      }
      Alert.error(msg);
    } finally {
      isLoading.value = false;
    }
  }

  bool isValidEmail(String email) {
    final emailRegex = RegExp(
        r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$');
    if (!emailRegex.hasMatch(email)) return false;

    final disposableDomains = [
      '10minutemail.com', 'guerrillamail.com', 'mailinator.com',
      'temp-mail.org', 'throwaway.email', 'yopmail.com',
      'maildrop.cc', 'tempail.com'
    ];
    final domain = email.split('@').last.toLowerCase();
    if (disposableDomains.contains(domain)) return false;
    return true;
  }
}
