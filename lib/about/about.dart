import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saver/components/widgets/buttons.dart';
import 'package:saver/components/widgets/others.dart';
import 'package:saver/components/widgets/space.dart';
import 'about_controller.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AboutController>(
      init: AboutController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text(
              'About Us',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontSize: 18,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios,
                  color: Colors.black87, size: 20),
              onPressed: controller.goBack,
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: SidePaddedWidget(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const VerticalGap(16),
                  // Logo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/logons.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const VerticalGap(16),
                  // App Name
                  Text(
                    controller.appName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                  const VerticalGap(4),
                  // Version
                  Text(
                    'Version ${controller.appVersion}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const VerticalGap(24),
                  // Divider
                  const DividerWidget(),
                  const VerticalGap(24),
                  // Our Mission Title
                  const Text(
                    'Our Mission',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const VerticalGap(16),
                  // Mission paragraphs
                  _buildParagraph(
                    'NeoSaver is dedicated to transforming emergency medical response in Bangladesh. We aim to connect individuals in critical situations with the nearest available and verified ambulance services swiftly and efficiently.',
                  ),
                  const VerticalGap(16),
                  _buildParagraph(
                    'Real-time location tracking is at the heart of our service. Users can see the live location of nearby ambulances, providing crucial information and reducing anxiety during emergencies. This feature ensures transparency and allows for better coordination.',
                  ),
                  const VerticalGap(16),
                  _buildParagraph(
                    'We prioritize the safety and reliability of our service. All ambulance providers on the NeoSaver platform undergo a verification process to ensure they meet our standards. This commitment to quality helps users access trusted emergency transport.',
                  ),
                  const VerticalGap(16),
                  _buildParagraph(
                    'Our goal is simple: to save lives by making emergency medical assistance accessible quickly and reliably. In critical moments, every second counts, and NeoSaver is designed to make those seconds work for you.',
                  ),
                  const VerticalGap(24),
                  // Divider
                  const DividerWidget(),
                  const VerticalGap(24),
                  // Contact Us Title
                  const Text(
                    'Contact Us',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const VerticalGap(12),
                  // Contact description
                  Text(
                    'For any inquiries or support, please feel free to contact us at',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    controller.contactEmail,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                  const VerticalGap(24),
                  // Send Email Button
                  IconedFilledButtonWidget(
                    onTap: controller.launchEmail,
                    icon:
                        const Icon(Icons.email, size: 20, color: Colors.white),
                    buttonText: 'Send Email',
                    isStretched: true,
                    minHeight: 50,
                    backgrondColor: const Color(0xFF42A5F5),
                    forgroundColor: Colors.white,
                    borderRadiusValue: 8,
                    buttonTextStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const VerticalGap(24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14,
        height: 1.6,
        color: Colors.grey.shade700,
      ),
    );
  }
}
