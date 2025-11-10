import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'terms_condiotion_controller.dart';

class TermsConditionPage extends StatelessWidget {
  const TermsConditionPage({super.key});

  // Enhanced medical-themed color palette
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color secondaryBlue = Color(0xFF42A5F5);
  static const Color accentBlue = Color(0xFF1E88E5);
  static const Color darkBlue = Color(0xFF0D47A1);
  static const Color lightBlue = Color(0xFFE3F2FD);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TermsConditionController>(
      init: TermsConditionController(),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Terms & Conditions',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,

            backgroundColor: Colors.white,
            elevation: 0,
            foregroundColor: primaryBlue,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: primaryBlue),
              onPressed: () => Get.back(),
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [lightBlue, Colors.white],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.description,
                          size: 60,
                          color: primaryBlue,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Terms & Conditions',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Last updated: November 5, 2025',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Terms & Conditions Content
                  _buildSection(
                    title: 'Acceptance of Terms',
                    content: 'By accessing and using NeoSaver, you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.'
                  ),

                  _buildSection(
                    title: 'Use License',
                    content: 'Permission is granted to temporarily use NeoSaver for personal, non-commercial transitory viewing only. This is the grant of a license, not a transfer of title, and under this license you may not:\n\n• Modify or copy the materials\n• Use the materials for any commercial purpose\n• Attempt to decompile or reverse engineer any software\n• Remove any copyright or other proprietary notations'
                  ),

                  _buildSection(
                    title: 'Service Description',
                    content: 'NeoSaver is an emergency ambulance booking and management platform that connects users with ambulance service providers. We provide real-time ambulance tracking, emergency response coordination, and partner management services.'
                  ),

                  _buildSection(
                    title: 'User Responsibilities',
                    content: 'Users must provide accurate information when requesting emergency services. You agree to use the service only for legitimate emergency purposes and not to misuse the platform for any illegal activities.'
                  ),

                  _buildSection(
                    title: 'Partner Responsibilities',
                    content: 'Ambulance service providers must maintain valid licenses, provide accurate service information, and respond promptly to emergency requests. Partners are responsible for the safety and proper operation of their vehicles and equipment.'
                  ),

                  _buildSection(
                    title: 'Payment Terms',
                    content: 'Payment for ambulance services is handled directly between users and service providers. NeoSaver may charge service fees for platform usage. All payments are processed securely through approved payment methods.'
                  ),

                  _buildSection(
                    title: 'Liability Limitations',
                    content: 'NeoSaver acts as a platform connecting users with service providers. We are not liable for the quality of services provided by ambulance operators. Users should verify provider credentials before accepting services.'
                  ),

                  _buildSection(
                    title: 'Privacy Protection',
                    content: 'Your privacy is important to us. Please review our Privacy Policy, which also governs your use of NeoSaver, to understand our practices.'
                  ),

                  _buildSection(
                    title: 'Contact Information',
                    content: 'If you have any questions about these Terms & Conditions, please contact us at:\n\nEmail: nobita105176@gmail.com\nPhone: +01581822846'
                  ),

                  const SizedBox(height: 30),

                  // Acceptance Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'By using NeoSaver, you agree to these Terms & Conditions.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: primaryBlue,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 15),
                        Text(
                          'These terms are designed to ensure safe and reliable emergency services for all users.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
