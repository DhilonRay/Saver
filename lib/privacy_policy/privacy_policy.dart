import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'privacy_policy_controller.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  // Enhanced medical-themed color palette
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color secondaryBlue = Color(0xFF42A5F5);
  static const Color accentBlue = Color(0xFF1E88E5);
  static const Color darkBlue = Color(0xFF0D47A1);
  static const Color lightBlue = Color(0xFFE3F2FD);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PrivacyPolicyController>(
      init: PrivacyPolicyController(),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Privacy Policy',
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
                          Icons.privacy_tip,
                          size: 60,
                          color: primaryBlue,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Privacy Policy',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Last updated: November 30, 2025',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Privacy Policy Content
                  _buildSection(
                    title: '1. Information We Collect',
                    content: 'We collect the following information to provide our services:\n\n• User name and contact details\n• Geo-location data\n• Device information\n• Ambulance provider details (vehicle number, driver license, registration)'
                  ),

                  _buildSection(
                    title: '2. How We Use Your Information',
                    content: 'Your information is used for:\n\n• Matching you with nearby ambulances\n• Real-time tracking of ambulance location\n• Identity verification and safety\n• Communication between users and providers\n• App improvement and service optimization'
                  ),

                  _buildSection(
                    title: '3. Location Data',
                    content: 'Location data is collected and used only for:\n\n• Emergency response coordination\n• Real-time ambulance tracking\n• Providing accurate pickup and drop-off locations\n\nYour location is only accessed when you use the app for emergency services.'
                  ),

                  _buildSection(
                    title: '4. Sharing of Information',
                    content: 'Your information may be shared with:\n\n• Ambulance service providers (for service delivery)\n• Government authorities (when required by law)\n• Required service partners (for app functionality)\n\nWe do not sell your personal data to third parties.'
                  ),

                  _buildSection(
                    title: '5. Data Storage & Security',
                    content: 'We protect your data using:\n\n• Encryption for data storage\n• Firebase security measures\n• Secure communication protocols (HTTPS)\n• Regular security audits and updates'
                  ),

                  _buildSection(
                    title: '6. Data Retention',
                    content: 'We retain your data only as long as necessary for:\n\n• Providing our services\n• Legal and regulatory compliance\n• Resolving disputes and enforcing agreements\n\nYou may request deletion of your data at any time.'
                  ),

                  _buildSection(
                    title: '7. Your Rights',
                    content: 'You have the right to:\n\n• Access your personal data\n• Request correction of inaccurate data\n• Request deletion of your data\n• Opt out of promotional communications\n\nContact us to exercise these rights.'
                  ),

                  _buildSection(
                    title: '8. Children\'s Privacy',
                    content: 'NeoSaver is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If you are a parent and believe your child has provided us with personal information, please contact us.'
                  ),

                  _buildSection(
                    title: '9. Third-Party Services',
                    content: 'NeoSaver uses the following third-party services:\n\n• Firebase (Authentication, Database, Storage)\n• Google Maps (Location and Mapping services)\n\nThese services have their own privacy policies governing data usage.'
                  ),

                  _buildSection(
                    title: '10. Changes to Policy',
                    content: 'This Privacy Policy may be updated periodically. We will notify users of significant changes. Continued use of NeoSaver after changes means acceptance of the updated policy. We encourage you to review this policy regularly.'
                  ),

                  _buildSection(
                    title: '11. Contact Us',
                    content: 'If you have any questions about this Privacy Policy, please contact us at:\n\nEmail: neosaver@gmail.com\nPhone: +880 1793-399913\nAddress: Khulna, Bangladesh'
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
                          'By using NeoSaver, you agree to this Privacy Policy.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: primaryBlue,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 15),
                        Text(
                          'We are committed to protecting your privacy and ensuring the security of your personal information.',
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
