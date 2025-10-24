import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'sos_chat_controller.dart';

class SOSChatPage extends StatelessWidget {
  const SOSChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SOSChatController>(
      init: SOSChatController(),
      builder: (controller) {
        final screenHeight = MediaQuery.of(context).size.height;
        final questionListHeight = screenHeight * 0.25;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'SOS Chat',
              style: TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
            ),
            backgroundColor: Colors.blueGrey.shade800,
            elevation: 2,
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: controller.clearChat,
                tooltip: 'Clear Chat',
              ),
            ],
          ),
          backgroundColor: Colors.grey.shade100,
          body: Column(
            children: [
              Obx(() {
                if (controller.presentingOptions.value) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "Choose a common emergency question:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey.shade800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: questionListHeight - 64,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: controller.initialQuestions.map((question) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                                    child: ElevatedButton(
                                      onPressed: () => controller.handleInitialQuestion(question),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blueGrey.shade300,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8.0),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                      ),
                                      child: Text(
                                        question,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  )).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              const Divider(
                height: 1,
                thickness: 1,
                color: Colors.grey,
              ),
              Expanded(
                child: Obx(() {
                  return ListView.builder(
                    reverse: false,
                    itemCount: controller.messages.length,
                    itemBuilder: (context, index) {
                      final message = controller.messages[index];
                      return ChatBubble(message: message);
                    },
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser)
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                backgroundColor: Colors.grey,
                child: Icon(Icons.phone_android_rounded,
                    color: Color.fromARGB(255, 227, 245, 95)),
              ),
            ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: message.isUser ? Colors.blueGrey.shade200 : Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [
                  BoxShadow(
                    offset: Offset(0, 1),
                    blurRadius: 1,
                    color: Colors.black.withValues(alpha: 0.05),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser
                      ? Colors.white
                      : Colors.blueGrey.shade800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          if (message.isUser)
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: CircleAvatar(
                backgroundColor: Colors.blueGrey,
                child: Icon(Icons.person, color: Color.fromARGB(255, 8, 254, 29)),
              ),
            ),
        ],
      ),
    );
  }
}
