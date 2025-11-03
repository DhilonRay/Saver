import 'package:flutter/material.dart';
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
      backgroundColor: Colors.white, // Or theme color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logons.png',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 20),
            const Text(
              'NeoSaver',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue, // Or app theme color
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () async {
      //     // Test FCM V1 notification
      //     await NotificationService.testFCMV1Notification();
      //   },
      //   child: const Icon(Icons.notifications),
      //   tooltip: 'Test FCM V1',
      // ),
    );
  }
}
