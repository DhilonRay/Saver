import 'package:flutter/material.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart' as lottie hide Marker;

class SuccessDialog extends StatefulWidget {
  final String title;
  final String message;
  final VoidCallback? onTap;

  const SuccessDialog({
    super.key,
    required this.title,
    required this.message,
    this.onTap,
  });

  static bool _isShowing = false;

  static void show({
    required String title,
    required String message,
    VoidCallback? onTap,
    Duration autoCloseDuration = const Duration(seconds: 3),
  }) {
    // Prevent multiple dialogs from showing
    if (_isShowing) return;

    _isShowing = true;

    Future? dialogFuture = Get.dialog(
      SuccessDialog(title: title, message: message, onTap: onTap),
      barrierDismissible: true, // Allow dismissing by tapping outside
      barrierColor: Colors.black.withValues(alpha: 0.3),
    );

    // Auto close after specified duration
    Timer? timer = Timer(autoCloseDuration, () {
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
    });

    // Clean up when dialog closes
    dialogFuture.then((_) {
      _isShowing = false;
      timer?.cancel();
    });
  }

  @override
  State<SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<SuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: GestureDetector(
              onTap: widget.onTap != null
                  ? () {
                      Get.back(); // Close dialog first
                      widget.onTap!(); // Then execute the callback
                    }
                  : null,
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                backgroundColor: Colors.white,
                elevation: 20,
                shadowColor: Colors.green.withValues(alpha: 0.3),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Success animation with glow effect
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: lottie.Lottie.asset(
                        'assets/success.json',
                        width: 130,
                        height: 130,
                        repeat: false, // Play only once
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.message,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF424242),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    // Progress indicator
                    Container(
                      width: 100,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.green.shade400,
                        ),
                        value: 1.0 -
                            (_animationController.duration!.inMilliseconds -
                                    _animationController.value *
                                        _animationController
                                            .duration!.inMilliseconds) /
                                _animationController.duration!.inMilliseconds,
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
