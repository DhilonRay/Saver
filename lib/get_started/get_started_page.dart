import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saver/components/constants/images.dart';
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
              child: Column(
                children: [
                  // Top Row (Language Support)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: Align(
                      alignment: Alignment.topRight,
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
                            const Text(
                              'English',
                              style: TextStyle(
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

                  const Spacer(),

                  // Ambulance Image
                  Image.asset(
                    'assets/images/ambulance.png',
                    height: 300,
                    fit: BoxFit.contain,
                  ),

                  const Spacer(),

                  // Get Started Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: controller.navigateToLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                              0xFFAEDFF7), // Button color matching top gradient
                          foregroundColor: Colors.black87,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Get Started',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const HorizontalGap(8),
                            const Icon(Icons.arrow_forward_sharp, size: 20),
                          ],
                        ),
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
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Privacy policies',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white,
                              ),
                            ),
                            const Text(
                              ' and ',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                            const Text(
                              'Terms',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white,
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
        );
      },
    );
  }
}
