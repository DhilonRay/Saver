import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/api_keys_secret.dart';

class AIChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  AIChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AIChatController extends GetxController {
  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final messages = <AIChatMessage>[].obs;
  final isLoading = false.obs;
  final isTyping = false.obs;

  // Gemini API key - loaded from secret file (git-ignored)
  // Create lib/config/api_keys_secret.dart with your actual key
  static const String _geminiApiKey = ApiKeysSecret.geminiApiKey;
  static const String _geminiApiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  // Flag to track if API is available
  var useLocalResponses = false.obs;

  // System context for the AI
  final String _systemPrompt = '''
আপনি NeoSaver অ্যাপের একটি সহায়ক AI সহকারী। আপনি শুধুমাত্র নিচের দুটি বিষয়ের উত্তর দেবেন:

১. স্বাস্থ্য সংক্রান্ত প্রশ্ন (Health related questions):
- প্রাথমিক চিকিৎসা (First aid)
- জরুরি নির্দেশনা (Emergency guidance - অ-নিদানিক/non-diagnostic)
- সাধারণ স্বাস্থ্য সচেতনতা (Basic health awareness)

২. NeoSaver সংক্রান্ত প্রশ্ন (NeoSaver related questions):
- অ্যাম্বুলেন্স বুকিং পদ্ধতি (How to book ambulance)
- পেমেন্ট প্রক্রিয়া (Payment process)
- নিরাপত্তা ও সেবা সংক্রান্ত তথ্য (Safety & service info)
- অ্যাপ ব্যবহারের নিয়ম (App usage help)

অন্য কোনো বিষয় (রাজনীতি, ব্যক্তিগত আলাপ, শিক্ষা, সাধারণ জ্ঞান বা অন্য কোনো সম্পর্কহীন তথ্য) নিয়ে প্রশ্ন করলে আপনি বিনীতভাবে উত্তর দিতে অস্বীকার করবেন। আপনার উত্তরগুলো সংক্ষিপ্ত এবং সহায়ক হতে হবে।

You are a helpful AI assistant for the NeoSaver app. You ONLY respond to the following two categories:

1. Health-related questions:
- First aid
- Emergency guidance (non-diagnostic)
- Basic health awareness

2. NeoSaver-related questions:
- How to book an ambulance
- Payment process
- Safety & service info
- App usage help

DO NOT answer any other topics (politics, personal chat, general knowledge, or any unrelated information). If asked about these, politely decline to answer.
''';

  // Conversation history for context
  final List<Map<String, String>> _conversationHistory = [];

  @override
  void onInit() {
    super.onInit();
    _addWelcomeMessage();
    _loadChatHistory();
  }

