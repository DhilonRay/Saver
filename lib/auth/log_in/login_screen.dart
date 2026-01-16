import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:saver/auth/log_in/login_screen_controller.dart';
import 'package:saver/auth/forgot_page/forgot_page.dart';
import 'package:saver/components/constants/colors.dart';
import 'package:saver/components/constants/images.dart';
import 'package:saver/components/widgets/form_input.dart';
import 'package:saver/components/widgets/buttons.dart';
import 'package:saver/components/widgets/space.dart';
import 'package:saver/components/text_styles.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LoginController>(
      init: LoginController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const VerticalGap(22),
                  _buildLoginTypeSelection(controller),
                  const VerticalGap(20),
                  Obx(() => controller.selectedTabIndex.value == 0
                      ? _buildEmailLoginForm(controller)
                      : _buildPhoneLoginForm(controller)),
                  const VerticalGap(16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => Get.to(() => const ForgotPasswordPage()),
                      child: Text(
                        'Forgot Password?',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const VerticalGap(24),
                  Obx(() => FilledButtonWidget(
                        onTap: controller.isLoading.value
                            ? null
                            : controller.signIn,
                        buttonText: 'Sign In',
                        isLoading: controller.isLoading.value,
                        backgroundColor: AppColors.lightBlue,
                        minHeight: 44,
                        borderRadiusValue: 8,
                      )),
                  const VerticalGap(32),
                  _buildSocialLoginDivider(),
                  const VerticalGap(20),
                  _buildGoogleLoginButton(),
                  const VerticalGap(32),
                  _buildSignUpLink(controller),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Center(
          child: Image.asset(
            AppImages.neo,
            width: 160,
            height: 160,
          ),
        ),

        Text(
          'NeoSaver',
          style: AppTextStyles.authMediumTitle.copyWith(
            fontSize: 28,
            color: AppColors.lightBlue,
          ),
        ),
        const VerticalGap(12),
        Text(
          'Welcome Back',
          style: AppTextStyles.authTitle.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginTypeSelection(LoginController controller) {
    return Obx(() => Row(
          children: [
            Expanded(
              child: controller.selectedTabIndex.value == 0
                  ? FilledButtonWidget(
                      onTap: () => controller.changeTab(0),
                      buttonText: 'Email Login',
                      backgroundColor: AppColors.lightBlue,
                      minHeight: 44,
                      borderRadiusValue: 8,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.email,
                              color: Colors.white, size: 18),
                          const HorizontalGap(8),
                          Text('Email Login',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )
                  : OutlinedButtonWidget(
                      onTap: () => controller.changeTab(0),
                      buttonText: 'Email Login',
                      minHeight: 44,
                      borderRadiusValue: 8,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.email,
                              color: AppColors.primaryText, size: 18),
                          const HorizontalGap(8),
                          Text('Email Login',
                              style: const TextStyle(
                                  color: AppColors.primaryText,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
            ),
            const HorizontalGap(16),
            Expanded(
              child: controller.selectedTabIndex.value == 1
                  ? FilledButtonWidget(
                      onTap: () => controller.changeTab(1),
                      buttonText: 'Phone Login',
                      backgroundColor: AppColors.lightBlue,
                      minHeight: 44,
                      borderRadiusValue: 8,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.phone,
                              color: Colors.white, size: 18),
                          const HorizontalGap(8),
                          Text('Phone Login',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )
                  : OutlinedButtonWidget(
                      onTap: () => controller.changeTab(1),
                      buttonText: 'Phone Login',
                      minHeight: 44,
                      borderRadiusValue: 8,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.phone,
                              color: AppColors.primaryText, size: 18),
                          const HorizontalGap(8),
                          Text('Phone Login',
                              style: const TextStyle(
                                  color: AppColors.primaryText,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
            ),
          ],
        ));
  }

  Widget _buildEmailLoginForm(LoginController controller) {
    return Column(
      children: [
        TextFormFieldWidget(
          controller: controller.emailController,
          hintText: 'Email Address',
          prefixIcon: const Icon(Icons.email_outlined, color: Colors.black54),
          textInputType: TextInputType.emailAddress,
          isFilled: true,
          fillColor: const Color(0xFFE3F2FD),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
        const VerticalGap(16),
        Obx(() => TextFormFieldWidget(
              controller: controller.passwordController,
              hintText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.black54),
              isPasswordTextField: !controller.isPasswordVisible.value,
              isFilled: true,
              fillColor: const Color(0xFFE3F2FD),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  controller.isPasswordVisible.value
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: Colors.black54,
                ),
                onPressed: controller.togglePasswordVisibility,
              ),
            )),
      ],
    );
  }

  Widget _buildPhoneLoginForm(LoginController controller) {
    return Column(
      children: [
        PhoneNumberTextFormFieldWidget(
          controller: controller.phoneController,
          hintText: '01XXXXXXXXX',
          isFilled: true,
          fillColor: const Color(0xFFE3F2FD),
          prefixIcon: const Icon(Icons.phone_outlined, color: Colors.black54),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
        const VerticalGap(16),
        Obx(() => TextFormFieldWidget(
              controller: controller.phonePasswordController,
              hintText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.black54),
              isPasswordTextField: !controller.isPhonePasswordVisible.value,
              isFilled: true,
              fillColor: const Color(0xFFE3F2FD),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  controller.isPhonePasswordVisible.value
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: Colors.black54,
                ),
                onPressed: controller.togglePhonePasswordVisibility,
              ),
            )),
      ],
    );
  }

  Widget _buildSocialLoginDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: Colors.grey)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Login Gmail',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Colors.grey)),
      ],
    );
  }

  Widget _buildGoogleLoginButton() {
    return Center(
      child: RawButtonWidget(
        backgroundColor: Colors.white,
        onTap: () {
          Get.snackbar('Coming Soon', 'Google Login not implemented yet');
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: SvgPicture.asset(
            AppImages.googleLogoSvg,
            width: 30,
            height: 30,
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpLink(LoginController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Don't have an account? ",
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: controller.goToSignUp,
          child: Text(
            'Create Account',
            style: TextStyle(
              color: AppColors.lightBlue,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
