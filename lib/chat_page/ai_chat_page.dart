import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saver/components/constants/colors.dart';
import 'package:saver/components/constants/images.dart';
import 'package:saver/components/text_styles.dart';
import 'package:saver/components/widgets/buttons.dart';
import 'package:saver/components/widgets/core_widgets.dart';
import 'package:saver/components/widgets/space.dart';
import 'ai_chat_controller.dart';

class AIChatPage extends StatelessWidget {
  const AIChatPage({super.key});

  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color quickBtnBlue = Color(0xFFE8F4FC);
  static const Color emergencyGreen = Color(0xFF22C55E);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AIChatController>(
      init: AIChatController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(controller),
          body: Column(
            children: [
              // Quick Questions Section
              _buildQuickQuestionsSection(controller),

              // Chat Messages
              Expanded(
                child: Obx(() {
                  return ListView.builder(
                    controller: controller.scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: controller.messages.length +
                        (controller.isTyping.value ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == controller.messages.length &&
                          controller.isTyping.value) {
                        return _buildTypingIndicator();
                      }
                      final message = controller.messages[index];
                      return _buildMessageBubble(message);
                    },
                  );
                }),
              ),

              // Input Field
              _buildInputField(controller),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(AIChatController controller) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: AppColors.primaryText,
      leading: BackButtonWidget(onTap: () => Get.back()),
      title: Row(
        children: [
          // Robot avatar
          Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: lightBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              AppImages.robotPng,
              fit: BoxFit.contain,
            ),
          ),
          const HorizontalGap(12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'স্বাস্থ্য বন্ধু',
                style: AppTextStyles.bodyLargeSemibold,
              ),
              Text(
                'আপনার ব্যক্তিগত AI সহকারী',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TightIconButtonWidget(
          icon: Image.asset(
            AppImages.trashPng,
            width: 24,
            height: 24,
          ),
          onTap: controller.clearChat,
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: AppColors.border,
        ),
      ),
    );
  }

  Widget _buildQuickQuestionsSection(AIChatController controller) {
    return Obx(() {
      if (controller.messages.length <= 1) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: AppColors.border),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with checkbox icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.secondary),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.check,
                      size: 14,
                      color: AppColors.secondary,
                    ),
                  ),
                  const HorizontalGap(8),
                  Text(
                    'দ্রুত প্রশ্ন / Quick Questions',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
              const VerticalGap(16),
              // Quick action buttons
              _buildQuickActionButton(
                controller,
                '🚑',
                'অ্যাম্বুলেন্স বুক করব কিভাবে?',
              ),
              const VerticalGap(8),
              _buildQuickActionButton(
                controller,
                '🏥',
                'নিকটতম হাসপাতাল কোথায়?',
              ),
              const VerticalGap(12),
              Row(
                children: [
                  Expanded(
                    child: _buildCompactQuickButton(
                      controller,
                      AppImages.tipsPng,
                      'প্রাথমিক চিকিৎসা টিপস',
                      '💊 প্রাথমিক চিকিৎসা টিপস',
                    ),
                  ),
                  const HorizontalGap(12),
                  Expanded(
                    child: _buildCompactQuickButton(
                      controller,
                      null,
                      'জরুরি নম্বর কি?',
                      '📞 জরুরি নম্বর কি?',
                      icon: Icons.phone,
                      iconColor: emergencyGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }
      return const SizedBox.shrink();
    });
  }

  Widget _buildQuickActionButton(
    AIChatController controller,
    String emoji,
    String text,
  ) {
    return InkWell(
      onTap: () => controller.sendQuickAction('$emoji $text'),
      borderRadius: BorderRadius.circular(25),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: quickBtnBlue,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: const Color(0x331976D2)),
        ),
        child: Row(
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 18),
            ),
            const HorizontalGap(10),
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: primaryBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactQuickButton(
    AIChatController controller,
    String? imagePath,
    String text,
    String fullQuery, {
    IconData? icon,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: () => controller.sendQuickAction(fullQuery),
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: quickBtnBlue,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: const Color(0x331976D2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imagePath != null)
              Image.asset(
                imagePath,
                width: 20,
                height: 20,
              )
            else if (icon != null)
              Icon(
                icon,
                size: 18,
                color: iconColor ?? primaryBlue,
              ),
            const HorizontalGap(6),
            Flexible(
              child: Text(
                text,
                style: AppTextStyles.bodySmallMedium.copyWith(
                  color: primaryBlue,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(AIChatMessage message) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // AI Robot Avatar
            Container(
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: lightBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                AppImages.robotPng,
                fit: BoxFit.contain,
              ),
            ),
            const HorizontalGap(10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? primaryBlue : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
                border: isUser ? null : Border.all(color: AppColors.border),
              ),
              child: _buildMessageText(message.text, isUser),
            ),
          ),
          if (isUser) ...[
            const HorizontalGap(10),
            // User Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  AppImages.manPng,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.person,
                      color: AppColors.secondary,
                      size: 24,
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageText(String text, bool isUser) {
    return Text(
      text,
      style: AppTextStyles.body.copyWith(
        color: isUser ? Colors.white : AppColors.primaryText,
        height: 1.5,
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: lightBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              AppImages.robotPng,
              fit: BoxFit.contain,
            ),
          ),
          const HorizontalGap(10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const HorizontalGap(4),
                _buildDot(1),
                const HorizontalGap(4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: primaryBlue.withAlpha((77 + (value * 178)).toInt()),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildInputField(AIChatController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Text field container
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    // Pen/Edit icon
                    const Padding(
                      padding: EdgeInsets.only(left: 16),
                      child: Icon(
                        Icons.edit,
                        color: Color(0xFF9E9E9E),
                        size: 20,
                      ),
                    ),
                    // Text field
                    Expanded(
                      child: TextField(
                        controller: controller.textController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => controller.sendMessage(),
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.primaryText),
                        decoration: InputDecoration(
                          hintText: 'Write Here',
                          hintStyle: AppTextStyles.body.copyWith(
                            color: const Color(0xFF9E9E9E),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const HorizontalGap(12),
            // Send button
            Obx(() => Container(
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.sendMessage,
                    icon: controller.isLoading.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
