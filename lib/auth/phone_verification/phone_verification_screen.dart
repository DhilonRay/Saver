import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import 'phone_verification_controller.dart';
import '../log_in/login_screen.dart';

class PhoneVerificationScreen extends StatelessWidget {
  final String userPhone;
  final String userRole; // 'user' বা 'driver'

  const PhoneVerificationScreen({
    super.key,
    required this.userPhone,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1976D2);
    const Color lightBlue = Color(0xFFE3F2FD);

    final controller = Get.put(PhoneVerificationController(
      userPhone: userPhone,
      userRole: userRole,
    ));

    final defaultPinTheme = PinTheme(
      width: 52,
      height: 56,
      textStyle: const TextStyle(
          fontSize: 22, fontWeight: FontWeight.w700, color: primaryBlue),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryBlue.withValues(alpha: 0.3), width: 1.5),
      ),
    );

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
                child: const Icon(
                  Icons.sms_outlined,
                  size: 60,
                  color: primaryBlue,
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                'Verify Your Phone Number',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'আমরা আপনার ফোনে একটি ৬ ডিজিটের verification code (OTP) পাঠিয়েছি:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 12),

              // Phone number box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: primaryBlue.withValues(alpha: 0.3), width: 1.5),
                ),
                child: Text(
                  userPhone,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: primaryBlue,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // OTP Input field (Pinput)
              Pinput(
                controller: controller.otpController,
                length: 6,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: defaultPinTheme.copyDecorationWith(
                  border: Border.all(color: primaryBlue, width: 2),
                  color: Colors.white,
                ),
                onCompleted: (_) => controller.verifyOtp(),
              ),

              const SizedBox(height: 24),

              // Verify Button
              Obx(() => SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: controller.isVerifying.value || controller.isLoading.value
                          ? null
                          : controller.verifyOtp,
                      icon: controller.isVerifying.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle_outline),
                      label: const Text(
                        'OTP Verify করুন',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  )),

              const Spacer(),

              // Resend Option
              Obx(() => TextButton.icon(
                    onPressed: controller.isCooldown.value || controller.isLoading.value
                        ? null
                        : controller.sendOtp,
                    icon: Icon(
                      Icons.refresh,
                      size: 16,
                      color: controller.isCooldown.value ? Colors.grey : primaryBlue,
                    ),
                    label: Text(
                      controller.isCooldown.value
                          ? 'Resend (${controller.cooldownSeconds.value}s)'
                          : 'OTP আসেনি? Resend করুন',
                      style: TextStyle(
                        color: controller.isCooldown.value ? Colors.grey : primaryBlue,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )),

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
  }
}
