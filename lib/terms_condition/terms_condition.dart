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
                    title: '1. Acceptance of Terms',
                    content: 'By using NeoSaver, you agree to comply with these Terms. If you do not agree to these terms, please do not use this service.'
                  ),

                  _buildSection(
                    title: '2. Services Provided',
                    content: 'NeoSaver connects users with verified ambulances, offering real-time tracking and communication. We provide emergency ambulance booking, live location tracking, and direct communication between users and ambulance providers.'
                  ),

                  _buildSection(
                    title: '3. User Responsibilities',
                    content: 'Users must provide accurate information and avoid fraudulent or harmful activity. You agree to:\n\n• Provide truthful personal and location information\n• Use the service only for legitimate emergency purposes\n• Not misuse the platform for any illegal activities\n• Not interfere with the proper operation of the service'
                  ),

                  _buildSection(
                    title: '4. Data Collection & Usage',
                    content: 'We collect the following information for service delivery and safety:\n\n• Name and contact information\n• Geo-location data\n• Ambulance number and vehicle details\n• Driver license number\n• Vehicle registration number\n\nThis data is used to provide emergency services, ensure safety, and improve our platform.'
                  ),

                  _buildSection(
                    title: '5. Data Security',
                    content: 'We use encrypted storage and secure authentication to protect your data. However, please be aware that internet transmission carries inherent risks, and we cannot guarantee absolute security of data transmitted over the internet.'
                  ),

                  _buildSection(
                    title: '6. Government Collaboration',
                    content: 'Data may be shared with Bangladeshi government authorities when required by law, for public safety purposes, or in response to valid legal requests. We cooperate with law enforcement agencies to ensure public safety.'
                  ),

                  _buildSection(
                    title: '7. Booking & Payment Terms',
                    content: 'Payment for ambulance services can be made through the following methods:\n\n• Cash payment\n• bKash (Pay on bKash)\n\nPayment is handled directly between users and service providers. All transactions should be completed as agreed upon during booking.'
                  ),

                  _buildSection(
                    title: '8. Limitation of Liability',
                    content: 'NeoSaver is a platform connecting users with ambulance service providers. We are not responsible for:\n\n• Delays in ambulance arrival\n• Medical outcomes or treatment quality\n• Third-party issues or disputes\n• Actions of ambulance service providers\n\nUsers should verify provider credentials before accepting services.'
                  ),

                  _buildSection(
                    title: '9. Suspension or Termination',
                    content: 'Accounts may be suspended or terminated for:\n\n• Violation of these terms\n• Fraudulent or harmful activity\n• Providing false information\n• Misuse of the platform\n• Any illegal activities\n\nWe reserve the right to terminate accounts without prior notice in cases of severe violations.'
                  ),

                  _buildSection(
                    title: '10. Changes to Terms',
                    content: 'These Terms may be updated periodically. We will notify users of significant changes. Continued use of NeoSaver after changes means acceptance of the updated terms. We encourage you to review these terms regularly.'
                  ),

                  _buildSection(
                    title: '11. Contact Information',
                    content: 'If you have any questions about these Terms & Conditions, please contact us at:\n\nEmail: neosaver@gmail.com\nPhone: +880 1793-399913\nAddress: Khulna, Bangladesh'
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
