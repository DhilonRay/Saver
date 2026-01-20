import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:saver/components/widgets/space.dart';
import 'privacy_policy_controller.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  static const Color primaryBlue = Color(0xFF1976D2);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PrivacyPolicyController>(
      init: PrivacyPolicyController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text(
              'Privacy Policy',
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
                    'Privacy Policy',
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

                  // Privacy Policy Sections
                  _buildSection(
                    title: '1. Information We Collect',
                    description:
                        'We collect the following information to provide our services:',
                    bulletPoints: [
                      'User name and contact details',
                      'Geo-location data',
                      'Device information',
                      'Ambulance provider details (vehicle number, driver license, registration)',
                    ],
                  ),

                  _buildSection(
                    title: '2. How We Use Your Information',
                    description: 'Your information is used for:',
                    bulletPoints: [
                      'Matching you with nearby ambulances',
                      'Real-time tracking of ambulance location',
                      'Identity verification and safety',
                      'Communication between users and providers',
                      'App improvement and service optimization',
                    ],
                  ),

                  _buildSection(
                    title: '3. Location Data',
                    description:
                        'Location data is collected and used only for:',
                    bulletPoints: [
                      'Emergency response coordination',
                      'Real-time ambulance tracking',
                      'Providing accurate pickup and drop-off locations',
                    ],
                    footer:
                        'Your location is only accessed when you use the app for emergency services.',
                  ),

                  _buildSection(
                    title: '4. Sharing of Information',
                    description: 'Your information may be shared with:',
                    bulletPoints: [
                      'Ambulance service providers (for service delivery)',
                      'Government authorities (when required by law)',
                      'Required service partners (for app functionality)',
                    ],
                    footer:
                        'We do not sell your personal data to third parties.',
                  ),

                  _buildSection(
                    title: '5. Data Storage & Security',
                    description: 'We protect your data using:',
                    bulletPoints: [
                      'Encryption for data storage',
                      'Firebase security measures',
                      'Secure communication protocols (HTTPS)',
                      'Regular security audits and updates',
                    ],
                  ),

                  _buildSection(
                    title: '6. Data Retention',
                    description:
                        'We retain your data only as long as necessary for:',
                    bulletPoints: [
                      'Providing our services',
                      'Legal and regulatory compliance',
                      'Resolving disputes and enforcing agreements',
                    ],
                    footer:
                        'You may request deletion of your data at any time.',
                  ),

                  _buildSection(
                    title: '7. Your Rights',
                    description: 'You have the right to:',
                    bulletPoints: [
                      'Access your personal data',
                      'Request correction of inaccurate data',
                      'Request deletion of your data',
                      'Opt out of promotional communications',
                    ],
                    footer: 'Contact us to exercise these rights.',
                  ),

                  _buildSection(
                    title: '8. Children\'s Privacy',
                    content:
                        'NeoSaver is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If you are a parent and believe your child has provided us with personal information, please contact us.',
                  ),

                  _buildSection(
                    title: '9. Third-Party Services',
                    description:
                        'NeoSaver uses the following third-party services:',
                    bulletPoints: [
                      'Firebase (Authentication, Database, Storage)',
                      'Google Maps (Location and Mapping services)',
                    ],
                    footer:
                        'These services have their own privacy policies governing data usage.',
                  ),

                  _buildSection(
                    title: '10. Changes to Policy',
                    content:
                        'This Privacy Policy may be updated periodically. We will notify users of significant changes. Continued use of NeoSaver after changes means acceptance of the updated policy. We encourage you to review this policy regularly.',
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
            '11.Contact Us',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'If you have any questions about this Privacy Policy, please contact us at:',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Email: neosaver@gmail.com',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            'Phone: Khulna, Bangladesh',
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
