import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saver/components/constants/images.dart';
import 'package:saver/components/widgets/buttons.dart';
import 'package:saver/components/widgets/space.dart';
import 'get_started_controller.dart';

class GetStartedPage extends StatelessWidget {
  const GetStartedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<GetStartedController>(
      init: GetStartedController(),
      builder: (controller) {
        return Scaffold(
          body: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFAEDFF7), // Light Blue Top
                  Color(0xFF3B99D9), // Darker Blue Bottom
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Top Row (Language Support)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: PopupMenuButton<String>(
                          offset: const Offset(0, 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onSelected: (String value) {
                            controller.changeLanguage(value);
                          },
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<String>>[
                            PopupMenuItem<String>(
                              value: 'English',
                              child: Row(
                                children: [
                                  const Text('English'),
                                  if (controller.currentLanguage == 'English')
                                    const Spacer(),
                                  if (controller.currentLanguage == 'English')
                                    const Icon(Icons.check,
                                        color: Colors.blue, size: 18),
                                ],
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'Bangla',
                              child: Row(
                                children: [
                                  const Text('Bangla'),
                                  if (controller.currentLanguage == 'Bangla')
                                    const Spacer(),
                                  if (controller.currentLanguage == 'Bangla')
                                    const Icon(Icons.check,
                                        color: Colors.blue, size: 18),
                                ],
                              ),
                            ),
                          ],
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  controller.currentLanguage,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                const HorizontalGap(4),
                                const Icon(Icons.language,
                                    color: Colors.white, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const VerticalGap(20),

                    // Logo Circle
                    Center(
                      child: Image.asset(
                        AppImages.neo,
                        width: 160,
                        height: 160,
                      ),
                    ),

                    // App Name
                    Transform.translate(
                      offset: const Offset(0, -30),
                      child: const Text(
                        'NeoSaver',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),

                    const VerticalGap(20),

                    // Ambulance Image
                    Image.asset(
                      'assets/images/ambulance.png',
                      height: 280,
                      fit: BoxFit.contain,
                    ),

                    const VerticalGap(20),

                    // Get Started Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: IconedFilledButtonWidget(
                        onTap: controller.navigateToLogin,
                        buttonText: 'Get Started',
                        icon: const Icon(Icons.arrow_forward_sharp, size: 20),
                        backgrondColor: const Color(0xFFAEDFF7),
                        forgroundColor: Colors.black87,
                        borderRadiusValue: 8,
                        minHeight: 44,
                        isStretched: true,
                        buttonTextStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const VerticalGap(20),

                    // Privacy Policy Text
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        children: [
                          const Text(
                            'By using this app you agree to',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: controller.navigateToPrivacyPolicy,
                                child: const Text(
                                  'Privacy policies',
                                  style: TextStyle(
                                    color: Color(0xFFAEDFF7),
                                    fontSize: 12,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Color(0xFFAEDFF7),
                                  ),
                                ),
                              ),
                              const Text(
                                ' and ',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                              GestureDetector(
                                onTap: controller.navigateToTerms,
                                child: const Text(
                                  'Terms',
                                  style: TextStyle(
                                    color: Color(0xFFAEDFF7),
                                    fontSize: 12,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Color(0xFFAEDFF7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
