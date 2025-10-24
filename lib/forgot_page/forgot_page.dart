import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'forgot_page_controller.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ForgotPasswordController>(
      init: ForgotPasswordController(),
      builder: (controller) {
        // Enhanced medical-themed color palette
        const Color primaryBlue = Color(0xFF1976D2);
        const Color secondaryBlue = Color(0xFF42A5F5);
        const Color accentBlue = Color(0xFF1E88E5);
        const Color darkBlue = Color(0xFF0D47A1);
        const Color lightBlue = Color(0xFFE3F2FD);
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
              
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    // Header Section
                    _buildHeader(primaryBlue, darkBlue, textPrimary, textSecondary),

                    const SizedBox(height: 40),

                    // Forgot Password Card
                    _buildForgotPasswordCard(
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

                    // Footer
                    _buildFooter(textSecondary, accentBlue),
                  ],
                ),
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
        // Logo
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
                Icons.lock_reset,
                size: 35,
                color: primaryBlue,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Title
        Text(
          'Forgot Password?',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: textPrimary,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 12),

        // Subtitle
        Text(
          'No worries! Enter your email address and we\'ll send you a link to reset your password.',
          style: TextStyle(
            fontSize: 16,
            color: textSecondary,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForgotPasswordCard(
    ForgotPasswordController controller,
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
            color: primaryBlue.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.8),
            blurRadius: 15,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border.all(
          color: primaryBlue.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email Field
          Container(
            decoration: BoxDecoration(
              color: lightBlue,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: primaryBlue.withValues(alpha: 0.1),
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: controller.emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF2D3748),
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Enter your email address',
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Container(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.email_outlined,
                    color: primaryBlue,
                    size: 20,
                  ),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Cooldown Timer (only show when active)
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
                        ? 'Next reset available in ${(controller.remainingTime.value ~/ 60)}m ${controller.remainingTime.value % 60}s'
                        : 'Next reset available in ${controller.remainingTime.value}s',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          const SizedBox(height: 16),

          // Reset Password Button
          Container(
            height: 50,
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
              onPressed: controller.isLoading.value ? null : controller.resetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: controller.isLoading.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Send Reset Link',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 20),

        
        ],
      ),
    );
  }

  Widget _buildFooter(Color textSecondary, Color accentBlue) {
    return Column(
      children: [
       
        const SizedBox(height: 20),
        Text(
          'Remember your password?',
          style: TextStyle(
            color: textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Get.back(),
          child: Text(
            'Sign In',
            style: TextStyle(
              color: accentBlue,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 40),
        Text(
          '© 2025 NeoSaver. All rights reserved.',
          style: TextStyle(
            color: textSecondary.withValues(alpha: 0.7),
            fontSize: 10,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
