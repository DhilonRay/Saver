import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'signup_controller.dart';
import '../../loader/loader.dart';
import '../../terms_condition/terms_condition.dart';
import '../../privacy_policy/privacy_policy.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SignUpController>(
      init: SignUpController(),
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
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: primaryBlue,
                size: 24,
              ),
              onPressed: () => Get.back(),
            ),
          ),
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
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    _buildHeader(primaryBlue, darkBlue, textSecondary),
                    const SizedBox(height: 24),
                    // Role Selection Section
                    _buildRoleSelection(
                      controller,
                      primaryBlue,
                      secondaryBlue,
                      accentBlue,
                      lightBlue,
                      cardBackground,
                      textPrimary,
                      textSecondary,
                    ),
                    const SizedBox(height: 24),
                    _buildSignUpCard(
                      controller,
                      primaryBlue,
                      secondaryBlue,
                      accentBlue,
                      lightBlue,
                      cardBackground,
                      textPrimary,
                      textSecondary,
                    ),
                    const SizedBox(height: 20),
                    _buildFooter(textSecondary, accentBlue, controller),
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
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: primaryBlue.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Text(
            'Join our healthcare community',
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpCard(
    SignUpController controller,
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
                  'Create Your Account',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Join NeoSaver for better healthcare access',
                  style: TextStyle(
                    fontSize: 16,
                    color: textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Name Field
          _buildEnhancedTextField(
            controller: controller.nameController,
            hintText: 'Full Name',
            primaryColor: primaryBlue,
            backgroundColor: lightBlue,
            customPrefix: Container(
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.person_outline,
                color: primaryBlue,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 16),

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

          // Address Field
          _buildEnhancedTextField(
            controller: controller.addressController,
            hintText: 'Address',
            primaryColor: primaryBlue,
            backgroundColor: lightBlue,
           
            customPrefix: Container(
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.home_outlined,
                color: primaryBlue,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 16),

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
            customPrefix: Container(
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.lock_outline,
                color: primaryBlue,
                size: 20,
              ),
            ),
            passwordVisibilityState: controller.isPasswordVisible,
            onVisibilityToggle: controller.togglePasswordVisibility,
          )),
          const SizedBox(height: 16),

          // Confirm Password Field
          Obx(() => _buildEnhancedTextField(
            controller: controller.confirmPasswordController,
            hintText: 'Confirm Password',
            primaryColor: primaryBlue,
            backgroundColor: lightBlue,
            obscureText: !controller.isConfirmPasswordVisible.value,
            isPasswordField: true,
            customPrefix: Container(
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.lock_outline,
                color: primaryBlue,
                size: 20,
              ),
            ),
            passwordVisibilityState: controller.isConfirmPasswordVisible,
            onVisibilityToggle: controller.toggleConfirmPasswordVisibility,
          )),
          const SizedBox(height: 16),

          // Terms and Conditions Checkbox
          Obx(() => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: controller.agreedToTerms.value,
                  onChanged: (value) {
                    controller.agreedToTerms.value = value ?? false;
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  activeColor: primaryBlue,
                  checkColor: Colors.white,
                  side: BorderSide(
                    color: primaryBlue,
                    width: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  children: [
                    Text(
                      'By continuing, you agree to our ',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Get.to(() => const TermsConditionPage());
                      },
                      child: Text(
                        'Terms of Use',
                        style: TextStyle(
                          color: primaryBlue,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    Text(
                      ' and ',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Get.to(() => const PrivacyPolicyPage());
                      },
                      child: Text(
                        'Privacy Policy',
                        style: TextStyle(
                          color: primaryBlue,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )),
          const SizedBox(height: 24),

          // Register Button
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
            child: ElevatedButton.icon(
              onPressed: controller.isLoading.value ? null : controller.registerUser,
              icon: Obx(() => controller.isLoading.value
                  ? HorizontalRotatingDots(size: 20, colors: [Colors.white, Colors.white.withOpacity(0.8), Colors.white.withOpacity(0.6)])
                  : const Icon(
                      Icons.app_registration_outlined,
                      color: Colors.white,
                    )),
              label: Obx(() => Text(
                controller.isLoading.value ? 'Creating Account...' : 'Create Account',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              )),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelection(
    SignUpController controller,
    Color primaryBlue,
    Color secondaryBlue,
    Color accentBlue,
    Color lightBlue,
    Color cardBackground,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: primaryBlue.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Your Role *',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textPrimary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 16),
          Obx(() => Row(
            children: [
              // User Role Option
              Expanded(
                child: GestureDetector(
                  onTap: () => controller.selectedRole.value = 'user',
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      color: controller.selectedRole.value == 'user'
                          ? primaryBlue.withValues(alpha: 0.1)
                          : lightBlue.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: controller.selectedRole.value == 'user'
                            ? primaryBlue
                            : primaryBlue.withValues(alpha: 0.2),
                        width: controller.selectedRole.value == 'user' ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.person_outline,
                          color: controller.selectedRole.value == 'user'
                              ? primaryBlue
                              : textSecondary,
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'User',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: controller.selectedRole.value == 'user'
                                ? primaryBlue
                                : textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Access healthcare services',
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Partner Role Option
              Expanded(
                child: GestureDetector(
                  onTap: () => controller.selectedRole.value = 'driver',
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      color: controller.selectedRole.value == 'driver'
                          ? primaryBlue.withValues(alpha: 0.1)
                          : lightBlue.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: controller.selectedRole.value == 'driver'
                            ? primaryBlue
                            : primaryBlue.withValues(alpha: 0.2),
                        width: controller.selectedRole.value == 'driver' ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.local_shipping,
                          color: controller.selectedRole.value == 'driver'
                              ? primaryBlue
                              : textSecondary,
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ambulance',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: controller.selectedRole.value == 'driver'
                                ? primaryBlue
                                : textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Provide ambulance services',
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          )),
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
    int maxLines = 1,
    bool isPasswordField = false,
    Widget? customPrefix,
    RxBool? passwordVisibilityState,
    VoidCallback? onVisibilityToggle,
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
        maxLines: maxLines,
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
          prefixIcon: customPrefix ?? Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.phone_outlined, // Default icon
              color: primaryColor,
              size: 20,
            ),
          ),
          suffixIcon: isPasswordField
              ? Builder(
                  builder: (context) {
                    final controller = Get.find<SignUpController>();
                    return Obx(() => IconButton(
                      icon: Icon(
                        (passwordVisibilityState ?? controller.isPasswordVisible).value
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: primaryColor,
                      ),
                      onPressed: onVisibilityToggle ?? controller.togglePasswordVisibility,
                    ));
                  },
                )
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

  Widget _buildFooter(Color textSecondary, Color accentBlue, SignUpController controller) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Already have an account? ",
              style: TextStyle(
                color: textSecondary,
                fontSize: 16,
              ),
            ),
            GestureDetector(
              onTap: controller.goToLogin,
              child: Text(
                'Sign In',
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
    );
  }
}