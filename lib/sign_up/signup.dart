import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'signup_controller.dart';

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
                color: primaryBlue.withOpacity(0.2),
                blurRadius: 25,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.8),
                blurRadius: 15,
                offset: const Offset(0, -5),
              ),
            ],
            border: Border.all(
              color: primaryBlue.withOpacity(0.1),
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
                color: primaryBlue.withOpacity(0.3),
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
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: primaryBlue.withOpacity(0.2),
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
            color: Colors.black.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
          BoxShadow(
            color: primaryBlue.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        border: Border.all(
          color: primaryBlue.withOpacity(0.08),
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
                  color: primaryBlue.withOpacity(0.1),
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
            icon: Icons.person_outline,
            primaryColor: primaryBlue,
            backgroundColor: lightBlue,
          ),
          const SizedBox(height: 16),

          // Phone Field
          _buildEnhancedTextField(
            controller: controller.phoneController,
            hintText: 'Phone Number',
            icon: Icons.phone_outlined,
            primaryColor: primaryBlue,
            backgroundColor: lightBlue,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),

          // Address Field
          _buildEnhancedTextField(
            controller: controller.addressController,
            hintText: 'Address',
            icon: Icons.home_outlined,
            primaryColor: primaryBlue,
            backgroundColor: lightBlue,
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          // Email Field
          _buildEnhancedTextField(
            controller: controller.emailController,
            hintText: 'Email Address',
            icon: Icons.email_outlined,
            primaryColor: primaryBlue,
            backgroundColor: lightBlue,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),

          // Password Field
          Obx(() => _buildEnhancedTextField(
            controller: controller.passwordController,
            hintText: 'Password',
            icon: Icons.lock_outline,
            primaryColor: primaryBlue,
            backgroundColor: lightBlue,
            obscureText: !controller.isPasswordVisible.value,
            isPasswordField: true,
            onVisibilityToggle: controller.togglePasswordVisibility,
            isPasswordVisible: controller.isPasswordVisible.value,
          )),
          const SizedBox(height: 16),

          // Confirm Password Field
          Obx(() => _buildEnhancedTextField(
            controller: controller.confirmPasswordController,
            hintText: 'Confirm Password',
            icon: Icons.lock_outline,
            primaryColor: primaryBlue,
            backgroundColor: lightBlue,
            obscureText: !controller.isConfirmPasswordVisible.value,
            isPasswordField: true,
            onVisibilityToggle: controller.toggleConfirmPasswordVisibility,
            isPasswordVisible: controller.isConfirmPasswordVisible.value,
          )),
          const SizedBox(height: 20),

          // Role Selection
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: lightBlue,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: primaryBlue.withOpacity(0.1),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Text(
                  "Register as:",
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Obx(() => DropdownButton<String>(
                    value: controller.selectedRole.value,
                    isExpanded: true,
                    underline: Container(),
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: primaryBlue,
                    ),
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'user',
                        child: Text('Patient/User'),
                      ),
                      DropdownMenuItem(
                        value: 'driver',
                        child: Text('Ambulance Partner'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        controller.updateSelectedRole(value);
                      }
                    },
                  )),
                ),
              ],
            ),
          ),
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
                  color: primaryBlue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: controller.isLoading.value ? null : controller.registerUser,
              icon: Obx(() => controller.isLoading.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
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

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required Color primaryColor,
    required Color backgroundColor,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool isPasswordField = false,
    VoidCallback? onVisibilityToggle,
    bool? isPasswordVisible,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.05),
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
          prefixIcon: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              color: primaryColor,
              size: 20,
            ),
          ),
          suffixIcon: isPasswordField
              ? IconButton(
                  icon: Icon(
                    isPasswordVisible ?? false
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: primaryColor,
                  ),
                  onPressed: onVisibilityToggle,
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
              color: primaryColor.withOpacity(0.1),
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
                  decorationColor: accentBlue.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          '© 2025 NeoSaver. All rights reserved.',
          style: TextStyle(
            color: textSecondary.withOpacity(0.7),
            fontSize: 10,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Your health data is protected with enterprise-grade security',
          style: TextStyle(
            color: textSecondary.withOpacity(0.5),
            fontSize: 9,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}