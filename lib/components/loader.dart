import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoaderView extends StatelessWidget {
  final bool loading;
  final Widget child;

  const LoaderView({super.key, required this.loading, required this.child});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Loader());
    }
    return child;
  }
}

class LoaderStack extends StatelessWidget {
  final bool loading;
  final Widget child;

  const LoaderStack({super.key, required this.loading, required this.child});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Stack(
        children: [
          child,
          const Opacity(
            opacity: 0.8,
            child: ModalBarrier(dismissible: false, color: Colors.white),
          ),
          const Loader(),
        ],
      );
    }
    return child;
  }
}

class Loader extends StatelessWidget {
  const Loader({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Lottie.asset(
        'assets/icons/loader.json',
        width: 120,
        height: 120,
        fit: BoxFit.contain,
      ),
    );
  }
}
