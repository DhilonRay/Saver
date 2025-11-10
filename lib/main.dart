import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saver/splash_page/splash_page.dart';
import 'package:saver/partner_file/accept_maps/accept_maps.dart';
import 'package:saver/services/notification_service.dart';
import 'package:saver/privacy_policy/privacy_policy.dart';
import 'package:saver/terms_condition/terms_condition.dart';
import 'package:saver/feedback/feedback.dart';
import 'package:saver/partner_file/partner_profile/partner_profile.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

 
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  //06d22db9f1e31db564c7cd0ba23662f000b8f0a8

  // Initialize comprehensive FCM setup
  await NotificationService.setupFCMOnAppStart();

  // Handle background messages
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📩 BACKGROUND MESSAGE RECEIVED: ${message.messageId}');
  print('📩 Message data: ${message.data}');
  print('📩 Message notification: ${message.notification?.title} - ${message.notification?.body}');

  // Initialize local notifications if needed
  await NotificationService.initializeLocalNotificationsForBackground();

  // Show local notification for background messages
  await NotificationService.showBackgroundNotification(message);

  // Add notification to partner's notification list for when app is opened
  if (message.notification != null) {
    try {
      // We can't get current user in background, so we'll handle this when app opens
      // The notification will be added when FirebaseMessaging.onMessageOpenedApp is triggered
      print('📱 Background notification will be added to partner list when app opens');
    } catch (e) {
      print('❌ Error handling background notification: $e');
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'NeoSaver',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home:  SplashPage(),
      getPages: [
        GetPage(name: '/accept-maps', page: () => AcceptMapsPage()),
     
        GetPage(name: '/feedback', page: () => const FeedbackPage()),
        GetPage(name: '/partner-profile', page: () => const PartnerProfilePage()),
        GetPage(name: '/privacy-policy', page: () => const PrivacyPolicyPage()),
        GetPage(name: '/terms-conditions', page: () => const TermsConditionPage()),
      ],
    );
  }
}