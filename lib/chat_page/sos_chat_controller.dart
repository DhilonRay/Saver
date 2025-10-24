import 'package:get/get.dart';

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class SOSChatController extends GetxController {
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxBool presentingOptions = true.obs;

  final List<String> initialQuestions = [
    "What is NeoSaver?",
    "What is the emergency number?",
    "How can I book an ambulance using NeoSaver?",
    "Is NeoSaver available in all areas of Bangladesh?",
    "How does NeoSaver ensure safety during ambulance rides?",
    "Does NeoSaver offer air ambulance services?",
    "How much does a NeoSaver air ambulance cost?",
    "Tell me more about ground ambulance services.",
    "What about air ambulance coverage?",
    "Are the ambulance providers verified?",
    "Is GPS tracking always active?",
    "Can I get a cost estimate before booking?",
  ];

  final Map<String, String> answers = {
    "What is NeoSaver?":
        "NeoSaver is a smart emergency response app that connects users to nearby ground and air ambulances with live tracking and verified service providers.",
    "What is the emergency number?":
        "Call at 01793399913.",
    "How can I book an ambulance using NeoSaver?":
        "To book an ambulance:\n\n1. Open the NeoSaver app and log in.\n2. Enable location access.\n3. Tap the 'Book Ambulance' button.\n4. Select Your Preferable Air Ambulance  , Call the Number or Click On the Order Button , and confirm the booking.",
    "Is NeoSaver available in all areas of Bangladesh?":
        "Currently, NeoSaver is expanding gradually. Ground ambulance services are available in major cities, and air ambulance coverage is being rolled out in emergency-prone zones.",
    "How does NeoSaver ensure safety during ambulance rides?":
        "NeoSaver verifies every ambulance provider. All rides are GPS-tracked in real-time, and users receive driver, vehicle, and route details for maximum safety.",
    "Does NeoSaver offer air ambulance services?":
        "Yes, NeoSaver now offers emergency air ambulance services via helicopters for critical cases requiring fast transport to hospitals.",
    "How much does a NeoSaver air ambulance cost?":
        "Air ambulance prices depend on distance and location. Users can request a quote directly in the app or contact our 24/7 support team for emergency pricing.",
    "Tell me more about ground ambulance services.":
        "Our ground ambulance services are equipped with essential medical equipment and staffed by trained paramedics to provide immediate care during transit.",
    "What about air ambulance coverage?":
        "Our air ambulance services are focused on critical emergency zones and major hospital locations. Please check the app for specific coverage areas.",
    "Are the ambulance providers verified?":
        "Yes, every ambulance provider on the NeoSaver platform undergoes a strict verification process to ensure reliability and safety.",
    "Is GPS tracking always active?":
        "Yes, for safety and transparency, GPS tracking is active throughout the entire ambulance ride.",
    "Can I get a cost estimate before booking?":
        "For ground ambulances, the app provides an estimated cost based on distance. For air ambulances, please request a direct quote within the app or contact our support team.",
  };

  void handleInitialQuestion(String question) {
    presentingOptions.value = false;
    messages.add(ChatMessage(text: question, isUser: true));
    if (answers.containsKey(question)) {
      messages.add(ChatMessage(text: answers[question]!, isUser: false));
    }
    presentingOptions.value = true;
  }

  void clearChat() {
    messages.clear();
    presentingOptions.value = true;
  }
}
