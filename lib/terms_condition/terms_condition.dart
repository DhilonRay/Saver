import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saver/components/widgets/space.dart';
import 'terms_condiotion_controller.dart';

class TermsConditionPage extends StatelessWidget {
  const TermsConditionPage({super.key});

  static const Color primaryBlue = Color(0xFF1976D2);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TermsConditionController>(
      init: TermsConditionController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text(
              'Terms & Conditions',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios,
                  color: Colors.black87, size: 20),
              onPressed: () => Get.back(),
            ),
          ),
          body: SingleChildScrollView(
            child: SidePaddedWidget(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const VerticalGap(16),
                  // Header Icon
                  Image.asset(
                    'assets/images/privacy.png',
                    width: 80,
                    height: 80,
                  ),
                  const VerticalGap(16),
                  // Title
                  const Text(
                    'Terms & Conditions',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                  const VerticalGap(4),
                  // Last Update
                  Text(
                    'Last update: January 10, 2026',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const VerticalGap(24),

                  // Terms & Conditions Sections
                  _buildSection(
                    title: '1. Acceptance of Terms',
                    content:
                        'By using NeoSaver, you agree to comply with these Terms. If you do not agree to these terms, please do not use this service.',
                  ),

                  _buildSection(
                    title: '2. Services Provided',
                    content:
                        'NeoSaver connects users with verified ambulances, offering real-time tracking and communication. We provide emergency ambulance booking, live location tracking, and direct communication between users and ambulance providers.',
                  ),

                  _buildSection(
                    title: '3.User Responsibilities',
                    description:
                        'Users must provide accurate information and avoid fraudulent or harmful activity.',
                    secondDescription: 'You agree to:',
                    bulletPoints: [
                      'Provide truthful personal and location information',
                      'Use the service only for legitimate emergency purposes',
                      'Not misuse the platform for any illegal activities',
                      'Not interfere with the proper operation of the service',
                    ],
                  ),

                  _buildSection(
                    title: '4. Data Collection & Usage',
                    description:
                        'We collect the following information for service delivery and safety:',
                    bulletPoints: [
                      'Name and contact information',
                      'Geo-location data',
                      'Ambulance number and vehicle details',
                      'Driver license number',
                      'Vehicle registration number',
                    ],
                    footer:
                        'This data is used to provide emergency services, ensure safety, and improve our platform.',
                  ),

                  _buildSection(
                    title: '5. Data Security',
                    content:
                        'We use encrypted storage and secure authentication to protect your data. However, please be aware that internet transmission carries inherent risks, and we cannot guarantee absolute security of data transmitted over the internet.',
                  ),

                  _buildSection(
                    title: '6. Government Collaboration',
                    content:
                        'Data may be shared with Bangladeshi government authorities when required by law, for public safety purposes, or in response to valid legal requests. We cooperate with law enforcement agencies.',
                  ),

                  _buildSection(
                    title: '7. Booking & Payment Terms',
                    description:
                        'Payment for ambulance services can be made through the following methods:',
                    bulletPoints: [
                      'Cash payment',
                      'bKash (Pay on bKash)',
                    ],
                    footer:
                        'Payment is handled directly between users and service providers. All transactions should be completed as agreed upon during booking.',
                  ),

                  _buildSection(
                    title: '8. Limitation of Liability',
                    description:
                        'NeoSaver is a platform connecting users with ambulance service providers. We are not responsible for:',
                    bulletPoints: [
                      'Delays in ambulance arrival',
                      'Medical outcomes or treatment quality',
                      'Third-party issues or disputes',
                      'Actions of ambulance service providers',
                    ],
                    footer:
                        'Users should verify provider credentials before accepting services.',
                  ),

                  _buildSection(
                    title: '9. Suspension or Termination',
                    description: 'Accounts may be suspended or terminated for:',
                    bulletPoints: [
                      'Violation of these terms',
                      'Fraudulent or harmful activity',
                      'Providing false information',
                      'Misuse of the platform',
                      'Any illegal activities',
                    ],
                    footer:
                        'We reserve the right to terminate accounts without prior notice in cases of severe violations.',
                  ),

                  _buildSection(
                    title: '10. Changes to Terms',
                    content:
                        'These Terms may be updated periodically. We will notify users of significant changes. Continued use of NeoSaver after changes means acceptance of the updated terms. We encourage you to review these terms regularly.',
                  ),

                  _buildContactSection(),

                  const VerticalGap(20),

                  // Acceptance Section
                  _buildAcceptanceSection(),

                  const VerticalGap(24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection({
    required String title,
    String? description,
    String? secondDescription,
    List<String>? bulletPoints,
    String? content,
    String? footer,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 8),
          if (description != null)
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          if (secondDescription != null) ...[
            const SizedBox(height: 8),
            Text(
              secondDescription,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ],
          if (content != null)
            Text(
              content,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          if (bulletPoints != null) ...[
            const SizedBox(height: 8),
            ...bulletPoints.map((point) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    point,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                )),
          ],
          if (footer != null) ...[
            const SizedBox(height: 8),
            Text(
              footer,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '11. Contact Us',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'If you have any questions about these Terms & Conditions, please contact us at:',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Email: contact.neosaver@gmail.com',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            'Location: Khulna, Bangladesh',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptanceSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'By using NeoSaver, you agree to this Privacy Policy.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: primaryBlue,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'We are committed to protecting your privacy and ensuring the security of your personal information.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
