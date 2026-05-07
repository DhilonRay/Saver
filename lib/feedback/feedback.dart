import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saver/components/widgets/buttons.dart';
import 'package:saver/components/widgets/space.dart';
import 'feedback_controller.dart';

class FeedbackPage extends StatelessWidget {
  const FeedbackPage({super.key});

  static const Color primaryBlue = Color(0xFF1976D2);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<FeedbackController>(
      init: FeedbackController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text(
              'Feedback',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios,
                  color: Colors.black87, size: 20),
              onPressed: () => Get.back(),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: SidePaddedWidget(
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const VerticalGap(16),
                      // Header Icon
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: Image.asset(
                          'assets/images/feedback.png',
                          width: 100,
                          height: 100,
                          errorBuilder: (context, error, stackTrace) {
                            return SizedBox(
                              width: 100,
                              height: 100,
                              child: Icon(
                                Icons.feedback_outlined,
                                size: 80,
                                color: Colors.grey.shade700,
                              ),
                            );
                          },
                        ),
                      ),
                      const VerticalGap(16),
                      // Title
                      const Text(
                        'We Value Your Feedback!',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const VerticalGap(4),
                      // Subtitle
                      Text(
                        'Help us improve our service',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const VerticalGap(24),

                      // Name Field
                      TextFormField(
                        controller: controller.nameController,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          prefixIcon: Icon(Icons.person_outline,
                              color: Colors.grey.shade600),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: primaryBlue, width: 1.5),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        validator: controller.validateName,
                      ),
                      const VerticalGap(16),

                      // Email Field
                      TextFormField(
                        controller: controller.emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined,
                              color: Colors.grey.shade600),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: primaryBlue, width: 1.5),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: controller.validateEmail,
                      ),
                      const VerticalGap(20),

                      // Rating Section
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Rate your Experience',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                      const VerticalGap(8),
                      Obx(() => Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              return IconButton(
                                icon: Icon(
                                  index < controller.rating.value
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 36,
                                ),
                                onPressed: () =>
                                    controller.setRating(index + 1),
                              );
                            }),
                          )),
                      const VerticalGap(16),

                      // Feedback Field
                      TextFormField(
                        controller: controller.feedbackController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Feedback',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: primaryBlue, width: 1.5),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        validator: controller.validateFeedback,
                      ),
                      const VerticalGap(16),

                      // Attachment Section
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Attachments (Max ${FeedbackController.maxFileCount})',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            Obx(() => Text(
                                  '${controller.selectedFiles.length}/${FeedbackController.maxFileCount}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                )),
                          ],
                        ),
                      ),
                      const VerticalGap(8),
                      Obx(() => Column(
                            children: [
                              // List of selected files
                              ...List.generate(controller.selectedFiles.length,
                                  (index) {
                                final file = controller.selectedFiles[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.blue.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.insert_drive_file,
                                          color: Colors.blue.shade700),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              file.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const Text(
                                              'File attached successfully',
                                              style: TextStyle(
                                                color: Colors.blue,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close,
                                            color: Colors.red, size: 20),
                                        onPressed: () =>
                                            controller.removeAttachment(index),
                                      ),
                                    ],
                                  ),
                                );
                              }),

                              // Add more button
                              if (controller.selectedFiles.length <
                                  FeedbackController.maxFileCount)
                                InkWell(
                                  onTap: controller.pickAttachment,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.grey.shade300,
                                          style: BorderStyle.solid),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(Icons.add_a_photo_outlined,
                                            color: Colors.grey.shade600),
                                        const SizedBox(height: 8),
                                        Text(
                                          controller.selectedFiles.isEmpty
                                              ? 'Attach Photos (Max 10 MB)'
                                              : 'Add Another Photo',
                                          style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          )),
                      const VerticalGap(24),

                      // Submit Button
                      Obx(() => FilledButtonWidget(
                            onTap: controller.isSubmitting.value
                                ? null
                                : controller.submitFeedback,
                            isStretched: true,
                            minHeight: 50,
                            backgroundColor: primaryBlue,
                            borderRadiusValue: 8,
                            isLoading: controller.isSubmitting.value,
                            buttonText: 'Submit Feedback',
                            buttonTextStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          )),
                      const VerticalGap(24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
