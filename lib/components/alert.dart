import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:saver/components/constants/colors.dart';
import 'package:saver/components/ui_components.dart';

class Alert {
  static Future<void> success(String msg) async {
    Get.dialog(
      Center(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              Expanded(child: Container()),
              Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: Lottie.asset(
                        'assets/success.json',
                        repeat: false,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      msg,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: Container()),
            ],
          ),
        ),
      ),
    );

    // Automatically close the dialog after 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  static void confirm(String msg, ValueGetter onConfirm) {
    Get.dialog(
      Center(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              Expanded(child: Container()),
              Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.primaryText,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.question_mark_outlined,
                        color: AppColors.primaryText,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Are you sure?'.tr,
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      msg,
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Get.back();
                          },
                          child: Container(
                            margin: const EdgeInsets.only(top: 20),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryText,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Cancel'.tr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            Get.back();
                            onConfirm();
                          },
                          child: Container(
                            margin: const EdgeInsets.only(top: 20),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Confirm'.tr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(child: Container()),
            ],
          ),
        ),
      ),
    );
  }

  static void info(String msg) {
    // AppHelper.showErrorGetSnackBar(message: msg);
    Fluttertoast.showToast(
      msg: msg.tr,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 4,
      toastLength: Toast.LENGTH_LONG,
      backgroundColor: AppColors.lightBlue.withOpacity(0.9),
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  static void error(String msg) {
    Fluttertoast.showToast(
      msg: msg.tr,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 3,
      backgroundColor: AppColors.error.withOpacity(0.8),
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  static void confirmDelete({
    required String msg,
    required String confirmText,
    required VoidCallback onConfirm,
  }) {
    Get.dialog(
      Center(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              Expanded(child: Container()),
              Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFF8BB86), // SweetAlert orange
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '!',
                          style: TextStyle(
                            fontSize: 40,
                            color: const Color(0xFFF8BB86), // SweetAlert orange
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Are you sure?'.tr,
                      style: const TextStyle(
                        color: Color(0xFF595959), // SweetAlert title color
                        fontSize: 24, // Larger title
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      msg,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF545454), // SweetAlert content color
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Get.back();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF717D8A), // Grey
                                borderRadius: BorderRadius.circular(6),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'No, cancel!'.tr,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Get.back();
                              onConfirm();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7066E0),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                confirmText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(child: Container()),
            ],
          ),
        ),
      ),
    );
  }
}

class AlertDialogWidget extends StatelessWidget {
  final List<Widget>? actionWidgets;
  final Widget? contentWidget;
  final Widget? titleWidget;
  final Color? backgroundColor;
  final bool isScrollable;
  const AlertDialogWidget({
    super.key,
    this.actionWidgets,
    this.contentWidget,
    this.titleWidget,
    this.backgroundColor,
    this.isScrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: AppUIComponents.borderRadius20,
      ),
      scrollable: isScrollable,
      titlePadding: EdgeInsets.fromLTRB(16, 0, 16, 18),
      contentPadding: EdgeInsets.fromLTRB(16, 20, 16, 20),
      title: titleWidget,
      content: contentWidget != null
          ? SizedBox(width: double.maxFinite, child: contentWidget)
          : null,
      actions: actionWidgets,
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: EdgeInsets.fromLTRB(16, 8, 16, 0),
      buttonPadding: EdgeInsets.zero,
    );
  }
}

class EnhancedDialogWidget extends StatelessWidget {
  final Widget? icon;
  final String title;
  final String? subtitle;
  final Widget? content;
  final Widget? primaryButton;
  final Widget? secondaryButton;
  final Color? backgroundColor;
  final bool isScrollable;
  final bool showCloseButton;

  const EnhancedDialogWidget({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    this.content,
    this.primaryButton,
    this.secondaryButton,
    this.backgroundColor,
    this.isScrollable = false,
    this.showCloseButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: backgroundColor ?? Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      scrollable: isScrollable,
      contentPadding: EdgeInsets.zero,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      content: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close button (positioned absolutely)
            if (showCloseButton)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: InkWell(
                    onTap: () => Get.back(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        color: AppColors.secondaryText,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),

            // Icon
            if (icon != null) ...[
              Padding(
                padding: EdgeInsets.only(
                  top: showCloseButton ? 0 : 20,
                  bottom: 24,
                ),
                child: icon,
              ),
            ] else ...[
              const SizedBox(height: 16),
            ],

            // Title and subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                      height: 1.2,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      subtitle!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondaryText,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Custom content
            if (content != null) ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: content,
              ),
            ],

            // Buttons
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: (primaryButton != null && secondaryButton != null)
                  ? Row(
                      children: [
                        Expanded(child: primaryButton!),
                        const SizedBox(width: 12),
                        Expanded(child: secondaryButton!),
                      ],
                    )
                  : Column(
                      children: [
                        if (primaryButton != null) primaryButton!,
                        if (secondaryButton != null) ...[
                          const SizedBox(height: 12),
                          secondaryButton!,
                        ],
                      ],
                    ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
