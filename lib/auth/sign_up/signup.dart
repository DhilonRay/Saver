import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import 'signup_controller.dart';
import '../../terms_condition/terms_condition.dart';
import '../../privacy_policy/privacy_policy.dart';
import '../../components/constants/images.dart';
import '../../components/widgets/form_input.dart';
import '../../components/widgets/buttons.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Define Theme Colors
    const Color primaryBlue = Color(0xFF007BFF); // Medical Blue
    const Color secondaryBlue = Color(0xFF00BFA6); // Teal/Green Accents
    const Color accentBlue = Color(0xFF0056B3); // Darker Blue for depth
    const Color lightBlue = Color(0xFFE3F2FD); // Background light blue
    const Color cardBackground = Colors.white;
    const Color textPrimary = Color(0xFF2D3748);
    const Color textSecondary = Color(0xFF718096);

    return GetBuilder<SignUpController>(
      init: SignUpController(),
      builder: (controller) {
        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  lightBlue,
                  Colors.white,
                  lightBlue.withValues(alpha: 0.5),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  _buildHeader(primaryBlue, accentBlue, textSecondary),
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
                  // Profile Picture Section
                  _buildProfilePicturePicker(controller, primaryBlue),
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
                  const SizedBox(height: 12),
                  _buildFooter(textSecondary, accentBlue, controller),
                ],
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
        Center(
          child: Image.asset(
            AppImages.neo,
            width: 120,
            height: 120,
          ),
        ),
        const SizedBox(height: 16),
        /*  const SizedBox(height: 16),
        Text(
          'Join our healthcare community',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ), */
        Transform.translate(
          offset: const Offset(0, -30),
          child: const Text(
            'Join our healthcare community',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
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
    return Column(
      children: [
        Text(
          'Create Your Account',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Join NeoSaver for better healthcare\naccess',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        /* 
        // Full Name Field
        TextFormFieldWidget(
          controller: controller.nameController,
          hintText: 'Full Name',
          isFilled: true,
          fillColor: const Color(0xFFE3F2FD),
          prefixIcon: const Icon(Icons.person_outline, color: Colors.black54),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
        const SizedBox(height: 16),
        */

        // First Name and Last Name Row
        Row(
          children: [
            Expanded(
              child: TextFormFieldWidget(
                controller: controller.firstNameController,
                hintText: 'First Name',
                isFilled: true,
                fillColor: const Color(0xFFE3F2FD),
                prefixIcon:
                    const Icon(Icons.badge_outlined, color: Colors.black54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormFieldWidget(
                controller: controller.lastNameController,
                hintText: 'LastName',
                isFilled: true,
                fillColor: const Color(0xFFE3F2FD),
                prefixIcon:
                    const Icon(Icons.badge_outlined, color: Colors.black54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        
        // Company Name Field (Only for Drivers)
        Obx(() => controller.selectedRole.value == 'driver'
            ? Column(
                children: [
                  const SizedBox(height: 16),
                  TextFormFieldWidget(
                    controller: controller.companyNameController,
                    hintText: 'Company / Ambulance Service Name',
                    isFilled: true,
                    fillColor: const Color(0xFFE3F2FD),
                    prefixIcon: const Icon(Icons.business_outlined,
                        color: Colors.black54),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ],
              )
            : const SizedBox.shrink()),

        const SizedBox(height: 16),

        // Phone Number Field (Matched Login Style)
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
        const SizedBox(height: 16),

        // Email Address (Matched Login Style)
        TextFormFieldWidget(
          controller: controller.emailController,
          hintText: 'Email Address',
          textInputType: TextInputType.emailAddress,
          isFilled: true,
          fillColor: const Color(0xFFE3F2FD),
          prefixIcon: const Icon(Icons.email_outlined, color: Colors.black54),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
        const SizedBox(height: 16),

        // Address and Post Code Row
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormFieldWidget(
                controller: controller.addressController,
                hintText: 'Address',
                isFilled: true,
                fillColor: const Color(0xFFE3F2FD),
                prefixIcon:
                    const Icon(Icons.home_outlined, color: Colors.black54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: TextFormFieldWidget(
                controller: controller.postCodeController,
                hintText: 'Post Code',
                isFilled: true,
                fillColor: const Color(0xFFE3F2FD),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Password (Matched Login Style)
        Obx(() => TextFormFieldWidget(
              controller: controller.passwordController,
              hintText: 'Password',
              isFilled: true,
              fillColor: const Color(0xFFE3F2FD),
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.black54),
              isPasswordTextField: !controller.isPasswordVisible.value,
              suffixIcon: IconButton(
                icon: Icon(
                  controller.isPasswordVisible.value
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: Colors.black54,
                ),
                onPressed: controller.togglePasswordVisibility,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            )),

        const SizedBox(height: 16),

        // Confirm Password
        Obx(() => TextFormFieldWidget(
              controller: controller.confirmPasswordController,
              hintText: 'Confirm Password',
              isFilled: true,
              fillColor: const Color(0xFFE3F2FD),
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.black54),
              isPasswordTextField: !controller.isConfirmPasswordVisible.value,
              suffixIcon: IconButton(
                icon: Icon(
                  controller.isConfirmPasswordVisible.value
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: Colors.black54,
                ),
                onPressed: controller.toggleConfirmPasswordVisibility,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            )),
        const SizedBox(height: 24),

        // Driver Documents Section
        Obx(() => controller.selectedRole.value == 'driver'
            ? _buildDriverDocumentsSection(controller, primaryBlue)
            : const SizedBox.shrink()),

        const SizedBox(height: 24),

        // Terms and Conditions
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

        // Create Account Button
        Obx(
          () => FilledButtonWidget(
            onTap:
                controller.agreedToTerms.value ? controller.registerUser : null,
            isLoading: controller.isLoading.value,
            buttonText: 'Create Account',
            minHeight: 44,
            borderRadiusValue: 8,
            isStretched: true,
            backgroundColor: const Color(0xFF5CAFE9),
            buttonTextStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
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
    return Column(
      children: [
        Text(
          'Choose Your Role *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
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
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: controller.selectedRole.value == 'user'
                              ? primaryBlue
                              : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            AppImages.userRole, // Use userRole image
                            height: 60,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'User',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: controller.selectedRole.value == 'user'
                                  ? primaryBlue
                                  : primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Access healthcare\nservices',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Partner Role Option
                Expanded(
                  child: GestureDetector(
                    onTap: () => controller.selectedRole.value = 'driver',
                    child: Container(
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: controller.selectedRole.value == 'driver'
                              ? primaryBlue
                              : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            AppImages.ambulanceRole, // Use ambulanceRole image
                            height: 60,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ambulance',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: controller.selectedRole.value == 'driver'
                                  ? primaryBlue
                                  : primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Provide ambulance\nsevices',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )),
      ],
    );
  }

  Widget _buildFooter(
      Color textSecondary, Color accentBlue, SignUpController controller) {
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

  Widget _buildProfilePicturePicker(
      SignUpController controller, Color primaryBlue) {
    return Obx(() => Center(
          child: Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryBlue, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: controller.profileImage.value != null
                      ? Image.file(
                          File(controller.profileImage.value!.path),
                          fit: BoxFit.cover,
                        )
                      : Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.grey.shade400,
                        ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: controller.pickProfileImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryBlue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildDriverDocumentsSection(
      SignUpController controller, Color primaryBlue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Verification Documents *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        // First Row: License & NID
        Row(
          children: [
            Expanded(
              child: Obx(() => _buildUploadCard(
                    title: 'Driving License',
                    icon: Icons.assignment_ind_outlined,
                    image: controller.licenseImage.value,
                    onTap: controller.pickLicenseImage,
                    primaryColor: primaryBlue,
                  )),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Obx(() => _buildUploadCard(
                    title: 'NID Card Photo',
                    icon: Icons.badge_outlined,
                    image: controller.nidImage.value,
                    onTap: controller.pickNidImage,
                    primaryColor: primaryBlue,
                  )),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Second Row: Registration & Ambulance Photo
        Row(
          children: [
            Expanded(
              child: Obx(() => _buildUploadCard(
                    title: 'Ambulance Reg.',
                    icon: Icons.description_outlined,
                    image: controller.registrationPapersImage.value,
                    onTap: controller.pickRegistrationPapersImage,
                    primaryColor: primaryBlue,
                  )),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Obx(() => _buildUploadCard(
                    title: 'Ambulance Photo',
                    icon: Icons.emergency_outlined,
                    image: controller.ambulanceImage.value,
                    onTap: controller.pickAmbulanceImage,
                    primaryColor: primaryBlue,
                  )),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUploadCard({
    required String title,
    required IconData icon,
    required XFile? image,
    required VoidCallback onTap,
    required Color primaryColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F7FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: image != null ? primaryColor : Colors.blue.shade100,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (image != null)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(image.path),
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
              )
            else ...[
              Icon(icon, color: primaryColor, size: 32),
              const SizedBox(height: 8),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text(
                image != null ? 'Change Photo' : title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: image != null ? primaryColor : Colors.blue.shade800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
