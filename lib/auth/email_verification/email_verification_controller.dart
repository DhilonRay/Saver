import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saver/components/alert.dart';

class EmailVerificationController extends GetxController {
  var isEmailVerified = false.obs;
  var isResending = false.obs;
  var isCooldown = false.obs;
  var cooldownSeconds = 60.obs;

  Timer? _checkTimer;
  Timer? _cooldownTimer;

  @override
  void onInit() {
    super.onInit();
    // প্রতি ৩ সেকেন্ডে verification check করব
    _startVerificationCheck();
  }

  @override
  void onClose() {
    _checkTimer?.cancel();
    _cooldownTimer?.cancel();
    super.onClose();
  }

  void _startVerificationCheck() {
    _checkTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      await _checkEmailVerified();
    });
  }

  Future<void> _checkEmailVerified() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await user.reload(); // Firebase থেকে fresh state নেয়
      final verified = user.emailVerified;
      isEmailVerified.value = verified;

      if (verified) {
        _checkTimer?.cancel();
        _onVerificationSuccess();
      }
    } catch (e) {
  
    }
  }

  void _onVerificationSuccess() {
    Alert.success('আপনার অ্যাকাউন্ট সফলভাবে verify হয়েছে।');
    // ২ সেকেন্ড পর navigate করবে — caller screen handle করবে
  }

  Future<void> resendVerificationEmail() async {
    if (isCooldown.value) return;

    try {
      isResending.value = true;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await user.sendEmailVerification();

      Alert.success('আপনার ইমেইল চেক করুন।');

      // Cooldown শুরু করো
      _startCooldown();
    } catch (e) {
      Alert.error('Email পাঠাতে সমস্যা হয়েছে: $e');
    } finally {
      isResending.value = false;
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

  Future<void> signOut() async {
    _checkTimer?.cancel();
    _cooldownTimer?.cancel();
    await FirebaseAuth.instance.signOut();
  }
}
