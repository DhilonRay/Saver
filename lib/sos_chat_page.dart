import 'package:flutter/material.dart';

class SOSChatPage extends StatefulWidget {
  const SOSChatPage({super.key});

  @override
  State<SOSChatPage> createState() => _SOSChatPageState();
}

class _SOSChatPageState extends State<SOSChatPage> {
  final List<ChatMessage> _messages = [];
  bool _presentingOptions = true;

  final List<String> _initialQuestions = [
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

  final Map<String, String> _answers = {
    "What is NeoSaver?":
        "NeoSaver is a smart emergency response app that connects users to nearby ground and air ambulances with live tracking and verified service providers.",
    "What is the emergency number?":
        "Call at 01793399913.",
    "How can I book an ambulance using NeoSaver?":
        "To book an ambulance:\n\n1. Open the NeoSaver app and log in.\n2. Enable location access.\n3. Tap the 'Book Ambulance' button.\n4. Select Your Preferable Air Ambulance  , Call the Number or Click On the Order Button , and confirm the booking.",
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

  void _handleInitialQuestion(String question) {
    setState(() {
      _presentingOptions = false;
      _messages.add(ChatMessage(text: question, isUser: true));
      if (_answers.containsKey(question)) {
        _messages.add(ChatMessage(text: _answers[question]!, isUser: false));
      }
      _presentingOptions = true;
    });
  }

  @override
  Widget build(BuildContext context) {
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
      ),
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          if (_presentingOptions)
            Padding(
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
                        children: _initialQuestions.map((question) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6.0),
                              child: ElevatedButton(
                                onPressed: () => _handleInitialQuestion(question),
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
            ),
          const Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey,
          ),
          Expanded(
            child: ListView.builder(
              reverse: false,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ChatBubble(message: message);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
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
                    color: Colors.black.withOpacity(0.05),
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