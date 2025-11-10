import 'package:flutter/material.dart';
import 'splash_page_controller.dart';
import '../loader/loader.dart';


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
    return const Loader();
  }
}
