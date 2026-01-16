import 'package:flutter/material.dart';
import 'package:saver/components/constants/images.dart';
import 'splash_page_controller.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final SplashPageController _controller = SplashPageController();

  @override
  void initState() {
    super.initState();
    _controller.navigateAfterSplash();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFAEDFF7), // Light Blue Top
              Color(0xFF3B99D9), // Darker Blue Bottom (approximate from image)
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Circle
            Image.asset(
              AppImages.neo,
              width: 160,
              height: 160,
            ),
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
          ],
        ),
      ),
    );
  }
}