  @override
  void onClose() {
    textController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void _addWelcomeMessage() {
    messages.add(AIChatMessage(
      text:
          '🤖 স্বাগতম! আমি NeoSaver AI সহকারী।\n\nআমাকে যেকোনো প্রশ্ন করতে পারেন:\n• জরুরি চিকিৎসা সংক্রান্ত তথ্য\n• অ্যাম্বুলেন্স বুকিং সাহায্য\n• প্রাথমিক চিকিৎসা পরামর্শ\n• অ্যাপ ব্যবহার গাইড\n\nWelcome! I am NeoSaver AI Assistant. Feel free to ask me anything!',
      isUser: false,
    ));
  }

  Future<void> _loadChatHistory() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('ai_chat_history')
          .orderBy('timestamp', descending: false)
          .limit(50)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Clear the welcome message if we have history
        messages.clear();

        for (var doc in snapshot.docs) {
          final data = doc.data();
          messages.add(AIChatMessage(
            text: data['text'] ?? '',
            isUser: data['isUser'] ?? false,
            timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
          ));

          // Rebuild conversation history for context
          _conversationHistory.add({
            'role': data['isUser'] == true ? 'user' : 'model',
            'parts': data['text'] ?? '',
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading chat history: $e');
    }
  }

  Future<void> _saveChatMessage(AIChatMessage message) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('ai_chat_history')
          .add({
        'text': message.text,
        'isUser': message.isUser,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error saving chat message: $e');
    }
  }

  Future<void> sendMessage() async {
    final text = textController.text.trim();
    if (text.isEmpty) return;

    // Add user message
    final userMessage = AIChatMessage(text: text, isUser: true);
    messages.add(userMessage);
    textController.clear();
    _saveChatMessage(userMessage);

    // Add to conversation history
    _conversationHistory.add({'role': 'user', 'parts': text});

    // Scroll to bottom
    _scrollToBottom();

    // Show typing indicator
    isLoading.value = true;
    isTyping.value = true;

    try {
      final response = await _getGeminiResponse(text);

      // Add AI response
      final aiMessage = AIChatMessage(text: response, isUser: false);
      messages.add(aiMessage);
      _saveChatMessage(aiMessage);

      // Add to conversation history
      _conversationHistory.add({'role': 'model', 'parts': response});

      // Keep conversation history manageable (last 20 messages)
      if (_conversationHistory.length > 20) {
        _conversationHistory.removeRange(0, _conversationHistory.length - 20);
      }
    } catch (e) {
      debugPrint('Error getting AI response: $e');
      messages.add(AIChatMessage(
        text:
            '⚠️ দুঃখিত, কিছু সমস্যা হয়েছে। আবার চেষ্টা করুন।\n\nSorry, something went wrong. Please try again.',
        isUser: false,
      ));
    } finally {
      isLoading.value = false;
      isTyping.value = false;
      _scrollToBottom();
    }
  }

  Future<String> _getGeminiResponse(String userMessage) async {
    // Check if API key is placeholder or use local responses
    if (_geminiApiKey == 'YOUR_GEMINI_API_KEY_HERE' ||
        _geminiApiKey.isEmpty ||
        useLocalResponses.value) {
      return _getLocalResponse(userMessage);
    }

    try {
      // Build the conversation with system prompt
      final List<Map<String, dynamic>> contents = [];

      // Add system context as first message
      contents.add({
        'role': 'user',
        'parts': [
          {'text': _systemPrompt}
        ]
      });
      contents.add({
        'role': 'model',
        'parts': [
          {
            'text':
                'বুঝেছি। আমি NeoSaver AI সহকারী হিসেবে সাহায্য করতে প্রস্তুত।'
          }
        ]
      });

      // Add conversation history
      for (var msg in _conversationHistory) {
        contents.add({
          'role': msg['role'],
          'parts': [
            {'text': msg['parts']}
          ]
        });
      }

      final response = await http.post(
        Uri.parse('$_geminiApiUrl?key=$_geminiApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': contents,
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            return parts[0]['text'] ?? 'কোন উত্তর পাওয়া যায়নি।';
          }
        }
        return 'কোন উত্তর পাওয়া যায়নি। আবার চেষ্টা করুন।';
      } else {
        debugPrint(
            'Gemini API error: ${response.statusCode} - ${response.body}');
        // Switch to local responses on API error
        useLocalResponses.value = true;
        return _getLocalResponse(userMessage);
      }
    } catch (e) {
      debugPrint('Error calling Gemini API: $e');
      // Switch to local responses on error
      useLocalResponses.value = true;
      return _getLocalResponse(userMessage);
    }
  }

  // Local response system for when API is unavailable
  String _getLocalResponse(String query) {
    final lowerQuery = query.toLowerCase();

    // Ambulance booking related
    if (lowerQuery.contains('অ্যাম্বুলেন্স') ||
        lowerQuery.contains('ambulance') ||
        lowerQuery.contains('বুক') ||
        lowerQuery.contains('book')) {
      return '''🚑 **অ্যাম্বুলেন্স বুক করার পদ্ধতি:**

1️⃣ হোম পেজে গিয়ে গন্তব্য (Destination) লিখুন
2️⃣ "Available Ambulances" এ ক্লিক করুন
3️⃣ পছন্দের অ্যাম্বুলেন্স সিলেক্ট করুন
4️⃣ "Book Now" বাটনে ক্লিক করুন
5️⃣ অর্ডার কনফার্ম হলে ট্র্যাক করুন

📞 জরুরি হেল্পলাইন: +8801793399913

**How to book an ambulance:**
1. Enter destination on home page
2. Click "Available Ambulances"
3. Select your preferred ambulance
4. Click "Book Now"
5. Track your order once confirmed''';
    }

    // Emergency numbers
    if (lowerQuery.contains('জরুরি') ||
        lowerQuery.contains('নম্বর') ||
        lowerQuery.contains('emergency') ||
        lowerQuery.contains('number') ||
        lowerQuery.contains('999') ||
        lowerQuery.contains('call')) {
      return '''📞 **জরুরি নম্বর সমূহ:**

🚨 জাতীয় জরুরি সেবা: **999** (ফ্রি)
🚑 NeoSaver হেল্পলাইন: **+8801793399913**
🏥 স্বাস্থ্য বাতায়ন: **16263**
🔥 ফায়ার সার্ভিস: **199**
👮 পুলিশ: **999**

**Emergency Numbers:**
- National Emergency: 999 (Free)
- NeoSaver Helpline: +8801793399913
- Health Hotline: 16263
- Fire Service: 199''';
    }

    // Hospital related
    if (lowerQuery.contains('হাসপাতাল') ||
        lowerQuery.contains('hospital') ||
        lowerQuery.contains('নিকটতম') ||
        lowerQuery.contains('nearest')) {
      return '''🏥 **নিকটতম হাসপাতাল খুঁজতে:**

1️⃣ হোম পেজে সার্চ বক্সে "Hospital" লিখুন
2️⃣ আপনার এলাকার নাম যোগ করুন (যেমন: "Hospital Dhaka")
3️⃣ সাজেশন থেকে সিলেক্ট করুন
4️⃣ ম্যাপে রুট দেখুন

💡 টিপস: জরুরি অবস্থায় 999 কল করুন

**To find nearest hospital:**
1. Type "Hospital" in search box
2. Add your area name
3. Select from suggestions
4. View route on map''';
    }

    // First aid
    if (lowerQuery.contains('প্রাথমিক') ||
        lowerQuery.contains('চিকিৎসা') ||
        lowerQuery.contains('first aid') ||
        lowerQuery.contains('টিপস') ||
        lowerQuery.contains('tips')) {
      return '''💊 **প্রাথমিক চিকিৎসা টিপস:**

🩸 **রক্তপাত হলে:**
- পরিষ্কার কাপড় দিয়ে চাপ দিন
- আক্রান্ত স্থান উঁচু করে রাখুন

🔥 **পুড়ে গেলে:**
- ঠাণ্ডা পানি দিয়ে ধুয়ে দিন (১০-২০ মিনিট)
- বরফ সরাসরি দেবেন না

😵 **অজ্ঞান হলে:**
- চিৎ করে শুইয়ে দিন
- পা উঁচু করে রাখুন
- শ্বাস-প্রশ্বাস চেক করুন

⚠️ **গুরুতর অবস্থায় অবশ্যই 999 কল করুন!**

*এটি শুধুমাত্র প্রাথমিক তথ্য। ডাক্তারের পরামর্শ নিন।*''';
    }

    // Tracking
    if (lowerQuery.contains('ট্র্যাক') ||
        lowerQuery.contains('track') ||
        lowerQuery.contains('কোথায়') ||
        lowerQuery.contains('where')) {
      return '''📍 **অ্যাম্বুলেন্স ট্র্যাক করার উপায়:**

1️⃣ মেনু (☰) থেকে "Tracking" এ যান
2️⃣ অথবা "Your Orders" এ গিয়ে অর্ডার সিলেক্ট করুন
3️⃣ রিয়েল-টাইম লোকেশন ম্যাপে দেখুন
4️⃣ ড্রাইভারের সাথে সরাসরি কল করতে পারবেন

**How to track ambulance:**
1. Go to "Tracking" from menu
2. Or select order from "Your Orders"
3. View real-time location on map
4. Call driver directly if needed''';
    }

    // App usage / help
    if (lowerQuery.contains('কিভাবে') ||
        lowerQuery.contains('how') ||
        lowerQuery.contains('সাহায্য') ||
        lowerQuery.contains('help') ||
        lowerQuery.contains('ব্যবহার') ||
        lowerQuery.contains('use')) {
      return '''📱 **NeoSaver অ্যাপ ব্যবহার গাইড:**

🏠 **হোম পেজ:**
- গন্তব্য সার্চ করুন
- ম্যাপে অ্যাম্বুলেন্স দেখুন
- AI বাটনে ক্লিক করে সাহায্য নিন

📋 **মেনু অপশন:**
- Profile: প্রোফাইল দেখুন/এডিট করুন
- Your Orders: অর্ডার হিস্ট্রি দেখুন
- Tracking: অ্যাম্বুলেন্স ট্র্যাক করুন
- Available Ambulances: সব অ্যাম্বুলেন্স দেখুন

📞 **জরুরি কল:** লাল কল বাটনে ক্লিক করুন

**কোন সমস্যা হলে Feedback দিন!**''';
    }

    // Generic greetings are allowed but should point to scope
    if (lowerQuery.contains('হাই') ||
        lowerQuery.contains('হ্যালো') ||
        lowerQuery.contains('hi') ||
        lowerQuery.contains('hello')) {
      return '''👋 হ্যালো! আমি NeoSaver AI সহকারী।

আমি শুধুমাত্র স্বাস্থ্য সংক্রান্ত এবং NeoSaver অ্যাপ সংক্রান্ত তথ্য দিতে পারি। আপনাকে কিভাবে সাহায্য করতে পারি?

Hello! I'm NeoSaver AI Assistant. I can only help with health-related or NeoSaver-related questions. How can I help you today?''';
    }

    // Out of scope detection for local response
    final outOfScopeTerms = [
      'politics',
      'রাজনীতি',
      'game',
      'খেলা',
      'movie',
      'ছবি',
      'song',
      'গান',
      'weather',
      'আবহাওয়া',
      'news',
      'খবর'
    ];
    for (var term in outOfScopeTerms) {
      if (lowerQuery.contains(term)) {
        return '''🤖 দুঃখিত, আমি শুধুমাত্র স্বাস্থ্য সংক্রান্ত এবং NeoSaver অ্যাপ সংক্রান্ত প্রশ্নের উত্তর দিতে পারি।

Sorry, I can only answer questions related to Health and the NeoSaver app.''';
      }
    }

    // Default response for unrecognized but potentially in-scope queries
    return '''🤖 আমি আপনার প্রশ্ন বুঝতে পেরেছি।

আমি এই বিষয়গুলোতে সাহায্য করতে পারি:

🚑 **অ্যাম্বুলেন্স বুকিং** - "অ্যাম্বুলেন্স বুক করব কিভাবে?"
💊 **প্রাথমিক চিকিৎসা** - "প্রাথমিক চিকিৎসা টিপস"
📱 **অ্যাপ সাহায্য** - "অ্যাপ কিভাবে ব্যবহার করব?"

অন্য কোনো বিষয়ে (যেমন রাজনীতি বা ব্যক্তিগত আলাপ) আমি উত্তর দিতে পারি না।

I can help with ambulance booking, first aid, and app usage. I cannot participate in other topics like politics or personal chats.''';
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void clearChat() {
    Get.dialog(
      AlertDialog(
        title: const Text('চ্যাট মুছুন'),
        content: const Text(
            'সব চ্যাট মুছে ফেলতে চান?\n\nAre you sure you want to clear all chat?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('বাতিল'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              messages.clear();
              _conversationHistory.clear();
              _addWelcomeMessage();

              // Clear from Firestore
              try {
                final userId = FirebaseAuth.instance.currentUser?.uid;
                if (userId != null) {
                  final batch = FirebaseFirestore.instance.batch();
                  final snapshot = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection('ai_chat_history')
                      .get();

                  for (var doc in snapshot.docs) {
                    batch.delete(doc.reference);
                  }
                  await batch.commit();
                }
              } catch (e) {
                debugPrint('Error clearing chat history: $e');
              }
            },
            child: const Text('মুছুন', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Quick action buttons for common queries
  final List<String> quickActions = [
    '🚑 অ্যাম্বুলেন্স বুক করব কিভাবে?',
    '🏥 নিকটতম হাসপাতাল কোথায়?',
    '💊 প্রাথমিক চিকিৎসা টিপস',
    '📞 জরুরি নম্বর কি?',
  ];

  void sendQuickAction(String action) {
    textController.text = action;
    sendMessage();
  }
}
