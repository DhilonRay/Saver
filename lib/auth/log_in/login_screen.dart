import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'login_screen_controller.dart';
import '../forgot_page/forgot_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LoginController>(
      init: LoginController(),
      builder: (controller) {
        // Enhanced medical-themed color palette
        const Color primaryBlue = Color(0xFF1976D2);
        const Color secondaryBlue = Color(0xFF42A5F5);
        const Color accentBlue = Color(0xFF1E88E5);
        const Color darkBlue = Color(0xFF0D47A1);
        const Color lightBlue = Color(0xFFE3F2FD);
        const Color backgroundStart = Color(0xFFE8F5E8);
        const Color backgroundEnd = Color(0xFFF3E5F5);
        const Color cardBackground = Color(0xFFFFFFFF);
        const Color textPrimary = Color(0xFF2D3748);
        const Color textSecondary = Color(0xFF718096);

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [backgroundStart, backgroundEnd],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    _buildHeader(primaryBlue, darkBlue, textSecondary),
                    const SizedBox(height: 24),
                    _buildLoginCard(
                      controller,
                      primaryBlue,
                      secondaryBlue,
                      accentBlue,
                      lightBlue,
                      cardBackground,
                      textPrimary,
                      textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(Color primaryBlue, Color darkBlue, Color textSecondary) {
    return Column(
      children: [
        // Enhanced logo with medical cross
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
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.8),
                blurRadius: 15,
                offset: const Offset(0, -5),
              ),
            ],
            border: Border.all(
              color: primaryBlue.withValues(alpha: 0.1),
              width: 2,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.local_hospital,
                size: 35,
                color: primaryBlue,
              ),
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'NeoSaver',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: darkBlue,
            letterSpacing: 1.5,
            shadows: [
              Shadow(
                color: primaryBlue.withValues(alpha: 0.3),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard(
    LoginController controller,
    Color primaryBlue,
    Color secondaryBlue,
    Color accentBlue,
    Color lightBlue,
    Color cardBackground,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
          BoxShadow(
            color: primaryBlue.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        border: Border.all(
          color: primaryBlue.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Welcome section with divider
          Container(
            padding: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: primaryBlue.withValues(alpha: 0.1),
                  width: 2,
                ),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Login Method Tabs
          Container(
            decoration: BoxDecoration(
              color: lightBlue.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Obx(() => Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => controller.changeTab(0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: controller.selectedTabIndex.value == 0
                                ? primaryBlue
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.email,
                                size: 18,
                                color: controller.selectedTabIndex.value == 0
                                    ? Colors.white
                                    : primaryBlue,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Email Login',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: controller.selectedTabIndex.value == 0
                                      ? Colors.white
                                      : primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => controller.changeTab(1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: controller.selectedTabIndex.value == 1
                                ? primaryBlue
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.phone,
                                size: 18,
                                color: controller.selectedTabIndex.value == 1
                                    ? Colors.white
                                    : primaryBlue,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Phone Login',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: controller.selectedTabIndex.value == 1
                                      ? Colors.white
                                      : primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                )),
          ),
          const SizedBox(height: 20),

          // Tab Content
          Obx(() => controller.selectedTabIndex.value == 0
              ? _buildEmailLoginForm(
                  controller,
                  primaryBlue,
                  lightBlue,
                  accentBlue,
                )
              : _buildPhoneLoginForm(
                  controller,
                  primaryBlue,
                  lightBlue,
                  accentBlue,
                )),
          const SizedBox(height: 20),

          // Sign In Button
          Container(
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryBlue, secondaryBlue],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: controller.isLoading.value ? null : controller.signIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Obx(() => controller.isLoading.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      controller.selectedTabIndex.value == 0
                          ? 'Sign In with Email'
                          : 'Sign In with Phone',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    )),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        primaryBlue.withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'or',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        primaryBlue.withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Sign Up Link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 16,
                ),
              ),
              GestureDetector(
                onTap: controller.goToSignUp,
                child: Text(
                  'Create Account',
                  style: TextStyle(
                    color: accentBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationColor: accentBlue.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String hintText,
    required Color primaryColor,
    required Color backgroundColor,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    bool isPasswordField = false,
    bool isEmailPasswordField =
        false, // New parameter to distinguish field types
    bool isPhonePasswordField =
        false, // New parameter to distinguish field types
    LoginController? loginController,
    Widget? customPrefix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF2D3748),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: customPrefix ??
              Container(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.phone_outlined, // Default icon for phone
                  color: primaryColor,
                  size: 20,
                ),
              ),
          suffixIcon: isPasswordField && loginController != null
              ? Obx(() => IconButton(
                    icon: Icon(
                      isEmailPasswordField
                          ? (loginController.isPasswordVisible.value
                              ? Icons.visibility_off
                              : Icons.visibility)
                          : isPhonePasswordField
                              ? (loginController.isPhonePasswordVisible.value
                                  ? Icons.visibility_off
                                  : Icons.visibility)
                              : Icons.visibility, // fallback
                      color: primaryColor,
                    ),
                    onPressed: isEmailPasswordField
                        ? loginController.togglePasswordVisibility
                        : isPhonePasswordField
                            ? loginController.togglePhonePasswordVisibility
                            : null,
                  ))
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: primaryColor,
              width: 2,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: primaryColor.withValues(alpha: 0.1),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailLoginForm(
    LoginController controller,
    Color primaryBlue,
    Color lightBlue,
    Color accentBlue,
  ) {
    return Column(
      children: [
        // Email Field
        _buildEnhancedTextField(
          controller: controller.emailController,
          hintText: 'Email Address',
          primaryColor: primaryBlue,
          backgroundColor: lightBlue,
          keyboardType: TextInputType.emailAddress,
          customPrefix: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.email_outlined,
              color: primaryBlue,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Password Field
        Obx(() => _buildEnhancedTextField(
              controller: controller.passwordController,
              hintText: 'Password',
              primaryColor: primaryBlue,
              backgroundColor: lightBlue,
              obscureText: !controller.isPasswordVisible.value,
              isPasswordField: true,
              isEmailPasswordField: true, // This is the email password field
              loginController: controller,
              customPrefix: Container(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.lock_outline,
                  color: primaryBlue,
                  size: 20,
                ),
              ),
            )),
        const SizedBox(height: 12),

        // Forgot Password
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              Get.to(() => const ForgotPasswordPage());
            },
            style: TextButton.styleFrom(
              foregroundColor: accentBlue,
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            child: const Text('Forgot Password?'),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneLoginForm(
    LoginController controller,
    Color primaryBlue,
    Color lightBlue,
    Color accentBlue,
  ) {
    return Column(
      children: [
        // Phone Field
        _buildEnhancedTextField(
          controller: controller.phoneController,
          hintText: 'Phone Number',
          primaryColor: primaryBlue,
          backgroundColor: lightBlue,
          keyboardType: TextInputType.phone,
          customPrefix: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CountryCodePicker(
                  onChanged: (countryCode) {
                    controller.onCountryCodeChanged(countryCode.dialCode);
                  },
                  initialSelection: 'BD',
                  favorite: const ['+880', '+1', '+44', '+86'],
                  showCountryOnly: false,
                  showOnlyCountryWhenClosed: false,
                  alignLeft: false,
                  textStyle: TextStyle(
                    color: primaryBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  dialogTextStyle: TextStyle(
                    color: primaryBlue,
                    fontSize: 14,
                  ),
                  searchStyle: TextStyle(
                    color: primaryBlue,
                    fontSize: 14,
                  ),
                ),
                Container(
                  height: 20,
                  width: 1,
                  color: primaryBlue.withValues(alpha: 0.3),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Password Field
        Obx(() => _buildEnhancedTextField(
              controller: controller.phonePasswordController,
              hintText: 'Password',
              primaryColor: primaryBlue,
              backgroundColor: lightBlue,
              obscureText: !controller.isPhonePasswordVisible.value,
              isPasswordField: true,
              isPhonePasswordField: true, // This is the phone password field
              loginController: controller,
              customPrefix: Container(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.lock_outline,
                  color: primaryBlue,
                  size: 20,
                ),
              ),
            )),
        const SizedBox(height: 12),

        // Forgot Password
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              Get.to(() => const ForgotPasswordPage());
            },
            style: TextButton.styleFrom(
              foregroundColor: accentBlue,
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            child: const Text('Forgot Password?'),
          ),
        ),
      ],
    );
  }
}
