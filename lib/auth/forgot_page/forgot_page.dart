import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'forgot_page_controller.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ForgotPasswordController>(
      init: ForgotPasswordController(),
      builder: (controller) {
        const Color primaryBlue = Color(0xFF1976D2);
        const Color secondaryBlue = Color(0xFF42A5F5);
        const Color darkBlue = Color(0xFF0D47A1);
        const Color lightBlue = Color(0xFFE3F2FD);
        const Color textPrimary = Color(0xFF2D3748);
        const Color textSecondary = Color(0xFF718096);

        return Scaffold(
          backgroundColor: lightBlue,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: primaryBlue, size: 22),
              onPressed: () => Get.back(),
            ),
            title: const Text(
              'Password Reset',
              style: TextStyle(
                  color: primaryBlue, fontWeight: FontWeight.w600, fontSize: 18),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  _buildHeader(primaryBlue, darkBlue, textPrimary, textSecondary),
                  const SizedBox(height: 24),

                  // Email | Phone Tab
                  _buildModeTabs(controller, primaryBlue, lightBlue),
                  const SizedBox(height: 20),

                  // Content based on mode
                  Obx(() => controller.resetMode.value == ResetMode.email
                      ? _buildEmailSection(controller, primaryBlue, secondaryBlue, lightBlue, textSecondary)
                      : _buildPhoneSection(controller, primaryBlue, secondaryBlue, lightBlue, textSecondary)),

                  const SizedBox(height: 24),
                  _buildFooter(textSecondary, primaryBlue),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(Color primaryBlue, Color darkBlue, Color textPrimary, Color textSecondary) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withValues(alpha: 0.2),
                blurRadius: 25,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.lock_reset, size: 38, color: Color(0xFF1976D2)),
        ),
        const SizedBox(height: 18),
        const Text(
          'Password ভুলে গেছেন?',
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
        ),
        const SizedBox(height: 8),
        Text(
          'ইমেইল বা ফোন নম্বর দিয়ে\npassword reset করুন।',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
        ),
      ],
    );
  }

  Widget _buildModeTabs(ForgotPasswordController controller, Color primaryBlue, Color lightBlue) {
    return Obx(() => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
            ],
          ),
          child: Row(
            children: [
              _tabButton(
                label: '📧 ইমেইল',
                isActive: controller.resetMode.value == ResetMode.email,
                onTap: () => controller.switchMode(ResetMode.email),
                primaryBlue: primaryBlue,
                isLeft: true,
              ),
              _tabButton(
                label: '📱 ফোন OTP',
                isActive: controller.resetMode.value == ResetMode.phone,
                onTap: () => controller.switchMode(ResetMode.phone),
                primaryBlue: primaryBlue,
                isLeft: false,
              ),
            ],
          ),
        ));
  }

  Widget _tabButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required Color primaryBlue,
    required bool isLeft,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.horizontal(
              left: isLeft ? const Radius.circular(16) : Radius.zero,
              right: !isLeft ? const Radius.circular(16) : Radius.zero,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey[600],
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  // ── EMAIL SECTION ──────────────────────────
  Widget _buildEmailSection(
    ForgotPasswordController controller,
    Color primaryBlue,
    Color secondaryBlue,
    Color lightBlue,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: primaryBlue.withValues(alpha: 0.07),
              blurRadius: 20,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('আপনার ইমেইল দিন:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15,color: Color(0xFF2D3748))),
          const SizedBox(height: 12),
          _inputBox(
            controller: controller.emailController,
            hint: 'example@email.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            primaryBlue: primaryBlue,
            lightBlue: lightBlue,
          ),
          const SizedBox(height: 12),

          // Cooldown timer
          Obx(() {
            if (controller.isCooldownActive.value && controller.remainingTime.value > 0) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.timer, color: Colors.orange[600], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      controller.remainingTime.value >= 60
                          ? '${controller.remainingTime.value ~/ 60}m ${controller.remainingTime.value % 60}s পর আবার চেষ্টা করুন'
                          : '${controller.remainingTime.value}s পর আবার চেষ্টা করুন',
                      style: TextStyle(
                          color: Colors.orange[800],
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          const SizedBox(height: 16),

          Obx(() => _gradientButton(
                label: 'Reset Link পাঠাও',
                icon: Icons.send,
                isLoading: controller.isLoading.value,
                onTap: controller.resetPassword,
                primaryBlue: primaryBlue,
                secondaryBlue: secondaryBlue,
              )),
        ],
      ),
    );
  }

  // ── PHONE OTP SECTION ──────────────────────
  Widget _buildPhoneSection(
    ForgotPasswordController controller,
    Color primaryBlue,
    Color secondaryBlue,
    Color lightBlue,
    Color textSecondary,
  ) {
    return Obx(() {
      if (controller.isShowPasswordReset.value) {
        return _buildNewPasswordForm(controller, primaryBlue, secondaryBlue, lightBlue);
      }

      if (controller.isOtpSent.value) {
        return _buildOtpForm(controller, primaryBlue, secondaryBlue, lightBlue);
      }

      return _buildPhoneInputForm(controller, primaryBlue, secondaryBlue, lightBlue);
    });
  }

  Widget _buildPhoneInputForm(
    ForgotPasswordController controller,
    Color primaryBlue,
    Color secondaryBlue,
    Color lightBlue,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: primaryBlue.withValues(alpha: 0.07),
              blurRadius: 20,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('আপনার ফোন নম্বর দিন:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF2D3748))),
          const SizedBox(height: 12),

          // Phone input with country code
          Container(
            decoration: BoxDecoration(
              color: lightBlue,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: primaryBlue.withValues(alpha: 0.2), width: 1.5),
            ),
            child: Row(
              children: [
                CountryCodePicker(
                  onChanged: (c) =>
                      controller.selectedCountryCode.value = c.dialCode ?? '+880',
                  initialSelection: 'BD',
                  showCountryOnly: false,
                  showOnlyCountryWhenClosed: false,
                  favorite: const ['+880', 'BD'],
                  textStyle: const TextStyle(fontSize: 14, color: Color(0xFF2D3748)),
                ),
                Expanded(
                  child: TextField(
                    controller: controller.phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(fontSize: 16, color: Color(0xFF2D3748)),
                    decoration: const InputDecoration(
                      hintText: '01XXXXXXXXX',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Obx(() => _gradientButton(
                label: 'OTP পাঠাও',
                icon: Icons.sms_outlined,
                isLoading: controller.isSendingOtp.value,
                onTap: controller.sendOtpToPhone,
                primaryBlue: primaryBlue,
                secondaryBlue: secondaryBlue,
              )),
        ],
      ),
    );
  }

  Widget _buildOtpForm(
    ForgotPasswordController controller,
    Color primaryBlue,
    Color secondaryBlue,
    Color lightBlue,
  ) {
    final defaultPinTheme = PinTheme(
      width: 52,
      height: 56,
      textStyle: const TextStyle(
          fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1976D2)),
      decoration: BoxDecoration(
        color: lightBlue,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryBlue.withValues(alpha: 0.3), width: 1.5),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: primaryBlue.withValues(alpha: 0.07),
              blurRadius: 20,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.sms, size: 40, color: Color(0xFF1976D2)),
          const SizedBox(height: 12),
          const Text(
            'OTP কোড দিন',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
          ),
          const SizedBox(height: 6),
          Obx(() => Text(
                '${controller.selectedCountryCode.value}${controller.phoneController.text} নম্বরে OTP পাঠানো হয়েছে।',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              )),
          const SizedBox(height: 24),

          // OTP Input
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

          const SizedBox(height: 20),

          Obx(() => _gradientButton(
                label: 'OTP Verify করো',
                icon: Icons.check_circle_outline,
                isLoading: controller.isVerifyingOtp.value,
                onTap: controller.verifyOtp,
                primaryBlue: primaryBlue,
                secondaryBlue: secondaryBlue,
              )),

          const SizedBox(height: 12),

          // Resend button
          Obx(() => TextButton.icon(
                onPressed: controller.isOtpCooldown.value
                    ? null
                    : controller.sendOtpToPhone,
                icon: Icon(Icons.refresh,
                    size: 16,
                    color: controller.isOtpCooldown.value
                        ? Colors.grey
                        : primaryBlue),
                label: Text(
                  controller.isOtpCooldown.value
                      ? '${controller.otpCountdown.value}s পর Resend করা যাবে'
                      : 'OTP আসেনি? Resend করুন',
                  style: TextStyle(
                    color: controller.isOtpCooldown.value
                        ? Colors.grey
                        : primaryBlue,
                    fontSize: 13,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildNewPasswordForm(
    ForgotPasswordController controller,
    Color primaryBlue,
    Color secondaryBlue,
    Color lightBlue,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: primaryBlue.withValues(alpha: 0.07),
              blurRadius: 20,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 22),
              SizedBox(width: 8),
              Text(
                'OTP Verified! নতুন Password সেট করুন',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1A237E)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          const Text('নতুন Password:',
              style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2D3748))),
          const SizedBox(height: 8),
          Obx(() => _passwordInput(
                controller: controller.newPasswordController,
                hint: 'কমপক্ষে ৬ অক্ষর',
                isVisible: controller.isNewPasswordVisible.value,
                onToggle: () => controller.isNewPasswordVisible.toggle(),
                primaryBlue: primaryBlue,
                lightBlue: lightBlue,
              )),

          const SizedBox(height: 16),

          const Text('Password নিশ্চিত করুন:',
              style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2D3748))),
          const SizedBox(height: 8),
          _passwordInput(
            controller: controller.confirmPasswordController,
            hint: 'পুনরায় লিখুন',
            isVisible: false,
            onToggle: () {},
            primaryBlue: primaryBlue,
            lightBlue: lightBlue,
          ),

          const SizedBox(height: 20),

          Obx(() => _gradientButton(
                label: 'Password পরিবর্তন করো',
                icon: Icons.lock_open,
                isLoading: controller.isLoading.value,
                onTap: controller.setNewPassword,
                primaryBlue: primaryBlue,
                secondaryBlue: secondaryBlue,
              )),
        ],
      ),
    );
  }

  Widget _buildFooter(Color textSecondary, Color primaryBlue) {
    return Column(
      children: [
        Text('Password মনে পড়েছে?',
            style: TextStyle(color: textSecondary, fontSize: 14)),
        const SizedBox(height: 6),
        TextButton(
          onPressed: () => Get.back(),
          child: Text('লগিন করুন',
              style: TextStyle(
                  color: primaryBlue,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 20),
        Text('© 2025 NeoSaver. All rights reserved.',
            style: TextStyle(
                color: textSecondary.withValues(alpha: 0.6), fontSize: 10)),
      ],
    );
  }

  // ── Reusable Widgets ──────────────────────

  Widget _inputBox({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required TextInputType keyboardType,
    required Color primaryBlue,
    required Color lightBlue,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: lightBlue,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: primaryBlue.withValues(alpha: 0.2), width: 1.5),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 16, color: Color(0xFF2D3748)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 15),
          prefixIcon: Icon(icon, color: primaryBlue, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _passwordInput({
    required TextEditingController controller,
    required String hint,
    required bool isVisible,
    required VoidCallback onToggle,
    required Color primaryBlue,
    required Color lightBlue,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: lightBlue,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: primaryBlue.withValues(alpha: 0.2), width: 1.5),
      ),
      child: TextField(
        controller: controller,
        obscureText: !isVisible,
        style: const TextStyle(fontSize: 16, color: Color(0xFF2D3748)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon:
              const Icon(Icons.lock_outline, color: Color(0xFF1976D2), size: 20),
          suffixIcon: IconButton(
            icon: Icon(
              isVisible ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
              size: 20,
            ),
            onPressed: onToggle,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _gradientButton({
    required String label,
    required IconData icon,
    required bool isLoading,
    required VoidCallback onTap,
    required Color primaryBlue,
    required Color secondaryBlue,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBlue, secondaryBlue],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onTap,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Icon(icon, color: Colors.white, size: 18),
        label: Text(
          label,
          style: const TextStyle(
              color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
