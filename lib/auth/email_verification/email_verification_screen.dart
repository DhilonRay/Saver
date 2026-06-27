import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'email_verification_controller.dart';
import '../log_in/login_screen.dart';
import '../../home_user/home_user.dart';
import '../../partner_file/home_partner/home_partner.dart';

/// Email Verification Screen — signup এর পর দেখানো হয়।
/// ইউজার ইমেইলে লিংকে ক্লিক করলে auto-detect করে home page-এ যায়।
class EmailVerificationScreen extends StatelessWidget {
  final String userEmail;
  final String userRole; // 'user' বা 'driver'

  const EmailVerificationScreen({
    super.key,
    required this.userEmail,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1976D2);
    const Color lightBlue = Color(0xFFE3F2FD);

    return GetBuilder<EmailVerificationController>(
      init: EmailVerificationController(),
      builder: (controller) {
        // Auto-navigate যখন verified হবে
        controller.isEmailVerified.listen((verified) {
          if (verified) {
            Future.delayed(const Duration(seconds: 1), () {
              _navigateToHome();
            });
          }
        });

        return Scaffold(
          backgroundColor: lightBlue,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  // Icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryBlue.withValues(alpha: 0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Obx(() => controller.isEmailVerified.value
                        ? const Icon(Icons.check_circle,
                            size: 60, color: Colors.green)
                        : const Icon(Icons.mark_email_unread_outlined,
                            size: 60, color: primaryBlue)),
                  ),

                  const SizedBox(height: 32),

                  Obx(() => Text(
                        controller.isEmailVerified.value
                            ? '✅ Email Verified!'
                            : 'Verify Your Email',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                        ),
                      )),

                  const SizedBox(height: 16),

                  Obx(() => Text(
                        controller.isEmailVerified.value
                            ? 'আপনার অ্যাকাউন্ট সফলভাবে verify হয়েছে!\nঅ্যাপে যাচ্ছি...'
                            : 'আমরা নিচের ইমেইলে একটি verification link পাঠিয়েছি:',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      )),

                  const SizedBox(height: 12),

                  // Email address box
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: primaryBlue.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: Text(
                      userEmail,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: primaryBlue,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Steps guide
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '📋 কীভাবে verify করবেন:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 10),
                        _stepItem('1', 'আপনার ইমেইল inbox খুলুন'),
                        _stepItem('2', 'NeoSaver থেকে আসা email খুঁজুন'),
                        _stepItem('3', '"Verify Email" বাটনে ক্লিক করুন'),
                        _stepItem('4', 'এই স্ক্রিনে ফিরে আসুন — auto-detect হবে!'),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Auto-check indicator
                  Obx(() => !controller.isEmailVerified.value
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: primaryBlue.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Verification-এর জন্য অপেক্ষা করছি...',
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 12),
                            ),
                          ],
                        )
                      : const SizedBox.shrink()),

                  const SizedBox(height: 20),

                  // Resend Button
                  Obx(() => !controller.isEmailVerified.value
                      ? SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: controller.isCooldown.value ||
                                    controller.isResending.value
                                ? null
                                : controller.resendVerificationEmail,
                            icon: controller.isResending.value
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.refresh),
                            label: Text(
                              controller.isCooldown.value
                                  ? 'Resend (${controller.cooldownSeconds.value}s)'
                                  : 'Resend Verification Email',
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: controller.isCooldown.value
                                  ? Colors.grey
                                  : primaryBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        )
                      : const SizedBox.shrink()),

                  const SizedBox(height: 12),

                  // Back to Login
                  TextButton(
                    onPressed: () async {
                      await controller.signOut();
                      Get.offAll(() => LoginPage());
                    },
                    child: Text(
                      'অন্য অ্যাকাউন্ট দিয়ে লগিন করুন',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _stepItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFF1976D2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(number,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 13, color: Colors.grey[700])),
          ),
        ],
      ),
    );
  }

  void _navigateToHome() {
    if (userRole == 'driver') {
      Get.offAll(() => HomePartnerPage());
    } else {
      Get.offAll(() => HomePage(isNewSignup: true));
    }
  }
}
